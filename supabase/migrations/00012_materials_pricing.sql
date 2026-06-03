-- Cond Manager - Materials pricing, services link and WO resale fields
-- Migration: 00012

ALTER TABLE materials
  ADD COLUMN IF NOT EXISTS item_type TEXT NOT NULL DEFAULT 'material'
    CHECK (item_type IN ('material', 'equipment')),
  ADD COLUMN IF NOT EXISTS is_storable BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS purchase_tax_percent NUMERIC(5, 2) NOT NULL DEFAULT 0
    CHECK (purchase_tax_percent >= 0 AND purchase_tax_percent <= 100),
  ADD COLUMN IF NOT EXISTS resale_unit_price NUMERIC(14, 4) NOT NULL DEFAULT 0
    CHECK (resale_unit_price >= 0),
  ADD COLUMN IF NOT EXISTS resale_tax_percent NUMERIC(5, 2) NOT NULL DEFAULT 0
    CHECK (resale_tax_percent >= 0 AND resale_tax_percent <= 100),
  ADD COLUMN IF NOT EXISTS applicable_services service_type[] NOT NULL DEFAULT '{}';

COMMENT ON COLUMN materials.unit_cost IS 'Preço unitário de compra (custo) sem impostos';
COMMENT ON COLUMN materials.purchase_tax_percent IS 'Percentual de impostos sobre a compra (ex.: ICMS, PIS/COFINS embutido)';
COMMENT ON COLUMN materials.resale_unit_price IS 'Preço unitário de repasse ao condomínio sem impostos';
COMMENT ON COLUMN materials.resale_tax_percent IS 'Percentual de impostos sobre o repasse ao condomínio';
COMMENT ON COLUMN materials.applicable_services IS 'Tipos de serviço/OS em que o item pode ser utilizado';

ALTER TABLE work_order_materials
  ADD COLUMN IF NOT EXISTS unit_resale_price NUMERIC(14, 4) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS resale_tax_percent NUMERIC(5, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_resale NUMERIC(14, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS purchase_tax_percent NUMERIC(5, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_cost_with_tax NUMERIC(14, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_resale_with_tax NUMERIC(14, 2) DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_materials_services ON materials USING GIN (applicable_services);
CREATE INDEX IF NOT EXISTS idx_materials_item_type ON materials(item_type);
