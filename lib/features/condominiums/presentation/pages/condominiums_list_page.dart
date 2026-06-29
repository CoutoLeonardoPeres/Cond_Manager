import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/condominium_route_prefix.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CondominiumsListPage extends ConsumerStatefulWidget {
  const CondominiumsListPage({
    super.key,
    this.routePrefix = CondominiumRoutePrefix.maintenance,
  });

  final CondominiumRoutePrefix routePrefix;

  @override
  ConsumerState<CondominiumsListPage> createState() => _CondominiumsListPageState();
}

class _CondominiumsListPageState extends ConsumerState<CondominiumsListPage> {
  static const _searchWidth = 300.0;
  static const _stateWidth = 140.0;
  static const _cityWidth = 180.0;

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _distinctStates(List<Condominium> condos) {
    final states = condos.map((c) => c.state.trim()).where((s) => s.isNotEmpty).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    return states;
  }

  List<String> _distinctCities(List<Condominium> condos, String? state) {
    final cities = condos
        .where((c) {
          if (state == null) return true;
          return c.state.trim().toLowerCase() == state.trim().toLowerCase();
        })
        .map((c) => c.city.trim())
        .where((city) => city.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));
    return cities;
  }

  String? _resolveStateValue(CondominiumListFilter filter, List<String> states) {
    if (filter.state == null) return null;
    final normalized = filter.state!.trim().toLowerCase();
    for (final state in states) {
      if (state.toLowerCase() == normalized) return state;
    }
    return null;
  }

  String? _resolveCityValue(CondominiumListFilter filter, List<String> cities) {
    if (filter.city == null) return null;
    final normalized = filter.city!.trim().toLowerCase();
    for (final city in cities) {
      if (city.toLowerCase() == normalized) return city;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final condosAsync = ref.watch(condominiumsListProvider);
    final filter = ref.watch(condominiumListFilterProvider);
    final canCreate = ref.watch(currentProfileProvider).value?.permissions.canCreateCondominium ?? false;

    void updateFilter(CondominiumListFilter next) {
      ref.read(condominiumListFilterProvider.notifier).state = next;
    }

    if (_searchController.text != filter.search) {
      _searchController.text = filter.search;
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: condosAsync.maybeWhen(
                data: (condos) {
                  if (condos.isEmpty) return const SizedBox.shrink();

                  final states = _distinctStates(condos);
                  final cities = _distinctCities(condos, filter.state);
                  final resolvedState = _resolveStateValue(filter, states);
                  final resolvedCity = _resolveCityValue(filter, cities);

                  if (resolvedState != filter.state || resolvedCity != filter.city) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      updateFilter(
                        filter.copyWith(
                          state: resolvedState,
                          city: resolvedCity,
                          clearState: resolvedState == null && filter.state != null,
                          clearCity: resolvedCity == null && filter.city != null,
                        ),
                      );
                    });
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: _searchWidth,
                          child: ClayTextField(
                            controller: _searchController,
                            label: 'Nome',
                            hint: 'Buscar condomínio',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: ClayTokens.muted,
                            ),
                            onChanged: (value) => updateFilter(filter.copyWith(search: value)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: _stateWidth,
                          child: ClayDropdownField<String?>(
                            label: 'Estado',
                            value: resolvedState,
                            items: [null, ...states],
                            itemLabel: (s) => s ?? 'Todos',
                            onChanged: (value) => updateFilter(
                              filter.copyWith(
                                state: value,
                                clearState: value == null,
                                clearCity: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: _cityWidth,
                          child: ClayDropdownField<String?>(
                            label: 'Cidade',
                            value: resolvedCity,
                            items: [null, ...cities],
                            itemLabel: (c) => c ?? 'Todas',
                            onChanged: (value) => updateFilter(
                              filter.copyWith(
                                city: value,
                                clearCity: value == null,
                              ),
                            ),
                          ),
                        ),
                        if (filter.hasActiveFilters) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                updateFilter(const CondominiumListFilter());
                              },
                              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                              label: const Text('Limpar'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: condosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => _ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(condominiumsListProvider),
                ),
                data: (condos) {
                  if (condos.isEmpty) {
                    return _EmptyState(
                      canCreate: canCreate,
                      onCreate: () => context.go(widget.routePrefix.create),
                    );
                  }

                  final filtered = filterCondominiums(condos, filter);
                  if (filtered.isEmpty) {
                    return _FilteredEmptyState(
                      onClear: () {
                        _searchController.clear();
                        updateFilter(const CondominiumListFilter());
                      },
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(condominiumsListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _CondominiumTile(
                        condominium: filtered[index],
                        routePrefix: widget.routePrefix,
                      ),
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
              label: 'Novo condomínio',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () => context.go(widget.routePrefix.create),
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

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nenhum condomínio encontrado com os filtros selecionados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ClayTokens.textSecondary),
            ),
            const SizedBox(height: 16),
            ClayButton(
              label: 'Limpar filtros',
              expand: false,
              icon: Icons.filter_alt_off_rounded,
              onPressed: onClear,
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
