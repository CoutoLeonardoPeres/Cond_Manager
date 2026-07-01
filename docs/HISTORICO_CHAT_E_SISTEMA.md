# Cond Manager — Histórico resumido (chat + sistema)

> **Uso:** cole este arquivo no início de um novo chat no Cursor para retomar contexto com menos tokens.  
> **Gerado em:** 2026-06-30 (atualizado)  
> **Repositório:** `/Users/leonardoperescouto/Documents/App_Cond_Manager`

---

## 1. O que é o app

**Cond Manager** — plataforma Web/Mobile (Flutter) para gestão de **manutenção de condomínios** e **locação de imóveis** (imobiliárias, hotéis, temporada, longo prazo), com backend **Supabase** (PostgreSQL + Auth + Storage + RLS).

### Stack
| Camada | Tecnologia |
|--------|------------|
| Frontend | Flutter 3.38+, Dart ^3.10 |
| Estado | Riverpod 2.x (`Provider`, `FutureProvider`, `StateProvider`) |
| Navegação | Go Router 15 |
| Backend | Supabase Flutter 2.9 |
| Arquitetura | Clean architecture por feature: `domain` → `data` → `presentation` |
| Tipografia | Plus Jakarta Sans (web) / sistema (mobile) |
| Design | **Soft Dark & Mint** — sidebar escura, accent mint `#00BFA5`, componentes Clay |
| Preferências | `shared_preferences` — atalhos da barra inferior mobile |

### Variáveis de ambiente
```bash
# Opção 1 (recomendada no Cursor)
cp dart_defines.example.json dart_defines.json
# Edite URL + anon key; launch.json usa --dart-define-from-file

# Opção 2
cp .env.example .env
# .env está em assets/ — lido por EnvLoader no boot

flutter run --dart-define-from-file=dart_defines.json
```

**Boot:** `AppConfig` usa `static const` para dart-defines (não chamar `fromEnvironment` em runtime — quebra Web). Fallback: `.env` via `EnvLoader`.

---

## 2. Dois módulos (AppModule)

| Módulo | Rota home | Conteúdo |
|--------|-----------|----------|
| **Manutenção** | `/` | Dashboard, chamados, OS, materiais, preventivas, financeiro, condomínios |
| **Locação** | `/rental` | Imóveis, contratos, reservas, calendário/Gantt, cobranças, despesas, partes |

Alternância via `AppModuleSwitcher` (sem `maxWidth` no mobile — rótulo completo) + `activeAppModuleProvider`. Permissões em `lib/core/permissions/app_permissions.dart` (tiers: platformAdmin, manager, analyst, fieldTeam, client, legacyStaff).

---

## 3. Features principais (`lib/features/`)

| Feature | Responsabilidade |
|---------|------------------|
| `auth` | Login, registro, perfil, convites |
| `shell` | Layout, sidebar, navegação, **barra inferior mobile personalizável** |
| `dashboard` | Home com KPIs operacionais + financeiros + gráficos |
| `condominiums` | Condomínios, blocos, unidades, áreas |
| `tickets` | Chamados |
| `work_orders` | Ordens de serviço, materiais, mão de obra |
| `providers` | Prestadores/fornecedores |
| `materials` | Estoque, categorias, fornecedores de material |
| `preventive` | Manutenção preventiva |
| `financial` | Lançamentos financeiros (condomínio + empresa) |
| `rental` | Todo módulo locação (imóveis, leases, bookings, charges, expenses) |
| `users` | Usuários e papéis |
| `access_logs` | Logs de acesso |
| `modules` | Admin: módulos contratados por empresa |

---

## 4. Dashboards (implementados neste chat)

### Home manutenção (`DashboardPage` — `/`)
- Cards compactos **2×2**: chamados, OS, preventivas, estoque baixo (`ClayStatCard` layout vertical)
- **Financeiro da manutenção:** KPIs só do módulo manutenção (sem ocupação/locação)
- 4 KPIs financeiros + margem manutenção; gráficos de despesas e comparativo anual (sem ocupação)
- Filtros compactos: condomínio, período, ano
- `dashboardFinancialMetricsProvider(DashboardFinancialModule.maintenance)` — exclui rental via `excludeRentalModule`

### Home locação (`RentalDashboardPage` — `/rental`)
- Mini-cards: imóveis, contratos, reservas, contas a vencer
- KPIs e gráficos com ocupação + rentabilidade (`DashboardFinancialModule.rental`)
- **Layout especial:** ocupação + rentabilidade KPI lado a lado; gráficos ocupação por imóvel + rentabilidade por unidade lado a lado

