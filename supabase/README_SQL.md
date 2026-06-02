# SQL — Cond Manager no Supabase

## Arquivos

| Arquivo | Uso |
|---------|-----|
| **`cond_manager_full_schema.sql`** | Script único — cole no **SQL Editor** |
| `migrations/00001` … `00011` | Versões separadas (CLI `supabase db push`) |
| `seed_optional.sql` | Dados de exemplo e admin (opcional) |

## Passo a passo (Dashboard)

1. Crie o projeto no [Supabase](https://supabase.com).
2. **SQL Editor** → **New query**.
3. Abra `cond_manager_full_schema.sql`, copie **tudo** e clique **Run**.
4. Confira em **Table Editor** se as tabelas foram criadas.
5. Em **Authentication** → crie um usuário ou cadastre pelo app.
6. Execute no SQL Editor:

```sql
UPDATE public.profiles
SET is_platform_admin = true
WHERE email = 'SEU_EMAIL_AQUI';
```

7. Em **Project Settings → API**, copie **URL** e **anon key** para o Flutter.

## Storage (buckets)

Criados automaticamente pelo script:

- `avatars` (público)
- `condominium-assets`
- `tickets`
- `work-orders`
- `provider-documents`
- `signatures`

## Realtime

Habilitado para: `tickets`, `work_orders`, `notifications`, `work_order_approvals`.

## Tabelas principais

```
profiles, user_condominium_roles, user_invitations
condominiums → blocks, towers, units, common_areas, equipment
providers → provider_documents, provider_contracts, provider_evaluations
materials, material_categories, stock_movements
tickets → ticket_attachments, ticket_interactions
work_orders → status_history, materials, labor, attachments, approvals
preventive_plans → checklist_items, preventive_executions
financial_records, notifications
```

## Erros comuns

| Erro | Solução |
|------|---------|
| `type "user_role" already exists` | Banco já tem schema; use projeto novo ou remova objetos antes |
| `relation "profiles" already exists` | Idem — não execute o script completo duas vezes |
| Login ok mas sem dados | Falta `user_condominium_roles` ou condomínio vinculado |
| Storage negado | Confirme buckets e policies em **Storage → Policies** |

## CLI (opcional)

```bash
npm i -g supabase
supabase login
supabase link --project-ref SEU_PROJECT_REF
cd /caminho/App_Cond_Manager
supabase db push
```
