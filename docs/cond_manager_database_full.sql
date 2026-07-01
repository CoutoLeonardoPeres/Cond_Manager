-- ========== 00001_extensions_and_enums.sql ==========
-- Cond Manager - Extensions and Enums
-- Migration: 00001

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Perfis de usuário da plataforma
CREATE TYPE user_role AS ENUM (
  'platform_admin',
  'condominium_admin',
  'syndic',
  'caretaker',
  'maintenance_manager',
  'internal_employee',
  'service_provider',
  'supplier',
  'resident',
  'financial',
  'auditor'
);

CREATE TYPE entity_status AS ENUM (
  'active',
  'inactive',
  'blocked',
  'pending'
);

CREATE TYPE service_type AS ENUM (
  'electrical',
  'plumbing',
  'mechanical',
  'masonry',
  'painting',
  'gates',
  'access_control',
  'cctv',
  'intercom',
  'cleaning',
  'water_tank',
  'lighting',
  'landscaping',
  'elevators',
  'pumps',
  'pool',
  'roof',
  'waterproofing',
  'other'
);

CREATE TYPE priority_level AS ENUM (
  'low',
  'medium',
  'high',
  'urgent'
);

CREATE TYPE ticket_status AS ENUM (
  'open',
  'in_analysis',
  'waiting_info',
  'converted_to_os',
  'resolved',
  'cancelled'
);

CREATE TYPE work_order_status AS ENUM (
  'open',
  'triage',
  'waiting_budget',
  'budget_received',
  'waiting_approval',
  'approved',
  'in_progress',
  'paused',
  'waiting_material',
  'completed',
  'rejected',
  'cancelled',
  'closed'
);

CREATE TYPE preventive_frequency AS ENUM (
  'daily',
  'weekly',
  'monthly',
  'quarterly',
  'semiannual',
  'annual'
);

CREATE TYPE provider_type AS ENUM (
  'supplier',
  'outsourced',
  'subcontracted',
  'internal_team'
);

CREATE TYPE approval_type AS ENUM (
  'budget',
  'execution',
  'closure'
);

CREATE TYPE approval_status AS ENUM (
  'pending',
  'approved',
  'rejected'
);

CREATE TYPE attachment_phase AS ENUM (
  'before',
  'during',
  'after',
  'document',
  'signature'
);

CREATE TYPE stock_movement_type AS ENUM (
  'entry',
  'exit',
  'adjustment'
);

CREATE TYPE financial_record_type AS ENUM (
  'expense',
  'income',
  'budget'
);

CREATE TYPE location_type AS ENUM (
  'unit',
  'common_area',
  'block',
  'tower',
  'equipment',
  'other'
);

-- ========== 00002_profiles_and_roles.sql ==========
-- Cond Manager - Profiles and User-Condominium Roles
-- Migration: 00002

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  cpf TEXT,
  is_platform_admin BOOLEAN NOT NULL DEFAULT FALSE,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_status ON profiles(status);

CREATE TABLE user_condominium_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  condominium_id UUID NOT NULL, -- FK added after condominiums table
  role user_role NOT NULL,
  unit_id UUID, -- FK added after units table (for residents)
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  invited_by UUID REFERENCES profiles(id),
  invited_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, condominium_id, role)
);

CREATE INDEX idx_ucr_user ON user_condominium_roles(user_id);
CREATE INDEX idx_ucr_condominium ON user_condominium_roles(condominium_id);
CREATE INDEX idx_ucr_role ON user_condominium_roles(role);

CREATE TABLE user_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  condominium_id UUID NOT NULL,
  role user_role NOT NULL,
  invited_by UUID NOT NULL REFERENCES profiles(id),
  token TEXT NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invitations_email ON user_invitations(email);
CREATE INDEX idx_invitations_token ON user_invitations(token);

-- Trigger: auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Trigger: updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER ucr_updated_at
  BEFORE UPDATE ON user_condominium_roles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ========== 00003_condominiums_structure.sql ==========
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
  manager_cnpj TEXT,
  manager_contact_name TEXT,
  manager_phone TEXT,
  manager_email TEXT,
  manager_street TEXT,
  manager_number TEXT,
  manager_complement TEXT,
  manager_neighborhood TEXT,
  manager_city TEXT,
  manager_state TEXT,
  manager_zip_code TEXT,
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

-- ========== 00004_providers_and_team.sql ==========
-- Cond Manager - Providers, Suppliers and Internal Team
-- Migration: 00004

CREATE TABLE providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id UUID REFERENCES condominiums(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  provider_type provider_type NOT NULL,
  document_type TEXT NOT NULL CHECK (document_type IN ('cpf', 'cnpj')),
  document_number TEXT NOT NULL,
  legal_name TEXT NOT NULL,
  trade_name TEXT,
  specialties service_type[] NOT NULL DEFAULT '{}',
  phones TEXT[] NOT NULL DEFAULT '{}',
  emails TEXT[] NOT NULL DEFAULT '{}',
  street TEXT,
  number TEXT,
  complement TEXT,
  neighborhood TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  rating NUMERIC(3, 2) CHECK (rating >= 0 AND rating <= 5),
  rating_count INT NOT NULL DEFAULT 0,
  status entity_status NOT NULL DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_providers_condominium ON providers(condominium_id);
CREATE INDEX idx_providers_type ON providers(provider_type);
CREATE INDEX idx_providers_status ON providers(status);
CREATE INDEX idx_providers_document ON providers(document_number);

CREATE TABLE provider_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  document_type TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_path TEXT NOT NULL,
  valid_from DATE,
  valid_until DATE,
  is_valid BOOLEAN NOT NULL DEFAULT TRUE,
  uploaded_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_provider_docs_provider ON provider_documents(provider_id);
CREATE INDEX idx_provider_docs_valid_until ON provider_documents(valid_until);

CREATE TABLE provider_contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  contract_number TEXT,
  description TEXT,
  start_date DATE NOT NULL,
  end_date DATE,
  value NUMERIC(14, 2),
  file_url TEXT,
  file_path TEXT,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE provider_evaluations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  work_order_id UUID, -- FK added later
  evaluator_id UUID NOT NULL REFERENCES profiles(id),
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER providers_updated_at
  BEFORE UPDATE ON providers FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER provider_documents_updated_at
  BEFORE UPDATE ON provider_documents FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER provider_contracts_updated_at
  BEFORE UPDATE ON provider_contracts FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ========== 00005_materials.sql ==========
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

-- ========== 00006_tickets.sql ==========
-- Cond Manager - Tickets (Chamados)
-- Migration: 00006

CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  ticket_number SERIAL,
  requester_id UUID NOT NULL REFERENCES profiles(id),
  -- Localização
  location_type location_type NOT NULL DEFAULT 'other',
  unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
  common_area_id UUID REFERENCES common_areas(id) ON DELETE SET NULL,
  block_id UUID REFERENCES blocks(id) ON DELETE SET NULL,
  location_description TEXT,
  -- Classificação
  service_type service_type NOT NULL DEFAULT 'other',
  priority priority_level NOT NULL DEFAULT 'medium',
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  status ticket_status NOT NULL DEFAULT 'open',
  assigned_to UUID REFERENCES profiles(id),
  work_order_id UUID, -- FK added after work_orders
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tickets_condominium ON tickets(condominium_id);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_requester ON tickets(requester_id);
CREATE INDEX idx_tickets_priority ON tickets(priority);

CREATE TABLE ticket_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  mime_type TEXT,
  uploaded_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE ticket_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id),
  message TEXT NOT NULL,
  is_internal BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ticket_interactions_ticket ON ticket_interactions(ticket_id);

CREATE TRIGGER tickets_updated_at
  BEFORE UPDATE ON tickets FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ========== 00007_work_orders.sql ==========
-- Cond Manager - Work Orders (Ordens de Serviço)
-- Migration: 00007

CREATE TABLE work_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  os_number SERIAL,
  ticket_id UUID REFERENCES tickets(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  service_type service_type NOT NULL DEFAULT 'other',
  priority priority_level NOT NULL DEFAULT 'medium',
  status work_order_status NOT NULL DEFAULT 'open',
  -- Pessoas
  requester_id UUID REFERENCES profiles(id),
  internal_responsible_id UUID REFERENCES profiles(id),
  provider_id UUID REFERENCES providers(id),
  -- Localização
  location_type location_type NOT NULL DEFAULT 'other',
  unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
  common_area_id UUID REFERENCES common_areas(id) ON DELETE SET NULL,
  equipment_id UUID REFERENCES equipment(id) ON DELETE SET NULL,
  location_description TEXT,
  -- Prazos e custos
  due_date TIMESTAMPTZ,
  estimated_cost NUMERIC(14, 2) DEFAULT 0,
  actual_cost NUMERIC(14, 2) DEFAULT 0,
  labor_cost NUMERIC(14, 2) DEFAULT 0,
  material_cost NUMERIC(14, 2) DEFAULT 0,
  travel_cost NUMERIC(14, 2) DEFAULT 0,
  -- Execução
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,
  closure_notes TEXT,
  -- Assinatura
  signature_url TEXT,
  signature_path TEXT,
  signed_by TEXT,
  signed_at TIMESTAMPTZ,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE tickets
  ADD CONSTRAINT fk_tickets_work_order
  FOREIGN KEY (work_order_id) REFERENCES work_orders(id) ON DELETE SET NULL;

ALTER TABLE provider_evaluations
  ADD CONSTRAINT fk_evaluations_work_order
  FOREIGN KEY (work_order_id) REFERENCES work_orders(id) ON DELETE SET NULL;

CREATE INDEX idx_work_orders_condominium ON work_orders(condominium_id);
CREATE INDEX idx_work_orders_status ON work_orders(status);
CREATE INDEX idx_work_orders_ticket ON work_orders(ticket_id);
CREATE INDEX idx_work_orders_provider ON work_orders(provider_id);
CREATE INDEX idx_work_orders_due_date ON work_orders(due_date);

CREATE TABLE work_order_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_order_id UUID NOT NULL REFERENCES work_orders(id) ON DELETE CASCADE,
  from_status work_order_status,
  to_status work_order_status NOT NULL,
  changed_by UUID REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_wo_history_order ON work_order_status_history(work_order_id);

CREATE TABLE work_order_materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_order_id UUID NOT NULL REFERENCES work_orders(id) ON DELETE CASCADE,
  material_id UUID REFERENCES materials(id) ON DELETE SET NULL,
  material_name TEXT NOT NULL,
  quantity NUMERIC(14, 4) NOT NULL,
  unit_of_measure TEXT NOT NULL DEFAULT 'un',
  unit_cost NUMERIC(14, 4) NOT NULL DEFAULT 0,
  total_cost NUMERIC(14, 2) NOT NULL DEFAULT 0,
  stock_movement_id UUID REFERENCES stock_movements(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE work_order_labor (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_order_id UUID NOT NULL REFERENCES work_orders(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES providers(id),
  worker_name TEXT NOT NULL,
  hours NUMERIC(8, 2) NOT NULL DEFAULT 0,
  hourly_rate NUMERIC(14, 2) NOT NULL DEFAULT 0,
  total_cost NUMERIC(14, 2) NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE work_order_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_order_id UUID NOT NULL REFERENCES work_orders(id) ON DELETE CASCADE,
  phase attachment_phase NOT NULL DEFAULT 'document',
  file_url TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  mime_type TEXT,
  uploaded_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE work_order_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_order_id UUID NOT NULL REFERENCES work_orders(id) ON DELETE CASCADE,
  approval_type approval_type NOT NULL,
  status approval_status NOT NULL DEFAULT 'pending',
  approver_id UUID REFERENCES profiles(id),
  requested_by UUID REFERENCES profiles(id),
  amount NUMERIC(14, 2),
  notes TEXT,
  decided_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_wo_approvals_order ON work_order_approvals(work_order_id);
CREATE INDEX idx_wo_approvals_status ON work_order_approvals(status);

-- Histórico automático de status
CREATE OR REPLACE FUNCTION log_work_order_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO work_order_status_history (work_order_id, from_status, to_status, changed_by)
    VALUES (NEW.id, OLD.status, NEW.status, auth.uid());
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_work_order_status_change
  AFTER UPDATE OF status ON work_orders
  FOR EACH ROW EXECUTE FUNCTION log_work_order_status_change();

CREATE TRIGGER work_orders_updated_at
  BEFORE UPDATE ON work_orders FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER wo_approvals_updated_at
  BEFORE UPDATE ON work_order_approvals FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ========== 00008_preventive_maintenance.sql ==========
-- Cond Manager - Preventive Maintenance
-- Migration: 00008

CREATE TABLE preventive_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  service_type service_type NOT NULL DEFAULT 'other',
  frequency preventive_frequency NOT NULL,
  -- Vinculação
  equipment_id UUID REFERENCES equipment(id) ON DELETE SET NULL,
  common_area_id UUID REFERENCES common_areas(id) ON DELETE SET NULL,
  unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
  -- Responsável
  responsible_id UUID REFERENCES profiles(id),
  provider_id UUID REFERENCES providers(id),
  -- Agendamento
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  next_due_date DATE NOT NULL,
  last_executed_at TIMESTAMPTZ,
  lead_time_days INT NOT NULL DEFAULT 7,
  auto_generate_os BOOLEAN NOT NULL DEFAULT TRUE,
  estimated_cost NUMERIC(14, 2) DEFAULT 0,
  status entity_status NOT NULL DEFAULT 'active',
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_preventive_plans_condominium ON preventive_plans(condominium_id);
CREATE INDEX idx_preventive_plans_next_due ON preventive_plans(next_due_date)
  WHERE status = 'active';

CREATE TABLE preventive_checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES preventive_plans(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  is_required BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE preventive_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES preventive_plans(id) ON DELETE CASCADE,
  work_order_id UUID REFERENCES work_orders(id) ON DELETE SET NULL,
  scheduled_date DATE NOT NULL,
  executed_at TIMESTAMPTZ,
  executed_by UUID REFERENCES profiles(id),
  checklist_results JSONB NOT NULL DEFAULT '[]',
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'completed', 'skipped', 'overdue')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_preventive_executions_plan ON preventive_executions(plan_id);
CREATE INDEX idx_preventive_executions_scheduled ON preventive_executions(scheduled_date);

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  condominium_id UUID REFERENCES condominiums(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  reference_type TEXT,
  reference_id UUID,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);

CREATE TRIGGER preventive_plans_updated_at
  BEFORE UPDATE ON preventive_plans FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ========== 00009_financial.sql ==========
-- Cond Manager - Financial Records
-- Migration: 00009

CREATE TABLE financial_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  condominium_id UUID NOT NULL REFERENCES condominiums(id) ON DELETE CASCADE,
  record_type financial_record_type NOT NULL,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  amount NUMERIC(14, 2) NOT NULL,
  reference_date DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE,
  paid_at TIMESTAMPTZ,
  work_order_id UUID REFERENCES work_orders(id) ON DELETE SET NULL,
  provider_id UUID REFERENCES providers(id) ON DELETE SET NULL,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_financial_condominium ON financial_records(condominium_id);
CREATE INDEX idx_financial_type ON financial_records(record_type);
CREATE INDEX idx_financial_date ON financial_records(reference_date);
CREATE INDEX idx_financial_work_order ON financial_records(work_order_id);

CREATE TRIGGER financial_records_updated_at
  BEFORE UPDATE ON financial_records FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ========== 00010_storage_and_functions.sql ==========
-- Cond Manager - Storage Buckets and Helper Functions
-- Migration: 00010

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('condominium-assets', 'condominium-assets', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('tickets', 'tickets', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('work-orders', 'work-orders', false, 20971520, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('provider-documents', 'provider-documents', false, 20971520, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
  ('signatures', 'signatures', false, 2097152, ARRAY['image/png', 'image/jpeg'])
ON CONFLICT (id) DO NOTHING;

-- Funções auxiliares para RLS
CREATE OR REPLACE FUNCTION is_platform_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT is_platform_admin FROM profiles WHERE id = auth.uid()),
    FALSE
  );
$$;

CREATE OR REPLACE FUNCTION has_condominium_access(p_condominium_id UUID)
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
        AND condominium_id = p_condominium_id
        AND status = 'active'
    );
$$;

CREATE OR REPLACE FUNCTION get_user_role(p_condominium_id UUID)
RETURNS user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM user_condominium_roles
  WHERE user_id = auth.uid()
    AND condominium_id = p_condominium_id
    AND status = 'active'
  ORDER BY is_primary DESC
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION can_manage_condominium(p_condominium_id UUID)
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
        AND condominium_id = p_condominium_id
        AND status = 'active'
        AND role IN (
          'condominium_admin', 'syndic', 'maintenance_manager', 'caretaker'
        )
    );
$$;

CREATE OR REPLACE FUNCTION can_approve_work_orders(p_condominium_id UUID)
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
        AND condominium_id = p_condominium_id
        AND status = 'active'
        AND role IN ('condominium_admin', 'syndic', 'financial', 'maintenance_manager')
    );
$$;

CREATE OR REPLACE FUNCTION can_view_financial(p_condominium_id UUID)
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
        AND condominium_id = p_condominium_id
        AND status = 'active'
        AND role IN (
          'condominium_admin', 'syndic', 'financial', 'maintenance_manager', 'auditor'
        )
    );
$$;

-- View: número formatado de chamado/OS por condomínio
CREATE OR REPLACE VIEW ticket_summary AS
SELECT
  t.id,
  t.condominium_id,
  t.ticket_number,
  CONCAT('CH-', LPAD(t.ticket_number::TEXT, 5, '0')) AS formatted_number,
  t.title,
  t.status,
  t.priority,
  t.service_type,
  t.created_at
FROM tickets t;

CREATE OR REPLACE VIEW work_order_summary AS
SELECT
  wo.id,
  wo.condominium_id,
  wo.os_number,
  CONCAT('OS-', LPAD(wo.os_number::TEXT, 5, '0')) AS formatted_number,
  wo.title,
  wo.status,
  wo.priority,
  wo.service_type,
  wo.estimated_cost,
  wo.actual_cost,
  wo.due_date,
  wo.created_at
FROM work_orders wo;

-- ========== 00011_rls_policies.sql ==========
-- Cond Manager - Row Level Security Policies
-- Migration: 00011

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_condominium_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE condominiums ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE towers ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;
ALTER TABLE common_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_labor ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE preventive_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE preventive_checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE preventive_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_records ENABLE ROW LEVEL SECURITY;

-- PROFILES
CREATE POLICY profiles_select ON profiles FOR SELECT
  USING (id = auth.uid() OR is_platform_admin());

CREATE POLICY profiles_update ON profiles FOR UPDATE
  USING (id = auth.uid() OR is_platform_admin());

-- USER CONDOMINIUM ROLES
CREATE POLICY ucr_select ON user_condominium_roles FOR SELECT
  USING (user_id = auth.uid() OR has_condominium_access(condominium_id) OR is_platform_admin());

CREATE POLICY ucr_insert ON user_condominium_roles FOR INSERT
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY ucr_update ON user_condominium_roles FOR UPDATE
  USING (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY ucr_delete ON user_condominium_roles FOR DELETE
  USING (can_manage_condominium(condominium_id) OR is_platform_admin());

-- INVITATIONS
CREATE POLICY invitations_select ON user_invitations FOR SELECT
  USING (has_condominium_access(condominium_id) OR is_platform_admin());

CREATE POLICY invitations_insert ON user_invitations FOR INSERT
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

-- CONDOMINIUMS
CREATE POLICY condominiums_select ON condominiums FOR SELECT
  USING (has_condominium_access(id) OR is_platform_admin());

CREATE POLICY condominiums_insert ON condominiums FOR INSERT
  WITH CHECK (is_platform_admin());

CREATE POLICY condominiums_update ON condominiums FOR UPDATE
  USING (can_manage_condominium(id) OR is_platform_admin());

CREATE POLICY condominiums_delete ON condominiums FOR DELETE
  USING (is_platform_admin());

-- STRUCTURE TABLES (blocks, towers, units, common_areas, equipment)
CREATE POLICY blocks_all ON blocks FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY towers_all ON towers FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY units_select ON units FOR SELECT
  USING (has_condominium_access(condominium_id));

CREATE POLICY units_modify ON units FOR ALL
  USING (can_manage_condominium(condominium_id) OR is_platform_admin())
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY common_areas_all ON common_areas FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY equipment_all ON equipment FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

-- PROVIDERS
CREATE POLICY providers_select ON providers FOR SELECT
  USING (
    is_platform_admin()
    OR (condominium_id IS NOT NULL AND has_condominium_access(condominium_id))
    OR user_id = auth.uid()
  );

CREATE POLICY providers_modify ON providers FOR ALL
  USING (can_manage_condominium(condominium_id) OR is_platform_admin())
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY provider_docs_select ON provider_documents FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM providers p
      WHERE p.id = provider_id
        AND (has_condominium_access(p.condominium_id) OR p.user_id = auth.uid())
    )
  );

CREATE POLICY provider_docs_modify ON provider_documents FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM providers p
      WHERE p.id = provider_id
        AND (can_manage_condominium(p.condominium_id) OR is_platform_admin())
    )
  );

