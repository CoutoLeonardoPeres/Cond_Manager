-- Isolamento multi-tenant: finanças da gestora, geração de cobranças, RLS financeiro e storage
-- Migration: 00053

-- ---------------------------------------------------------------------------
-- 1. financial_records.management_company_id
-- ---------------------------------------------------------------------------
ALTER TABLE financial_records
  ADD COLUMN IF NOT EXISTS management_company_id UUID
    REFERENCES management_companies(id) ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS idx_financial_management_company
  ON financial_records(management_company_id)
  WHERE management_company_id IS NOT NULL;

UPDATE financial_records fr
SET management_company_id = sub.company_id
FROM (
  SELECT fr2.id,
         (
           SELECT cm.company_id
           FROM company_memberships cm
           WHERE cm.user_id = fr2.created_by
             AND cm.status = 'active'
           ORDER BY cm.created_at
           LIMIT 1
         ) AS company_id
  FROM financial_records fr2
  WHERE fr2.scope = 'management_company'
    AND fr2.management_company_id IS NULL
    AND fr2.created_by IS NOT NULL
) sub
WHERE fr.id = sub.id
  AND sub.company_id IS NOT NULL;

-- Registros legados sem empresa identificável não podem permanecer neste escopo.
DELETE FROM financial_records
WHERE scope = 'management_company'
  AND management_company_id IS NULL;

ALTER TABLE financial_records
  DROP CONSTRAINT IF EXISTS financial_scope_condo;

ALTER TABLE financial_records
  ADD CONSTRAINT financial_scope_condo CHECK (
    (scope = 'condominium' AND condominium_id IS NOT NULL)
    OR (scope = 'management_company' AND management_company_id IS NOT NULL)
  );

-- ---------------------------------------------------------------------------
-- 2. Funções financeiras alinhadas ao modelo organizacional
-- ---------------------------------------------------------------------------
-- Policies dependem das funções antigas (sem parâmetro) — remover antes de recriar.
DROP POLICY IF EXISTS financial_select ON financial_records;
DROP POLICY IF EXISTS financial_modify ON financial_records;

DROP FUNCTION IF EXISTS can_view_management_financial();
DROP FUNCTION IF EXISTS can_manage_management_financial();

