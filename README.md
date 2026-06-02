# Cond Manager

Plataforma Web e Mobile (Flutter) para gestão operacional, financeira e administrativa de manutenções em condomínios, com backend **Supabase** (PostgreSQL, Auth, Storage, Realtime e RLS).

## Design

Interface **Claymorphism ultramodeno** em Web, iOS e Android:

- Fundo mesh gradiente com orbes suaves
- Superfícies com sombras duplas (elevado / pressionado)
- Tipografia **Plus Jakarta Sans**
- Componentes reutilizáveis em `lib/shared/widgets/clay/`

## Stack

| Camada | Tecnologia |
|--------|------------|
| Frontend | Flutter (Web, iOS, Android) |
| Estado | Riverpod |
| Navegação | Go Router |
| Backend | Supabase Cloud |
| Banco | PostgreSQL + Row Level Security |
| Auth | Supabase Auth |
| Arquivos | Supabase Storage |
| Tempo real | Supabase Realtime (chamados, OS, notificações) |

## Estrutura do projeto

```
lib/
├── core/           # Config, tema, router, erros, utils
├── features/       # Módulos por domínio (clean architecture)
│   ├── auth/
│   ├── dashboard/
│   └── shell/
└── shared/         # Enums e widgets compartilhados

supabase/migrations/   # Schema SQL versionado (11 migrations)
docs/ARCHITECTURE.md   # Detalhes de arquitetura e permissões
```

## Perfis de usuário

| Perfil | Enum no banco |
|--------|----------------|
| Administrador da plataforma | `platform_admin` |
| Administrador do condomínio | `condominium_admin` |
| Síndico | `syndic` |
| Zelador | `caretaker` |
| Gestor de manutenção | `maintenance_manager` |
| Funcionário interno | `internal_employee` |
| Prestador de serviço | `service_provider` |
| Fornecedor | `supplier` |
| Morador | `resident` |
| Financeiro | `financial` |
| Auditor | `auditor` |

## Módulos (roadmap)

- [x] Fundação: schema, RLS, auth, shell, dashboard
- [ ] Gestão de condomínios (blocos, torres, unidades, áreas, equipamentos)
- [ ] Usuários e convites por e-mail
- [ ] Fornecedores e prestadores
- [ ] Materiais e estoque
- [ ] Chamados
- [ ] Ordens de Serviço
- [ ] Manutenção preventiva
- [ ] Financeiro e relatórios

## Configuração do Supabase

**Script SQL completo:** [`supabase/cond_manager_full_schema.sql`](supabase/cond_manager_full_schema.sql)  
Guia detalhado: [`supabase/README_SQL.md`](supabase/README_SQL.md)

1. Crie um projeto em [supabase.com](https://supabase.com).
2. No **SQL Editor**, execute **`supabase/cond_manager_full_schema.sql`** (recomendado) ou as migrations em ordem (`00001` → `00011`) / CLI:

```bash
npm i -g supabase
supabase login
supabase link --project-ref SEU_PROJECT_REF
supabase db push
```

3. Em **Authentication → URL Configuration**, adicione as URLs de redirect do app.
4. Copie **Project URL** e **anon key** para o launch do Flutter.

## Executar o app

```bash
flutter pub get

flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY
```

Ou use a configuração em `.vscode/launch.json` (edite as chaves antes).

## Primeiro administrador da plataforma

Após criar um usuário via app ou Auth:

```sql
UPDATE profiles
SET is_platform_admin = true
WHERE email = 'seu@email.com';
```

## Segurança

- RLS em todas as tabelas sensíveis
- Funções `SECURITY DEFINER` para checagem de permissões
- Storage com políticas por bucket e condomínio
- Chaves sensíveis apenas via `--dart-define` (não commitar `.env`)

## Licença

Projeto privado — uso interno.
