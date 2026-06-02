-- =============================================================================
-- COND MANAGER — Schema completo para Supabase
-- Execute no SQL Editor (projeto novo). Ver supabase/README_SQL.md
-- =============================================================================

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

-- -----------------------------------------------------------------------------
-- Realtime (ignora se tabela já estiver na publicação)
-- -----------------------------------------------------------------------------
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE tickets;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE work_orders;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE work_order_approvals;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Grants para roles do Supabase
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

