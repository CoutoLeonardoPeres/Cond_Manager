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
