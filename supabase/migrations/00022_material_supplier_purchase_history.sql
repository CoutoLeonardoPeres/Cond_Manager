-- Cond Manager - Histórico de compras por fornecedor (material × fornecedor)
-- Migration: 00022

-- Cache da última compra no vínculo material-fornecedor (consulta rápida na OS)
ALTER TABLE material_supplier_links
  ADD COLUMN IF NOT EXISTS last_purchase_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS last_unit_cost NUMERIC(14, 4),
  ADD COLUMN IF NOT EXISTS last_purchase_quantity NUMERIC(14, 4),
  ADD COLUMN IF NOT EXISTS last_resale_unit_price NUMERIC(14, 4);

COMMENT ON COLUMN material_supplier_links.last_purchase_at IS
  'Data/hora da última compra registrada deste material com este fornecedor';
COMMENT ON COLUMN material_supplier_links.last_unit_cost IS
  'Custo unitário (s/ impostos) da última compra com este fornecedor';
COMMENT ON COLUMN material_supplier_links.last_purchase_quantity IS
  'Quantidade da última compra com este fornecedor';
COMMENT ON COLUMN material_supplier_links.last_resale_unit_price IS
  'Preço unitário de repasse (s/ impostos) na última compra com este fornecedor';

-- Fornecedor opcional nas entradas de estoque
ALTER TABLE stock_movements
  ADD COLUMN IF NOT EXISTS provider_id UUID REFERENCES providers(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_stock_movements_provider
  ON stock_movements(provider_id)
  WHERE provider_id IS NOT NULL;

-- Histórico completo de compras por material e fornecedor
CREATE TABLE IF NOT EXISTS material_supplier_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  material_id UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  purchased_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  quantity NUMERIC(14, 4) NOT NULL CHECK (quantity > 0),
  unit_cost NUMERIC(14, 4) NOT NULL CHECK (unit_cost >= 0),
  purchase_tax_percent NUMERIC(5, 2) NOT NULL DEFAULT 0
    CHECK (purchase_tax_percent >= 0 AND purchase_tax_percent <= 100),
  total_cost NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (total_cost >= 0),
  resale_unit_price NUMERIC(14, 4) NOT NULL DEFAULT 0 CHECK (resale_unit_price >= 0),
  resale_tax_percent NUMERIC(5, 2) NOT NULL DEFAULT 0
    CHECK (resale_tax_percent >= 0 AND resale_tax_percent <= 100),
  stock_movement_id UUID REFERENCES stock_movements(id) ON DELETE SET NULL,
  invoice_number TEXT,
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT material_supplier_purchases_provider_link_fkey
    FOREIGN KEY (material_id, provider_id)
    REFERENCES material_supplier_links(material_id, provider_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_msp_material ON material_supplier_purchases(material_id);
CREATE INDEX IF NOT EXISTS idx_msp_provider ON material_supplier_purchases(provider_id);
CREATE INDEX IF NOT EXISTS idx_msp_condominium ON material_supplier_purchases(condominium_id);
CREATE INDEX IF NOT EXISTS idx_msp_purchased_at ON material_supplier_purchases(material_id, provider_id, purchased_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS idx_msp_stock_movement_unique
  ON material_supplier_purchases(stock_movement_id)
  WHERE stock_movement_id IS NOT NULL;

-- Atualiza cache no vínculo material-fornecedor
CREATE OR REPLACE FUNCTION refresh_material_supplier_last_purchase()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE material_supplier_links msl
  SET
    last_purchase_at = NEW.purchased_at,
    last_unit_cost = NEW.unit_cost,
    last_purchase_quantity = NEW.quantity,
    last_resale_unit_price = NEW.resale_unit_price
  WHERE msl.material_id = NEW.material_id
    AND msl.provider_id = NEW.provider_id
    AND (
      msl.last_purchase_at IS NULL
      OR NEW.purchased_at >= msl.last_purchase_at
    );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_material_supplier_purchase_refresh_link ON material_supplier_purchases;
CREATE TRIGGER on_material_supplier_purchase_refresh_link
  AFTER INSERT ON material_supplier_purchases
  FOR EACH ROW EXECUTE FUNCTION refresh_material_supplier_last_purchase();

-- Registra compra automaticamente em entradas de estoque com fornecedor
CREATE OR REPLACE FUNCTION record_purchase_from_stock_entry()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  m RECORD;
  v_unit_cost NUMERIC(14, 4);
  v_total_cost NUMERIC(14, 2);
BEGIN
  IF NEW.movement_type <> 'entry' OR NEW.provider_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT
    unit_cost,
    purchase_tax_percent,
    resale_unit_price,
    resale_tax_percent
  INTO m
  FROM materials
  WHERE id = NEW.material_id;

  v_unit_cost := COALESCE(NEW.unit_cost, m.unit_cost, 0);
  v_total_cost := COALESCE(NEW.total_cost, v_unit_cost * NEW.quantity, 0);

  INSERT INTO material_supplier_purchases (
    material_id,
    provider_id,
    condominium_id,
    purchased_at,
    quantity,
    unit_cost,
    purchase_tax_percent,
    total_cost,
    resale_unit_price,
    resale_tax_percent,
    stock_movement_id,
    notes,
    created_by
  )
  VALUES (
    NEW.material_id,
    NEW.provider_id,
    NEW.condominium_id,
    NEW.created_at,
    NEW.quantity,
    v_unit_cost,
    COALESCE(m.purchase_tax_percent, 0),
    v_total_cost,
    COALESCE(m.resale_unit_price, 0),
    COALESCE(m.resale_tax_percent, 0),
    NEW.id,
    NEW.notes,
    NEW.performed_by
  )
  ON CONFLICT (stock_movement_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_stock_entry_record_purchase ON stock_movements;
CREATE TRIGGER on_stock_entry_record_purchase
  AFTER INSERT ON stock_movements
  FOR EACH ROW EXECUTE FUNCTION record_purchase_from_stock_entry();

-- Seed inicial: fornecedor principal herda custo/repasse cadastrado no material
UPDATE material_supplier_links msl
SET
  last_purchase_at = m.updated_at,
  last_unit_cost = m.unit_cost,
  last_resale_unit_price = m.resale_unit_price
FROM materials m
WHERE msl.material_id = m.id
  AND msl.is_primary = true
  AND msl.last_purchase_at IS NULL;

-- RLS
ALTER TABLE material_supplier_purchases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS material_supplier_purchases_select ON material_supplier_purchases;
CREATE POLICY material_supplier_purchases_select ON material_supplier_purchases
  FOR SELECT
  USING (has_condominium_access(condominium_id));

DROP POLICY IF EXISTS material_supplier_purchases_modify ON material_supplier_purchases;
CREATE POLICY material_supplier_purchases_modify ON material_supplier_purchases
  FOR ALL
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
