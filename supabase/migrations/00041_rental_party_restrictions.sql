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
