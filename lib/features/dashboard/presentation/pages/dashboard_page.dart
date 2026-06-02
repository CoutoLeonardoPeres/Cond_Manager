import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (profile) {
        final roles = profile?.condominiumRoles ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClaySurface(
                depth: ClayDepth.floating,
                radius: ClayTokens.radiusLg,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ClayTokens.primary.withValues(alpha: 0.12),
                    ClayTokens.secondary.withValues(alpha: 0.08),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${profile?.fullName ?? 'usuário'}!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile?.isPlatformAdmin == true
                                ? 'Administrador da plataforma'
                                : roles.isEmpty
                                    ? 'Selecione ou associe-se a um condomínio'
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
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: ClayTokens.primaryGradient,
                        borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
                      ),
                      child: const Icon(Icons.waving_hand_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Visão geral',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
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
                    children: const [
                      ClayStatCard(
                        title: 'Chamados abertos',
                        value: '—',
                        icon: Icons.support_agent_rounded,
                        accentColor: ClayTokens.warning,
                      ),
                      ClayStatCard(
                        title: 'OS em execução',
                        value: '—',
                        icon: Icons.assignment_rounded,
                        accentColor: ClayTokens.primary,
                      ),
                      ClayStatCard(
                        title: 'Preventivas vencendo',
                        value: '—',
                        icon: Icons.event_repeat_rounded,
                        accentColor: ClayTokens.secondary,
                      ),
                      ClayStatCard(
                        title: 'Estoque baixo',
                        value: '—',
                        icon: Icons.inventory_2_rounded,
                        accentColor: ClayTokens.accent,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Próximos passos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
              const ClayListTileCard(
                icon: Icons.cloud_upload_rounded,
                title: 'Configurar Supabase',
                subtitle: 'Aplique as migrations e configure SUPABASE_URL e SUPABASE_ANON_KEY',
                iconColor: ClayTokens.primary,
              ),
              const SizedBox(height: 12),
              const ClayListTileCard(
                icon: Icons.apartment_rounded,
                title: 'Cadastrar condomínio',
                subtitle: 'Comece pelo módulo de condomínios',
                iconColor: ClayTokens.secondary,
              ),
            ],
          ),
        );
      },
    );
  }
}
