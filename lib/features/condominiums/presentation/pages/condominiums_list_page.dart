import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/condominium_route_prefix.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CondominiumsListPage extends ConsumerWidget {
  const CondominiumsListPage({
    super.key,
    this.routePrefix = CondominiumRoutePrefix.maintenance,
  });

  final CondominiumRoutePrefix routePrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final condosAsync = ref.watch(condominiumsListProvider);
    final canCreate = ref.watch(currentProfileProvider).value?.permissions.canCreateCondominium ?? false;

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
                onCreate: () => context.go(routePrefix.create),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(condominiumsListProvider),
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(20, 8, 20, canCreate ? 88 : 24),
                itemCount: condos.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _CondominiumTile(
                  condominium: condos[index],
                  routePrefix: routePrefix,
                ),
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
              onPressed: () => context.go(routePrefix.create),
            ),
          ),
      ],
    );
  }
}

class _CondominiumTile extends StatelessWidget {
  const _CondominiumTile({
    required this.condominium,
    required this.routePrefix,
  });

  final Condominium condominium;
  final CondominiumRoutePrefix routePrefix;

  @override
  Widget build(BuildContext context) {
    return ClayListTileCard(
      icon: Icons.apartment_rounded,
      iconColor: ClayTokens.primary,
      title: condominium.name,
      subtitle: condominium.displayAddress,
      onTap: () => context.go(routePrefix.detail(condominium.id)),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nenhum condomínio cadastrado.',
              style: TextStyle(color: ClayTokens.textSecondary),
            ),
            if (canCreate) ...[
              const SizedBox(height: 16),
              ClayButton(
                label: 'Cadastrar condomínio',
                expand: false,
                icon: Icons.add_rounded,
                onPressed: onCreate,
              ),
            ],
          ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ClayButton(label: 'Tentar novamente', expand: false, onPressed: onRetry),
        ],
      ),
    );
  }
}