### Arquivos-chave dashboard
- `lib/features/dashboard/domain/dashboard_financial_metrics.dart`
- `lib/features/dashboard/presentation/providers/dashboard_financial_providers.dart` — enum `DashboardFinancialModule`
- `lib/features/dashboard/presentation/widgets/clay_chart_widgets.dart`
- `lib/features/dashboard/presentation/widgets/dashboard_financial_kpi_section.dart`
- `lib/features/dashboard/presentation/widgets/dashboard_charts_section.dart`

---

## 4b. Financeiro manutenção vs locação

### Isolamento de dados
- **Manutenção** (`/financial`): `excludeRentalModule: true` em listas e relatórios
- Exclui: despesas com `rental_expense_entry_type`, rateios (`allocation_parent_id`), receitas de cobrança (`rental_charge_id`)
- `FinancialRecord.belongsToMaintenanceModule` — getter de domínio
- Receitas de aluguel/locação ficam em **Locação → Cobranças** (sync para `financial_records` com `rental_charge_id`)

### Filtros em carrossel (financeiro)
- `FinancialListFiltersBar` + `MonthFilterBar` (shared) + `ResponsiveFilterLayout`
- Telas: **Lançamentos**, **Relatório condomínio**, **Relatório gestora**
- `ClayDropdownField(compact: true)` com ellipsis no valor selecionado
- Carrossel mobile: altura 92px; grade responsiva limita colunas pela largura

### Arquivos-chave financeiro
- `lib/features/financial/presentation/widgets/financial_list_filters_bar.dart`
- `lib/shared/widgets/form/month_filter_bar.dart`
- `lib/features/financial/presentation/providers/financial_providers.dart`

---

## 5. Módulo locação — mapa de ocupação

- `rentalOccupancyHorizonMonthsProvider` — horizonte 3/6/12 meses (padrão 3)
- 2 meses visíveis na viewport; scroll horizontal no horizonte completo
- Filtro: só imóveis com **vaga** no horizonte (`rentalPropertiesWithVacancyInHorizon`)
- Contratos longo prazo **sem data fim** não bloqueiam nem aparecem no Gantt
- Modo **Dia** removido do filtro superior
- Barra horizontal de scroll sincronizada (cabeçalho + corpo)
- **Mobile:** cabeçalho compacto (chips 3m/6m/12m, Semana/Mês/Ano), legenda em sheet (ícone ℹ️), coluna imóvel 108px, sem legenda fixa no card
- Arquivos: `rental_occupancy_view.dart`, `rental_gantt_chart.dart`, `rental_gantt_timeline.dart`, `rental_calendar_page.dart`

---

## 5b. UX mobile (2026-06)

### Navegação
- `mobile_nav_shortcuts_storage.dart` + provider — até 4 atalhos na barra + Menu
- Menu → *Personalizar barra inferior* (`mobile_nav_shortcuts_sheet.dart`)
- `app_shell_page.dart` — atalhos salvos por módulo; loading enquanto `authStateProvider` restaura sessão

### Filtros
- `filter_carousel_layout.dart` / `responsive_filter_layout.dart` / `month_filter_bar.dart` — carrossel em telas com vários filtros (imóveis, contratos, reservas, cobranças, **financeiro**, dashboard, etc.)
- `ClayDropdownField(compact: true)` — modo denso para filtros; ellipsis no valor selecionado

### Chamados e OS (listas)
- Cards de lista: `Wrap` para chips status + prioridade (evita overflow do badge *Urgente*)
- Título/subtítulo com `maxLines` + ellipsis

### Cobranças
- Board 3 colunas no iPhone (`rental_charges_board.dart`, `ultraCompact`)
- Botão **Pagar** ampliado no card (`rental_charge_tile.dart`)

### Despesas
- Mobile: modal `rental_expense_draft_sheet.dart` ao adicionar (campos da planilha)
- Cabeçalho empilhado sem overflow (`_MobileExpensesHeader`)
- FAB **Nova despesa** + botão principal no topo
- Desktop: planilha inline inalterada

### Boot / iOS
- `bootstrap_app.dart` — splash mint, retry 2x, watchdog 25s, botão *Tentar novamente*
- `supabase_bootstrap.dart` — init idempotente, limpeza de sessão corrompida no `SharedPreferences`
- `env_loader.dart` — `.env` via `rootBundle`
- Scheme Xcode `Runner` = **Release** (abre pelo ícone); `Runner-Debug` = LLDB
- iOS: builds Debug sem debugger fecham na hora (flash branco) — usar **Cond Manager (iOS)** no Cursor
- Chave Supabase truncada causa *Invalid API key* — usar `dart_defines.json` completo (ver `dart_defines.example.json`)

