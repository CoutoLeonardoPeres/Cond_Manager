-- Itens inclusos na locação do imóvel (utilidades, eletrodomésticos, mobiliário)
-- Migration: 00033

DO $$ BEGIN
  CREATE TYPE rental_inclusion_category AS ENUM (
    'condominium_fee',
    'water',
    'electricity',
    'internet',
    'gas',
    'television',
    'appliance',
    'furniture',
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS rental_property_inclusions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES rental_properties(id) ON DELETE CASCADE,
  category rental_inclusion_category NOT NULL,
  custom_name TEXT,
  amount NUMERIC(14, 2),
  included_in_rent BOOLEAN NOT NULL DEFAULT FALSE,
  quantity SMALLINT,
  size_label TEXT,
  model TEXT,
  chair_count SMALLINT,
  notes TEXT,
  sort_order SMALLINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_property_inclusions_property
  ON rental_property_inclusions(property_id, sort_order);

DROP TRIGGER IF EXISTS rental_property_inclusions_updated_at ON rental_property_inclusions;
CREATE TRIGGER rental_property_inclusions_updated_at
  BEFORE UPDATE ON rental_property_inclusions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE rental_property_inclusions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS rental_property_inclusions_select ON rental_property_inclusions;
CREATE POLICY rental_property_inclusions_select ON rental_property_inclusions FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_property_inclusions_modify ON rental_property_inclusions;
CREATE POLICY rental_property_inclusions_modify ON rental_property_inclusions FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));
