-- Cond Manager - Restrição de cadastro de papéis por perfil
-- Migration: 00026
-- Admin: pode cadastrar todos os papéis, inclusive gerente.
-- Gerente: pode cadastrar analista, equipe de campo e cliente — não gerente nem admin.

CREATE OR REPLACE FUNCTION guard_organization_role_assignment(
  p_target_user_id UUID,
  p_new_role organization_role,
  p_old_role organization_role DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_target_is_admin BOOLEAN;
BEGIN
  IF is_platform_admin() THEN
    RETURN;
  END IF;

  IF NOT can_manage_company_users(get_user_company_id()) THEN
    RAISE EXCEPTION 'Sem permissão para gerenciar usuários.';
  END IF;

  SELECT is_platform_admin
    INTO v_target_is_admin
    FROM profiles
   WHERE id = p_target_user_id;

  IF COALESCE(v_target_is_admin, FALSE) THEN
    RAISE EXCEPTION 'Apenas o administrador pode gerenciar administradores.';
  END IF;

  IF p_old_role = 'manager' THEN
    RAISE EXCEPTION 'Apenas o administrador pode alterar gerentes.';
  END IF;

  IF p_new_role = 'manager' THEN
    RAISE EXCEPTION 'Apenas o administrador pode cadastrar gerentes.';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION trg_guard_company_membership_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM guard_organization_role_assignment(
    NEW.user_id,
    NEW.role,
    CASE WHEN TG_OP = 'UPDATE' THEN OLD.role ELSE NULL END
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS company_memberships_role_guard ON company_memberships;
CREATE TRIGGER company_memberships_role_guard
  BEFORE INSERT OR UPDATE OF role, user_id ON company_memberships
  FOR EACH ROW
  EXECUTE FUNCTION trg_guard_company_membership_role();

CREATE OR REPLACE FUNCTION trg_guard_user_invitation_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.organization_role IS NULL THEN
    RETURN NEW;
  END IF;

  IF is_platform_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.organization_role = 'manager' THEN
    RAISE EXCEPTION 'Apenas o administrador pode convidar gerentes.';
  END IF;

  IF NEW.company_id IS NOT NULL
     AND NOT can_manage_company_users(NEW.company_id) THEN
    RAISE EXCEPTION 'Sem permissão para convidar usuários desta empresa.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS user_invitations_role_guard ON user_invitations;
CREATE TRIGGER user_invitations_role_guard
  BEFORE INSERT OR UPDATE OF organization_role ON user_invitations
  FOR EACH ROW
  EXECUTE FUNCTION trg_guard_user_invitation_role();
