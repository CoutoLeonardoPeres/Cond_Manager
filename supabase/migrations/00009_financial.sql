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
