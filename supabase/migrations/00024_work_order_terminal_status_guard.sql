-- OS concluída ou cancelada: alteração de status apenas para admin/gerente
-- Migration: 00024

CREATE OR REPLACE FUNCTION can_override_terminal_work_order_status(p_condominium_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_platform_admin()
    OR EXISTS (
      SELECT 1
      FROM condominiums c
      JOIN company_memberships cm ON cm.company_id = c.management_company_id
      WHERE c.id = p_condominium_id
        AND cm.user_id = auth.uid()
        AND cm.status = 'active'
        AND cm.role = 'manager'
    )
    OR get_user_role(p_condominium_id) IN ('condominium_admin', 'maintenance_manager');
$$;

CREATE OR REPLACE FUNCTION enforce_work_order_terminal_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status
     AND OLD.status IN ('completed', 'cancelled')
  THEN
    IF NOT can_override_terminal_work_order_status(NEW.condominium_id) THEN
      RAISE EXCEPTION
        'Apenas administrador ou gerente pode alterar o status de uma OS concluída ou cancelada.'
        USING ERRCODE = '42501';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS work_order_terminal_status_guard ON work_orders;
CREATE TRIGGER work_order_terminal_status_guard
  BEFORE UPDATE ON work_orders
  FOR EACH ROW EXECUTE FUNCTION enforce_work_order_terminal_status_change();
