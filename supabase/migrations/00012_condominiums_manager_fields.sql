-- Cond Manager - Campos completos da administradora no condomínio
-- Migration: 00012
-- Execute no SQL Editor se o schema base (00003) já foi aplicado antes desta atualização

ALTER TABLE condominiums
  ADD COLUMN IF NOT EXISTS manager_cnpj TEXT,
  ADD COLUMN IF NOT EXISTS manager_contact_name TEXT,
  ADD COLUMN IF NOT EXISTS manager_street TEXT,
  ADD COLUMN IF NOT EXISTS manager_number TEXT,
  ADD COLUMN IF NOT EXISTS manager_complement TEXT,
  ADD COLUMN IF NOT EXISTS manager_neighborhood TEXT,
  ADD COLUMN IF NOT EXISTS manager_city TEXT,
  ADD COLUMN IF NOT EXISTS manager_state TEXT,
  ADD COLUMN IF NOT EXISTS manager_zip_code TEXT;

COMMENT ON COLUMN condominiums.manager_contact_name IS 'Nome do contato na administradora';
COMMENT ON COLUMN condominiums.manager_cnpj IS 'CNPJ da empresa administradora';
