-- Locação + Manutenção: condomínios compartilhados, vínculo imóvel↔chamados/OS, relatório P&L
-- Migration: 00030

-- Acesso organizacional aos condomínios da empresa gestora
CREATE OR REPLACE FUNCTION has_condominium_access(p_condominium_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT condominium_belongs_to_user_company(p_condominium_id);
$$;

CREATE OR REPLACE FUNCTION can_manage_condominium(p_condominium_id UUID)
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
          'condominium_admin', 'syndic', 'maintenance_manager', 'caretaker'
        )
    )
    OR EXISTS (
      SELECT 1 FROM condominiums c
      WHERE c.id = p_condominium_id
        AND c.management_company_id IS NOT NULL
        AND is_company_manager(c.management_company_id)
    );
$$;

DROP POLICY IF EXISTS condominiums_insert ON condominiums;
CREATE POLICY condominiums_insert ON condominiums FOR INSERT
  WITH CHECK (
    is_platform_admin()
    OR (
      management_company_id IS NOT NULL
      AND management_company_id = get_user_company_id()
      AND is_company_manager(management_company_id)
    )
  );

-- Vínculo direto imóvel ↔ chamados / ordens de serviço
ALTER TABLE tickets
  ADD COLUMN IF NOT EXISTS rental_property_id UUID
    REFERENCES rental_properties(id) ON DELETE SET NULL;

ALTER TABLE work_orders
  ADD COLUMN IF NOT EXISTS rental_property_id UUID
    REFERENCES rental_properties(id) ON DELETE SET NULL;

ALTER TABLE financial_records
  ADD COLUMN IF NOT EXISTS rental_property_id UUID
    REFERENCES rental_properties(id) ON DELETE SET NULL;

ALTER TABLE rental_charges
  ADD COLUMN IF NOT EXISTS property_id UUID
    REFERENCES rental_properties(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_tickets_rental_property ON tickets(rental_property_id);
CREATE INDEX IF NOT EXISTS idx_work_orders_rental_property ON work_orders(rental_property_id);
CREATE INDEX IF NOT EXISTS idx_financial_rental_property ON financial_records(rental_property_id);
CREATE INDEX IF NOT EXISTS idx_rental_charges_property ON rental_charges(property_id);

-- Backfill property_id em cobranças existentes
UPDATE rental_charges rc
SET property_id = rl.property_id
FROM rental_leases rl
WHERE rc.lease_id = rl.id AND rc.property_id IS NULL;

UPDATE rental_charges rc
SET property_id = rb.property_id
FROM rental_bookings rb
WHERE rc.booking_id = rb.id AND rc.property_id IS NULL;

-- Manter property_id sincronizado
CREATE OR REPLACE FUNCTION sync_rental_charge_property_id()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.property_id IS NULL AND NEW.lease_id IS NOT NULL THEN
    SELECT property_id INTO NEW.property_id FROM rental_leases WHERE id = NEW.lease_id;
  END IF;
  IF NEW.property_id IS NULL AND NEW.booking_id IS NOT NULL THEN
    SELECT property_id INTO NEW.property_id FROM rental_bookings WHERE id = NEW.booking_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS rental_charges_property_sync ON rental_charges;
CREATE TRIGGER rental_charges_property_sync
  BEFORE INSERT OR UPDATE ON rental_charges
  FOR EACH ROW EXECUTE FUNCTION sync_rental_charge_property_id();

-- Relatório receita × custo manutenção por imóvel
CREATE OR REPLACE FUNCTION rental_property_pnl_report(
  p_from DATE DEFAULT NULL,
  p_to DATE DEFAULT NULL
)
RETURNS TABLE (
  property_id UUID,
  property_title TEXT,
  condominium_name TEXT,
  rental_revenue NUMERIC,
  maintenance_cost NUMERIC,
  ticket_count BIGINT,
  work_order_count BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    rp.id AS property_id,
    rp.title AS property_title,
    c.name AS condominium_name,
    COALESCE(rev.total, 0) AS rental_revenue,
    COALESCE(cost.total, 0) AS maintenance_cost,
    COALESCE(tk.cnt, 0) AS ticket_count,
    COALESCE(wo.cnt, 0) AS work_order_count
  FROM rental_properties rp
  LEFT JOIN condominiums c ON c.id = rp.condominium_id
  LEFT JOIN LATERAL (
    SELECT SUM(rc.amount) AS total
    FROM rental_charges rc
    WHERE rc.property_id = rp.id
      AND rc.status = 'paid'
      AND (p_from IS NULL OR COALESCE(rc.paid_at::date, rc.due_date) >= p_from)
      AND (p_to IS NULL OR COALESCE(rc.paid_at::date, rc.due_date) <= p_to)
  ) rev ON TRUE
  LEFT JOIN LATERAL (
    SELECT SUM(wo2.actual_cost) AS total
    FROM work_orders wo2
    WHERE wo2.rental_property_id = rp.id
      AND wo2.status IN ('completed', 'closed')
      AND (p_from IS NULL OR COALESCE(wo2.completed_at::date, wo2.closed_at::date, wo2.created_at::date) >= p_from)
      AND (p_to IS NULL OR COALESCE(wo2.completed_at::date, wo2.closed_at::date, wo2.created_at::date) <= p_to)
  ) cost ON TRUE
  LEFT JOIN LATERAL (
    SELECT COUNT(*) AS cnt FROM tickets t
    WHERE t.rental_property_id = rp.id
      AND (p_from IS NULL OR t.created_at::date >= p_from)
      AND (p_to IS NULL OR t.created_at::date <= p_to)
  ) tk ON TRUE
  LEFT JOIN LATERAL (
    SELECT COUNT(*) AS cnt FROM work_orders wo3
    WHERE wo3.rental_property_id = rp.id
      AND (p_from IS NULL OR wo3.created_at::date >= p_from)
      AND (p_to IS NULL OR wo3.created_at::date <= p_to)
  ) wo ON TRUE
  WHERE (
    is_platform_admin()
    OR (
      get_user_company_id() IS NOT NULL
      AND rp.company_id = get_user_company_id()
      AND user_has_module('rental')
    )
  )
  ORDER BY rp.title;
$$;

GRANT EXECUTE ON FUNCTION rental_property_pnl_report(DATE, DATE) TO authenticated;

NOTIFY pgrst, 'reload schema';
