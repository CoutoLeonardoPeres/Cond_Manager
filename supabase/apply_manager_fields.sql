-- =============================================================================
-- COND MANAGER — Campos da administradora (execute no Supabase SQL Editor)
-- Use este arquivo se o banco JÁ EXISTE e você só precisa adicionar as colunas novas
-- =============================================================================

ALTER TABLE public.condominiums
  ADD COLUMN IF NOT EXISTS manager_cnpj TEXT,
  ADD COLUMN IF NOT EXISTS manager_contact_name TEXT,
  ADD COLUMN IF NOT EXISTS manager_street TEXT,
  ADD COLUMN IF NOT EXISTS manager_number TEXT,
  ADD COLUMN IF NOT EXISTS manager_complement TEXT,
  ADD COLUMN IF NOT EXISTS manager_neighborhood TEXT,
  ADD COLUMN IF NOT EXISTS manager_city TEXT,
  ADD COLUMN IF NOT EXISTS manager_state TEXT,
  ADD COLUMN IF NOT EXISTS manager_zip_code TEXT;

-- Verificar colunas
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'condominiums'
  AND column_name LIKE 'manager_%'
ORDER BY column_name;
