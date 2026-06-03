import 'package:cond_manager/features/materials/domain/entities/material_supplier.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final materialSupplierListFilterProvider = StateProvider<MaterialSupplierListFilter>(
  (ref) => const MaterialSupplierListFilter(),
);

final materialSuppliersListProvider =
    FutureProvider.autoDispose<List<MaterialSupplierListItem>>((ref) async {
  final filter = ref.watch(materialSupplierListFilterProvider);
  final repo = ref.watch(materialRepositoryProvider);
  final result = await repo.listMaterialSuppliers(filter);
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});

final materialSupplierDetailProvider =
    FutureProvider.autoDispose.family<MaterialSupplierDetail, String>((ref, id) async {
  final repo = ref.watch(materialRepositoryProvider);
  final result = await repo.getMaterialSupplier(id);
  return result.when(
    success: (d) => d,
    failure: (e) => throw e,
  );
});