CREATE OR REPLACE FUNCTION can_view_financial(p_condominium_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_platform_admin()
    OR EXISTS (
      SELECT 1 FROM user_condominium_roles
      WHERE user_id = auth.uid()
        AND condominium_id = p_condominium_id
        AND status = 'active'
        AND role IN (
          'condominium_admin', 'syndic', 'financial', 'maintenance_manager', 'auditor'
        )
    )
    OR (
      condominium_belongs_to_user_company(p_condominium_id)
      AND EXISTS (
        SELECT 1 FROM company_memberships cm
        JOIN condominiums c ON c.management_company_id = cm.company_id
        WHERE c.id = p_condominium_id
          AND cm.user_id = auth.uid()
          AND cm.status = 'active'
          AND cm.role IN ('manager', 'analyst')
      )
    );
$$;

CREATE OR REPLACE FUNCTION can_view_management_financial(p_company_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_platform_admin()
    OR (
      p_company_id IS NOT NULL
      AND has_company_access(p_company_id)
      AND get_user_organization_role(p_company_id) IN ('manager', 'analyst')
    );
$$;

CREATE OR REPLACE FUNCTION can_manage_management_financial(p_company_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_platform_admin()
    OR (
      p_company_id IS NOT NULL
      AND has_company_access(p_company_id)
      AND is_company_manager(p_company_id)
    );
$$;

CREATE POLICY financial_select ON financial_records FOR SELECT
  USING (
    (
      scope = 'condominium'
      AND condominium_id IS NOT NULL
      AND can_view_financial(condominium_id)
    )
    OR (
      scope = 'management_company'
      AND management_company_id IS NOT NULL
      AND can_view_management_financial(management_company_id)
    )
  );

CREATE POLICY financial_modify ON financial_records FOR ALL
  USING (
    (
      scope = 'condominium'
      AND condominium_id IS NOT NULL
      AND (
        get_user_role(condominium_id) IN ('condominium_admin', 'financial')
        OR (
          user_has_module('rental')
          AND EXISTS (
            SELECT 1 FROM condominiums c
            WHERE c.id = condominium_id
              AND c.management_company_id IS NOT NULL
              AND c.management_company_id = get_user_company_id()
              AND is_company_manager(c.management_company_id)
          )
        )
      )
    )
    OR (
      scope = 'management_company'
      AND management_company_id IS NOT NULL
      AND can_manage_management_financial(management_company_id)
    )
  )
  WITH CHECK (
    (
      scope = 'condominium'
      AND condominium_id IS NOT NULL
      AND (
        get_user_role(condominium_id) IN ('condominium_admin', 'financial')
        OR (
          user_has_module('rental')
          AND EXISTS (
            SELECT 1 FROM condominiums c
            WHERE c.id = condominium_id
              AND c.management_company_id IS NOT NULL
              AND c.management_company_id = get_user_company_id()
              AND is_company_manager(c.management_company_id)
          )
        )
      )
    )
    OR (
      scope = 'management_company'
      AND management_company_id IS NOT NULL
      AND can_manage_management_financial(management_company_id)
      AND (is_platform_admin() OR management_company_id = get_user_company_id())
    )
  );

-- ---------------------------------------------------------------------------
-- 3. Geração de cobranças — apenas da empresa do usuário
-- ---------------------------------------------------------------------------
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
  v_company_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado';
  END IF;

  v_company_id := get_user_company_id();

  IF NOT is_platform_admin() THEN
    IF v_company_id IS NULL OR NOT has_company_access(v_company_id) THEN
      RAISE EXCEPTION 'Acesso negado: empresa não vinculada ao usuário';
    END IF;
  END IF;

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
      AND (is_platform_admin() OR rl.company_id = v_company_id)
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
      AND (is_platform_admin() OR rb.company_id = v_company_id)
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
      JOIN rental_leases rl ON rl.id = rc.lease_id
      WHERE rl.property_id = v_row.property_id
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

-- ---------------------------------------------------------------------------
-- 4. Storage — buckets restritos por condomínio/OS/prestador
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS storage_provider_docs ON storage.objects;
CREATE POLICY storage_provider_docs ON storage.objects FOR ALL
  USING (
    bucket_id = 'provider-documents'
    AND EXISTS (
      SELECT 1 FROM providers p
      WHERE p.id = (storage.foldername(name))[1]::UUID
        AND has_condominium_access(p.condominium_id)
    )
  );

DROP POLICY IF EXISTS storage_signatures ON storage.objects;
CREATE POLICY storage_signatures ON storage.objects FOR ALL
  USING (
    bucket_id = 'signatures'
    AND EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = (storage.foldername(name))[1]::UUID
        AND has_condominium_access(wo.condominium_id)
    )
  );

-- ---------------------------------------------------------------------------
-- 5. Views — respeitar RLS das tabelas base
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS ticket_summary;
CREATE VIEW ticket_summary
WITH (security_invoker = true) AS
SELECT
  t.id,
  t.condominium_id,
  t.ticket_number,
  CONCAT('CH-', LPAD(t.ticket_number::TEXT, 5, '0')) AS formatted_number,
  t.title,
  t.status,
  t.priority,
  t.service_type,
  t.created_at
FROM tickets t;

DROP VIEW IF EXISTS work_order_summary;
CREATE VIEW work_order_summary
WITH (security_invoker = true) AS
SELECT
  wo.id,
  wo.condominium_id,
  wo.os_number,
  CONCAT('OS-', LPAD(wo.os_number::TEXT, 5, '0')) AS formatted_number,
  wo.title,
  wo.status,
  wo.priority,
  wo.service_type,
  wo.estimated_cost,
  wo.actual_cost,
  wo.due_date,
  wo.created_at
FROM work_orders wo;

NOTIFY pgrst, 'reload schema';
