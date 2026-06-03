-- Convites: preview público, múltiplos condomínios e aceite aprimorado
-- Migration: 00018

ALTER TABLE user_invitations
  ADD COLUMN IF NOT EXISTS condominium_ids JSONB;

-- Preview do convite (sem autenticação — só metadados)
CREATE OR REPLACE FUNCTION get_user_invitation_preview(p_token TEXT)
RETURNS TABLE (
  email TEXT,
  organization_role organization_role,
  company_name TEXT,
  condominium_names TEXT[],
  expires_at TIMESTAMPTZ,
  is_valid BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  inv user_invitations%ROWTYPE;
  names TEXT[] := ARRAY[]::TEXT[];
  company TEXT;
BEGIN
  SELECT * INTO inv FROM user_invitations WHERE token = p_token;

  IF NOT FOUND THEN
    RETURN QUERY SELECT NULL::TEXT, NULL::organization_role, NULL::TEXT,
      ARRAY[]::TEXT[], NULL::TIMESTAMPTZ, FALSE;
    RETURN;
  END IF;

  IF inv.condominium_ids IS NOT NULL THEN
    SELECT coalesce(array_agg(c.name ORDER BY c.name), ARRAY[]::TEXT[])
      INTO names
      FROM condominiums c
     WHERE c.id IN (
       SELECT jsonb_array_elements_text(inv.condominium_ids)::UUID
     );
  ELSIF inv.condominium_id IS NOT NULL THEN
    SELECT array_agg(c.name)
      INTO names
      FROM condominiums c
     WHERE c.id = inv.condominium_id;
  END IF;

  IF inv.company_id IS NOT NULL THEN
    SELECT COALESCE(mc.trade_name, mc.legal_name)
      INTO company
      FROM management_companies mc
     WHERE mc.id = inv.company_id;
  END IF;

  RETURN QUERY
  SELECT
    inv.email,
    inv.organization_role,
    company,
    coalesce(names, ARRAY[]::TEXT[]),
    inv.expires_at,
    (inv.accepted_at IS NULL AND inv.expires_at > NOW());
END;
$$;

CREATE OR REPLACE FUNCTION accept_user_invitation(p_token TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  inv user_invitations%ROWTYPE;
  cid UUID;
  condo_ids UUID[];
BEGIN
  SELECT * INTO inv FROM user_invitations
   WHERE token = p_token
     AND accepted_at IS NULL
     AND expires_at > NOW()
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Convite inválido ou expirado';
  END IF;

  IF lower(trim(inv.email)) <> lower(trim((SELECT email FROM profiles WHERE id = auth.uid()))) THEN
    RAISE EXCEPTION 'Este convite foi enviado para outro e-mail';
  END IF;

  IF inv.company_id IS NOT NULL AND inv.organization_role IS NOT NULL THEN
    INSERT INTO company_memberships (user_id, company_id, role, status)
    VALUES (auth.uid(), inv.company_id, inv.organization_role, 'active')
    ON CONFLICT (user_id, company_id) DO UPDATE
      SET role = EXCLUDED.role, status = 'active', updated_at = NOW();
  END IF;

  condo_ids := ARRAY[]::UUID[];

  IF inv.condominium_ids IS NOT NULL THEN
    SELECT array_agg(value::UUID)
      INTO condo_ids
      FROM jsonb_array_elements_text(inv.condominium_ids) AS value;
  END IF;

  IF inv.condominium_id IS NOT NULL THEN
    condo_ids := array_append(coalesce(condo_ids, ARRAY[]::UUID[]), inv.condominium_id);
  END IF;

  IF condo_ids IS NOT NULL THEN
    FOREACH cid IN ARRAY condo_ids
    LOOP
      INSERT INTO user_condominium_roles (user_id, condominium_id, role, status, invited_by, accepted_at)
      VALUES (
        auth.uid(),
        cid,
        COALESCE(inv.role, 'resident'),
        'active',
        inv.invited_by,
        NOW()
      )
      ON CONFLICT (user_id, condominium_id, role) DO UPDATE
        SET status = 'active', updated_at = NOW();
    END LOOP;
  END IF;

  UPDATE user_invitations SET accepted_at = NOW() WHERE id = inv.id;
END;
$$;
