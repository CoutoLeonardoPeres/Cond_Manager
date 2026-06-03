import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/materials/data/repositories/material_repository_impl.dart';
import 'package:cond_manager/features/materials/domain/entities/material.dart';
import 'package:cond_manager/features/materials/domain/repositories/material_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final materialRepositoryProvider = Provider<MaterialRepository>((ref) {
  return MaterialRepositoryImpl(ref.watch(supabaseClientProvider));
});

final materialListFilterProvider = StateProvider<MaterialListFilter>(
  (ref) => const MaterialListFilter(),
);

final materialsListProvider = FutureProvider.autoDispose<List<Material>>((ref) async {
  final filter = ref.watch(materialListFilterProvider);
  final repo = ref.watch(materialRepositoryProvider);
  final result = await repo.list(filter);
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});

final materialDetailProvider =
    FutureProvider.autoDispose.family<Material, String>((ref, id) async {
  final repo = ref.watch(materialRepositoryProvider);
  final result = await repo.getById(id);
  return result.when(
    success: (m) => m,
    failure: (e) => throw e,
  );
});

final materialCategoriesProvider =
    FutureProvider.autoDispose.family<List<MaterialCategory>, String>(
  (ref, condominiumId) async {
    final repo = ref.watch(materialRepositoryProvider);
    final result = await repo.listCategories(condominiumId);
    return result.when(
      success: (list) => list,
      failure: (e) => throw e,
    );
  },
);

final materialSuppliersProvider =
    FutureProvider.autoDispose.family<List<ProviderPickerForMaterial>, String>(
  (ref, condominiumId) async {
    final repo = ref.watch(materialRepositoryProvider);
    final result = await repo.listSuppliers(condominiumId);
    return result.when(
      success: (list) => list,
      failure: (e) => throw e,
    );
  },
);

final materialsForCondominiumProvider =
    FutureProvider.autoDispose.family<List<Material>, String>(
  (ref, condominiumId) async {
    final repo = ref.watch(materialRepositoryProvider);
    final result = await repo.list(MaterialListFilter(condominiumId: condominiumId));
    return result.when(
      success: (list) => list,
      failure: (e) => throw e,
    );
  },
);

final materialStockMovementsProvider =
    FutureProvider.autoDispose.family<List<StockMovement>, String>(
  (ref, materialId) async {
    final repo = ref.watch(materialRepositoryProvider);
    final result = await repo.listStockMovements(materialId);
    return result.when(
      success: (list) => list,
      failure: (e) => throw e,
    );
  },
);

final materialBalanceSummaryProvider =
    FutureProvider.autoDispose.family<MaterialBalanceSummary, String?>(
  (ref, condominiumId) async {
    final repo = ref.watch(materialRepositoryProvider);
    final result = await repo.balanceSummary(condominiumId: condominiumId);
    return result.when(
      success: (s) => s,
      failure: (e) => throw e,
    );
  },
);
