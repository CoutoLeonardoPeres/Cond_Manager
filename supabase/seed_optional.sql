-- =============================================================================
-- COND MANAGER — Dados iniciais (OPCIONAL)
-- Execute APÓS cond_manager_full_schema.sql e após criar usuário no Auth
-- =============================================================================

-- 1) Torne-se administrador da plataforma (substitua o e-mail)
-- UPDATE public.profiles
-- SET is_platform_admin = true
-- WHERE email = 'seu@email@exemplo.com';

-- 2) Exemplo: condomínio de demonstração (somente platform_admin consegue INSERT)
/*
INSERT INTO public.condominiums (
  name, legal_name, city, state, zip_code,
  syndic_name, syndic_email, manager_company
) VALUES (
  'Residencial Parque Verde',
  'Condomínio Residencial Parque Verde LTDA',
  'São Paulo',
  'SP',
  '01310-100',
  'Maria Silva',
  'sindico@parqueverde.com.br',
  'Administradora Exemplo'
);
*/

-- 3) Vincular seu usuário ao condomínio como síndico
/*
INSERT INTO public.user_condominium_roles (user_id, condominium_id, role, is_primary)
SELECT
  p.id,
  c.id,
  'syndic'::user_role,
  true
FROM public.profiles p
CROSS JOIN public.condominiums c
WHERE p.email = 'seu@email@exemplo.com'
  AND c.name = 'Residencial Parque Verde'
LIMIT 1;
*/

-- 4) Categorias de material exemplo
/*
INSERT INTO public.material_categories (condominium_id, name, description)
SELECT c.id, 'Elétrica', 'Materiais elétricos'
FROM public.condominiums c WHERE c.name = 'Residencial Parque Verde';
*/
