import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CondominiumsListPage extends ConsumerWidget {
  const CondominiumsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final condosAsync = ref.watch(condominiumsListProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final canCreate = profileAsync.value?.isPlatformAdmin == true;

    return Stack(
      children: [
        condosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
          error: (e, _) => _ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(condominiumsListProvider),
          ),
          data: (condos) {
            if (condos.isEmpty) {
              return _EmptyState(
                canCreate: canCreate,
                onCreate: () => context.go('/condominiums/new'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(condominiumsListProvider),
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(20, 8, 20, canCreate ? 88 : 24),
                itemCount: condos.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _CondominiumTile(condominium: condos[index]),
              ),
            );
          },
        ),
        if (canCreate)
          Positioned(
            right: 20,
            bottom: 20,
            child: ClayButton(
              label: 'Novo condomínio',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () => context.go('/condominiums/new'),
            ),
          ),
      ],
    );
  }
}

class _CondominiumTile extends StatelessWidget {
  const _CondominiumTile({required this.condominium});

  final Condominium condominium;

  @override
  Widget build(BuildContext context) {
    return ClayListTileCard(
      icon: Icons.apartment_rounded,
      iconColor: ClayTokens.primary,
      title: condominium.name,
      subtitle: condominium.displayAddress,
      onTap: () => context.go('/condominiums/${condominium.id}'),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canCreate, required this.onCreate});

  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ClaySurface(
          depth: ClayDepth.floating,
          radius: ClayTokens.radiusXl,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ClayTokens.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
                ),
                child: const Icon(Icons.apartment_rounded, size: 40, color: ClayTokens.primary),
              ),
              const SizedBox(height: 20),
              Text(
                'Nenhum condomínio cadastrado',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                canCreate
                    ? 'Cadastre o primeiro condomínio para começar a operação.'
                    : 'Peça ao administrador da plataforma para cadastrar um condomínio e vincular seu usuário.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: ClayTokens.textSecondary, height: 1.4),
              ),
              if (canCreate) ...[
                const SizedBox(height: 24),
                ClayButton(
                  label: 'Cadastrar condomínio',
                  icon: Icons.add_rounded,
                  onPressed: onCreate,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClaySurface(
          depth: ClayDepth.floating,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: ClayTokens.error, size: 40),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ClayButton(
                label: 'Tentar novamente',
                variant: ClayButtonVariant.secondary,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
