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
