-- Dados cadastrais do imóvel e do locador para contratos.

ALTER TABLE rental_properties
  ADD COLUMN IF NOT EXISTS registry_matricula TEXT,
  ADD COLUMN IF NOT EXISTS registry_cartorio TEXT,
  ADD COLUMN IF NOT EXISTS iptu_inscription TEXT,
  ADD COLUMN IF NOT EXISTS municipal_inscription TEXT,
  ADD COLUMN IF NOT EXISTS is_furnished BOOLEAN,
  ADD COLUMN IF NOT EXISTS accepts_pets BOOLEAN;

ALTER TABLE rental_parties
  ADD COLUMN IF NOT EXISTS nationality TEXT,
  ADD COLUMN IF NOT EXISTS rg_number TEXT,
  ADD COLUMN IF NOT EXISTS rg_issuer TEXT,
  ADD COLUMN IF NOT EXISTS profession TEXT,
  ADD COLUMN IF NOT EXISTS marital_status TEXT;
