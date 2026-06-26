-- Cond Manager - Log de acesso e tempo de uso dos usuários
-- Migration: 00025

CREATE TABLE IF NOT EXISTS user_access_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user_full_name TEXT NOT NULL,
  company_id UUID REFERENCES management_companies(id) ON DELETE SET NULL,
  company_name TEXT,
  condominium_id UUID REFERENCES condominiums(id) ON DELETE SET NULL,
  condominium_name TEXT,
  contract_manager_name TEXT,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  duration_seconds INT,
  access_year SMALLINT NOT NULL,
  access_month SMALLINT NOT NULL,
  access_day SMALLINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT user_access_sessions_duration_nonneg
    CHECK (duration_seconds IS NULL OR duration_seconds >= 0)
);

CREATE INDEX IF NOT EXISTS idx_user_access_sessions_user
  ON user_access_sessions(user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_access_sessions_company
  ON user_access_sessions(company_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_access_sessions_date
  ON user_access_sessions(access_year, access_month, access_day);

CREATE OR REPLACE FUNCTION resolve_contract_manager_name(
  p_condominium_id UUID,
  p_company_id UUID
)
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (
      SELECT p.full_name
      FROM company_memberships cm
      JOIN profiles p ON p.id = cm.user_id
      WHERE cm.company_id = p_company_id
        AND cm.role = 'manager'
        AND cm.status = 'active'
      ORDER BY cm.created_at
      LIMIT 1
    ),
    (
      SELECT COALESCE(NULLIF(TRIM(c.manager_contact_name), ''), NULLIF(TRIM(c.syndic_name), ''))
      FROM condominiums c
      WHERE c.id = p_condominium_id
    ),
    '—'
  );
$$;

CREATE OR REPLACE FUNCTION start_user_access_session(p_condominium_id UUID DEFAULT NULL)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_session_id UUID;
  v_user_name TEXT;
  v_company_id UUID;
  v_company_name TEXT;
  v_condo_id UUID := p_condominium_id;
  v_condo_name TEXT;
  v_manager_name TEXT;
  v_started TIMESTAMPTZ := NOW();
  v_tz_started TIMESTAMPTZ := v_started AT TIME ZONE 'America/Sao_Paulo';
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Não autenticado';
  END IF;

  UPDATE user_access_sessions
     SET ended_at = v_started,
         duration_seconds = GREATEST(0, EXTRACT(EPOCH FROM (v_started - started_at))::INT)
   WHERE user_id = v_user_id
     AND ended_at IS NULL;

  SELECT full_name INTO v_user_name FROM profiles WHERE id = v_user_id;

  SELECT cm.company_id, COALESCE(mc.trade_name, mc.legal_name)
    INTO v_company_id, v_company_name
  FROM company_memberships cm
  LEFT JOIN management_companies mc ON mc.id = cm.company_id
  WHERE cm.user_id = v_user_id
    AND cm.status = 'active'
  ORDER BY cm.created_at
  LIMIT 1;

  IF v_condo_id IS NULL THEN
    SELECT ucr.condominium_id, c.name
      INTO v_condo_id, v_condo_name
    FROM user_condominium_roles ucr
    JOIN condominiums c ON c.id = ucr.condominium_id
    WHERE ucr.user_id = v_user_id
      AND ucr.status = 'active'
    ORDER BY ucr.is_primary DESC, ucr.created_at
    LIMIT 1;
  ELSE
    SELECT name INTO v_condo_name FROM condominiums WHERE id = v_condo_id;
  END IF;

  IF v_company_id IS NULL AND v_condo_id IS NOT NULL THEN
    SELECT c.management_company_id, COALESCE(mc.trade_name, mc.legal_name)
      INTO v_company_id, v_company_name
    FROM condominiums c
    LEFT JOIN management_companies mc ON mc.id = c.management_company_id
    WHERE c.id = v_condo_id;
  END IF;

  v_manager_name := resolve_contract_manager_name(v_condo_id, v_company_id);

  INSERT INTO user_access_sessions (
    user_id,
    user_full_name,
    company_id,
    company_name,
    condominium_id,
    condominium_name,
    contract_manager_name,
    started_at,
    access_year,
    access_month,
    access_day
  ) VALUES (
    v_user_id,
    COALESCE(v_user_name, ''),
    v_company_id,
    v_company_name,
    v_condo_id,
    v_condo_name,
    v_manager_name,
    v_started,
    EXTRACT(YEAR FROM v_tz_started)::SMALLINT,
    EXTRACT(MONTH FROM v_tz_started)::SMALLINT,
    EXTRACT(DAY FROM v_tz_started)::SMALLINT
  )
  RETURNING id INTO v_session_id;

  RETURN v_session_id;
END;
$$;

CREATE OR REPLACE FUNCTION end_user_access_session(p_session_id UUID DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_ended TIMESTAMPTZ := NOW();
BEGIN
  IF v_user_id IS NULL THEN
    RETURN;
  END IF;

  IF p_session_id IS NOT NULL THEN
    UPDATE user_access_sessions
       SET ended_at = v_ended,
           duration_seconds = GREATEST(0, EXTRACT(EPOCH FROM (v_ended - started_at))::INT)
     WHERE id = p_session_id
       AND user_id = v_user_id
       AND ended_at IS NULL;
  ELSE
    UPDATE user_access_sessions
       SET ended_at = v_ended,
           duration_seconds = GREATEST(0, EXTRACT(EPOCH FROM (v_ended - started_at))::INT)
     WHERE user_id = v_user_id
       AND ended_at IS NULL;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION start_user_access_session(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION end_user_access_session(UUID) TO authenticated;

ALTER TABLE user_access_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_access_sessions_select ON user_access_sessions;
CREATE POLICY user_access_sessions_select ON user_access_sessions
  FOR SELECT
  USING (
    is_platform_admin()
    OR (
      company_id IS NOT NULL
      AND can_manage_company_users(company_id)
    )
  );

DROP POLICY IF EXISTS user_access_sessions_insert ON user_access_sessions;
CREATE POLICY user_access_sessions_insert ON user_access_sessions
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_access_sessions_update ON user_access_sessions;
CREATE POLICY user_access_sessions_update ON user_access_sessions
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
