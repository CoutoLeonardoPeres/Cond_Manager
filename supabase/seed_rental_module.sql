-- Habilita o módulo de Locação para todas as empresas gestoras (opcional).
-- Execute no SQL Editor do Supabase quando o cliente contratar o módulo.

INSERT INTO company_modules (company_id, module, status)
SELECT id, 'rental', 'active'
FROM management_companies
ON CONFLICT (company_id, module) DO UPDATE
  SET status = 'active', updated_at = NOW();

-- Para habilitar só uma empresa:
-- INSERT INTO company_modules (company_id, module, status)
-- VALUES ('UUID_DA_EMPRESA', 'rental', 'active')
-- ON CONFLICT (company_id, module) DO UPDATE SET status = 'active', updated_at = NOW();
