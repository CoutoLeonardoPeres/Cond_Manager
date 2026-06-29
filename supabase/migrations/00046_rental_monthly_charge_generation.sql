-- Gera cobranças de aluguel mensais ao atingir a data de vencimento.
-- Pode ser chamada pelo app (RPC) ou por job agendado (pg_cron).

CREATE UNIQUE INDEX IF NOT EXISTS idx_rental_charges_lease_ref_month
  ON rental_charges (lease_id, reference_month)
  WHERE lease_id IS NOT NULL
    AND charge_type = 'rent'
    AND status <> 'cancelled'
    AND reference_month IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_rental_charges_booking_ref_month
  ON rental_charges (booking_id, reference_month)
  WHERE booking_id IS NOT NULL
    AND charge_type = 'rent'
    AND status <> 'cancelled'
    AND reference_month IS NOT NULL;

CREATE OR REPLACE FUNCTION rental_month_due_date(p_ref_month DATE, p_due_day SMALLINT)
RETURNS DATE
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT make_date(
    EXTRACT(YEAR FROM p_ref_month)::INT,
    EXTRACT(MONTH FROM p_ref_month)::INT,
    LEAST(
      p_due_day,
      EXTRACT(
        DAY FROM (DATE_TRUNC('month', p_ref_month) + INTERVAL '1 month - 1 day')
      )::INT
    )
  );
$$;

CREATE OR REPLACE FUNCTION generate_rental_monthly_charges(p_as_of DATE DEFAULT CURRENT_DATE)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ref_month DATE := DATE_TRUNC('month', p_as_of)::DATE;
  v_created INTEGER := 0;
  v_row RECORD;
  v_due_date DATE;
BEGIN
  -- Contratos ativos com dia de vencimento configurado.
  FOR v_row IN
    SELECT
      rl.id AS lease_id,
      rl.company_id,
      rl.property_id,
      rl.primary_tenant_party_id AS party_id,
      rl.monthly_rent,
      rl.due_day_of_month,
      rl.start_date,
      rl.end_date,
      rp.title AS property_title
    FROM rental_leases rl
    JOIN rental_properties rp ON rp.id = rl.property_id
    WHERE rl.status = 'active'
      AND rl.due_day_of_month IS NOT NULL
      AND rl.monthly_rent > 0
      AND rl.start_date <= p_as_of
      AND (rl.end_date IS NULL OR rl.end_date >= v_ref_month)
  LOOP
    v_due_date := rental_month_due_date(v_ref_month, v_row.due_day_of_month);

    IF p_as_of < v_due_date THEN
      CONTINUE;
    END IF;

    IF v_row.start_date > v_due_date THEN
      CONTINUE;
    END IF;

    IF EXISTS (
      SELECT 1
      FROM rental_charges rc
      WHERE rc.lease_id = v_row.lease_id
        AND rc.charge_type = 'rent'
        AND rc.status <> 'cancelled'
        AND (
          rc.reference_month = v_ref_month
          OR (
            rc.reference_month IS NULL
            AND rc.due_date >= v_ref_month
            AND rc.due_date < (v_ref_month + INTERVAL '1 month')::DATE
          )
        )
    ) THEN
      CONTINUE;
    END IF;

    INSERT INTO rental_charges (
      company_id,
      lease_id,
      party_id,
      property_id,
      charge_type,
      status,
      description,
      amount,
      due_date,
      reference_month,
      notes
    ) VALUES (
      v_row.company_id,
      v_row.lease_id,
      v_row.party_id,
      v_row.property_id,
      'rent',
      'pending',
      'Aluguel — ' || v_row.property_title || ' — ' ||
        TO_CHAR(v_ref_month, 'MM/YYYY'),
      v_row.monthly_rent,
      v_due_date,
      v_ref_month,
      'Gerado automaticamente na data de vencimento.'
    );

    v_created := v_created + 1;
  END LOOP;

  -- Reservas com aluguel fixo mensal.
  FOR v_row IN
    SELECT
      rb.id AS booking_id,
      rb.company_id,
      rb.property_id,
      rb.guest_party_id AS party_id,
      rb.monthly_rent,
      rb.payment_due_day,
      rb.check_in,
      rb.check_out,
      rp.title AS property_title
    FROM rental_bookings rb
    JOIN rental_properties rp ON rp.id = rb.property_id
    WHERE rb.is_fixed_rent = TRUE
      AND rb.payment_due_day IS NOT NULL
      AND rb.monthly_rent > 0
      AND rb.status IN ('confirmed', 'checked_in')
      AND rb.check_in <= p_as_of
      AND rb.check_out > v_ref_month
  LOOP
    v_due_date := rental_month_due_date(v_ref_month, v_row.payment_due_day);

    IF p_as_of < v_due_date THEN
      CONTINUE;
    END IF;

    IF v_row.check_in > v_due_date THEN
      CONTINUE;
    END IF;

    IF v_due_date >= v_row.check_out THEN
      CONTINUE;
    END IF;

    IF EXISTS (
      SELECT 1
      FROM rental_charges rc
      WHERE rc.booking_id = v_row.booking_id
        AND rc.charge_type = 'rent'
        AND rc.status <> 'cancelled'
        AND (
          rc.reference_month = v_ref_month
          OR (
            rc.reference_month IS NULL
            AND rc.due_date >= v_ref_month
            AND rc.due_date < (v_ref_month + INTERVAL '1 month')::DATE
          )
        )
    ) THEN
      CONTINUE;
    END IF;

    INSERT INTO rental_charges (
      company_id,
      booking_id,
      party_id,
      property_id,
      charge_type,
      status,
      description,
      amount,
      due_date,
      reference_month,
      notes
    ) VALUES (
      v_row.company_id,
      v_row.booking_id,
      v_row.party_id,
      v_row.property_id,
      'rent',
      'pending',
      'Aluguel fixo — ' || v_row.property_title || ' — ' ||
        TO_CHAR(v_ref_month, 'MM/YYYY'),
      v_row.monthly_rent,
      v_due_date,
      v_ref_month,
      'Gerado automaticamente na data de vencimento.'
    );

    v_created := v_created + 1;
  END LOOP;

  RETURN v_created;
END;
$$;

GRANT EXECUTE ON FUNCTION generate_rental_monthly_charges(DATE) TO authenticated;

NOTIFY pgrst, 'reload schema';
