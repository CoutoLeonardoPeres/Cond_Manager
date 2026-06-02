-- Cond Manager - Storage Buckets and Helper Functions
-- Migration: 00010

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('condominium-assets', 'condominium-assets', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('tickets', 'tickets', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('work-orders', 'work-orders', false, 20971520, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('provider-documents', 'provider-documents', false, 20971520, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
  ('signatures', 'signatures', false, 2097152, ARRAY['image/png', 'image/jpeg'])
ON CONFLICT (id) DO NOTHING;

-- Funções auxiliares para RLS
CREATE OR REPLACE FUNCTION is_platform_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT is_platform_admin FROM profiles WHERE id = auth.uid()),
    FALSE
  );
$$;

CREATE OR REPLACE FUNCTION has_condominium_access(p_condominium_id UUID)
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
    );
$$;

CREATE OR REPLACE FUNCTION get_user_role(p_condominium_id UUID)
RETURNS user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM user_condominium_roles
  WHERE user_id = auth.uid()
    AND condominium_id = p_condominium_id
    AND status = 'active'
  ORDER BY is_primary DESC
  LIMIT 1;
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
    );
$$;

CREATE OR REPLACE FUNCTION can_approve_work_orders(p_condominium_id UUID)
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
        AND role IN ('condominium_admin', 'syndic', 'financial', 'maintenance_manager')
    );
$$;

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
    );
$$;

-- View: número formatado de chamado/OS por condomínio
CREATE OR REPLACE VIEW ticket_summary AS
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

CREATE OR REPLACE VIEW work_order_summary AS
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
