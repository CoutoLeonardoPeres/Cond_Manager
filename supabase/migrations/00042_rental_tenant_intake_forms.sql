-- Formulário público de cadastro de locatário/inquilino via link compartilhável

ALTER TABLE rental_parties
  ADD COLUMN IF NOT EXISTS intake_metadata JSONB;

CREATE TABLE IF NOT EXISTS rental_tenant_intake_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE DEFAULT replace(gen_random_uuid()::text, '-', ''),
  category rental_party_category NOT NULL DEFAULT 'tenant',
  label TEXT,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'revoked')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_tenant_intake_links_token
  ON rental_tenant_intake_links(token);

CREATE INDEX IF NOT EXISTS idx_rental_tenant_intake_links_company
  ON rental_tenant_intake_links(company_id, created_at DESC);

CREATE TABLE IF NOT EXISTS rental_tenant_intake_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  link_id UUID NOT NULL REFERENCES rental_tenant_intake_links(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  party_id UUID REFERENCES rental_parties(id) ON DELETE SET NULL,
  protocol TEXT UNIQUE,
  form_data JSONB NOT NULL DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted')),
  submitted_at TIMESTAMPTZ,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_tenant_intake_submissions_link
  ON rental_tenant_intake_submissions(link_id, status);

CREATE TRIGGER rental_tenant_intake_submissions_updated_at
  BEFORE UPDATE ON rental_tenant_intake_submissions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE rental_tenant_intake_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_tenant_intake_submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS rental_tenant_intake_links_select ON rental_tenant_intake_links;
CREATE POLICY rental_tenant_intake_links_select ON rental_tenant_intake_links FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_tenant_intake_links_modify ON rental_tenant_intake_links;
CREATE POLICY rental_tenant_intake_links_modify ON rental_tenant_intake_links FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_tenant_intake_submissions_select ON rental_tenant_intake_submissions;
CREATE POLICY rental_tenant_intake_submissions_select ON rental_tenant_intake_submissions FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_tenant_intake_submissions_modify ON rental_tenant_intake_submissions;
CREATE POLICY rental_tenant_intake_submissions_modify ON rental_tenant_intake_submissions FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

CREATE OR REPLACE FUNCTION _rental_intake_protocol()
RETURNS TEXT
LANGUAGE sql
AS $$
  SELECT 'RIT-' || to_char(NOW(), 'YYYYMMDD') || '-' ||
         upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
$$;

CREATE OR REPLACE FUNCTION _rental_intake_link_valid(p_token TEXT)
RETURNS rental_tenant_intake_links
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  link rental_tenant_intake_links%ROWTYPE;
BEGIN
  SELECT * INTO link FROM rental_tenant_intake_links WHERE token = p_token;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Link inválido ou não encontrado.';
  END IF;
  IF link.status <> 'active' THEN
    RAISE EXCEPTION 'Este link foi revogado.';
  END IF;
  IF link.expires_at <= NOW() THEN
    RAISE EXCEPTION 'Este link expirou.';
  END IF;
  RETURN link;
END;
$$;

CREATE OR REPLACE FUNCTION get_rental_tenant_intake_preview(p_token TEXT)
RETURNS TABLE (
  company_name TEXT,
  form_name TEXT,
  expires_at TIMESTAMPTZ,
  is_valid BOOLEAN,
  link_id UUID,
  category TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  link rental_tenant_intake_links%ROWTYPE;
  company TEXT;
BEGIN
  SELECT * INTO link FROM rental_tenant_intake_links WHERE token = p_token;

  IF NOT FOUND THEN
    RETURN QUERY SELECT NULL::TEXT, NULL::TEXT, NULL::TIMESTAMPTZ, FALSE, NULL::UUID, NULL::TEXT;
    RETURN;
  END IF;

  SELECT COALESCE(mc.trade_name, mc.legal_name) INTO company
  FROM management_companies mc WHERE mc.id = link.company_id;

  RETURN QUERY SELECT
    company,
    'Cadastro do Locatário para Contrato de Locação'::TEXT,
    link.expires_at,
    (link.status = 'active' AND link.expires_at > NOW()),
    link.id,
    link.category::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION save_rental_tenant_intake_draft(
  p_token TEXT,
  p_form_data JSONB,
  p_submission_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  link rental_tenant_intake_links%ROWTYPE;
  sub_id UUID;
BEGIN
  link := _rental_intake_link_valid(p_token);

  IF p_submission_id IS NOT NULL THEN
    UPDATE rental_tenant_intake_submissions
       SET form_data = p_form_data,
           updated_at = NOW()
     WHERE id = p_submission_id
       AND link_id = link.id
       AND status = 'draft'
     RETURNING id INTO sub_id;

    IF sub_id IS NOT NULL THEN
      RETURN sub_id;
    END IF;
  END IF;

  INSERT INTO rental_tenant_intake_submissions (link_id, company_id, form_data, status)
  VALUES (link.id, link.company_id, p_form_data, 'draft')
  RETURNING id INTO sub_id;

  RETURN sub_id;
END;
$$;

CREATE OR REPLACE FUNCTION submit_rental_tenant_intake(
  p_token TEXT,
  p_form_data JSONB,
  p_submission_id UUID DEFAULT NULL,
  p_ip_address TEXT DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
)
RETURNS TABLE (
  protocol TEXT,
  party_id UUID,
  submission_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  link rental_tenant_intake_links%ROWTYPE;
  sub rental_tenant_intake_submissions%ROWTYPE;
  sub_id UUID;
  party_uuid UUID;
  proto TEXT;
  full_name TEXT;
  cpf_raw TEXT;
  cpf_fmt TEXT;
  email_val TEXT;
  phone_val TEXT;
  notes_text TEXT;
  existing rental_parties%ROWTYPE;
BEGIN
  link := _rental_intake_link_valid(p_token);

  full_name := trim(coalesce(p_form_data->>'LOCATARIO_NOME_COMPLETO', ''));
  IF full_name = '' THEN
    RAISE EXCEPTION 'Nome completo é obrigatório.';
  END IF;

  cpf_raw := regexp_replace(coalesce(p_form_data->>'LOCATARIO_CPF', ''), '\D', '', 'g');
  IF length(cpf_raw) <> 11 THEN
    RAISE EXCEPTION 'CPF inválido.';
  END IF;
  cpf_fmt := substring(cpf_raw from 1 for 3) || '.' ||
             substring(cpf_raw from 4 for 3) || '.' ||
             substring(cpf_raw from 7 for 3) || '-' ||
             substring(cpf_raw from 10 for 2);

  email_val := nullif(trim(coalesce(p_form_data->>'LOCATARIO_EMAIL', '')), '');
  phone_val := nullif(trim(coalesce(
    p_form_data->>'LOCATARIO_WHATSAPP',
    p_form_data->>'LOCATARIO_TELEFONE',
    ''
  )), '');

  SELECT * INTO existing
  FROM rental_parties
  WHERE company_id = link.company_id
    AND regexp_replace(coalesce(document_number, ''), '\D', '', 'g') = cpf_raw
  LIMIT 1;

  IF FOUND AND coalesce(existing.is_rental_restricted, FALSE) THEN
    RAISE EXCEPTION 'Este CPF possui restrição de locação e não pode ser cadastrado.';
  END IF;

  notes_text := 'Cadastro via formulário público. Imóvel: ' ||
    coalesce(p_form_data->>'IMOVEL_DESEJADO', '—') || '. Tipo: ' ||
    coalesce(p_form_data->>'TIPO_LOCACAO', '—');

  IF FOUND THEN
    party_uuid := existing.id;
    UPDATE rental_parties SET
      full_name = full_name,
      category = link.category,
      email = email_val,
      phone = phone_val,
      document_number = cpf_fmt,
      address_street = nullif(trim(coalesce(p_form_data->>'LOCATARIO_LOGRADOURO', '')), ''),
      address_number = nullif(trim(coalesce(p_form_data->>'LOCATARIO_NUMERO', '')), ''),
      address_complement = nullif(trim(coalesce(p_form_data->>'LOCATARIO_COMPLEMENTO', '')), ''),
      address_neighborhood = nullif(trim(coalesce(p_form_data->>'LOCATARIO_BAIRRO', '')), ''),
      address_city = nullif(trim(coalesce(p_form_data->>'LOCATARIO_CIDADE', '')), ''),
      address_state = nullif(trim(coalesce(p_form_data->>'LOCATARIO_ESTADO', '')), ''),
      address_zip = nullif(trim(coalesce(p_form_data->>'LOCATARIO_CEP', '')), ''),
      notes = notes_text,
      intake_metadata = p_form_data,
      status = 'active'
    WHERE id = party_uuid;
  ELSE
    INSERT INTO rental_parties (
      company_id, full_name, category, email, phone, document_number,
      address_street, address_number, address_complement, address_neighborhood,
      address_city, address_state, address_zip, notes, intake_metadata, status
    ) VALUES (
      link.company_id, full_name, link.category, email_val, phone_val, cpf_fmt,
      nullif(trim(coalesce(p_form_data->>'LOCATARIO_LOGRADOURO', '')), ''),
      nullif(trim(coalesce(p_form_data->>'LOCATARIO_NUMERO', '')), ''),
      nullif(trim(coalesce(p_form_data->>'LOCATARIO_COMPLEMENTO', '')), ''),
      nullif(trim(coalesce(p_form_data->>'LOCATARIO_BAIRRO', '')), ''),
      nullif(trim(coalesce(p_form_data->>'LOCATARIO_CIDADE', '')), ''),
      nullif(trim(coalesce(p_form_data->>'LOCATARIO_ESTADO', '')), ''),
      nullif(trim(coalesce(p_form_data->>'LOCATARIO_CEP', '')), ''),
      notes_text, p_form_data, 'active'
    ) RETURNING id INTO party_uuid;
  END IF;

  proto := _rental_intake_protocol();

  IF p_submission_id IS NOT NULL THEN
    UPDATE rental_tenant_intake_submissions
       SET form_data = p_form_data,
           party_id = party_uuid,
           protocol = proto,
           status = 'submitted',
           submitted_at = NOW(),
           ip_address = p_ip_address,
           user_agent = p_user_agent,
           updated_at = NOW()
     WHERE id = p_submission_id
       AND link_id = link.id
     RETURNING * INTO sub;

    IF NOT FOUND THEN
      INSERT INTO rental_tenant_intake_submissions (
        link_id, company_id, party_id, protocol, form_data, status,
        submitted_at, ip_address, user_agent
      ) VALUES (
        link.id, link.company_id, party_uuid, proto, p_form_data, 'submitted',
        NOW(), p_ip_address, p_user_agent
      ) RETURNING * INTO sub;
    END IF;
  ELSE
    INSERT INTO rental_tenant_intake_submissions (
      link_id, company_id, party_id, protocol, form_data, status,
      submitted_at, ip_address, user_agent
    ) VALUES (
      link.id, link.company_id, party_uuid, proto, p_form_data, 'submitted',
      NOW(), p_ip_address, p_user_agent
    ) RETURNING * INTO sub;
  END IF;

  RETURN QUERY SELECT proto, party_uuid, sub.id;
END;
$$;

GRANT EXECUTE ON FUNCTION get_rental_tenant_intake_preview(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION save_rental_tenant_intake_draft(TEXT, JSONB, UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION submit_rental_tenant_intake(TEXT, JSONB, UUID, TEXT, TEXT) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
