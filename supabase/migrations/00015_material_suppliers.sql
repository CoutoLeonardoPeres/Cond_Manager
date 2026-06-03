-- Cond Manager - Fornecedores de materiais (N:N com materiais)
-- Migration: 00015

CREATE TABLE IF NOT EXISTS material_supplier_links (
  material_id UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  is_primary BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (material_id, provider_id)
);

CREATE INDEX IF NOT EXISTS idx_material_supplier_provider
  ON material_supplier_links(provider_id);
CREATE INDEX IF NOT EXISTS idx_material_supplier_condo
  ON material_supplier_links(condominium_id);

-- Um fornecedor principal por material
CREATE UNIQUE INDEX IF NOT EXISTS idx_material_supplier_one_primary
  ON material_supplier_links(material_id)
  WHERE is_primary = true;

-- Migrar vínculo legado (materials.provider_id)
INSERT INTO material_supplier_links (material_id, provider_id, condominium_id, is_primary)
SELECT m.id, m.provider_id, m.condominium_id, true
FROM materials m
WHERE m.provider_id IS NOT NULL
ON CONFLICT (material_id, provider_id) DO NOTHING;

ALTER TABLE material_supplier_links ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS material_supplier_links_select ON material_supplier_links;
CREATE POLICY material_supplier_links_select ON material_supplier_links FOR SELECT
  USING (has_condominium_access(condominium_id));

DROP POLICY IF EXISTS material_supplier_links_modify ON material_supplier_links;
CREATE POLICY material_supplier_links_modify ON material_supplier_links FOR ALL
  USING (
    get_user_role(condominium_id) IN (
      'condominium_admin', 'maintenance_manager', 'caretaker'
    ) OR is_platform_admin()
  )
  WITH CHECK (
    get_user_role(condominium_id) IN (
      'condominium_admin', 'maintenance_manager', 'caretaker'
    ) OR is_platform_admin()
  );