-- MATERIALS
CREATE POLICY materials_select ON materials FOR SELECT
  USING (has_condominium_access(condominium_id));

CREATE POLICY materials_modify ON materials FOR ALL
  USING (
    get_user_role(condominium_id) IN (
      'condominium_admin', 'maintenance_manager', 'caretaker', 'internal_employee'
    ) OR is_platform_admin()
  )
  WITH CHECK (
    get_user_role(condominium_id) IN (
      'condominium_admin', 'maintenance_manager', 'caretaker'
    ) OR is_platform_admin()
  );

CREATE POLICY stock_movements_all ON stock_movements FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (
    get_user_role(condominium_id) IN (
      'condominium_admin', 'maintenance_manager', 'caretaker', 'internal_employee'
    ) OR is_platform_admin()
  );

CREATE POLICY material_categories_all ON material_categories FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

-- TICKETS
CREATE POLICY tickets_select ON tickets FOR SELECT
  USING (
    has_condominium_access(condominium_id)
    AND (
      requester_id = auth.uid()
      OR assigned_to = auth.uid()
      OR get_user_role(condominium_id) NOT IN ('resident')
      OR is_platform_admin()
    )
  );

CREATE POLICY tickets_insert ON tickets FOR INSERT
  WITH CHECK (
    has_condominium_access(condominium_id)
    AND requester_id = auth.uid()
  );

CREATE POLICY tickets_update ON tickets FOR UPDATE
  USING (
    has_condominium_access(condominium_id)
    AND (
      requester_id = auth.uid()
      OR can_manage_condominium(condominium_id)
      OR assigned_to = auth.uid()
      OR is_platform_admin()
    )
  );

CREATE POLICY ticket_attachments_all ON ticket_attachments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_id AND has_condominium_access(t.condominium_id)
    )
  );

CREATE POLICY ticket_interactions_select ON ticket_interactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_id
        AND has_condominium_access(t.condominium_id)
        AND (NOT is_internal OR can_manage_condominium(t.condominium_id))
    )
  );

CREATE POLICY ticket_interactions_insert ON ticket_interactions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_id AND has_condominium_access(t.condominium_id)
    )
    AND author_id = auth.uid()
  );

-- WORK ORDERS
CREATE POLICY work_orders_select ON work_orders FOR SELECT
  USING (has_condominium_access(condominium_id));

CREATE POLICY work_orders_insert ON work_orders FOR INSERT
  WITH CHECK (
    can_manage_condominium(condominium_id)
    OR get_user_role(condominium_id) IN ('maintenance_manager', 'caretaker', 'internal_employee')
    OR is_platform_admin()
  );

CREATE POLICY work_orders_update ON work_orders FOR UPDATE
  USING (
    has_condominium_access(condominium_id)
    AND (
      can_manage_condominium(condominium_id)
      OR internal_responsible_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM providers p
        WHERE p.id = provider_id AND p.user_id = auth.uid()
      )
      OR is_platform_admin()
    )
  );

CREATE POLICY wo_history_select ON work_order_status_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = work_order_id AND has_condominium_access(wo.condominium_id)
    )
  );

CREATE POLICY wo_materials_all ON work_order_materials FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = work_order_id AND has_condominium_access(wo.condominium_id)
    )
  );

CREATE POLICY wo_labor_all ON work_order_labor FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = work_order_id AND has_condominium_access(wo.condominium_id)
    )
  );

CREATE POLICY wo_attachments_all ON work_order_attachments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = work_order_id AND has_condominium_access(wo.condominium_id)
    )
  );

CREATE POLICY wo_approvals_select ON work_order_approvals FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = work_order_id AND has_condominium_access(wo.condominium_id)
    )
  );

CREATE POLICY wo_approvals_update ON work_order_approvals FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = work_order_id AND can_approve_work_orders(wo.condominium_id)
    )
  );

-- PREVENTIVE
CREATE POLICY preventive_plans_all ON preventive_plans FOR ALL
  USING (has_condominium_access(condominium_id))
  WITH CHECK (can_manage_condominium(condominium_id) OR is_platform_admin());

CREATE POLICY preventive_checklist_all ON preventive_checklist_items FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM preventive_plans pp
      WHERE pp.id = plan_id AND has_condominium_access(pp.condominium_id)
    )
  );

CREATE POLICY preventive_executions_all ON preventive_executions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM preventive_plans pp
      WHERE pp.id = plan_id AND has_condominium_access(pp.condominium_id)
    )
  );

-- NOTIFICATIONS
CREATE POLICY notifications_own ON notifications FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- FINANCIAL
CREATE POLICY financial_select ON financial_records FOR SELECT
  USING (can_view_financial(condominium_id));

CREATE POLICY financial_modify ON financial_records FOR ALL
  USING (
    get_user_role(condominium_id) IN ('condominium_admin', 'financial')
    OR is_platform_admin()
  )
  WITH CHECK (
    get_user_role(condominium_id) IN ('condominium_admin', 'financial')
    OR is_platform_admin()
  );

-- STORAGE POLICIES
CREATE POLICY storage_avatars ON storage.objects FOR ALL
  USING (bucket_id = 'avatars' AND auth.uid()::TEXT = (storage.foldername(name))[1])
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::TEXT = (storage.foldername(name))[1]);

CREATE POLICY storage_condominium ON storage.objects FOR ALL
  USING (
    bucket_id = 'condominium-assets'
    AND has_condominium_access((storage.foldername(name))[1]::UUID)
  );

CREATE POLICY storage_tickets ON storage.objects FOR ALL
  USING (
    bucket_id = 'tickets'
    AND EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = (storage.foldername(name))[2]::UUID
        AND has_condominium_access(t.condominium_id)
    )
  );

CREATE POLICY storage_work_orders ON storage.objects FOR ALL
  USING (
    bucket_id = 'work-orders'
    AND EXISTS (
      SELECT 1 FROM work_orders wo
      WHERE wo.id = (storage.foldername(name))[2]::UUID
        AND has_condominium_access(wo.condominium_id)
    )
  );

CREATE POLICY storage_provider_docs ON storage.objects FOR ALL
  USING (bucket_id = 'provider-documents' AND auth.uid() IS NOT NULL);

CREATE POLICY storage_signatures ON storage.objects FOR ALL
  USING (bucket_id = 'signatures' AND auth.uid() IS NOT NULL);

-- Realtime (habilitar nas tabelas críticas via dashboard ou):
ALTER PUBLICATION supabase_realtime ADD TABLE tickets;
ALTER PUBLICATION supabase_realtime ADD TABLE work_orders;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE work_order_approvals;

-- ========== 00012_condominiums_manager_fields.sql ==========
-- Cond Manager - Campos completos da administradora no condomínio
-- Migration: 00012
-- Execute no SQL Editor se o schema base (00003) já foi aplicado antes desta atualização

ALTER TABLE condominiums
  ADD COLUMN IF NOT EXISTS manager_cnpj TEXT,
  ADD COLUMN IF NOT EXISTS manager_contact_name TEXT,
  ADD COLUMN IF NOT EXISTS manager_street TEXT,
  ADD COLUMN IF NOT EXISTS manager_number TEXT,
  ADD COLUMN IF NOT EXISTS manager_complement TEXT,
  ADD COLUMN IF NOT EXISTS manager_neighborhood TEXT,
  ADD COLUMN IF NOT EXISTS manager_city TEXT,
  ADD COLUMN IF NOT EXISTS manager_state TEXT,
  ADD COLUMN IF NOT EXISTS manager_zip_code TEXT;

COMMENT ON COLUMN condominiums.manager_contact_name IS 'Nome do contato na administradora';
COMMENT ON COLUMN condominiums.manager_cnpj IS 'CNPJ da empresa administradora';

-- ========== 00012_materials_pricing.sql ==========
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

-- ========== 00013_preventive_notifications.sql ==========
-- Permite gestores criarem alertas de preventiva para responsáveis do condomínio
CREATE POLICY notifications_insert_management ON notifications FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    OR (
      condominium_id IS NOT NULL
      AND (can_manage_condominium(condominium_id) OR is_platform_admin())
    )
  );

-- WITH CHECK em checklist e execuções (insert/update)
CREATE POLICY preventive_checklist_modify ON preventive_checklist_items FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM preventive_plans pp
      WHERE pp.id = plan_id AND has_condominium_access(pp.condominium_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM preventive_plans pp
      WHERE pp.id = plan_id
        AND (can_manage_condominium(pp.condominium_id) OR is_platform_admin())
    )
  );

