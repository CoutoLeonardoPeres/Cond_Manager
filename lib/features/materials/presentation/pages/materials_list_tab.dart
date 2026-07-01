import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/materials/domain/entities/material.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/features/materials/presentation/utils/material_permissions.dart';
import 'package:cond_manager/shared/domain/enums/material_item_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:cond_manager/shared/widgets/form/responsive_filter_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MaterialsListTab extends ConsumerWidget {
  const MaterialsListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsListProvider);
    final filter = ref.watch(materialListFilterProvider);
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final profile = ref.watch(currentProfileProvider).value;
    final canCreate = profile != null && profile.canCreateMaterial;
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return Stack(
      children: [
        Column(
          children: [
            _FiltersBar(
              filter: filter,
              condosAsync: condosAsync,
              onFilterChanged: (f) =>
                  ref.read(materialListFilterProvider.notifier).state = f,
            ),
            Expanded(
              child: materialsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum material cadastrado.',
                        style: TextStyle(color: ClayTokens.textSecondary),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(materialsListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final m = items[index];
                        final canEdit = profile != null &&
                            profile.canManageMaterialsIn(m.condominiumId);
                        return ClayListTileCard(
                          icon: m.itemType == MaterialItemType.equipment
                              ? Icons.precision_manufacturing_rounded
                              : Icons.inventory_2_rounded,
                          iconColor: m.isLowStock ? ClayTokens.warning : ClayTokens.primary,
                          title: m.name,
                          subtitle: [
                            m.itemType.label,
                            if (m.suppliersLabel != null) m.suppliersLabel!,
                            if (m.isStorable)
                              'Estoque: ${m.currentStock} ${m.unitOfMeasureLabel}',
                            'Repasse: ${currency.format(m.resaleUnitPriceWithTax)}',
                          ].join(' · '),
                          onTap: canEdit
                              ? () => context.go('/materials/${m.id}')
                              : () => context.go('/materials/${m.id}'),
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
              label: 'Novo item',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () {
                final condoId = ref.read(materialListFilterProvider).condominiumId;
                final uri = Uri(
                  path: '/materials/new',
                  queryParameters: condoId != null ? {'condominiumId': condoId} : null,
                );
                context.go(uri.toString());
              },
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

  final MaterialListFilter filter;
  final AsyncValue<List<Condominium>> condosAsync;
  final void Function(MaterialListFilter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: condosAsync.when(
        data: (condos) {
          final condoItems = [
            const _CondoOpt(id: null, label: 'Todos'),
            ...condos.map((c) => _CondoOpt(id: c.id, label: c.name)),
          ];
          final selectedCondo = condoItems.firstWhere(
            (o) => o.id == filter.condominiumId,
            orElse: () => condoItems.first,
          );

          final fields = <Widget>[
            if (condos.isNotEmpty)
              ClayDropdownField<_CondoOpt>(
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
              label: 'Serviço',
              value: filter.serviceType,
              items: [null, ...ServiceType.values],
              itemLabel: (v) => v?.label ?? 'Todos',
              onChanged: (v) => onFilterChanged(
                filter.copyWith(
                  serviceType: v,
                  clearServiceType: v == null,
                ),
              ),
            ),
            ClayDropdownField<MaterialItemType?>(
              label: 'Tipo',
              value: filter.itemType,
              items: [null, ...MaterialItemType.values],
              itemLabel: (v) => v?.label ?? 'Todos',
              onChanged: (v) => onFilterChanged(
                filter.copyWith(itemType: v, clearItemType: v == null),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Somente estoque baixo', style: TextStyle(fontSize: 13)),
              value: filter.lowStockOnly,
              onChanged: (v) => onFilterChanged(filter.copyWith(lowStockOnly: v)),
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

class _CondoOpt {
  const _CondoOpt({required this.id, required this.label});
  final String? id;
  final String label;
}
