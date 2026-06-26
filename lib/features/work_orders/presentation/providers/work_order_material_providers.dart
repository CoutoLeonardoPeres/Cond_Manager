import 'package:cond_manager/features/materials/domain/entities/material.dart' as mat;
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order_material.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/material_item_type.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final workOrderMaterialsProvider =
    FutureProvider.autoDispose.family<WorkOrderMaterialsTotals, String>(
  (ref, workOrderId) async {
    final repo = ref.watch(workOrderRepositoryProvider);
    final result = await repo.listMaterials(workOrderId);
    return result.when(
      success: (t) => t,
      failure: (e) => throw e,
    );
  },
);

class WorkOrderAvailableMaterialsQuery extends Equatable {
  const WorkOrderAvailableMaterialsQuery({
    required this.condominiumId,
    required this.serviceType,
    this.itemType,
  });

  final String condominiumId;
  final ServiceType serviceType;
  final MaterialItemType? itemType;

  @override
  List<Object?> get props => [condominiumId, serviceType, itemType];
}

final workOrderAvailableMaterialsProvider = FutureProvider.autoDispose
    .family<List<mat.Material>, WorkOrderAvailableMaterialsQuery>((ref, query) async {
  final repo = ref.watch(materialRepositoryProvider);
  final result = await repo.list(
    mat.MaterialListFilter(
      condominiumId: query.condominiumId,
      status: EntityStatus.active,
    ),
  );
  final all = result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
  return all.where((m) {
    if (query.itemType != null && m.itemType != query.itemType) return false;
    if (m.applicableServices.isEmpty) return true;
    return m.applicableServices.contains(query.serviceType);
  }).toList();
});
