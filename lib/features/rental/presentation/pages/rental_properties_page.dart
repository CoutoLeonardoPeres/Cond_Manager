import 'package:cond_manager/core/permissions/app_permissions.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/presentation/providers/rental_providers.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:cond_manager/shared/domain/enums/rental_property_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RentalPropertiesPage extends ConsumerWidget {
  const RentalPropertiesPage({super.key});

  static const _condoFilterWidth = 300.0;
  static const _filterFieldWidth = _condoFilterWidth / 2;

  RentalPropertyListFilter _sanitizeFilter(
    RentalPropertyListFilter filter,
    List<RentalProperty> properties,
  ) {
    final states = _distinctStates(properties);
    final cities = _distinctCities(properties, filter.addressState);
    final condos = _distinctCondominiums(properties, filter);

    var next = filter;
    if (next.addressState != null &&
        !states.any((s) => s.toLowerCase() == next.addressState!.trim().toLowerCase())) {
      next = next.copyWith(clearState: true, clearCity: true, clearCondominium: true);
    }
    if (next.addressCity != null &&
        !cities.any((c) => c.toLowerCase() == next.addressCity!.trim().toLowerCase())) {
      next = next.copyWith(clearCity: true, clearCondominium: true);
    }
    if (next.condominiumId != null && !condos.any((c) => c.id == next.condominiumId)) {
      next = next.copyWith(clearCondominium: true);
    }
    return next;
  }

  List<String> _distinctStates(List<RentalProperty> properties) {
    return properties
        .map((p) => p.effectiveAddressState?.trim())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));
  }

  List<String> _distinctCities(List<RentalProperty> properties, String? state) {
    return properties
        .where((p) {
          if (state == null) return true;
          return (p.effectiveAddressState ?? '').trim().toLowerCase() ==
              state.trim().toLowerCase();
        })
        .map((p) => p.effectiveAddressCity?.trim())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));
  }

  List<_CondoFilterOption> _distinctCondominiums(
    List<RentalProperty> properties,
    RentalPropertyListFilter filter,
  ) {
    final scoped = properties.where((p) {
      if (filter.addressState != null &&
          (p.effectiveAddressState ?? '').trim().toLowerCase() !=
              filter.addressState!.trim().toLowerCase()) {
        return false;
      }
      if (filter.addressCity != null &&
          (p.effectiveAddressCity ?? '').trim().toLowerCase() !=
              filter.addressCity!.trim().toLowerCase()) {
        return false;
      }
      return p.condominiumId != null && (p.condominiumName ?? '').trim().isNotEmpty;
    });

    final byId = <String, String>{};
    for (final p in scoped) {
      byId[p.condominiumId!] = p.condominiumName!.trim();
    }

    return byId.entries
        .map((e) => _CondoFilterOption(id: e.key, label: e.value))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  bool _hasActiveFilters(RentalPropertyListFilter filter) =>
      filter.propertyType != null ||
      filter.listingMode != null ||
      filter.addressState != null ||
      filter.addressCity != null ||
      filter.condominiumId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(rentalPropertyListFilterProvider);
    final propertiesAsync = ref.watch(rentalPropertiesListProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final canCreate = ref.watch(currentProfileProvider).value?.permissions.canManageRental ?? false;

    void updateFilter(RentalPropertyListFilter next) {
      ref.read(rentalPropertyListFilterProvider.notifier).state = next;
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Imóveis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Quartos, casas, apartamentos, prédios, salas, galpões e demais unidades locáveis.',
                    style: TextStyle(color: ClayTokens.textSecondary, fontSize: 13),
                  ),
                  propertiesAsync.maybeWhen(
                    data: (properties) {
                      if (properties.isEmpty) return const SizedBox.shrink();

                      final safeFilter = _sanitizeFilter(filter, properties);
                      if (safeFilter != filter) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          updateFilter(safeFilter);
                        });
                      }

                      final states = _distinctStates(properties);
                      final cities = _distinctCities(properties, safeFilter.addressState);
                      final condos = _distinctCondominiums(properties, safeFilter);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: _filterFieldWidth,
                                  child: ClayDropdownField<RentalPropertyType?>(
                                    label: 'Tipo',
                                    value: safeFilter.propertyType,
                                    items: [null, ...RentalPropertyType.values],
                                    itemLabel: (t) => t?.label ?? 'Todos',
                                    onChanged: (v) => updateFilter(
                                      safeFilter.copyWith(propertyType: v, clearType: v == null),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: _filterFieldWidth,
                                  child: ClayDropdownField<RentalListingMode?>(
                                    label: 'Modalidade',
                                    value: safeFilter.listingMode,
                                    items: [null, ...RentalListingMode.values],
                                    itemLabel: (m) => m?.label ?? 'Todas',
                                    onChanged: (v) => updateFilter(
                                      safeFilter.copyWith(listingMode: v, clearMode: v == null),
                                    ),
                                  ),
                                ),
                                if (states.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: _filterFieldWidth,
                                    child: ClayDropdownField<String?>(
                                      label: 'Estado',
                                      value: safeFilter.addressState != null &&
                                              states.any(
                                                (s) =>
                                                    s.toLowerCase() ==
                                                    safeFilter.addressState!.trim().toLowerCase(),
                                              )
                                          ? safeFilter.addressState
                                          : null,
                                      items: [null, ...states],
                                      itemLabel: (s) => s ?? 'Todos',
                                      onChanged: (v) => updateFilter(
                                        safeFilter.copyWith(
                                          addressState: v,
                                          clearState: v == null,
                                          clearCity: true,
                                          clearCondominium: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (cities.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: _filterFieldWidth,
                                    child: ClayDropdownField<String?>(
                                      label: 'Cidade',
                                      value: safeFilter.addressCity != null &&
                                              cities.any(
                                                (c) =>
                                                    c.toLowerCase() ==
                                                    safeFilter.addressCity!.trim().toLowerCase(),
                                              )
                                          ? safeFilter.addressCity
                                          : null,
                                      items: [null, ...cities],
                                      itemLabel: (c) => c ?? 'Todas',
                                      onChanged: (v) => updateFilter(
                                        safeFilter.copyWith(
                                          addressCity: v,
                                          clearCity: v == null,
                                          clearCondominium: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (condos.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: _condoFilterWidth,
                                    child: ClayDropdownField<String?>(
                                      label: 'Condomínio',
                                      value: condos.any((c) => c.id == safeFilter.condominiumId)
                                          ? safeFilter.condominiumId
                                          : null,
                                      items: [null, ...condos.map((c) => c.id)],
                                      itemLabel: (id) {
                                        if (id == null) return 'Todos';
                                        return condos.firstWhere((c) => c.id == id).label;
                                      },
                                      onChanged: (v) => updateFilter(
                                        safeFilter.copyWith(
                                          condominiumId: v,
                                          clearCondominium: v == null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (_hasActiveFilters(safeFilter)) ...[
                                  const SizedBox(width: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: TextButton.icon(
                                      onPressed: () => updateFilter(const RentalPropertyListFilter()),
                                      icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                                      label: const Text('Limpar'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: propertiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (properties) {
                  final safeFilter = _sanitizeFilter(filter, properties);
                  final filtered = properties
                      .where((p) => rentalPropertyMatchesFilter(p, safeFilter))
                      .toList();

                  if (properties.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Nenhum imóvel cadastrado.',
                            style: TextStyle(color: ClayTokens.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          if (canCreate) ...[
                            const SizedBox(height: 16),
                            ClayButton(
                              label: 'Novo imóvel',
                              expand: false,
                              icon: Icons.add_rounded,
                              onPressed: () => context.go('/rental/properties/new'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhum imóvel encontrado com os filtros selecionados.',
                        style: const TextStyle(color: ClayTokens.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(rentalPropertiesListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _PropertyTile(
                        property: filtered[i],
                        currency: currency,
                        onTap: () => context.go('/rental/properties/${filtered[i].id}/edit'),
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
              label: 'Novo imóvel',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () => context.go('/rental/properties/new'),
            ),
          ),
      ],
    );
  }
}

class _CondoFilterOption {
  const _CondoFilterOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _PropertyTile extends StatelessWidget {
  const _PropertyTile({
    required this.property,
    required this.currency,
    this.onTap,
  });

  final RentalProperty property;
  final NumberFormat currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rate = property.listingMode == RentalListingMode.daily ||
            property.listingMode == RentalListingMode.shortTerm ||
            property.listingMode == RentalListingMode.vacationRental
        ? property.baseDailyRate
        : property.baseRentAmount;

    return ClayListTileCard(
      icon: Icons.home_work_rounded,
      title: property.title,
      subtitle: [
        property.propertyType.label,
        property.listingMode.label,
        if (property.condominiumName != null) 'Condomínio: ${property.condominiumName}',
        property.locationLabel,
        if (property.ownerName != null) 'Proprietário: ${property.ownerName}',
        if (rate != null) currency.format(rate),
        if (property.status != 'active') 'Inativo',
      ].join(' · '),
      onTap: onTap,
    );
  }
}
