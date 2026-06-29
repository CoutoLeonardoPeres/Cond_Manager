-- Vincular despesa de locação a bloco/torre do condomínio
ALTER TABLE financial_records
  ADD COLUMN IF NOT EXISTS block_id UUID REFERENCES blocks(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_financial_block ON financial_records(block_id);

NOTIFY pgrst, 'reload schema';
