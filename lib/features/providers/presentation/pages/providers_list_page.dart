import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/providers/domain/entities/service_provider.dart';
import 'package:cond_manager/features/providers/presentation/providers/service_provider_providers.dart';
import 'package:cond_manager/features/providers/presentation/utils/provider_permissions.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:cond_manager/shared/widgets/form/responsive_filter_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProvidersListPage extends ConsumerWidget {
  const ProvidersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(serviceProvidersListProvider);
    final filter = ref.watch(serviceProviderListFilterProvider);
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final profile = ref.watch(currentProfileProvider).value;
    final canCreate = profile != null && profile.canCreateProvider;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FiltersBar(
              filter: filter,
              condosAsync: condosAsync,
              onFilterChanged: (f) =>
                  ref.read(serviceProviderListFilterProvider.notifier).state = f,
            ),
            Expanded(
              child: providersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => _ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(serviceProvidersListProvider),
                ),
                data: (providers) {
                  if (providers.isEmpty) {
                    return const _EmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(serviceProvidersListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: providers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final p = providers[index];
                        final canEdit = profile != null &&
                            profile.canManageProvidersIn(p.condominiumId);
                        return _ProviderTile(
                          provider: p,
                          onTap: canEdit
                              ? () => context.go('/providers/${p.id}/edit')
                              : null,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (canCreate)
          Positioned(
            right: 20,
            bottom: 20,
            child: ClayButton(
              label: 'Novo prestador',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () => context.go('/providers/new'),
            ),
          ),
      ],
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.filter,
    required this.condosAsync,
    required this.onFilterChanged,
  });

  final ServiceProviderListFilter filter;
  final AsyncValue<List<Condominium>> condosAsync;
  final void Function(ServiceProviderListFilter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: condosAsync.when(
        data: (condos) {
          final condoItems = [
            const _CondoFilterOption(id: null, label: 'Todos os condomínios'),
            ...condos.map((c) => _CondoFilterOption(id: c.id, label: c.name)),
          ];
          final selectedCondo = condoItems.firstWhere(
            (o) => o.id == filter.condominiumId,
            orElse: () => condoItems.first,
          );

          final fields = <Widget>[
            if (condos.isNotEmpty)
              ClayDropdownField<_CondoFilterOption>(
                label: 'Condomínio',
                value: selectedCondo,
                items: condoItems,
                itemLabel: (o) => o.label,
                onChanged: (v) => onFilterChanged(
                  filter.copyWith(
                    condominiumId: v?.id,
                    clearCondominium: v?.id == null,
                  ),
                ),
              ),
            ClayDropdownField<ServiceType?>(
              label: 'Área de serviço',
              value: filter.serviceType,
              items: [null, ...ServiceType.values],
              itemLabel: (v) => v?.label ?? 'Todas as áreas',
              onChanged: (v) => onFilterChanged(
                filter.copyWith(
                  serviceType: v,
                  clearServiceType: v == null,
                ),
              ),
            ),
            ClayDropdownField<EntityStatus?>(
              label: 'Status',
              value: filter.status,
              items: [null, ...EntityStatus.values],
              itemLabel: (v) => v?.label ?? 'Todos',
              onChanged: (v) => onFilterChanged(
                filter.copyWith(
                  status: v,
                  clearStatus: v == null,
                ),
              ),
            ),
          ];

          return ResponsiveFilterLayout(fields: fields, wideColumns: 3);
        },
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _CondoFilterOption {
  const _CondoFilterOption({required this.id, required this.label});
  final String? id;
  final String label;
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({required this.provider, this.onTap});

  final ServiceProvider provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClayListTileCard(
      icon: Icons.engineering_rounded,
      iconColor: ClayTokens.primary,
      title: provider.displayName,
      subtitle: [
        provider.status.label,
        if (provider.condominiumName != null) provider.condominiumName!,
        provider.specialtiesLabel,
      ].join(' · '),
      onTap: onTap,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.engineering_outlined, size: 56, color: ClayTokens.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Nenhum prestador cadastrado',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cadastre prestadores com as áreas de serviço em que atuam.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ClayTokens.textSecondary),
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ClayButton(label: 'Tentar novamente', variant: ClayButtonVariant.secondary, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
