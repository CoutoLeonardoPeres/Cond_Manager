-- Cond Manager - Empresa gestora, papéis organizacionais e usuários
-- Migration: 00017

DO $$ BEGIN
  CREATE TYPE organization_role AS ENUM (
    'manager',
    'analyst',
    'field_team',
    'client'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS management_companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  legal_name TEXT NOT NULL,
  trade_name TEXT,
  cnpj TEXT UNIQUE,
  email TEXT,
  phone TEXT,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER management_companies_updated_at
  BEFORE UPDATE ON management_companies
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE condominiums
  ADD COLUMN IF NOT EXISTS management_company_id UUID REFERENCES management_companies(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_condominiums_management_company
  ON condominiums(management_company_id);

CREATE TABLE IF NOT EXISTS company_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  role organization_role NOT NULL,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, company_id)
);

CREATE INDEX IF NOT EXISTS idx_company_memberships_user ON company_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_company_memberships_company ON company_memberships(company_id);
CREATE INDEX IF NOT EXISTS idx_company_memberships_role ON company_memberships(role);

CREATE TRIGGER company_memberships_updated_at
  BEFORE UPDATE ON company_memberships
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE user_invitations
  ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES management_companies(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS organization_role organization_role;

ALTER TABLE user_invitations
  ALTER COLUMN condominium_id DROP NOT NULL;

-- Helpers de permissão organizacional
CREATE OR REPLACE FUNCTION get_user_company_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT company_id
    FROM company_memberships
   WHERE user_id = auth.uid()
     AND status = 'active'
   ORDER BY created_at
   LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION get_user_organization_role(p_company_id UUID DEFAULT NULL)
RETURNS organization_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role
    FROM company_memberships
   WHERE user_id = auth.uid()
     AND status = 'active'
     AND (p_company_id IS NULL OR company_id = p_company_id)
   ORDER BY created_at
   LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION is_company_manager(p_company_id UUID DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_platform_admin()
    OR get_user_organization_role(p_company_id) = 'manager';
$$;

CREATE OR REPLACE FUNCTION can_manage_company_users(p_company_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_platform_admin()
    OR (
      get_user_company_id() = p_company_id
      AND get_user_organization_role(p_company_id) = 'manager'
    );
$$;

CREATE OR REPLACE FUNCTION has_company_access(p_company_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_platform_admin()
    OR EXISTS (
      SELECT 1 FROM company_memberships
      WHERE user_id = auth.uid()
        AND company_id = p_company_id
        AND status = 'active'
    );
$$;

CREATE OR REPLACE FUNCTION condominium_belongs_to_user_company(p_condominium_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_platform_admin()
    OR EXISTS (
      SELECT 1 FROM condominiums c
      JOIN company_memberships cm ON cm.company_id = c.management_company_id
      WHERE c.id = p_condominium_id
        AND cm.user_id = auth.uid()
        AND cm.status = 'active'
        AND cm.role IN ('manager', 'analyst', 'field_team')
    )
    OR EXISTS (
      SELECT 1 FROM user_condominium_roles ucr
      WHERE ucr.user_id = auth.uid()
        AND ucr.condominium_id = p_condominium_id
        AND ucr.status = 'active'
    );
$$;

-- Aceitar convite → membership + papel no condomínio (cliente)
CREATE OR REPLACE FUNCTION accept_user_invitation(p_token TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  inv user_invitations%ROWTYPE;
BEGIN
  SELECT * INTO inv FROM user_invitations
   WHERE token = p_token
     AND accepted_at IS NULL
     AND expires_at > NOW()
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Convite inválido ou expirado';
  END IF;

  IF inv.company_id IS NOT NULL AND inv.organization_role IS NOT NULL THEN
    INSERT INTO company_memberships (user_id, company_id, role, status)
    VALUES (auth.uid(), inv.company_id, inv.organization_role, 'active')
    ON CONFLICT (user_id, company_id) DO UPDATE
      SET role = EXCLUDED.role, status = 'active', updated_at = NOW();
  END IF;

  IF inv.condominium_id IS NOT NULL THEN
    INSERT INTO user_condominium_roles (user_id, condominium_id, role, status, invited_by, accepted_at)
    VALUES (
      auth.uid(),
      inv.condominium_id,
      COALESCE(inv.role, 'resident'),
      'active',
      inv.invited_by,
      NOW()
    )
    ON CONFLICT (user_id, condominium_id, role) DO UPDATE
      SET status = 'active', updated_at = NOW();
  END IF;

  UPDATE user_invitations SET accepted_at = NOW() WHERE id = inv.id;
END;
$$;

ALTER TABLE management_companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_memberships ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS management_companies_select ON management_companies;
CREATE POLICY management_companies_select ON management_companies FOR SELECT
  USING (is_platform_admin() OR has_company_access(id));

DROP POLICY IF EXISTS management_companies_modify ON management_companies;
CREATE POLICY management_companies_modify ON management_companies FOR ALL
  USING (is_platform_admin())
  WITH CHECK (is_platform_admin());

DROP POLICY IF EXISTS company_memberships_select ON company_memberships;
CREATE POLICY company_memberships_select ON company_memberships FOR SELECT
  USING (
    is_platform_admin()
    OR user_id = auth.uid()
    OR has_company_access(company_id)
  );

DROP POLICY IF EXISTS company_memberships_modify ON company_memberships;
CREATE POLICY company_memberships_modify ON company_memberships FOR ALL
  USING (can_manage_company_users(company_id) OR is_platform_admin())
  WITH CHECK (can_manage_company_users(company_id) OR is_platform_admin());