---

## 6. Tela de Despesas (`RentalExpensesPage` + planilha)

### Layout toolbar
- **Desktop:** linha título + filtro mês; toolbar horizontal (condomínio, botões, alertas, totais)
- **Mobile:** coluna — mês → condomínio → **Adicionar despesa** → copiar fixas → totais; FAB inferior

### Planilha (`rental_expenses_spreadsheet.dart`)
- Edição inline estilo Excel; realce de linha em edição (draft/dirty/foco)
- Mobile: `openMobileDraftSheet()` → `showRentalExpenseDraftSheet` (salva direto no repositório)
- Desktop: `addDraftRow()` insere rascunho no topo da tabela

### Dropdown customizado (`_SpreadsheetDropdown`)
- Substituído `DropdownButton` Material (limite 48px) por **popup customizado** (`showGeneralDialog`)
- Menu: fonte 10px, itens 34px altura, altura máx 137px
- **Largura proporcional ao texto** (`TextPainter` no item mais longo) — resolve nomes longos de condomínio
- Célula fechada mantém fonte 11px; só o popup é compacto

### Despesas — domínio/BD
- Tipos: `fixedBill`, `service`, `material`
- Contas fixas recorrentes; cópia mês a mês (`generateRecurringRentalExpenses`)
- Alocação por unidade; `block_id` em financial_records (migration 00052)
- Anexos NF/recibo por despesa (`rental_expense_attachments`, migration 00054)
- UI: `rental_expense_attachments_editor.dart` (Foto/PDF até 20 MB) em formulário, detalhe, draft e planilha
- Multi-tenant financeiro (`management_company_id`, migration 00053)
- Migrations: 00050–00054

---

## 7. Design system (commit ~904ca49)

- `lib/core/theme/clay_tokens.dart` — tokens Soft Dark & Mint
- `lib/shared/widgets/clay/` — ClaySurface, ClayCard, ClayStatCard, ClayDropdownField, etc.
- Cards/gráficos dashboard em modo `compact: true` para caber em uma tela

---

## 8. Banco de dados

- **54 migrations** em `supabase/migrations/00001` … `00054`
- Export consolidado: `docs/cond_manager_database_full.sql` (~5300 linhas)
- Schema legado alternativo: `supabase/cond_manager_full_schema.sql` (pode estar desatualizado vs migrations)
- RLS em `00011_rls_policies.sql` + extensões posteriores
- Seeds: `seed_optional.sql`, `seed_rental_module.sql`, seeds Itaparica (00037–00040)

### Tabelas rental principais
`rental_properties`, `rental_leases`, `rental_bookings`, `rental_parties`, `rental_charges`, `rental_property_inclusions`, `rental_property_photos`, `rental_tenant_intake_forms`

### Financial + rental
`financial_records` com campos rental (`rental_expense_entry_type`, `rental_property_id`, `rental_charge_id`, `block_id`, recorrência, work_order_id, etc.)

---

## 9. Rotas rental (referência rápida)

```
/rental                    → dashboard locação
/rental/properties         → imóveis
/rental/leases             → contratos
/rental/bookings           → reservas
/rental/calendar           → mapa ocupação / Gantt
/rental/expenses           → despesas (planilha)
/rental/charges            → cobranças
/rental/parties            → locadores/locatários
/rental/reports            → relatórios P&L
```

---

## 10. Prompt sugerido para novo chat

```
Estou no projeto Cond Manager (Flutter + Supabase + Riverpod).
Leia docs/HISTORICO_CHAT_E_SISTEMA.md e docs/cond_manager_system_blueprint.json.
Módulos: manutenção (/) e locação (/rental).
Design: Soft Dark & Mint, widgets Clay.
Credenciais: dart_defines.json (ver dart_defines.example.json) ou .env.
Último trabalho: isolamento financeiro manutenção/locação, filtros financeiro em carrossel, dashboard por módulo, anexos despesas (00054), UX cards chamados/OS, boot iOS, multi-tenant (00053).
[descreva sua tarefa aqui]
```

---

## 11. Arquivos de exportação

| Arquivo | Conteúdo |
|---------|----------|
| `docs/HISTORICO_CHAT_E_SISTEMA.md` | Este resumo |
| `docs/cond_manager_system_blueprint.json` | Blueprint JSON completo para replicação |
| `docs/cond_manager_database_full.sql` | Todas as migrations concatenadas em ordem |
| `dart_defines.example.json` | Template de credenciais Supabase para `dart_defines.json` |
