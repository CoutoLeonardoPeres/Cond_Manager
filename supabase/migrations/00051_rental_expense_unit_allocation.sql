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