CREATE POLICY preventive_executions_modify ON preventive_executions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM preventive_plans pp
      WHERE pp.id = plan_id AND has_condominium_access(pp.condominium_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM preventive_plans pp
      WHERE pp.id = plan_id
        AND (can_manage_condominium(pp.condominium_id) OR is_platform_admin())
    )
  );

-- ========== 00014_financial_extended.sql ==========
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

-- ========== 00015_material_suppliers.sql ==========
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

-- ========== 00016_work_order_labor_extended.sql ==========
-- Cond Manager - Mão de obra detalhada na OS (HH, profissionais, deslocamento)
-- Migration: 00016

DO $$ BEGIN
  CREATE TYPE labor_source AS ENUM ('third_party', 'internal_team');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE work_order_labor
  ADD COLUMN IF NOT EXISTS labor_source labor_source NOT NULL DEFAULT 'third_party',
  ADD COLUMN IF NOT EXISTS service_type service_type NOT NULL DEFAULT 'other',
  ADD COLUMN IF NOT EXISTS worker_count INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS travel_cost NUMERIC(14, 2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL;

DO $$ BEGIN
  ALTER TABLE work_order_labor
    ADD CONSTRAINT work_order_labor_worker_count_positive CHECK (worker_count >= 1);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE work_order_labor
    ADD CONSTRAINT work_order_labor_travel_nonneg CHECK (travel_cost >= 0);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE OR REPLACE FUNCTION work_order_labor_compute_total()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.total_cost := (NEW.worker_count * NEW.hours * NEW.hourly_rate) + NEW.travel_cost;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS work_order_labor_compute_total_trg ON work_order_labor;
CREATE TRIGGER work_order_labor_compute_total_trg
  BEFORE INSERT OR UPDATE ON work_order_labor
  FOR EACH ROW EXECUTE FUNCTION work_order_labor_compute_total();

CREATE OR REPLACE FUNCTION refresh_work_order_labor_totals()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  wo_id UUID;
  labor_sum NUMERIC(14, 2);
  travel_sum NUMERIC(14, 2);
  material_sum NUMERIC(14, 2);
BEGIN
  wo_id := COALESCE(NEW.work_order_id, OLD.work_order_id);

  SELECT COALESCE(SUM(worker_count * hours * hourly_rate), 0),
         COALESCE(SUM(travel_cost), 0)
    INTO labor_sum, travel_sum
    FROM work_order_labor
   WHERE work_order_id = wo_id;

  SELECT COALESCE(material_cost, 0) INTO material_sum
    FROM work_orders WHERE id = wo_id;

  UPDATE work_orders
     SET labor_cost = labor_sum,
         travel_cost = travel_sum,
         actual_cost = material_sum + labor_sum + travel_sum
   WHERE id = wo_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS work_order_labor_refresh_wo_costs_ins ON work_order_labor;
CREATE TRIGGER work_order_labor_refresh_wo_costs_ins
  AFTER INSERT ON work_order_labor
  FOR EACH ROW EXECUTE FUNCTION refresh_work_order_labor_totals();

DROP TRIGGER IF EXISTS work_order_labor_refresh_wo_costs_upd ON work_order_labor;
CREATE TRIGGER work_order_labor_refresh_wo_costs_upd
  AFTER UPDATE ON work_order_labor
  FOR EACH ROW EXECUTE FUNCTION refresh_work_order_labor_totals();

DROP TRIGGER IF EXISTS work_order_labor_refresh_wo_costs_del ON work_order_labor;
CREATE TRIGGER work_order_labor_refresh_wo_costs_del
  AFTER DELETE ON work_order_labor
  FOR EACH ROW EXECUTE FUNCTION refresh_work_order_labor_totals();

-- Recalcular linhas existentes
UPDATE work_order_labor
   SET total_cost = (worker_count * hours * hourly_rate) + travel_cost;

-- ========== 00017_organization_users.sql ==========
-- Cond Manager - Empresa gestora, papéis organizacionais e usuários
-- Migration: 00017

DO $$ BEGIN
  CREATE TYPE organization_role AS ENUM (
    'manager',
    'analyst',
    'field_team',
    'client'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS management_companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  legal_name TEXT NOT NULL,
  trade_name TEXT,
  cnpj TEXT UNIQUE,
  email TEXT,
  phone TEXT,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER management_companies_updated_at
  BEFORE UPDATE ON management_companies
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE condominiums
  ADD COLUMN IF NOT EXISTS management_company_id UUID REFERENCES management_companies(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_condominiums_management_company
  ON condominiums(management_company_id);

CREATE TABLE IF NOT EXISTS company_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  role organization_role NOT NULL,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, company_id)
);

CREATE INDEX IF NOT EXISTS idx_company_memberships_user ON company_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_company_memberships_company ON company_memberships(company_id);
CREATE INDEX IF NOT EXISTS idx_company_memberships_role ON company_memberships(role);

CREATE TRIGGER company_memberships_updated_at
  BEFORE UPDATE ON company_memberships
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE user_invitations
  ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES management_companies(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS organization_role organization_role;

ALTER TABLE user_invitations
  ALTER COLUMN condominium_id DROP NOT NULL;

-- Helpers de permissão organizacional
CREATE OR REPLACE FUNCTION get_user_company_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT company_id
    FROM company_memberships
   WHERE user_id = auth.uid()
     AND status = 'active'
   ORDER BY created_at
   LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION get_user_organization_role(p_company_id UUID DEFAULT NULL)
RETURNS organization_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role
    FROM company_memberships
   WHERE user_id = auth.uid()
     AND status = 'active'
     AND (p_company_id IS NULL OR company_id = p_company_id)
   ORDER BY created_at
   LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION is_company_manager(p_company_id UUID DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_platform_admin()
    OR get_user_organization_role(p_company_id) = 'manager';
$$;

CREATE OR REPLACE FUNCTION can_manage_company_users(p_company_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_platform_admin()
    OR (
      get_user_company_id() = p_company_id
      AND get_user_organization_role(p_company_id) = 'manager'
    );
$$;

CREATE OR REPLACE FUNCTION has_company_access(p_company_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_platform_admin()
    OR EXISTS (
      SELECT 1 FROM company_memberships
      WHERE user_id = auth.uid()
        AND company_id = p_company_id
        AND status = 'active'
    );
$$;

CREATE OR REPLACE FUNCTION condominium_belongs_to_user_company(p_condominium_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_platform_admin()
    OR EXISTS (
      SELECT 1 FROM condominiums c
      JOIN company_memberships cm ON cm.company_id = c.management_company_id
      WHERE c.id = p_condominium_id
        AND cm.user_id = auth.uid()
        AND cm.status = 'active'
        AND cm.role IN ('manager', 'analyst', 'field_team')
    )
    OR EXISTS (
      SELECT 1 FROM user_condominium_roles ucr
      WHERE ucr.user_id = auth.uid()
        AND ucr.condominium_id = p_condominium_id
        AND ucr.status = 'active'
    );
$$;

-- Aceitar convite → membership + papel no condomínio (cliente)
CREATE OR REPLACE FUNCTION accept_user_invitation(p_token TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  inv user_invitations%ROWTYPE;
BEGIN
  SELECT * INTO inv FROM user_invitations
   WHERE token = p_token
     AND accepted_at IS NULL
     AND expires_at > NOW()
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Convite inválido ou expirado';
  END IF;

  IF inv.company_id IS NOT NULL AND inv.organization_role IS NOT NULL THEN
    INSERT INTO company_memberships (user_id, company_id, role, status)
    VALUES (auth.uid(), inv.company_id, inv.organization_role, 'active')
    ON CONFLICT (user_id, company_id) DO UPDATE
      SET role = EXCLUDED.role, status = 'active', updated_at = NOW();
  END IF;

  IF inv.condominium_id IS NOT NULL THEN
    INSERT INTO user_condominium_roles (user_id, condominium_id, role, status, invited_by, accepted_at)
    VALUES (
      auth.uid(),
      inv.condominium_id,
      COALESCE(inv.role, 'resident'),
      'active',
      inv.invited_by,
      NOW()
    )
    ON CONFLICT (user_id, condominium_id, role) DO UPDATE
      SET status = 'active', updated_at = NOW();
  END IF;

  UPDATE user_invitations SET accepted_at = NOW() WHERE id = inv.id;
END;
$$;

ALTER TABLE management_companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_memberships ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS management_companies_select ON management_companies;
CREATE POLICY management_companies_select ON management_companies FOR SELECT
  USING (is_platform_admin() OR has_company_access(id));

DROP POLICY IF EXISTS management_companies_modify ON management_companies;
CREATE POLICY management_companies_modify ON management_companies FOR ALL
  USING (is_platform_admin())
  WITH CHECK (is_platform_admin());

DROP POLICY IF EXISTS company_memberships_select ON company_memberships;
CREATE POLICY company_memberships_select ON company_memberships FOR SELECT
  USING (
    is_platform_admin()
    OR user_id = auth.uid()
    OR has_company_access(company_id)
  );

DROP POLICY IF EXISTS company_memberships_modify ON company_memberships;
CREATE POLICY company_memberships_modify ON company_memberships FOR ALL
  USING (can_manage_company_users(company_id) OR is_platform_admin())
  WITH CHECK (can_manage_company_users(company_id) OR is_platform_admin());

-- ========== 00018_user_invitations_extended.sql ==========
-- Convites: preview público, múltiplos condomínios e aceite aprimorado
-- Migration: 00018

ALTER TABLE user_invitations
  ADD COLUMN IF NOT EXISTS condominium_ids JSONB;

-- Preview do convite (sem autenticação — só metadados)
CREATE OR REPLACE FUNCTION get_user_invitation_preview(p_token TEXT)
RETURNS TABLE (
  email TEXT,
  organization_role organization_role,
  company_name TEXT,
  condominium_names TEXT[],
  expires_at TIMESTAMPTZ,
  is_valid BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  inv user_invitations%ROWTYPE;
  names TEXT[] := ARRAY[]::TEXT[];
  company TEXT;
BEGIN
  SELECT * INTO inv FROM user_invitations WHERE token = p_token;

  IF NOT FOUND THEN
    RETURN QUERY SELECT NULL::TEXT, NULL::organization_role, NULL::TEXT,
      ARRAY[]::TEXT[], NULL::TIMESTAMPTZ, FALSE;
    RETURN;
  END IF;

  IF inv.condominium_ids IS NOT NULL THEN
    SELECT coalesce(array_agg(c.name ORDER BY c.name), ARRAY[]::TEXT[])
      INTO names
      FROM condominiums c
     WHERE c.id IN (
       SELECT jsonb_array_elements_text(inv.condominium_ids)::UUID
     );
  ELSIF inv.condominium_id IS NOT NULL THEN
    SELECT array_agg(c.name)
      INTO names
      FROM condominiums c
     WHERE c.id = inv.condominium_id;
  END IF;

  IF inv.company_id IS NOT NULL THEN
    SELECT COALESCE(mc.trade_name, mc.legal_name)
      INTO company
      FROM management_companies mc
     WHERE mc.id = inv.company_id;
  END IF;

  RETURN QUERY
  SELECT
    inv.email,
    inv.organization_role,
    company,
    coalesce(names, ARRAY[]::TEXT[]),
    inv.expires_at,
    (inv.accepted_at IS NULL AND inv.expires_at > NOW());
END;
$$;

CREATE OR REPLACE FUNCTION accept_user_invitation(p_token TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  inv user_invitations%ROWTYPE;
  cid UUID;
  condo_ids UUID[];
BEGIN
  SELECT * INTO inv FROM user_invitations
   WHERE token = p_token
     AND accepted_at IS NULL
     AND expires_at > NOW()
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Convite inválido ou expirado';
  END IF;

  IF lower(trim(inv.email)) <> lower(trim((SELECT email FROM profiles WHERE id = auth.uid()))) THEN
    RAISE EXCEPTION 'Este convite foi enviado para outro e-mail';
  END IF;

  IF inv.company_id IS NOT NULL AND inv.organization_role IS NOT NULL THEN
    INSERT INTO company_memberships (user_id, company_id, role, status)
    VALUES (auth.uid(), inv.company_id, inv.organization_role, 'active')
    ON CONFLICT (user_id, company_id) DO UPDATE
      SET role = EXCLUDED.role, status = 'active', updated_at = NOW();
  END IF;

  condo_ids := ARRAY[]::UUID[];

  IF inv.condominium_ids IS NOT NULL THEN
    SELECT array_agg(value::UUID)
      INTO condo_ids
      FROM jsonb_array_elements_text(inv.condominium_ids) AS value;
  END IF;

  IF inv.condominium_id IS NOT NULL THEN
    condo_ids := array_append(coalesce(condo_ids, ARRAY[]::UUID[]), inv.condominium_id);
  END IF;

  IF condo_ids IS NOT NULL THEN
    FOREACH cid IN ARRAY condo_ids
    LOOP
      INSERT INTO user_condominium_roles (user_id, condominium_id, role, status, invited_by, accepted_at)
      VALUES (
        auth.uid(),
        cid,
        COALESCE(inv.role, 'resident'),
        'active',
        inv.invited_by,
        NOW()
      )
      ON CONFLICT (user_id, condominium_id, role) DO UPDATE
        SET status = 'active', updated_at = NOW();
    END LOOP;
  END IF;

  UPDATE user_invitations SET accepted_at = NOW() WHERE id = inv.id;
END;
$$;

-- ========== 00019_ticket_status_enum_extend.sql ==========
-- Cond Manager - Novos valores do enum ticket_status (transação isolada)
-- Migration: 00019
-- PostgreSQL exige commit antes de usar valores novos do enum (55P04).

ALTER TYPE ticket_status ADD VALUE IF NOT EXISTS 'waiting_material';
ALTER TYPE ticket_status ADD VALUE IF NOT EXISTS 'in_progress';
ALTER TYPE ticket_status ADD VALUE IF NOT EXISTS 'completed';

-- ========== 00020_ticket_work_order_workflow.sql ==========
-- Cond Manager - Fluxo de status chamado + OS (auditoria e métricas)
-- Migration: 00020
-- Depende de 00019 (novos valores de ticket_status já commitados).

-- Migra status legados para o novo fluxo
UPDATE tickets SET status = 'in_analysis' WHERE status = 'waiting_info';
UPDATE tickets SET status = 'in_progress' WHERE status = 'converted_to_os';
UPDATE tickets SET status = 'completed' WHERE status = 'resolved';

ALTER TABLE tickets
  ADD COLUMN IF NOT EXISTS analysis_started_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS problem_accepted_at TIMESTAMPTZ;

CREATE TABLE ticket_status_changes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  from_status ticket_status,
  to_status ticket_status NOT NULL,
  changed_by UUID NOT NULL REFERENCES profiles(id),
  notes TEXT,
  metadata JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ticket_status_changes_ticket ON ticket_status_changes(ticket_id, created_at);

CREATE TABLE ticket_status_durations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  status ticket_status NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  changed_by UUID REFERENCES profiles(id),
  metadata JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX idx_ticket_status_durations_ticket ON ticket_status_durations(ticket_id, status);

CREATE TABLE work_order_status_changes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_order_id UUID NOT NULL REFERENCES work_orders(id) ON DELETE CASCADE,
  from_status work_order_status,
  to_status work_order_status NOT NULL,
  changed_by UUID NOT NULL REFERENCES profiles(id),
  notes TEXT,
  metadata JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_work_order_status_changes_wo ON work_order_status_changes(work_order_id, created_at);

CREATE TABLE work_order_status_durations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_order_id UUID NOT NULL REFERENCES work_orders(id) ON DELETE CASCADE,
  status work_order_status NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  changed_by UUID REFERENCES profiles(id),
  metadata JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX idx_work_order_status_durations_wo ON work_order_status_durations(work_order_id, status);

ALTER TABLE ticket_status_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_status_durations ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_status_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_status_durations ENABLE ROW LEVEL SECURITY;

CREATE POLICY ticket_status_changes_select ON ticket_status_changes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_id AND has_condominium_access(t.condominium_id)
    )
  );

CREATE POLICY ticket_status_changes_insert ON ticket_status_changes FOR INSERT
  WITH CHECK (
    changed_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_id
        AND has_condominium_access(t.condominium_id)
        AND can_manage_condominium(t.condominium_id)
    )
  );

CREATE POLICY ticket_status_durations_select ON ticket_status_durations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_id AND has_condominium_access(t.condominium_id)
    )
  );

CREATE POLICY ticket_status_durations_insert ON ticket_status_durations FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_id
        AND has_condominium_access(t.condominium_id)
        AND can_manage_condominium(t.condominium_id)
    )
  );

CREATE POLICY ticket_status_durations_update ON ticket_status_durations FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_id
        AND has_condominium_access(t.condominium_id)
        AND can_manage_condominium(t.condominium_id)
    )
  );

