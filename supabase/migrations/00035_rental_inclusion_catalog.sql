-- Catálogo reutilizável de itens inclusos na locação (por empresa)
-- Migration: 00035

CREATE TABLE IF NOT EXISTS rental_inclusion_catalog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category rental_inclusion_category NOT NULL DEFAULT 'appliance',
  default_amount NUMERIC(14, 2),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_rental_inclusion_catalog_company_name
  ON rental_inclusion_catalog(company_id, lower(trim(name)));

CREATE INDEX IF NOT EXISTS idx_rental_inclusion_catalog_company
  ON rental_inclusion_catalog(company_id, is_active);

DROP TRIGGER IF EXISTS rental_inclusion_catalog_updated_at ON rental_inclusion_catalog;
CREATE TRIGGER rental_inclusion_catalog_updated_at
  BEFORE UPDATE ON rental_inclusion_catalog
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE rental_property_inclusions
  ADD COLUMN IF NOT EXISTS catalog_item_id UUID
    REFERENCES rental_inclusion_catalog(id) ON DELETE SET NULL;

ALTER TABLE rental_inclusion_catalog ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS rental_inclusion_catalog_select ON rental_inclusion_catalog;
CREATE POLICY rental_inclusion_catalog_select ON rental_inclusion_catalog FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_inclusion_catalog_modify ON rental_inclusion_catalog;
CREATE POLICY rental_inclusion_catalog_modify ON rental_inclusion_catalog FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));
