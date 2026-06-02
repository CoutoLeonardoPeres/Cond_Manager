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
