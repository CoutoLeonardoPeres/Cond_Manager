import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/preventive/data/repositories/preventive_repository_impl.dart';
import 'package:cond_manager/features/preventive/domain/entities/preventive_plan.dart';
import 'package:cond_manager/features/preventive/domain/repositories/preventive_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final preventiveRepositoryProvider = Provider<PreventiveRepository>((ref) {
  return PreventiveRepositoryImpl(ref.watch(supabaseClientProvider));
});

final preventivePlanListFilterProvider = StateProvider<PreventivePlanListFilter>(
  (ref) => const PreventivePlanListFilter(),
);

final preventivePlansListProvider =
    FutureProvider.autoDispose<List<PreventivePlan>>((ref) async {
  final filter = ref.watch(preventivePlanListFilterProvider);
  final repo = ref.watch(preventiveRepositoryProvider);
  final result = await repo.listPlans(filter);
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});

final preventivePlanDetailProvider =
    FutureProvider.autoDispose.family<PreventivePlan, String>((ref, id) async {
  final repo = ref.watch(preventiveRepositoryProvider);
  final result = await repo.getPlan(id);
  return result.when(
    success: (p) => p,
    failure: (e) => throw e,
  );
});

final preventiveBacklogProvider =
    FutureProvider.autoDispose.family<List<PreventiveBacklogItem>, String?>(
  (ref, condominiumId) async {
    final repo = ref.watch(preventiveRepositoryProvider);
    final result = await repo.listBacklog(condominiumId: condominiumId);
    return result.when(
      success: (list) => list,
      failure: (e) => throw e,
    );
  },
);

final preventiveBacklogCountProvider =
    FutureProvider.autoDispose.family<int, String?>((ref, condominiumId) async {
  final list = await ref.watch(preventiveBacklogProvider(condominiumId).future);
  return list.length;
});
