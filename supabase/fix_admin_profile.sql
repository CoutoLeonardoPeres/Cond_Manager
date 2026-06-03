-- =============================================================================
-- DIAGNÓSTICO + CORREÇÃO COMPLETA DO USUÁRIO
-- Cole no SQL Editor do Supabase e execute TUDO de uma vez
-- =============================================================================

-- A) O schema foi aplicado?
SELECT EXISTS (
  SELECT 1 FROM information_schema.tables
  WHERE table_schema = 'public' AND table_name = 'profiles'
) AS tabela_profiles_existe;

-- B) Usuário existe no Auth?
SELECT id, email, email_confirmed_at, created_at
FROM auth.users
WHERE email = 'leonardopcouto@gmail.com';

-- C) Perfil existe?
SELECT id, email, is_platform_admin, status
FROM public.profiles
WHERE email = 'leonardopcouto@gmail.com';

-- D) CORREÇÃO: cria/atualiza perfil + admin
INSERT INTO public.profiles (id, email, full_name, is_platform_admin, status)
SELECT
  u.id,
  u.email,
  COALESCE(u.raw_user_meta_data->>'full_name', 'Leonardo'),
  true,
  'active'::entity_status
FROM auth.users u
WHERE u.email = 'leonardopcouto@gmail.com'
ON CONFLICT (id) DO UPDATE SET
  is_platform_admin = true,
  email = EXCLUDED.email,
  updated_at = NOW();

-- E) Confirmar resultado (DEVE retornar 1 linha)
SELECT id, email, full_name, is_platform_admin, status
FROM public.profiles
WHERE email = 'leonardopcouto@gmail.com';
