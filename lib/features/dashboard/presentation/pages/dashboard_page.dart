import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:cond_manager/features/dashboard/presentation/widgets/dashboard_filters_bar.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  static bool _dateLocaleReady = false;

  @override
  void initState() {
    super.initState();
    _ensureDateLocale();
  }

  Future<void> _ensureDateLocale() async {
    if (_dateLocaleReady) return;
    await initializeDateFormatting('pt_BR');
    if (mounted) setState(() => _dateLocaleReady = true);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final filter = ref.watch(dashboardFilterProvider);
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final condos = condosAsync.value ?? const [];
    String? selectedCondoName;
    if (filter.condominiumId != null) {
      for (final c in condos) {
        if (c.id == filter.condominiumId) {
          selectedCondoName = c.name;
          break;
        }
      }
    }
    final periodLabel = filter.periodDescription(condominiumName: selectedCondoName);

    return profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
      error: (e, _) => _SetupHelpView(message: e.toString()),
      data: (profile) {
        if (profile == null) {
          return const _SetupHelpView(
            message: 'Sessão ativa, mas perfil não encontrado no banco.',
          );
        }
        final roles = profile.condominiumRoles;
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(currentProfileProvider);
            ref.invalidate(accessibleCondominiumsProvider);
            await ref.read(dashboardStatsProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClaySurface(
                  depth: ClayDepth.floating,
                  radius: ClayTokens.radiusHero,
                  glass: true,
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, ${profile.fullName}!',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.6,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile.isPlatformAdmin
                                  ? 'Administrador da plataforma'
                                  : roles.isEmpty
                                      ? 'Sem condomínio vinculado — peça ao admin para associar seu usuário'
                                      : '${roles.length} condomínio(s) vinculado(s)',
                              style: const TextStyle(
                                color: ClayTokens.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: ClayTokens.primaryGradient,
                          borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: ClayTokens.accent.withValues(alpha: 0.35),
                              offset: const Offset(0, 8),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                DashboardFiltersBar(
                  filter: filter,
                  condominiums: condos,
                  onChanged: (f) => ref.read(dashboardFilterProvider.notifier).state = f,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Visão geral',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            periodLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              color: ClayTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (statsAsync.hasError)
                      TextButton(
                        onPressed: () => ref.invalidate(dashboardStatsProvider),
                        child: const Text('Atualizar'),
                      ),
                  ],
                ),
                if (statsAsync.hasError) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Não foi possível carregar os indicadores: ${statsAsync.error}',
                    style: const TextStyle(color: ClayTokens.error, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                statsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                  error: (_, _) => _StatsGrid(
                    stats: const DashboardStats(
                      openTicketsCount: 0,
                      activeWorkOrdersCount: 0,
                      preventiveDueCount: 0,
                      lowStockCount: 0,
                    ),
                    valuesHidden: true,
                  ),
                  data: (stats) => _StatsGrid(stats: stats),
                ),
                const SizedBox(height: 28),
                Text(
                  'Acesso rápido',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 14),
                ClayListTileCard(
                  icon: Icons.support_agent_rounded,
                  title: 'Chamados',
                  subtitle: 'Abrir, acompanhar e converter em ordem de serviço',
                  gradientIndex: 5,
                  onTap: () => context.go('/tickets'),
                ),
                const SizedBox(height: 12),
                ClayListTileCard(
                  icon: Icons.assignment_rounded,
                  title: 'Ordens de serviço',
                  subtitle: 'Criar OS, materiais, fotos e encerramento',
                  gradientIndex: 1,
                  onTap: () => context.go('/work-orders'),
                ),
                const SizedBox(height: 12),
                ClayListTileCard(
                  icon: Icons.apartment_rounded,
                  title: 'Condomínios',
                  subtitle: 'Cadastro e vínculos de usuários',
                  gradientIndex: 3,
                  onTap: () => context.go('/condominiums'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.stats,
    this.valuesHidden = false,
  });

  final DashboardStats stats;
  final bool valuesHidden;

  String _formatCount(int n) => valuesHidden ? '—' : '$n';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1000
            ? 4
            : constraints.maxWidth > 640
                ? 2
                : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.55,
          children: [
            ClayStatCard(
              title: 'Chamados abertos',
              value: _formatCount(stats.openTicketsCount),
              icon: Icons.support_agent_rounded,
              accentColor: ClayTokens.warning,
              gradientIndex: 5,
              onTap: () => context.go('/tickets'),
            ),
            ClayStatCard(
              title: 'OS ativas',
              value: _formatCount(stats.activeWorkOrdersCount),
              icon: Icons.assignment_rounded,
              accentColor: ClayTokens.accent,
              gradientIndex: 1,
              onTap: () => context.go('/work-orders'),
            ),
            ClayStatCard(
              title: 'Preventivas vencendo',
              value: _formatCount(stats.preventiveDueCount),
              icon: Icons.event_repeat_rounded,
              accentColor: ClayTokens.tertiary,
              gradientIndex: 4,
              onTap: () => context.go('/preventive'),
            ),
            ClayStatCard(
              title: 'Estoque baixo',
              value: _formatCount(stats.lowStockCount),
              icon: Icons.inventory_2_rounded,
              accentColor: ClayTokens.accentAlt,
              gradientIndex: 2,
              onTap: () => context.go('/materials'),
            ),
          ],
        );
      },
    );
  }
}

class _SetupHelpView extends StatelessWidget {
  const _SetupHelpView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ClaySurface(
        depth: ClayDepth.floating,
        radius: ClayTokens.radiusLg,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: ClayTokens.warning, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Configuração pendente',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: ClayTokens.textSecondary)),
            const SizedBox(height: 20),
            const Text(
              'Siga no Supabase (SQL Editor):',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _step('1', 'Execute supabase/cond_manager_full_schema.sql'),
            _step('2', 'Execute supabase/fix_admin_profile.sql'),
            _step('3', 'Authentication → desative "Confirm email" (dev)'),
            _step('4', 'Authentication → URL: http://localhost:7357/**'),
            _step('5', 'Saia e entre de novo no app'),
          ],
        ),
      ),
    );
  }

  Widget _step(String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$n.', style: const TextStyle(fontWeight: FontWeight.w700, color: ClayTokens.primary)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
