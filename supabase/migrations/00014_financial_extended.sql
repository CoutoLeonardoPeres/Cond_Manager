-- Cond Manager - Financial module extensions
-- Migration: 00014
-- Seguro para rodar em banco que JÁ tem o schema base (não use cond_manager_full_schema.sql).

DO $$ BEGIN
  CREATE TYPE financial_scope AS ENUM (
    'condominium',
    'management_company'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE financial_records
  ALTER COLUMN condominium_id DROP NOT NULL;

ALTER TABLE financial_records
  ADD COLUMN IF NOT EXISTS scope financial_scope NOT NULL DEFAULT 'condominium',
  ADD COLUMN IF NOT EXISTS tax_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS labor_hours NUMERIC(10, 2),
  ADD COLUMN IF NOT EXISTS hourly_rate NUMERIC(14, 2),
  ADD COLUMN IF NOT EXISTS material_id UUID REFERENCES materials(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS notes TEXT;

DO $$ BEGIN
  ALTER TABLE financial_records
    ADD CONSTRAINT financial_records_tax_amount_nonneg CHECK (tax_amount >= 0);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE financial_records
    ADD CONSTRAINT financial_records_labor_hours_nonneg
    CHECK (labor_hours IS NULL OR labor_hours >= 0);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE financial_records
    ADD CONSTRAINT financial_records_hourly_rate_nonneg
    CHECK (hourly_rate IS NULL OR hourly_rate >= 0);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE financial_records
    ADD CONSTRAINT financial_scope_condo CHECK (
      (scope = 'condominium' AND condominium_id IS NOT NULL)
      OR (scope = 'management_company')
    );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_financial_scope ON financial_records(scope);
CREATE INDEX IF NOT EXISTS idx_financial_category ON financial_records(category);

CREATE OR REPLACE FUNCTION can_view_management_financial()
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
        AND status = 'active'
        AND role IN ('condominium_admin', 'financial', 'maintenance_manager', 'auditor')
    );
$$;

CREATE OR REPLACE FUNCTION can_manage_management_financial()
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
        AND status = 'active'
        AND role IN ('condominium_admin', 'financial')
    );
$$;

DROP POLICY IF EXISTS financial_select ON financial_records;
CREATE POLICY financial_select ON financial_records FOR SELECT
  USING (
    (scope = 'condominium' AND condominium_id IS NOT NULL AND can_view_financial(condominium_id))
    OR (scope = 'management_company' AND can_view_management_financial())
  );

DROP POLICY IF EXISTS financial_modify ON financial_records;
CREATE POLICY financial_modify ON financial_records FOR ALL
  USING (
    (scope = 'condominium' AND condominium_id IS NOT NULL
      AND get_user_role(condominium_id) IN ('condominium_admin', 'financial'))
    OR (scope = 'management_company' AND can_manage_management_financial())
  )
  WITH CHECK (
    (scope = 'condominium' AND condominium_id IS NOT NULL
      AND get_user_role(condominium_id) IN ('condominium_admin', 'financial'))
    OR (scope = 'management_company' AND can_manage_management_financial())
  );
