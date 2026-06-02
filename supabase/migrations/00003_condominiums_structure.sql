-- Cond Manager - Condominiums Structure
-- Migration: 00003

CREATE TABLE condominiums (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  legal_name TEXT,
  cnpj TEXT,
  logo_url TEXT,
  -- Endereço
  street TEXT,
  number TEXT,
  complement TEXT,
  neighborhood TEXT,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  zip_code TEXT,
  country TEXT NOT NULL DEFAULT 'BR',
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  -- Síndico
  syndic_name TEXT,
  syndic_phone TEXT,
  syndic_email TEXT,
  -- Administradora
  manager_company TEXT,
  manager_phone TEXT,
  manager_email TEXT,
  -- Configurações
  settings JSONB NOT NULL DEFAULT '{}',
  status entity_status NOT NULL DEFAULT 'active',
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_condominiums_status ON condominiums(status);
CREATE INDEX idx_condominiums_city ON condominiums(city);

ALTER TABLE user_condominium_roles
  ADD CONSTRAINT fk_ucr_condominium
  FOREIGN KEY (condominium_id) REFERENCES condominiums(id) ON DELETE CASCADE;

ALTER TABLE user_invitations
  ADD CONSTRAINT fk_invitations_condominium
  FOREIGN KEY (condominium_id) REFERENCES condominiums(id) ON DELETE CASCADE;

CREATE TABLE blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(condominium_id, name)
);

CREATE TABLE towers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  block_id UUID REFERENCES blocks(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  floors INT,
  description TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(condominium_id, name)
);

CREATE TABLE units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  block_id UUID REFERENCES blocks(id) ON DELETE SET NULL,
  tower_id UUID REFERENCES towers(id) ON DELETE SET NULL,
  identifier TEXT NOT NULL,
  floor INT,
  area_sqm NUMERIC(10, 2),
  owner_name TEXT,
  owner_phone TEXT,
  owner_email TEXT,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(condominium_id, identifier)
);

ALTER TABLE user_condominium_roles
  ADD CONSTRAINT fk_ucr_unit
  FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE SET NULL;

CREATE TABLE common_areas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  block_id UUID REFERENCES blocks(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  area_sqm NUMERIC(10, 2),
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(condominium_id, name)
);

CREATE TABLE equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  common_area_id UUID REFERENCES common_areas(id) ON DELETE SET NULL,
  unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  brand TEXT,
  model TEXT,
  serial_number TEXT,
  service_type service_type,
  installation_date DATE,
  warranty_until DATE,
  last_maintenance_at TIMESTAMPTZ,
  next_maintenance_at TIMESTAMPTZ,
  notes TEXT,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_equipment_condominium ON equipment(condominium_id);
CREATE INDEX idx_equipment_next_maintenance ON equipment(next_maintenance_at);

CREATE TRIGGER condominiums_updated_at
  BEFORE UPDATE ON condominiums FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER blocks_updated_at
  BEFORE UPDATE ON blocks FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER towers_updated_at
  BEFORE UPDATE ON towers FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER units_updated_at
  BEFORE UPDATE ON units FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER common_areas_updated_at
  BEFORE UPDATE ON common_areas FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER equipment_updated_at
  BEFORE UPDATE ON equipment FOR EACH ROW EXECUTE FUNCTION set_updated_at();
