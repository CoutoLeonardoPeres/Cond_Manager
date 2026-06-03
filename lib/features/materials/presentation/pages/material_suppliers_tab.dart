import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/presentation/providers/condominium_providers.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_supplier_providers.dart';
import 'package:cond_manager/features/materials/presentation/utils/material_permissions.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MaterialSuppliersTab extends ConsumerWidget {
  const MaterialSuppliersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(materialSuppliersListProvider);
    final filter = ref.watch(materialSupplierListFilterProvider);
    final materialFilter = ref.watch(materialListFilterProvider);
    final condosAsync = ref.watch(accessibleCondominiumsProvider);
    final profile = ref.watch(currentProfileProvider).value;
    final canCreate = profile != null && profile.canCreateMaterial;

    if (filter.condominiumId != materialFilter.condominiumId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(materialSupplierListFilterProvider.notifier).state = filter.copyWith(
          condominiumId: materialFilter.condominiumId,
          clearCondominium: materialFilter.condominiumId == null,
        );
      });
    }

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  condosAsync.when(
                    data: (condos) {
                      if (condos.isEmpty) return const SizedBox.shrink();
                      Condominium? selected;
                      if (filter.condominiumId != null) {
                        for (final c in condos) {
                          if (c.id == filter.condominiumId) selected = c;
                        }
                      }
                      return ClayDropdownField<Condominium?>(
                        label: 'Condomínio',
                        value: selected,
                        items: [null, ...condos],
                        itemLabel: (c) => c?.name ?? 'Todos',
                        onChanged: (v) {
                          ref.read(materialSupplierListFilterProvider.notifier).state =
                              filter.copyWith(
                            condominiumId: v?.id,
                            clearCondominium: v == null,
                          );
                          ref.read(materialListFilterProvider.notifier).state =
                              materialFilter.copyWith(
                            condominiumId: v?.id,
                            clearCondominium: v == null,
                          );
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 8),
                  ClayDropdownField<ServiceType?>(
                    label: 'Tipo de material/serviço',
                    value: filter.serviceType,
                    items: [null, ...ServiceType.values],
                    itemLabel: (t) => t?.label ?? 'Todos',
                    onChanged: (v) {
                      ref.read(materialSupplierListFilterProvider.notifier).state =
                          filter.copyWith(serviceType: v, clearServiceType: v == null);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: suppliersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                error: (e, _) => Center(child: Text('$e')),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum fornecedor de materiais cadastrado.',
                        style: TextStyle(color: ClayTokens.textSecondary),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(materialSuppliersListProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, canCreate ? 88 : 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final s = items[index];
                        final canEdit = profile != null &&
                            profile.canManageMaterialsIn(s.condominiumId);
                        return ClayListTileCard(
                          icon: Icons.local_shipping_rounded,
                          iconColor: ClayTokens.primary,
                          title: s.displayName,
                          subtitle: [
                            s.specialtiesLabel,
                            '${s.materialCount} material(is)',
                            s.materialsPreview,
                          ].join(' · '),
                          onTap: canEdit
                              ? () => context.go('/materials/suppliers/${s.id}/edit')
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
              label: 'Novo fornecedor',
              expand: false,
              icon: Icons.add_rounded,
              onPressed: () => context.go(
                Uri(
                  path: '/materials/suppliers/new',
                  queryParameters: {
                    if (filter.condominiumId != null)
                      'condominiumId': filter.condominiumId!,
                  },
                ).toString(),
              ),
            ),
          ),
      ],
    );
  }
}
