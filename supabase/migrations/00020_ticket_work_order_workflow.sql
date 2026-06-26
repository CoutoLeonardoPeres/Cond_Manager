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
