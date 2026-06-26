-- Vínculo cobrança de locação ↔ financeiro
-- Migration: 00029

ALTER TABLE rental_charges
  ADD COLUMN IF NOT EXISTS financial_record_id UUID REFERENCES financial_records(id) ON DELETE SET NULL;

ALTER TABLE financial_records
  ADD COLUMN IF NOT EXISTS rental_charge_id UUID REFERENCES rental_charges(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_rental_charges_financial ON rental_charges(financial_record_id);
CREATE INDEX IF NOT EXISTS idx_financial_rental_charge ON financial_records(rental_charge_id);

NOTIFY pgrst, 'reload schema';
