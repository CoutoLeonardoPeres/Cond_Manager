-- Corrige dependência de pgcrypto (gen_random_bytes) no formulário público de locatário.
-- Supabase/Postgres pode não expor gen_random_bytes no search_path das RPCs.

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION _rental_intake_protocol()
RETURNS TEXT
LANGUAGE sql
AS $$
  SELECT 'RIT-' || to_char(NOW(), 'YYYYMMDD') || '-' ||
         upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
$$;

ALTER TABLE rental_tenant_intake_links
  ALTER COLUMN token SET DEFAULT replace(gen_random_uuid()::text, '-', '');

NOTIFY pgrst, 'reload schema';
