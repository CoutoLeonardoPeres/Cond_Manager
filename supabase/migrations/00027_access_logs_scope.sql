-- Cond Manager - Escopo do log de acesso: admin vê tudo, gerente só da própria empresa
-- Migration: 00027

CREATE OR REPLACE FUNCTION can_view_access_session(p_company_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    is_platform_admin()
    OR (
      p_company_id IS NOT NULL
      AND p_company_id = get_user_company_id()
      AND get_user_organization_role(p_company_id) = 'manager'
    );
$$;

DROP POLICY IF EXISTS user_access_sessions_select ON user_access_sessions;
CREATE POLICY user_access_sessions_select ON user_access_sessions
  FOR SELECT
  USING (can_view_access_session(company_id));

NOTIFY pgrst, 'reload schema';
