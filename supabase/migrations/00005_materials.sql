-- Cond Manager - Materials and Stock
-- Migration: 00005

CREATE TABLE material_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(condominium_id, name)
);

CREATE TABLE materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  category_id UUID REFERENCES material_categories(id) ON DELETE SET NULL,
  provider_id UUID REFERENCES providers(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  sku TEXT,
  unit_of_measure TEXT NOT NULL DEFAULT 'un',
  unit_cost NUMERIC(14, 4) NOT NULL DEFAULT 0,
  min_stock NUMERIC(14, 4) NOT NULL DEFAULT 0,
  current_stock NUMERIC(14, 4) NOT NULL DEFAULT 0,
  description TEXT,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(condominium_id, sku)
);

CREATE INDEX idx_materials_condominium ON materials(condominium_id);
CREATE INDEX idx_materials_category ON materials(category_id);
CREATE INDEX idx_materials_low_stock ON materials(condominium_id)
  WHERE current_stock <= min_stock AND status = 'active';

CREATE TABLE stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  material_id UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  movement_type stock_movement_type NOT NULL,
  quantity NUMERIC(14, 4) NOT NULL CHECK (quantity > 0),
  unit_cost NUMERIC(14, 4),
  total_cost NUMERIC(14, 2),
  reference_type TEXT,
  reference_id UUID,
  notes TEXT,
  performed_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_stock_movements_material ON stock_movements(material_id);
CREATE INDEX idx_stock_movements_condominium ON stock_movements(condominium_id);

-- Atualiza estoque automaticamente
CREATE OR REPLACE FUNCTION update_material_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.movement_type = 'entry' THEN
    UPDATE materials SET current_stock = current_stock + NEW.quantity WHERE id = NEW.material_id;
  ELSIF NEW.movement_type = 'exit' THEN
    UPDATE materials SET current_stock = current_stock - NEW.quantity WHERE id = NEW.material_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_stock_movement
  AFTER INSERT ON stock_movements
  FOR EACH ROW EXECUTE FUNCTION update_material_stock();

CREATE TRIGGER materials_updated_at
  BEFORE UPDATE ON materials FOR EACH ROW EXECUTE FUNCTION set_updated_at();