CREATE POLICY work_order_status_changes_select ON work_order_status_changes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM work_orders w
      WHERE w.id = work_order_id AND has_condominium_access(w.condominium_id)
    )
  );

CREATE POLICY work_order_status_changes_insert ON work_order_status_changes FOR INSERT
  WITH CHECK (
    changed_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM work_orders w
      WHERE w.id = work_order_id
        AND has_condominium_access(w.condominium_id)
        AND can_manage_condominium(w.condominium_id)
    )
  );

CREATE POLICY work_order_status_durations_select ON work_order_status_durations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM work_orders w
      WHERE w.id = work_order_id AND has_condominium_access(w.condominium_id)
    )
  );

CREATE POLICY work_order_status_durations_insert ON work_order_status_durations FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM work_orders w
      WHERE w.id = work_order_id
        AND has_condominium_access(w.condominium_id)
        AND can_manage_condominium(w.condominium_id)
    )
  );

CREATE POLICY work_order_status_durations_update ON work_order_status_durations FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM work_orders w
      WHERE w.id = work_order_id
        AND has_condominium_access(w.condominium_id)
        AND can_manage_condominium(w.condominium_id)
    )
  );

-- ========== 00021_location_type_apartment.sql ==========
-- Migration: 00021 — Local do problema: Apartamento
ALTER TYPE location_type ADD VALUE IF NOT EXISTS 'apartment';

-- ========== 00022_material_supplier_purchase_history.sql ==========
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

-- ========== 00023_work_order_labor_profile_fkey.sql ==========
-- Garante colunas estendidas de mão de obra na OS (caso 00016 não tenha sido aplicada)
-- Migration: 00023

