# Cond Manager

Plataforma **Web e Mobile** (Flutter) para gestão operacional, financeira e administrativa de **manutenção em condomínios** e **locação de imóveis**, com backend **Supabase** (PostgreSQL, Auth, Storage, Realtime e RLS).

## Design

Interface **Soft Dark & Mint** com componentes **Clay** (claymorphism):

- Fundo mesh gradiente, sidebar escura, accent mint `#00BFA5`
- Superfícies com sombras duplas (elevado / pressionado)
- Tipografia **Plus Jakarta Sans** (web) / sistema no mobile
- Componentes em `lib/shared/widgets/clay/`

## Stack

| Camada | Tecnologia |
|--------|------------|
| Frontend | Flutter (Web, iOS, Android) |
| Estado | Riverpod 2.x |
| Navegação | Go Router |
| Backend | Supabase Cloud |
| Banco | PostgreSQL + Row Level Security |
| Auth | Supabase Auth |
| Arquivos | Supabase Storage |
| Preferências locais | `shared_preferences` (atalhos da barra mobile) |

## Módulos do app

| Módulo | Rota | Conteúdo |
|--------|------|----------|
| **Manutenção** | `/` | Dashboard, condomínios, chamados, OS, prestadores, materiais, preventivas, financeiro |
| **Locação** | `/rental` | Imóveis, contratos, reservas, mapa de ocupação, cobranças, despesas, pessoas, relatórios |

Alternância via `AppModuleSwitcher`. Permissões em `lib/core/permissions/app_permissions.dart`.

## Estrutura do projeto

```
lib/
├── core/           # Config, tema, router, bootstrap, permissões, módulos
├── features/       # Clean architecture por domínio
│   ├── auth/
│   ├── dashboard/
│   ├── rental/     # Módulo locação completo
│   └── shell/      # Layout, sidebar, navegação mobile
└── shared/         # Enums e widgets Clay

supabase/migrations/   # 54 migrations (00001 → 00054)
docs/
  ARCHITECTURE.md
  HISTORICO_CHAT_E_SISTEMA.md
  cond_manager_system_blueprint.json
  cond_manager_database_full.sql
```

## Configuração do Supabase

**Guia SQL:** [`supabase/README_SQL.md`](supabase/README_SQL.md)  
**Export consolidado:** [`docs/cond_manager_database_full.sql`](docs/cond_manager_database_full.sql)

1. Crie um projeto em [supabase.com](https://supabase.com).
2. Aplique as migrations em ordem (`00001` … `00054`) ou o export SQL:

```bash
npm i -g supabase
supabase login
supabase link --project-ref SEU_PROJECT_REF
supabase db push
```

3. Em **Authentication → URL Configuration**, configure as URLs de redirect.
4. Configure credenciais no app (veja abaixo).

## Credenciais e variáveis de ambiente

O app lê `SUPABASE_URL` e `SUPABASE_ANON_KEY` nesta ordem:

1. **Compile-time** — `--dart-define` ou `dart_defines.json` (recomendado no VS Code/Cursor)
2. **Runtime** — arquivo `.env` no bundle (`assets` no `pubspec.yaml`)

### Opção A — `dart_defines.json` (recomendado)

```bash
cp dart_defines.example.json dart_defines.json
# Edite dart_defines.json com URL e anon key completas (JWT com 3 segmentos)
```

O arquivo `dart_defines.json` está no `.gitignore` — **não commitar**.

### Opção B — `.env`

```bash
cp .env.example .env
# Edite .env com as mesmas chaves SUPABASE_*
```

### Opção C — linha de comando

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY_COMPLETA
```

> **Importante:** nunca use chave truncada (`...`). `AppConfig` valida formato JWT antes de iniciar o Supabase.

## Executar o app

```bash
flutter pub get
```

No **Cursor/VS Code**, use uma das configs em [`.vscode/launch.json`](.vscode/launch.json):

| Config | Uso |
|--------|-----|
| Cond Manager (Web) | Chrome + `dart_defines.json` |
| Cond Manager (iOS) | iPhone — **Release** (abre pelo ícone sem debugger) |
| Cond Manager (iOS Debug — só com debugger) | Só com Xcode/Cursor conectado (não use pelo ícone) |
| Cond Manager (iOS Release) | Igual ao iOS acima |
| Cond Manager (Android) | Emulador ou dispositivo |

```bash
flutter run --release --dart-define-from-file=dart_defines.json
```

> **iPhone:** builds **Debug** só funcionam com o debugger ligado (Cursor/Xcode). Se instalar em Debug e abrir pelo ícone, o app pode fechar na hora (flash branco). Use **Cond Manager (iOS)** (Release). O scheme Xcode `Runner` usa Release; depuração com LLDB em `Runner-Debug`.

## Mobile — recursos recentes

- **Boot iOS robusto** — `bootstrap_app.dart` + `supabase_bootstrap.dart`: retry, limpeza de sessão corrompida, scheme Release no Xcode
- **Barra inferior personalizável** — Menu → *Personalizar barra inferior* (até 4 atalhos + Menu)
- **Filtros em carrossel** — telas com muitos filtros usam `FilterCarouselLayout` / `ResponsiveFilterLayout` (locação + **financeiro**)
- **Financeiro manutenção** — sem receitas/despesas de locação (`excludeRentalModule`, `rental_charge_id`); relatórios e lançamentos com filtro de mês
- **Dashboard por módulo** — manutenção sem KPIs de ocupação; locação com ocupação e cobranças
- **Cobranças** — board 3 colunas, botão *Pagar* ampliado nos cards
- **Despesas** — planilha compacta no mobile; rateio por unidade; anexos NF/recibo (migration `00054`)
- **Multi-tenant** — isolamento por gestora (`00053`)
- **Mapa de ocupação** — cabeçalho compacto; legenda via ícone ℹ️; mais área para o Gantt

## Documentação técnica

| Arquivo | Conteúdo |
|---------|----------|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Camadas, RLS, storage, convenções |
| [`docs/HISTORICO_CHAT_E_SISTEMA.md`](docs/HISTORICO_CHAT_E_SISTEMA.md) | Resumo para retomar contexto no Cursor |
| [`docs/cond_manager_system_blueprint.json`](docs/cond_manager_system_blueprint.json) | Blueprint JSON completo do sistema |
| [`docs/PERMISSIONS_MATRIX.md`](docs/PERMISSIONS_MATRIX.md) | Matriz de permissões |

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
- Chaves sensíveis em `.env` / `dart_defines.json` (gitignored) — nunca `service_role` no cliente

## Licença

Projeto privado — uso interno.