DO $$ BEGIN
  CREATE TYPE labor_source AS ENUM ('third_party', 'internal_team');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE work_order_labor
  ADD COLUMN IF NOT EXISTS labor_source labor_source NOT NULL DEFAULT 'third_party',
  ADD COLUMN IF NOT EXISTS service_type service_type NOT NULL DEFAULT 'other',
  ADD COLUMN IF NOT EXISTS worker_count INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS travel_cost NUMERIC(14, 2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS profile_id UUID;

DO $$ BEGIN
  ALTER TABLE work_order_labor
    ADD CONSTRAINT work_order_labor_profile_id_fkey
    FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE SET NULL;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE work_order_labor
    ADD CONSTRAINT work_order_labor_worker_count_positive CHECK (worker_count >= 1);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE work_order_labor
    ADD CONSTRAINT work_order_labor_travel_nonneg CHECK (travel_cost >= 0);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

COMMENT ON COLUMN work_order_labor.profile_id IS
  'Funcionário interno vinculado (equipe própria); worker_name permanece como rótulo exibido';

-- ========== 00024_work_order_terminal_status_guard.sql ==========
-- OS concluída ou cancelada: alteração de status apenas para admin/gerente
-- Migration: 00024

CREATE OR REPLACE FUNCTION can_override_terminal_work_order_status(p_condominium_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT is_platform_admin()
    OR EXISTS (
      SELECT 1
      FROM condominiums c
      JOIN company_memberships cm ON cm.company_id = c.management_company_id
      WHERE c.id = p_condominium_id
        AND cm.user_id = auth.uid()
        AND cm.status = 'active'
        AND cm.role = 'manager'
    )
    OR get_user_role(p_condominium_id) IN ('condominium_admin', 'maintenance_manager');
$$;

CREATE OR REPLACE FUNCTION enforce_work_order_terminal_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status
     AND OLD.status IN ('completed', 'cancelled')
  THEN
    IF NOT can_override_terminal_work_order_status(NEW.condominium_id) THEN
      RAISE EXCEPTION
        'Apenas administrador ou gerente pode alterar o status de uma OS concluída ou cancelada.'
        USING ERRCODE = '42501';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS work_order_terminal_status_guard ON work_orders;
CREATE TRIGGER work_order_terminal_status_guard
  BEFORE UPDATE ON work_orders
  FOR EACH ROW EXECUTE FUNCTION enforce_work_order_terminal_status_change();

-- ========== 00025_user_access_sessions.sql ==========
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

-- ========== 00026_user_role_assignment_guard.sql ==========
-- Cond Manager - Restrição de cadastro de papéis por perfil
-- Migration: 00026
-- Admin: pode cadastrar todos os papéis, inclusive gerente.
-- Gerente: pode cadastrar analista, equipe de campo e cliente — não gerente nem admin.

CREATE OR REPLACE FUNCTION guard_organization_role_assignment(
  p_target_user_id UUID,
  p_new_role organization_role,
  p_old_role organization_role DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_target_is_admin BOOLEAN;
BEGIN
  IF is_platform_admin() THEN
    RETURN;
  END IF;

  IF NOT can_manage_company_users(get_user_company_id()) THEN
    RAISE EXCEPTION 'Sem permissão para gerenciar usuários.';
  END IF;

  SELECT is_platform_admin
    INTO v_target_is_admin
    FROM profiles
   WHERE id = p_target_user_id;

  IF COALESCE(v_target_is_admin, FALSE) THEN
    RAISE EXCEPTION 'Apenas o administrador pode gerenciar administradores.';
  END IF;

  IF p_old_role = 'manager' THEN
    RAISE EXCEPTION 'Apenas o administrador pode alterar gerentes.';
  END IF;

  IF p_new_role = 'manager' THEN
    RAISE EXCEPTION 'Apenas o administrador pode cadastrar gerentes.';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION trg_guard_company_membership_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM guard_organization_role_assignment(
    NEW.user_id,
    NEW.role,
    CASE WHEN TG_OP = 'UPDATE' THEN OLD.role ELSE NULL END
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS company_memberships_role_guard ON company_memberships;
CREATE TRIGGER company_memberships_role_guard
  BEFORE INSERT OR UPDATE OF role, user_id ON company_memberships
  FOR EACH ROW
  EXECUTE FUNCTION trg_guard_company_membership_role();

CREATE OR REPLACE FUNCTION trg_guard_user_invitation_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.organization_role IS NULL THEN
    RETURN NEW;
  END IF;

  IF is_platform_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.organization_role = 'manager' THEN
    RAISE EXCEPTION 'Apenas o administrador pode convidar gerentes.';
  END IF;

  IF NEW.company_id IS NOT NULL
     AND NOT can_manage_company_users(NEW.company_id) THEN
    RAISE EXCEPTION 'Sem permissão para convidar usuários desta empresa.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS user_invitations_role_guard ON user_invitations;
CREATE TRIGGER user_invitations_role_guard
  BEFORE INSERT OR UPDATE OF organization_role ON user_invitations
  FOR EACH ROW
  EXECUTE FUNCTION trg_guard_user_invitation_role();

-- ========== 00027_access_logs_scope.sql ==========
-- Cond Manager - Escopo do log de acesso: admin vê tudo, gerente só da própria empresa
-- Migration: 00027

CREATE OR REPLACE FUNCTION can_view_access_session(p_company_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    is_platform_admin()
    OR (
      p_company_id IS NOT NULL
      AND p_company_id = get_user_company_id()
      AND get_user_organization_role(p_company_id) = 'manager'
    );
$$;

DROP POLICY IF EXISTS user_access_sessions_select ON user_access_sessions;
CREATE POLICY user_access_sessions_select ON user_access_sessions
  FOR SELECT
  USING (can_view_access_session(company_id));

NOTIFY pgrst, 'reload schema';

-- ========== 00028_app_modules_and_rental.sql ==========
-- Cond Manager - Módulos (Manutenção + Locação) e gestão de aluguéis
-- Migration: 00028

DO $$ BEGIN
  CREATE TYPE app_module AS ENUM ('maintenance', 'rental');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_property_type AS ENUM (
    'room',
    'house',
    'apartment',
    'studio',
    'loft',
    'building',
    'commercial_room',
    'office',
    'warehouse',
    'store',
    'chalet',
    'farm',
    'land',
    'parking_space',
    'hostel_bed',
    'hotel_room',
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_listing_mode AS ENUM (
    'long_term',
    'short_term',
    'seasonal',
    'daily',
    'corporate',
    'vacation_rental'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_lease_status AS ENUM (
    'draft',
    'active',
    'expired',
    'terminated',
    'suspended'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_booking_status AS ENUM (
    'inquiry',
    'reserved',
    'confirmed',
    'checked_in',
    'checked_out',
    'cancelled',
    'no_show'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_charge_type AS ENUM (
    'rent',
    'deposit',
    'fee',
    'utility',
    'cleaning',
    'fine',
    'refund',
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_charge_status AS ENUM (
    'pending',
    'paid',
    'overdue',
    'cancelled',
    'refunded'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE rental_booking_channel AS ENUM (
    'direct',
    'airbnb',
    'booking_com',
    'expedia',
    'decolar',
    'whatsapp',
    'agency',
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Módulos contratados por empresa gestora
CREATE TABLE IF NOT EXISTS company_modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  module app_module NOT NULL,
  status entity_status NOT NULL DEFAULT 'active',
  enabled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(company_id, module)
);

CREATE INDEX IF NOT EXISTS idx_company_modules_company ON company_modules(company_id);

DROP TRIGGER IF EXISTS company_modules_updated_at ON company_modules;
CREATE TRIGGER company_modules_updated_at
  BEFORE UPDATE ON company_modules
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO company_modules (company_id, module, status)
SELECT id, 'maintenance', 'active'
FROM management_companies
ON CONFLICT (company_id, module) DO NOTHING;

CREATE OR REPLACE FUNCTION company_has_module(p_company_id UUID, p_module app_module)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    is_platform_admin()
    OR EXISTS (
      SELECT 1 FROM company_modules cm
      WHERE cm.company_id = p_company_id
        AND cm.module = p_module
        AND cm.status = 'active'
        AND (cm.expires_at IS NULL OR cm.expires_at > NOW())
    );
$$;

CREATE OR REPLACE FUNCTION user_has_module(p_module app_module)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    is_platform_admin()
    OR (
      get_user_company_id() IS NOT NULL
      AND company_has_module(get_user_company_id(), p_module)
    );
$$;

-- Partes (proprietários, inquilinos, hóspedes, fiadores)
CREATE TABLE IF NOT EXISTS rental_parties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  document_type TEXT,
  document_number TEXT,
  address_street TEXT,
  address_number TEXT,
  address_complement TEXT,
  address_neighborhood TEXT,
  address_city TEXT,
  address_state TEXT,
  address_zip TEXT,
  notes TEXT,
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_parties_company ON rental_parties(company_id);
CREATE INDEX IF NOT EXISTS idx_rental_parties_email ON rental_parties(company_id, email);

CREATE TRIGGER rental_parties_updated_at
  BEFORE UPDATE ON rental_parties
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Imóveis / unidades locáveis
CREATE TABLE IF NOT EXISTS rental_properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  condominium_id UUID REFERENCES condominiums(id) ON DELETE SET NULL,
  unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
  owner_party_id UUID REFERENCES rental_parties(id) ON DELETE SET NULL,
  property_type rental_property_type NOT NULL DEFAULT 'apartment',
  listing_mode rental_listing_mode NOT NULL DEFAULT 'long_term',
  code TEXT,
  title TEXT NOT NULL,
  description TEXT,
  address_street TEXT,
  address_number TEXT,
  address_complement TEXT,
  address_neighborhood TEXT,
  address_city TEXT,
  address_state TEXT,
  address_zip TEXT,
  address_country TEXT DEFAULT 'BR',
  latitude NUMERIC(10, 7),
  longitude NUMERIC(10, 7),
  area_sqm NUMERIC(12, 2),
  bedrooms SMALLINT,
  bathrooms SMALLINT,
  parking_spots SMALLINT,
  max_guests SMALLINT,
  floors SMALLINT,
  base_rent_amount NUMERIC(14, 2),
  base_daily_rate NUMERIC(14, 2),
  deposit_amount NUMERIC(14, 2),
  cleaning_fee NUMERIC(14, 2),
  condominium_fee NUMERIC(14, 2),
  iptu_annual NUMERIC(14, 2),
  is_furnished BOOLEAN NOT NULL DEFAULT FALSE,
  allows_pets BOOLEAN NOT NULL DEFAULT FALSE,
  status entity_status NOT NULL DEFAULT 'active',
  settings JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_properties_company ON rental_properties(company_id);
CREATE INDEX IF NOT EXISTS idx_rental_properties_type ON rental_properties(company_id, property_type);
CREATE INDEX IF NOT EXISTS idx_rental_properties_condo ON rental_properties(condominium_id);

CREATE TRIGGER rental_properties_updated_at
  BEFORE UPDATE ON rental_properties
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Subunidades (quartos, salas em prédio, etc.)
CREATE TABLE IF NOT EXISTS rental_units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES rental_properties(id) ON DELETE CASCADE,
  unit_code TEXT,
  name TEXT NOT NULL,
  property_type rental_property_type,
  floor SMALLINT,
  area_sqm NUMERIC(12, 2),
  bedrooms SMALLINT,
  bathrooms SMALLINT,
  max_guests SMALLINT,
  base_monthly_rent NUMERIC(14, 2),
  base_daily_rate NUMERIC(14, 2),
  status entity_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_units_property ON rental_units(property_id);

CREATE TRIGGER rental_units_updated_at
  BEFORE UPDATE ON rental_units
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Contratos de locação (longo prazo)
CREATE TABLE IF NOT EXISTS rental_leases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES rental_properties(id) ON DELETE RESTRICT,
  unit_id UUID REFERENCES rental_units(id) ON DELETE SET NULL,
  primary_tenant_party_id UUID REFERENCES rental_parties(id) ON DELETE SET NULL,
  lease_number TEXT,
  listing_mode rental_listing_mode NOT NULL DEFAULT 'long_term',
  status rental_lease_status NOT NULL DEFAULT 'draft',
  start_date DATE NOT NULL,
  end_date DATE,
  signed_at TIMESTAMPTZ,
  monthly_rent NUMERIC(14, 2) NOT NULL,
  deposit_amount NUMERIC(14, 2),
  due_day_of_month SMALLINT CHECK (due_day_of_month IS NULL OR due_day_of_month BETWEEN 1 AND 28),
  adjustment_index TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_leases_company ON rental_leases(company_id, status);
CREATE INDEX IF NOT EXISTS idx_rental_leases_property ON rental_leases(property_id);

CREATE TRIGGER rental_leases_updated_at
  BEFORE UPDATE ON rental_leases
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS rental_lease_tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lease_id UUID NOT NULL REFERENCES rental_leases(id) ON DELETE CASCADE,
  party_id UUID NOT NULL REFERENCES rental_parties(id) ON DELETE CASCADE,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(lease_id, party_id)
);

-- Reservas (curta temporada / hotel / Airbnb)
CREATE TABLE IF NOT EXISTS rental_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES rental_properties(id) ON DELETE RESTRICT,
  unit_id UUID REFERENCES rental_units(id) ON DELETE SET NULL,
  guest_party_id UUID REFERENCES rental_parties(id) ON DELETE SET NULL,
  booking_number TEXT,
  channel rental_booking_channel NOT NULL DEFAULT 'direct',
  status rental_booking_status NOT NULL DEFAULT 'inquiry',
  guest_name TEXT NOT NULL,
  guest_email TEXT,
  guest_phone TEXT,
  guests_count SMALLINT NOT NULL DEFAULT 1,
  check_in DATE NOT NULL,
  check_out DATE NOT NULL,
  nightly_rate NUMERIC(14, 2),
  total_amount NUMERIC(14, 2),
  paid_amount NUMERIC(14, 2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT rental_bookings_dates_valid CHECK (check_out > check_in)
);

CREATE INDEX IF NOT EXISTS idx_rental_bookings_company ON rental_bookings(company_id, status);
CREATE INDEX IF NOT EXISTS idx_rental_bookings_dates ON rental_bookings(check_in, check_out);

CREATE TRIGGER rental_bookings_updated_at
  BEFORE UPDATE ON rental_bookings
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Cobranças / recebimentos
CREATE TABLE IF NOT EXISTS rental_charges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  lease_id UUID REFERENCES rental_leases(id) ON DELETE SET NULL,
  booking_id UUID REFERENCES rental_bookings(id) ON DELETE SET NULL,
  party_id UUID REFERENCES rental_parties(id) ON DELETE SET NULL,
  charge_type rental_charge_type NOT NULL DEFAULT 'rent',
  status rental_charge_status NOT NULL DEFAULT 'pending',
  description TEXT NOT NULL,
  amount NUMERIC(14, 2) NOT NULL,
  due_date DATE,
  paid_at TIMESTAMPTZ,
  reference_month DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT rental_charges_source CHECK (lease_id IS NOT NULL OR booking_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_rental_charges_company ON rental_charges(company_id, status);
CREATE INDEX IF NOT EXISTS idx_rental_charges_due ON rental_charges(due_date);

CREATE TRIGGER rental_charges_updated_at
  BEFORE UPDATE ON rental_charges
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS
ALTER TABLE company_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_leases ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_lease_tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_charges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS company_modules_select ON company_modules;
CREATE POLICY company_modules_select ON company_modules FOR SELECT
  USING (is_platform_admin() OR has_company_access(company_id));

DROP POLICY IF EXISTS company_modules_modify ON company_modules;
CREATE POLICY company_modules_modify ON company_modules FOR ALL
  USING (is_platform_admin())
  WITH CHECK (is_platform_admin());

DROP POLICY IF EXISTS rental_company_select ON rental_parties;
CREATE POLICY rental_parties_select ON rental_parties FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_parties_modify ON rental_parties;
CREATE POLICY rental_parties_modify ON rental_parties FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_properties_select ON rental_properties;
CREATE POLICY rental_properties_select ON rental_properties FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_properties_modify ON rental_properties;
CREATE POLICY rental_properties_modify ON rental_properties FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_units_select ON rental_units;
CREATE POLICY rental_units_select ON rental_units FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_units_modify ON rental_units;
CREATE POLICY rental_units_modify ON rental_units FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_leases_select ON rental_leases;
CREATE POLICY rental_leases_select ON rental_leases FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_leases_modify ON rental_leases;
CREATE POLICY rental_leases_modify ON rental_leases FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_lease_tenants_select ON rental_lease_tenants;
CREATE POLICY rental_lease_tenants_select ON rental_lease_tenants FOR SELECT
  USING (
    is_platform_admin()
    OR EXISTS (
      SELECT 1 FROM rental_leases l
      WHERE l.id = lease_id
        AND has_company_access(l.company_id)
        AND user_has_module('rental')
    )
  );

DROP POLICY IF EXISTS rental_lease_tenants_modify ON rental_lease_tenants;
CREATE POLICY rental_lease_tenants_modify ON rental_lease_tenants FOR ALL
  USING (
    is_platform_admin()
    OR EXISTS (
      SELECT 1 FROM rental_leases l
      WHERE l.id = lease_id
        AND can_manage_company_users(l.company_id)
        AND user_has_module('rental')
    )
  )
  WITH CHECK (
    is_platform_admin()
    OR EXISTS (
      SELECT 1 FROM rental_leases l
      WHERE l.id = lease_id
        AND can_manage_company_users(l.company_id)
        AND user_has_module('rental')
    )
  );

DROP POLICY IF EXISTS rental_bookings_select ON rental_bookings;
CREATE POLICY rental_bookings_select ON rental_bookings FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_bookings_modify ON rental_bookings;
CREATE POLICY rental_bookings_modify ON rental_bookings FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_charges_select ON rental_charges;
CREATE POLICY rental_charges_select ON rental_charges FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_charges_modify ON rental_charges;
CREATE POLICY rental_charges_modify ON rental_charges FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

NOTIFY pgrst, 'reload schema';

-- ========== 00029_rental_financial_link.sql ==========
-- Vínculo cobrança de locação ↔ financeiro
-- Migration: 00029

ALTER TABLE rental_charges
  ADD COLUMN IF NOT EXISTS financial_record_id UUID REFERENCES financial_records(id) ON DELETE SET NULL;

ALTER TABLE financial_records
  ADD COLUMN IF NOT EXISTS rental_charge_id UUID REFERENCES rental_charges(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_rental_charges_financial ON rental_charges(financial_record_id);
CREATE INDEX IF NOT EXISTS idx_financial_rental_charge ON financial_records(rental_charge_id);

NOTIFY pgrst, 'reload schema';

-- ========== 00030_rental_maintenance_integration.sql ==========
-- Locação + Manutenção: condomínios compartilhados, vínculo imóvel↔chamados/OS, relatório P&L
-- Migration: 00030

-- Acesso organizacional aos condomínios da empresa gestora
CREATE OR REPLACE FUNCTION has_condominium_access(p_condominium_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT condominium_belongs_to_user_company(p_condominium_id);
$$;

CREATE OR REPLACE FUNCTION can_manage_condominium(p_condominium_id UUID)
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
        AND condominium_id = p_condominium_id
        AND status = 'active'
        AND role IN (
          'condominium_admin', 'syndic', 'maintenance_manager', 'caretaker'
        )
    )
    OR EXISTS (
      SELECT 1 FROM condominiums c
      WHERE c.id = p_condominium_id
        AND c.management_company_id IS NOT NULL
        AND is_company_manager(c.management_company_id)
    );
$$;

DROP POLICY IF EXISTS condominiums_insert ON condominiums;
CREATE POLICY condominiums_insert ON condominiums FOR INSERT
  WITH CHECK (
    is_platform_admin()
    OR (
      management_company_id IS NOT NULL
      AND management_company_id = get_user_company_id()
      AND is_company_manager(management_company_id)
    )
  );

-- Vínculo direto imóvel ↔ chamados / ordens de serviço
ALTER TABLE tickets
  ADD COLUMN IF NOT EXISTS rental_property_id UUID
    REFERENCES rental_properties(id) ON DELETE SET NULL;

ALTER TABLE work_orders
  ADD COLUMN IF NOT EXISTS rental_property_id UUID
    REFERENCES rental_properties(id) ON DELETE SET NULL;

ALTER TABLE financial_records
  ADD COLUMN IF NOT EXISTS rental_property_id UUID
    REFERENCES rental_properties(id) ON DELETE SET NULL;

ALTER TABLE rental_charges
  ADD COLUMN IF NOT EXISTS property_id UUID
    REFERENCES rental_properties(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_tickets_rental_property ON tickets(rental_property_id);
CREATE INDEX IF NOT EXISTS idx_work_orders_rental_property ON work_orders(rental_property_id);
CREATE INDEX IF NOT EXISTS idx_financial_rental_property ON financial_records(rental_property_id);
CREATE INDEX IF NOT EXISTS idx_rental_charges_property ON rental_charges(property_id);

-- Backfill property_id em cobranças existentes
UPDATE rental_charges rc
SET property_id = rl.property_id
FROM rental_leases rl
WHERE rc.lease_id = rl.id AND rc.property_id IS NULL;

UPDATE rental_charges rc
SET property_id = rb.property_id
FROM rental_bookings rb
WHERE rc.booking_id = rb.id AND rc.property_id IS NULL;

-- Manter property_id sincronizado
CREATE OR REPLACE FUNCTION sync_rental_charge_property_id()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.property_id IS NULL AND NEW.lease_id IS NOT NULL THEN
    SELECT property_id INTO NEW.property_id FROM rental_leases WHERE id = NEW.lease_id;
  END IF;
  IF NEW.property_id IS NULL AND NEW.booking_id IS NOT NULL THEN
    SELECT property_id INTO NEW.property_id FROM rental_bookings WHERE id = NEW.booking_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS rental_charges_property_sync ON rental_charges;
CREATE TRIGGER rental_charges_property_sync
  BEFORE INSERT OR UPDATE ON rental_charges
  FOR EACH ROW EXECUTE FUNCTION sync_rental_charge_property_id();

-- Relatório receita × custo manutenção por imóvel
CREATE OR REPLACE FUNCTION rental_property_pnl_report(
  p_from DATE DEFAULT NULL,
  p_to DATE DEFAULT NULL
)
RETURNS TABLE (
  property_id UUID,
  property_title TEXT,
  condominium_name TEXT,
  rental_revenue NUMERIC,
  maintenance_cost NUMERIC,
  ticket_count BIGINT,
  work_order_count BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    rp.id AS property_id,
    rp.title AS property_title,
    c.name AS condominium_name,
    COALESCE(rev.total, 0) AS rental_revenue,
    COALESCE(cost.total, 0) AS maintenance_cost,
    COALESCE(tk.cnt, 0) AS ticket_count,
    COALESCE(wo.cnt, 0) AS work_order_count
  FROM rental_properties rp
  LEFT JOIN condominiums c ON c.id = rp.condominium_id
  LEFT JOIN LATERAL (
    SELECT SUM(rc.amount) AS total
    FROM rental_charges rc
    WHERE rc.property_id = rp.id
      AND rc.status = 'paid'
      AND (p_from IS NULL OR COALESCE(rc.paid_at::date, rc.due_date) >= p_from)
      AND (p_to IS NULL OR COALESCE(rc.paid_at::date, rc.due_date) <= p_to)
  ) rev ON TRUE
  LEFT JOIN LATERAL (
    SELECT SUM(wo2.actual_cost) AS total
    FROM work_orders wo2
    WHERE wo2.rental_property_id = rp.id
      AND wo2.status IN ('completed', 'closed')
      AND (p_from IS NULL OR COALESCE(wo2.completed_at::date, wo2.closed_at::date, wo2.created_at::date) >= p_from)
      AND (p_to IS NULL OR COALESCE(wo2.completed_at::date, wo2.closed_at::date, wo2.created_at::date) <= p_to)
  ) cost ON TRUE
  LEFT JOIN LATERAL (
    SELECT COUNT(*) AS cnt FROM tickets t
    WHERE t.rental_property_id = rp.id
      AND (p_from IS NULL OR t.created_at::date >= p_from)
      AND (p_to IS NULL OR t.created_at::date <= p_to)
  ) tk ON TRUE
  LEFT JOIN LATERAL (
    SELECT COUNT(*) AS cnt FROM work_orders wo3
    WHERE wo3.rental_property_id = rp.id
      AND (p_from IS NULL OR wo3.created_at::date >= p_from)
      AND (p_to IS NULL OR wo3.created_at::date <= p_to)
  ) wo ON TRUE
  WHERE (
    is_platform_admin()
    OR (
      get_user_company_id() IS NOT NULL
      AND rp.company_id = get_user_company_id()
      AND user_has_module('rental')
    )
  )
  ORDER BY rp.title;
$$;

GRANT EXECUTE ON FUNCTION rental_property_pnl_report(DATE, DATE) TO authenticated;

NOTIFY pgrst, 'reload schema';

-- ========== 00031_rental_party_category.sql ==========
-- Categoria de pessoas no módulo Locação (locador, locatário, inquilino, hóspede)
-- Migration: 00031

DO $$ BEGIN
  CREATE TYPE rental_party_category AS ENUM (
    'landlord',
    'tenant',
    'occupant',
    'guest'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE rental_parties
  ADD COLUMN IF NOT EXISTS category rental_party_category NOT NULL DEFAULT 'tenant';

CREATE INDEX IF NOT EXISTS idx_rental_parties_category
  ON rental_parties(company_id, category);

-- ========== 00032_rental_property_address_details.sql ==========
-- Detalhes de endereço para imóveis (edifício, bloco/torre, apartamento)
-- Migration: 00032

ALTER TABLE rental_properties
  ADD COLUMN IF NOT EXISTS address_building TEXT,
  ADD COLUMN IF NOT EXISTS address_block TEXT,
  ADD COLUMN IF NOT EXISTS address_apartment TEXT;

-- ========== 00033_rental_property_inclusions.sql ==========
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

-- ========== 00034_rental_property_photos.sql ==========
-- Fotos de imóveis (locação) + bucket de storage
-- Migration: 00034

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'rental-properties',
  'rental-properties',
  false,
  20971520,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS rental_property_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES management_companies(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES rental_properties(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_name TEXT,
  mime_type TEXT,
  sort_order SMALLINT NOT NULL DEFAULT 0,
  uploaded_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rental_property_photos_property
  ON rental_property_photos(property_id, sort_order);

ALTER TABLE rental_property_photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS rental_property_photos_select ON rental_property_photos;
CREATE POLICY rental_property_photos_select ON rental_property_photos FOR SELECT
  USING (is_platform_admin() OR (has_company_access(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS rental_property_photos_modify ON rental_property_photos;
CREATE POLICY rental_property_photos_modify ON rental_property_photos FOR ALL
  USING (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')))
  WITH CHECK (is_platform_admin() OR (can_manage_company_users(company_id) AND user_has_module('rental')));

DROP POLICY IF EXISTS storage_rental_properties ON storage.objects;
CREATE POLICY storage_rental_properties ON storage.objects FOR ALL
  USING (
    bucket_id = 'rental-properties'
    AND (
      is_platform_admin()
      OR (
        has_company_access((storage.foldername(name))[1]::UUID)
        AND user_has_module('rental')
      )
    )
  )
  WITH CHECK (
    bucket_id = 'rental-properties'
    AND (
      is_platform_admin()
      OR (
        has_company_access((storage.foldername(name))[1]::UUID)
        AND user_has_module('rental')
      )
    )
  );

-- ========== 00035_rental_inclusion_catalog.sql ==========
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

-- ========== 00036_rental_booking_fixed_rent.sql ==========
-- Aluguel fixo mensal em reservas (com dia de vencimento)
-- Migration: 00036

ALTER TABLE rental_bookings
  ADD COLUMN IF NOT EXISTS is_fixed_rent BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS monthly_rent NUMERIC(14, 2),
  ADD COLUMN IF NOT EXISTS payment_due_day SMALLINT;

ALTER TABLE rental_bookings
  DROP CONSTRAINT IF EXISTS rental_bookings_payment_due_day_valid;

ALTER TABLE rental_bookings
  ADD CONSTRAINT rental_bookings_payment_due_day_valid
  CHECK (payment_due_day IS NULL OR (payment_due_day >= 1 AND payment_due_day <= 28));

NOTIFY pgrst, 'reload schema';

-- ========== 00037_seed_praia_itaparica_rentals.sql ==========
-- Carga inicial: imóveis, inquilinos e reservas (aluguel fixo) — Condomínio Praia de Itaparica
-- Migration: 00037
--
-- Pré-requisitos:
--   1. Condomínio "Praia de Itaparica" já cadastrado (ajuste o filtro em v_condo_name se o nome for diferente).
--   2. Empresa gestora com módulo locação ativo.
--   3. Migration 00036 aplicada (is_fixed_rent, monthly_rent, payment_due_day em rental_bookings).
--
-- Período: alugado de 01/01/2026 a 31/12/2026 (check_out exclusivo em 01/01/2027).
-- Locador de todos os imóveis: Monica Gomes (categoria landlord em rental_parties).

DO $$
DECLARE
  v_company_id UUID;
  v_condo_id UUID;
  v_landlord_id UUID;
  v_landlord_name TEXT := 'Monica Gomes';
BEGIN
  SELECT id INTO v_company_id
  FROM management_companies
  ORDER BY created_at
  LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Nenhuma empresa gestora encontrada. Cadastre uma management_company antes.';
  END IF;

  SELECT id INTO v_condo_id
  FROM condominiums
  WHERE name ILIKE '%praia%itaparica%'
  ORDER BY created_at
  LIMIT 1;

  IF v_condo_id IS NULL THEN
    RAISE EXCEPTION 'Condomínio "Praia de Itaparica" não encontrado. Cadastre-o antes de rodar esta migration.';
  END IF;

  CREATE TEMP TABLE _itaparica_rows (
    apto TEXT PRIMARY KEY,
    tenant_name TEXT,
    due_day SMALLINT,
    monthly_rent NUMERIC(14, 2)
  ) ON COMMIT DROP;

  INSERT INTO _itaparica_rows (apto, tenant_name, due_day, monthly_rent) VALUES
    ('102', 'SILVANA', 9, 830.00),
    ('103', 'ELIAS', 8, 830.00),
    ('104', 'ESTER', 6, 1250.00),
    ('105', NULL, NULL, NULL),
    ('106', 'EDIMAR', 16, 830.00),
    ('107', 'THIAGO', 25, 730.00),
    ('108', 'JÚLIA', 16, 830.00),
    ('109', 'HAROLDO', 15, 830.00),
    ('110', 'EDUARDO', 6, 830.00),
    ('111', 'GEOVANE', 17, 830.00),
    ('112', 'ELIANE', 15, 830.00),
    ('113', 'ALEXANDER', 25, 1400.00),
    ('114', 'JOSÉ LÚCIO', 7, 1350.00),
    ('115', 'PAULO', 19, 1400.00),
    ('116', 'CARIOCA', 14, 1400.00),
    ('117', 'ANTÔNIO', 1, 1400.00),
    ('118', 'SIRLENE', 12, 1400.00),
    ('119', 'ROBSON', 3, 1400.00),
    ('120', 'ERIC', 13, 1400.00),
    ('121', 'RODRIGO', 17, 1400.00),
    ('122', 'RICARDO', 1, 1400.00),
    ('123', 'LAURA', 4, 1400.00),
    ('124', 'GABRIEL', 1, 1250.00),
    ('125', 'AILTON', 28, 830.00),   -- planilha: 31.03 → dia 28 (limite do sistema)
    ('126', 'JUAN LUCAS', 2, 830.00),
    ('127', 'DANILO', 10, 830.00),
    ('128', 'FERNADO', 16, 830.00),
    ('129', 'MARCELO PAIOL', NULL, NULL),
    ('130', 'SCARLAT', 16, 830.00),
    ('131', 'ROSA', 8, 830.00),
    ('132', 'ROBERTO', 10, 830.00),
    ('133', 'FLAVIANO', 2, 830.00),
    ('134', 'CLÁUDIO', 5, 830.00),
    ('QUARTINHO', 'FABRÍCIO', 5, 500.00);

  -- Locador(a) de todos os imóveis
  INSERT INTO rental_parties (company_id, full_name, category, status)
  SELECT v_company_id, v_landlord_name, 'landlord'::rental_party_category, 'active'::entity_status
  WHERE NOT EXISTS (
    SELECT 1
    FROM rental_parties p
    WHERE p.company_id = v_company_id
      AND p.full_name = v_landlord_name
      AND p.category = 'landlord'::rental_party_category
  );

  SELECT id INTO v_landlord_id
  FROM rental_parties
  WHERE company_id = v_company_id
    AND full_name = v_landlord_name
    AND category = 'landlord'::rental_party_category
  LIMIT 1;

  IF v_landlord_id IS NULL THEN
    RAISE EXCEPTION 'Não foi possível cadastrar ou localizar o locador %.', v_landlord_name;
  END IF;

  -- Imóveis
  INSERT INTO rental_properties (
    company_id,
    condominium_id,
    owner_party_id,
    property_type,
    listing_mode,
    code,
    title,
    address_apartment,
    base_rent_amount,
    status
  )
  SELECT
    v_company_id,
    v_condo_id,
    v_landlord_id,
    'apartment'::rental_property_type,
    'long_term'::rental_listing_mode,
    'ITAP-' || r.apto,
    CASE
      WHEN r.apto ~ '^[0-9]+$' THEN 'Apto ' || r.apto
      ELSE r.apto
    END,
    r.apto,
    r.monthly_rent,
    'active'::entity_status
  FROM _itaparica_rows r
  WHERE NOT EXISTS (
    SELECT 1
    FROM rental_properties p
    WHERE p.company_id = v_company_id
      AND p.code = 'ITAP-' || r.apto
  );

  -- Garante locador nos imóveis já existentes (reexecução idempotente)
  UPDATE rental_properties p
  SET owner_party_id = v_landlord_id,
      updated_at = NOW()
  WHERE p.company_id = v_company_id
    AND p.code LIKE 'ITAP-%'
    AND p.condominium_id = v_condo_id
    AND (p.owner_party_id IS NULL OR p.owner_party_id IS DISTINCT FROM v_landlord_id);

  -- Inquilinos / locatários
  INSERT INTO rental_parties (company_id, full_name, category, status)
  SELECT DISTINCT
    v_company_id,
    r.tenant_name,
    'tenant'::rental_party_category,
    'active'::entity_status
  FROM _itaparica_rows r
  WHERE r.tenant_name IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM rental_parties p
      WHERE p.company_id = v_company_id
        AND p.full_name = r.tenant_name
        AND p.category = 'tenant'::rental_party_category
    );

  -- Reservas com aluguel fixo (jan–dez/2026)
  INSERT INTO rental_bookings (
    company_id,
    property_id,
    guest_party_id,
    channel,
    status,
    guest_name,
    guests_count,
    check_in,
    check_out,
    is_fixed_rent,
    monthly_rent,
    payment_due_day,
    total_amount,
    notes
  )
  SELECT
    v_company_id,
    p.id,
    party.id,
    'direct'::rental_booking_channel,
    'confirmed'::rental_booking_status,
    r.tenant_name,
    1,
    DATE '2026-01-01',
    DATE '2027-01-01',
    TRUE,
    r.monthly_rent,
    r.due_day,
    r.monthly_rent,
    'Importado da planilha Praia de Itaparica (00037).'
  FROM _itaparica_rows r
  JOIN rental_properties p
    ON p.company_id = v_company_id
   AND p.code = 'ITAP-' || r.apto
  LEFT JOIN rental_parties party
    ON party.company_id = v_company_id
   AND party.full_name = r.tenant_name
   AND party.category = 'tenant'::rental_party_category
  WHERE r.tenant_name IS NOT NULL
    AND r.monthly_rent IS NOT NULL
    AND r.due_day IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM rental_bookings b
      WHERE b.property_id = p.id
        AND b.check_in = DATE '2026-01-01'
        AND b.check_out = DATE '2027-01-01'
        AND b.status <> 'cancelled'::rental_booking_status
    );

  RAISE NOTICE 'Carga Praia de Itaparica concluída para empresa % e condomínio %.', v_company_id, v_condo_id;
END $$;

NOTIFY pgrst, 'reload schema';

-- ========== 00038_restore_itaparica_apts_102_105.sql ==========
-- Restaura imóveis ITAP-102, ITAP-103, ITAP-104 e ITAP-105 (Praia de Itaparica)
-- Migration: 00038

DO $$
DECLARE
  v_company_id UUID;
  v_condo_id UUID;
  v_landlord_id UUID;
  v_landlord_name TEXT := 'Monica Gomes';
BEGIN
  SELECT id INTO v_company_id
  FROM management_companies
  ORDER BY created_at
  LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Nenhuma empresa gestora encontrada.';
  END IF;

  SELECT id INTO v_condo_id
  FROM condominiums
  WHERE name ILIKE '%praia%itaparica%'
  ORDER BY created_at
  LIMIT 1;

  IF v_condo_id IS NULL THEN
    RAISE EXCEPTION 'Condomínio "Praia de Itaparica" não encontrado.';
  END IF;

  SELECT id INTO v_landlord_id
  FROM rental_parties
  WHERE company_id = v_company_id
    AND full_name = v_landlord_name
    AND category = 'landlord'::rental_party_category
  LIMIT 1;

  IF v_landlord_id IS NULL THEN
    INSERT INTO rental_parties (company_id, full_name, category, status)
    VALUES (v_company_id, v_landlord_name, 'landlord'::rental_party_category, 'active'::entity_status)
    RETURNING id INTO v_landlord_id;
  END IF;

  CREATE TEMP TABLE _restore_rows (
    apto TEXT PRIMARY KEY,
    tenant_name TEXT,
    due_day SMALLINT,
    monthly_rent NUMERIC(14, 2)
  ) ON COMMIT DROP;

  INSERT INTO _restore_rows (apto, tenant_name, due_day, monthly_rent) VALUES
    ('102', 'SILVANA', 9, 830.00),
    ('103', 'ELIAS', 8, 830.00),
    ('104', 'ESTER', 6, 1250.00),
    ('105', NULL, NULL, NULL);

  INSERT INTO rental_properties (
    company_id,
    condominium_id,
    owner_party_id,
    property_type,
    listing_mode,
    code,
    title,
    address_apartment,
    base_rent_amount,
    status
  )
  SELECT
    v_company_id,
    v_condo_id,
    v_landlord_id,
    'apartment'::rental_property_type,
    'long_term'::rental_listing_mode,
    'ITAP-' || r.apto,
    'Apto ' || r.apto,
    r.apto,
    r.monthly_rent,
    'active'::entity_status
  FROM _restore_rows r
  WHERE NOT EXISTS (
    SELECT 1
    FROM rental_properties p
    WHERE p.company_id = v_company_id
      AND p.code = 'ITAP-' || r.apto
  );

  INSERT INTO rental_parties (company_id, full_name, category, status)
  SELECT DISTINCT
    v_company_id,
    r.tenant_name,
    'tenant'::rental_party_category,
    'active'::entity_status
  FROM _restore_rows r
  WHERE r.tenant_name IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM rental_parties p
      WHERE p.company_id = v_company_id
        AND p.full_name = r.tenant_name
        AND p.category = 'tenant'::rental_party_category
    );

  INSERT INTO rental_bookings (
    company_id,
    property_id,
    guest_party_id,
    channel,
    status,
    guest_name,
    guests_count,
    check_in,
    check_out,
    is_fixed_rent,
    monthly_rent,
    payment_due_day,
    total_amount,
    notes
  )
  SELECT
    v_company_id,
    p.id,
    party.id,
    'direct'::rental_booking_channel,
    'confirmed'::rental_booking_status,
    r.tenant_name,
    1,
    DATE '2026-01-01',
    DATE '2027-01-01',
    TRUE,
    r.monthly_rent,
    r.due_day,
    r.monthly_rent,
    'Restaurado via migration 00038.'
  FROM _restore_rows r
  JOIN rental_properties p
    ON p.company_id = v_company_id
   AND p.code = 'ITAP-' || r.apto
  LEFT JOIN rental_parties party
    ON party.company_id = v_company_id
   AND party.full_name = r.tenant_name
   AND party.category = 'tenant'::rental_party_category
  WHERE r.tenant_name IS NOT NULL
    AND r.monthly_rent IS NOT NULL
    AND r.due_day IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM rental_bookings b
      WHERE b.property_id = p.id
        AND b.check_in = DATE '2026-01-01'
        AND b.check_out = DATE '2027-01-01'
        AND b.status <> 'cancelled'::rental_booking_status
    );

  RAISE NOTICE 'Imóveis ITAP-102 a ITAP-105 restaurados (locador: %).', v_landlord_name;
END $$;

NOTIFY pgrst, 'reload schema';

-- ========== 00039_itaparica_lease_contracts.sql ==========
-- Contratos de locação (longo prazo) para inquilinos da planilha Praia de Itaparica
-- Migration: 00039
--
-- Cria rental_leases jan–dez/2026 para cada imóvel ITAP-* com inquilino, aluguel e dia de vencimento.
-- Idempotente: não duplica contrato ativo no mesmo período para o mesmo imóvel.

DO $$
DECLARE
  v_company_id UUID;
  v_condo_id UUID;
BEGIN
  SELECT id INTO v_company_id
  FROM management_companies
  ORDER BY created_at
  LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Nenhuma empresa gestora encontrada.';
  END IF;

  SELECT id INTO v_condo_id
  FROM condominiums
  WHERE name ILIKE '%praia%itaparica%'
  ORDER BY created_at
  LIMIT 1;

  IF v_condo_id IS NULL THEN
    RAISE EXCEPTION 'Condomínio "Praia de Itaparica" não encontrado.';
  END IF;

  CREATE TEMP TABLE _lease_rows (
    apto TEXT PRIMARY KEY,
    tenant_name TEXT NOT NULL,
    due_day SMALLINT NOT NULL,
    monthly_rent NUMERIC(14, 2) NOT NULL
  ) ON COMMIT DROP;

  INSERT INTO _lease_rows (apto, tenant_name, due_day, monthly_rent) VALUES
    ('102', 'SILVANA', 9, 830.00),
    ('103', 'ELIAS', 8, 830.00),
    ('104', 'ESTER', 6, 1250.00),
    ('106', 'EDIMAR', 16, 830.00),
    ('107', 'THIAGO', 25, 730.00),
    ('108', 'JÚLIA', 16, 830.00),
    ('109', 'HAROLDO', 15, 830.00),
    ('110', 'EDUARDO', 6, 830.00),
    ('111', 'GEOVANE', 17, 830.00),
    ('112', 'ELIANE', 15, 830.00),
    ('113', 'ALEXANDER', 25, 1400.00),
    ('114', 'JOSÉ LÚCIO', 7, 1350.00),
    ('115', 'PAULO', 19, 1400.00),
    ('116', 'CARIOCA', 14, 1400.00),
    ('117', 'ANTÔNIO', 1, 1400.00),
    ('118', 'SIRLENE', 12, 1400.00),
    ('119', 'ROBSON', 3, 1400.00),
    ('120', 'ERIC', 13, 1400.00),
    ('121', 'RODRIGO', 17, 1400.00),
    ('122', 'RICARDO', 1, 1400.00),
    ('123', 'LAURA', 4, 1400.00),
    ('124', 'GABRIEL', 1, 1250.00),
    ('125', 'AILTON', 28, 830.00),
    ('126', 'JUAN LUCAS', 2, 830.00),
    ('127', 'DANILO', 10, 830.00),
    ('128', 'FERNADO', 16, 830.00),
    ('130', 'SCARLAT', 16, 830.00),
    ('131', 'ROSA', 8, 830.00),
    ('132', 'ROBERTO', 10, 830.00),
    ('133', 'FLAVIANO', 2, 830.00),
    ('134', 'CLÁUDIO', 5, 830.00),
    ('QUARTINHO', 'FABRÍCIO', 5, 500.00);

  WITH inserted_leases AS (
    INSERT INTO rental_leases (
      company_id,
      property_id,
      primary_tenant_party_id,
      lease_number,
      listing_mode,
      status,
      start_date,
      end_date,
      monthly_rent,
      due_day_of_month,
      notes
    )
    SELECT
      v_company_id,
      p.id,
      party.id,
      'ITAP-' || r.apto || '-2026',
      'long_term'::rental_listing_mode,
      'active'::rental_lease_status,
      DATE '2026-01-01',
      DATE '2026-12-31',
      r.monthly_rent,
      r.due_day,
      'Contrato importado da planilha Praia de Itaparica (00039).'
    FROM _lease_rows r
    JOIN rental_properties p
      ON p.company_id = v_company_id
     AND p.condominium_id = v_condo_id
     AND p.code = 'ITAP-' || r.apto
    JOIN rental_parties party
      ON party.company_id = v_company_id
     AND party.category = 'tenant'::rental_party_category
     AND (
       upper(trim(party.full_name)) = upper(trim(r.tenant_name))
       OR party.id IN (
         SELECT b.guest_party_id
         FROM rental_bookings b
         WHERE b.property_id = p.id
           AND b.check_in = DATE '2026-01-01'
           AND b.status <> 'cancelled'::rental_booking_status
           AND b.guest_party_id IS NOT NULL
       )
     )
    WHERE NOT EXISTS (
      SELECT 1
      FROM rental_leases l
      WHERE l.property_id = p.id
        AND l.status = 'active'::rental_lease_status
        AND l.start_date <= DATE '2026-12-31'
        AND (l.end_date IS NULL OR l.end_date >= DATE '2026-01-01')
    )
    RETURNING id, primary_tenant_party_id
  )
  INSERT INTO rental_lease_tenants (lease_id, party_id, is_primary)
  SELECT il.id, il.primary_tenant_party_id, TRUE
  FROM inserted_leases il
  WHERE il.primary_tenant_party_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM rental_lease_tenants lt
      WHERE lt.lease_id = il.id
        AND lt.party_id = il.primary_tenant_party_id
    );

  RAISE NOTICE 'Contratos Praia de Itaparica criados (empresa %, condomínio %).', v_company_id, v_condo_id;
END $$;

NOTIFY pgrst, 'reload schema';

-- ========== 00040_repair_missing_itaparica_leases.sql ==========
-- Repara contratos ITAP faltantes usando reservas já cadastradas (match por imóvel, não por nome exato)
-- Migration: 00040

DO $$
BEGIN
  WITH src AS (
    SELECT DISTINCT ON (p.id)
      b.company_id,
      p.id AS property_id,
      COALESCE(b.guest_party_id, party_by_name.id) AS tenant_party_id,
      p.code,
      COALESCE(b.monthly_rent, p.base_rent_amount) AS monthly_rent,
      b.payment_due_day AS due_day,
      b.guest_name
    FROM rental_properties p
    JOIN rental_bookings b
      ON b.property_id = p.id
     AND b.check_in = DATE '2026-01-01'
     AND b.check_out = DATE '2027-01-01'
     AND b.status <> 'cancelled'::rental_booking_status
    LEFT JOIN rental_parties party_by_name
      ON party_by_name.company_id = b.company_id
     AND party_by_name.category = 'tenant'::rental_party_category
     AND upper(trim(party_by_name.full_name)) = upper(trim(b.guest_name))
    WHERE p.code LIKE 'ITAP-%'
      AND COALESCE(b.is_fixed_rent, FALSE) = TRUE
    ORDER BY p.id, b.created_at DESC
  ),
  inserted_leases AS (
    INSERT INTO rental_leases (
      company_id,
      property_id,
      primary_tenant_party_id,
      lease_number,
      listing_mode,
      status,
      start_date,
      end_date,
      monthly_rent,
      due_day_of_month,
      notes
    )
    SELECT
      s.company_id,
      s.property_id,
      s.tenant_party_id,
      s.code || '-2026',
      'long_term'::rental_listing_mode,
      'active'::rental_lease_status,
      DATE '2026-01-01',
      DATE '2026-12-31',
      s.monthly_rent,
      s.due_day,
      'Contrato reparado a partir da reserva (00040).'
    FROM src s
    WHERE s.monthly_rent IS NOT NULL
      AND s.due_day IS NOT NULL
      AND NOT EXISTS (
        SELECT 1
        FROM rental_leases l
        WHERE l.property_id = s.property_id
          AND l.status = 'active'::rental_lease_status
          AND l.start_date <= DATE '2026-12-31'
          AND (l.end_date IS NULL OR l.end_date >= DATE '2026-01-01')
      )
    RETURNING id, primary_tenant_party_id
  )
  INSERT INTO rental_lease_tenants (lease_id, party_id, is_primary)
  SELECT il.id, il.primary_tenant_party_id, TRUE
  FROM inserted_leases il
  WHERE il.primary_tenant_party_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM rental_lease_tenants lt
      WHERE lt.lease_id = il.id
        AND lt.party_id = il.primary_tenant_party_id
    );

  RAISE NOTICE 'Contratos ITAP reparados (00040).';
END $$;

NOTIFY pgrst, 'reload schema';

-- ========== 00041_rental_party_restrictions.sql ==========
-- Restrições de locação em pessoas e motivo de encerramento em contratos

ALTER TABLE rental_parties
  ADD COLUMN IF NOT EXISTS is_rental_restricted BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS restriction_reason TEXT,
  ADD COLUMN IF NOT EXISTS restricted_at TIMESTAMPTZ;

ALTER TABLE rental_leases
  ADD COLUMN IF NOT EXISTS termination_reason TEXT;

CREATE INDEX IF NOT EXISTS idx_rental_parties_company_document
  ON rental_parties(company_id, document_number)
  WHERE document_number IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_rental_parties_company_phone
  ON rental_parties(company_id, phone)
  WHERE phone IS NOT NULL;

-- ========== 00042_rental_tenant_intake_forms.sql ==========
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

-- ========== 00043_fix_intake_gen_random_bytes.sql ==========
-- Corrige dependência de pgcrypto (gen_random_bytes) no formulário público de locatário.
-- Supabase/Postgres pode não expor gen_random_bytes no search_path das RPCs.

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION _rental_intake_protocol()
RETURNS TEXT
LANGUAGE sql
AS $$
  SELECT 'RIT-' || to_char(NOW(), 'YYYYMMDD') || '-' ||
         upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
$$;

ALTER TABLE rental_tenant_intake_links
  ALTER COLUMN token SET DEFAULT replace(gen_random_uuid()::text, '-', '');

NOTIFY pgrst, 'reload schema';

-- ========== 00044_rental_lease_contract_terms.sql ==========
-- Termos contratuais adicionais para geração de PDF e gestão do contrato.
-- adjustment_index já existe em rental_leases (00028).

ALTER TABLE rental_leases
  ADD COLUMN IF NOT EXISTS adjustment_period_months SMALLINT,
  ADD COLUMN IF NOT EXISTS guarantee_type TEXT,
  ADD COLUMN IF NOT EXISTS guarantee_other_description TEXT,
  ADD COLUMN IF NOT EXISTS payment_method TEXT,
  ADD COLUMN IF NOT EXISTS pix_key TEXT,
  ADD COLUMN IF NOT EXISTS bank_name TEXT,
  ADD COLUMN IF NOT EXISTS bank_agency TEXT,
  ADD COLUMN IF NOT EXISTS bank_account TEXT,
  ADD COLUMN IF NOT EXISTS bank_account_type TEXT,
  ADD COLUMN IF NOT EXISTS bank_holder TEXT,
  ADD COLUMN IF NOT EXISTS bank_holder_document TEXT,
  ADD COLUMN IF NOT EXISTS late_fee_percent NUMERIC(5, 2),
  ADD COLUMN IF NOT EXISTS interest_percent NUMERIC(5, 2),
  ADD COLUMN IF NOT EXISTS termination_penalty_months SMALLINT,
  ADD COLUMN IF NOT EXISTS inspection_objection_days SMALLINT,
  ADD COLUMN IF NOT EXISTS key_delivery_method TEXT,
  ADD COLUMN IF NOT EXISTS max_occupants SMALLINT,
  ADD COLUMN IF NOT EXISTS allows_pets BOOLEAN,
  ADD COLUMN IF NOT EXISTS pets_description TEXT,
  ADD COLUMN IF NOT EXISTS cancellation_policy TEXT,
  ADD COLUMN IF NOT EXISTS season_total_amount NUMERIC(14, 2),
  ADD COLUMN IF NOT EXISTS tenant_charges TEXT,
  ADD COLUMN IF NOT EXISTS landlord_charges TEXT,
  ADD COLUMN IF NOT EXISTS witness_1_name TEXT,
  ADD COLUMN IF NOT EXISTS witness_1_cpf TEXT,
  ADD COLUMN IF NOT EXISTS witness_2_name TEXT,
  ADD COLUMN IF NOT EXISTS witness_2_cpf TEXT;

-- ========== 00045_rental_property_landlord_profile.sql ==========
-- Dados cadastrais do imóvel e do locador para contratos.

ALTER TABLE rental_properties
  ADD COLUMN IF NOT EXISTS registry_matricula TEXT,
  ADD COLUMN IF NOT EXISTS registry_cartorio TEXT,
  ADD COLUMN IF NOT EXISTS iptu_inscription TEXT,
  ADD COLUMN IF NOT EXISTS municipal_inscription TEXT,
  ADD COLUMN IF NOT EXISTS is_furnished BOOLEAN,
  ADD COLUMN IF NOT EXISTS accepts_pets BOOLEAN;

ALTER TABLE rental_parties
  ADD COLUMN IF NOT EXISTS nationality TEXT,
  ADD COLUMN IF NOT EXISTS rg_number TEXT,
  ADD COLUMN IF NOT EXISTS rg_issuer TEXT,
  ADD COLUMN IF NOT EXISTS profession TEXT,
  ADD COLUMN IF NOT EXISTS marital_status TEXT;

-- ========== 00046_rental_monthly_charge_generation.sql ==========
-- Gera cobranças de aluguel mensais ao atingir a data de vencimento.
-- Pode ser chamada pelo app (RPC) ou por job agendado (pg_cron).

CREATE UNIQUE INDEX IF NOT EXISTS idx_rental_charges_lease_ref_month
  ON rental_charges (lease_id, reference_month)
  WHERE lease_id IS NOT NULL
    AND charge_type = 'rent'
    AND status <> 'cancelled'
    AND reference_month IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_rental_charges_booking_ref_month
  ON rental_charges (booking_id, reference_month)
  WHERE booking_id IS NOT NULL
    AND charge_type = 'rent'
    AND status <> 'cancelled'
    AND reference_month IS NOT NULL;

CREATE OR REPLACE FUNCTION rental_month_due_date(p_ref_month DATE, p_due_day SMALLINT)
RETURNS DATE
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT make_date(
    EXTRACT(YEAR FROM p_ref_month)::INT,
    EXTRACT(MONTH FROM p_ref_month)::INT,
    LEAST(
      p_due_day,
      EXTRACT(
        DAY FROM (DATE_TRUNC('month', p_ref_month) + INTERVAL '1 month - 1 day')
      )::INT
    )
  );
$$;

CREATE OR REPLACE FUNCTION generate_rental_monthly_charges(p_as_of DATE DEFAULT CURRENT_DATE)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ref_month DATE := DATE_TRUNC('month', p_as_of)::DATE;
  v_created INTEGER := 0;
  v_row RECORD;
  v_due_date DATE;
BEGIN
  -- Contratos ativos com dia de vencimento configurado.
  FOR v_row IN
    SELECT
      rl.id AS lease_id,
      rl.company_id,
      rl.property_id,
      rl.primary_tenant_party_id AS party_id,
      rl.monthly_rent,
      rl.due_day_of_month,
      rl.start_date,
      rl.end_date,
      rp.title AS property_title
    FROM rental_leases rl
    JOIN rental_properties rp ON rp.id = rl.property_id
    WHERE rl.status = 'active'
      AND rl.due_day_of_month IS NOT NULL
      AND rl.monthly_rent > 0
      AND rl.start_date <= p_as_of
      AND (rl.end_date IS NULL OR rl.end_date >= v_ref_month)
  LOOP
    v_due_date := rental_month_due_date(v_ref_month, v_row.due_day_of_month);

    IF p_as_of < v_due_date THEN
      CONTINUE;
    END IF;

    IF v_row.start_date > v_due_date THEN
      CONTINUE;
    END IF;

    IF EXISTS (
      SELECT 1
      FROM rental_charges rc
      WHERE rc.lease_id = v_row.lease_id
        AND rc.charge_type = 'rent'
        AND rc.status <> 'cancelled'
        AND (
          rc.reference_month = v_ref_month
          OR (
            rc.reference_month IS NULL
            AND rc.due_date >= v_ref_month
            AND rc.due_date < (v_ref_month + INTERVAL '1 month')::DATE
          )
        )
    ) THEN
      CONTINUE;
    END IF;

    INSERT INTO rental_charges (
      company_id,
      lease_id,
      party_id,
      property_id,
      charge_type,
      status,
      description,
      amount,
      due_date,
      reference_month,
      notes
    ) VALUES (
      v_row.company_id,
      v_row.lease_id,
      v_row.party_id,
      v_row.property_id,
      'rent',
      'pending',
      'Aluguel — ' || v_row.property_title || ' — ' ||
        TO_CHAR(v_ref_month, 'MM/YYYY'),
      v_row.monthly_rent,
      v_due_date,
      v_ref_month,
      'Gerado automaticamente na data de vencimento.'
    );

    v_created := v_created + 1;
  END LOOP;

  -- Reservas com aluguel fixo mensal.
  FOR v_row IN
    SELECT
      rb.id AS booking_id,
      rb.company_id,
      rb.property_id,
      rb.guest_party_id AS party_id,
      rb.monthly_rent,
      rb.payment_due_day,
      rb.check_in,
      rb.check_out,
      rp.title AS property_title
    FROM rental_bookings rb
    JOIN rental_properties rp ON rp.id = rb.property_id
    WHERE rb.is_fixed_rent = TRUE
      AND rb.payment_due_day IS NOT NULL
      AND rb.monthly_rent > 0
      AND rb.status IN ('confirmed', 'checked_in')
      AND rb.check_in <= p_as_of
      AND rb.check_out > v_ref_month
  LOOP
    v_due_date := rental_month_due_date(v_ref_month, v_row.payment_due_day);

    IF p_as_of < v_due_date THEN
      CONTINUE;
    END IF;

    IF v_row.check_in > v_due_date THEN
      CONTINUE;
    END IF;

    IF v_due_date >= v_row.check_out THEN
      CONTINUE;
    END IF;

    IF EXISTS (
      SELECT 1
      FROM rental_charges rc
      WHERE rc.booking_id = v_row.booking_id
        AND rc.charge_type = 'rent'
        AND rc.status <> 'cancelled'
        AND (
          rc.reference_month = v_ref_month
          OR (
            rc.reference_month IS NULL
            AND rc.due_date >= v_ref_month
            AND rc.due_date < (v_ref_month + INTERVAL '1 month')::DATE
          )
        )
    ) THEN
      CONTINUE;
    END IF;

    INSERT INTO rental_charges (
      company_id,
      booking_id,
      party_id,
      property_id,
      charge_type,
      status,
      description,
      amount,
      due_date,
      reference_month,
      notes
    ) VALUES (
      v_row.company_id,
      v_row.booking_id,
      v_row.party_id,
      v_row.property_id,
      'rent',
      'pending',
      'Aluguel fixo — ' || v_row.property_title || ' — ' ||
        TO_CHAR(v_ref_month, 'MM/YYYY'),
      v_row.monthly_rent,
      v_due_date,
      v_ref_month,
      'Gerado automaticamente na data de vencimento.'
    );

    v_created := v_created + 1;
  END LOOP;

  RETURN v_created;
END;
$$;

GRANT EXECUTE ON FUNCTION generate_rental_monthly_charges(DATE) TO authenticated;

NOTIFY pgrst, 'reload schema';

-- ========== 00047_fix_rental_charge_unique_constraint.sql ==========
-- O índice único impedia editar cobranças quando já existia outra do mesmo mês.
-- A deduplicação continua na função generate_rental_monthly_charges.

DROP INDEX IF EXISTS idx_rental_charges_lease_ref_month;
DROP INDEX IF EXISTS idx_rental_charges_booking_ref_month;

NOTIFY pgrst, 'reload schema';

-- ========== 00048_rental_charge_dedup_by_property.sql ==========
-- Evita gerar cobrança pela reserva fixa quando o imóvel já tem cobrança de contrato no mês.

CREATE OR REPLACE FUNCTION generate_rental_monthly_charges(p_as_of DATE DEFAULT CURRENT_DATE)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ref_month DATE := DATE_TRUNC('month', p_as_of)::DATE;
  v_created INTEGER := 0;
  v_row RECORD;
  v_due_date DATE;
BEGIN
  FOR v_row IN
    SELECT
      rl.id AS lease_id,
      rl.company_id,
      rl.property_id,
      rl.primary_tenant_party_id AS party_id,
      rl.monthly_rent,
      rl.due_day_of_month,
      rl.start_date,
      rl.end_date,
      rp.title AS property_title
    FROM rental_leases rl
    JOIN rental_properties rp ON rp.id = rl.property_id
    WHERE rl.status = 'active'
      AND rl.due_day_of_month IS NOT NULL
      AND rl.monthly_rent > 0
      AND rl.start_date <= p_as_of
      AND (rl.end_date IS NULL OR rl.end_date >= v_ref_month)
  LOOP
    v_due_date := rental_month_due_date(v_ref_month, v_row.due_day_of_month);

    IF p_as_of < v_due_date THEN
      CONTINUE;
    END IF;

    IF v_row.start_date > v_due_date THEN
      CONTINUE;
    END IF;

    IF EXISTS (
      SELECT 1
      FROM rental_charges rc
      WHERE rc.lease_id = v_row.lease_id
        AND rc.charge_type = 'rent'
        AND rc.status <> 'cancelled'
        AND (
          rc.reference_month = v_ref_month
          OR (
            rc.reference_month IS NULL
            AND rc.due_date >= v_ref_month
            AND rc.due_date < (v_ref_month + INTERVAL '1 month')::DATE
          )
        )
    ) THEN
      CONTINUE;
    END IF;

    INSERT INTO rental_charges (
      company_id,
      lease_id,
      party_id,
      property_id,
      charge_type,
      status,
      description,
      amount,
      due_date,
      reference_month,
      notes
    ) VALUES (
      v_row.company_id,
      v_row.lease_id,
      v_row.party_id,
      v_row.property_id,
      'rent',
      'pending',
      'Aluguel — ' || v_row.property_title || ' — ' ||
        TO_CHAR(v_ref_month, 'MM/YYYY'),
      v_row.monthly_rent,
      v_due_date,
      v_ref_month,
      'Gerado automaticamente na data de vencimento.'
    );

    v_created := v_created + 1;
  END LOOP;

  FOR v_row IN
    SELECT
      rb.id AS booking_id,
      rb.company_id,
      rb.property_id,
      rb.guest_party_id AS party_id,
      rb.monthly_rent,
      rb.payment_due_day,
      rb.check_in,
      rb.check_out,
      rp.title AS property_title
    FROM rental_bookings rb
    JOIN rental_properties rp ON rp.id = rb.property_id
    WHERE rb.is_fixed_rent = TRUE
      AND rb.payment_due_day IS NOT NULL
      AND rb.monthly_rent > 0
      AND rb.status IN ('confirmed', 'checked_in')
      AND rb.check_in <= p_as_of
      AND rb.check_out > v_ref_month
  LOOP
    v_due_date := rental_month_due_date(v_ref_month, v_row.payment_due_day);

    IF p_as_of < v_due_date THEN
      CONTINUE;
    END IF;

    IF v_row.check_in > v_due_date THEN
      CONTINUE;
    END IF;

    IF v_due_date >= v_row.check_out THEN
      CONTINUE;
    END IF;

    -- Não duplicar se o imóvel já tem cobrança de contrato no mês.
    IF EXISTS (
      SELECT 1
      FROM rental_charges rc
      JOIN rental_leases rl ON rl.id = rc.lease_id
      WHERE rl.property_id = v_row.property_id
        AND rc.charge_type = 'rent'
        AND rc.status <> 'cancelled'
        AND (
          rc.reference_month = v_ref_month
          OR (
            rc.reference_month IS NULL
            AND rc.due_date >= v_ref_month
            AND rc.due_date < (v_ref_month + INTERVAL '1 month')::DATE
          )
        )
    ) THEN
      CONTINUE;
    END IF;

    IF EXISTS (
      SELECT 1
      FROM rental_charges rc
      WHERE rc.booking_id = v_row.booking_id
        AND rc.charge_type = 'rent'
        AND rc.status <> 'cancelled'
        AND (
          rc.reference_month = v_ref_month
          OR (
            rc.reference_month IS NULL
            AND rc.due_date >= v_ref_month
            AND rc.due_date < (v_ref_month + INTERVAL '1 month')::DATE
          )
        )
    ) THEN
      CONTINUE;
    END IF;

    INSERT INTO rental_charges (
      company_id,
      booking_id,
      party_id,
      property_id,
      charge_type,
      status,
      description,
      amount,
      due_date,
      reference_month,
      notes
    ) VALUES (
      v_row.company_id,
      v_row.booking_id,
      v_row.party_id,
      v_row.property_id,
      'rent',
      'pending',
      'Aluguel fixo — ' || v_row.property_title || ' — ' ||
        TO_CHAR(v_ref_month, 'MM/YYYY'),
      v_row.monthly_rent,
      v_due_date,
      v_ref_month,
      'Gerado automaticamente na data de vencimento.'
    );

    v_created := v_created + 1;
  END LOOP;

  RETURN v_created;
END;
$$;

NOTIFY pgrst, 'reload schema';

-- ========== 00049_rental_charge_payment_method.sql ==========
-- Forma de pagamento registrada ao confirmar cobrança.

ALTER TABLE rental_charges
  ADD COLUMN IF NOT EXISTS paid_payment_method TEXT;

NOTIFY pgrst, 'reload schema';

-- ========== 00050_rental_condominium_expenses.sql ==========
-- Despesas de condomínio no módulo locação (financial_records estendido)
-- Migration: 00050

ALTER TABLE financial_records
  ADD COLUMN IF NOT EXISTS unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS rental_expense_entry_type TEXT
    CHECK (rental_expense_entry_type IS NULL OR rental_expense_entry_type IN ('fixed_bill', 'service', 'material')),
  ADD COLUMN IF NOT EXISTS condominium_bill_type TEXT,
  ADD COLUMN IF NOT EXISTS expense_service_type TEXT,
  ADD COLUMN IF NOT EXISTS material_category_id UUID REFERENCES material_categories(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS is_recurring_template BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS recurrence_template_id UUID REFERENCES financial_records(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS recurrence_day_of_month INT
    CHECK (recurrence_day_of_month IS NULL OR (recurrence_day_of_month >= 1 AND recurrence_day_of_month <= 28)),
  ADD COLUMN IF NOT EXISTS recurrence_active BOOLEAN NOT NULL DEFAULT true;

CREATE INDEX IF NOT EXISTS idx_financial_unit ON financial_records(unit_id);
CREATE INDEX IF NOT EXISTS idx_financial_rental_expense_entry ON financial_records(rental_expense_entry_type)
  WHERE rental_expense_entry_type IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_financial_recurring_template ON financial_records(is_recurring_template)
  WHERE is_recurring_template = true;
CREATE INDEX IF NOT EXISTS idx_financial_recurrence_template ON financial_records(recurrence_template_id);

COMMENT ON COLUMN financial_records.rental_expense_entry_type IS
  'Origem módulo locação: conta fixa, serviço técnico ou material';
COMMENT ON COLUMN financial_records.condominium_bill_type IS
  'Tipo de conta fixa (água, energia, internet, etc.)';
COMMENT ON COLUMN financial_records.is_recurring_template IS
  'Modelo mensal reutilizável; gera lançamentos via recurrence_template_id';

-- Gestores da empresa com módulo locação podem lançar despesas do condomínio
DROP POLICY IF EXISTS financial_modify ON financial_records;
CREATE POLICY financial_modify ON financial_records FOR ALL
  USING (
    (scope = 'condominium' AND condominium_id IS NOT NULL
      AND (
        get_user_role(condominium_id) IN ('condominium_admin', 'financial')
        OR (
          user_has_module('rental')
          AND EXISTS (
            SELECT 1 FROM condominiums c
            WHERE c.id = condominium_id
              AND c.management_company_id IS NOT NULL
              AND c.management_company_id = get_user_company_id()
              AND is_company_manager(c.management_company_id)
          )
        )
      ))
    OR (scope = 'management_company' AND can_manage_management_financial())
  )
  WITH CHECK (
    (scope = 'condominium' AND condominium_id IS NOT NULL
      AND (
        get_user_role(condominium_id) IN ('condominium_admin', 'financial')
        OR (
          user_has_module('rental')
          AND EXISTS (
            SELECT 1 FROM condominiums c
            WHERE c.id = condominium_id
              AND c.management_company_id IS NOT NULL
              AND c.management_company_id = get_user_company_id()
              AND is_company_manager(c.management_company_id)
          )
        )
      ))
    OR (scope = 'management_company' AND can_manage_management_financial())
  );

NOTIFY pgrst, 'reload schema';

-- ========== 00051_rental_expense_unit_allocation.sql ==========
-- Rateio de despesa do condomínio entre unidades
-- Migration: 00051

ALTER TABLE financial_records
  ADD COLUMN IF NOT EXISTS allocation_parent_id UUID
    REFERENCES financial_records(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_financial_allocation_parent
  ON financial_records(allocation_parent_id)
  WHERE allocation_parent_id IS NOT NULL;

COMMENT ON COLUMN financial_records.allocation_parent_id IS
  'Despesa filha gerada por rateio da despesa pai (condomínio → unidades)';

NOTIFY pgrst, 'reload schema';

-- ========== 00052_financial_record_block_id.sql ==========
-- Vincular despesa de locação a bloco/torre do condomínio
ALTER TABLE financial_records
  ADD COLUMN IF NOT EXISTS block_id UUID REFERENCES blocks(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_financial_block ON financial_records(block_id);

NOTIFY pgrst, 'reload schema';

