import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:cond_manager/features/condominiums/data/repositories/condominium_block_repository_impl.dart';
import 'package:cond_manager/features/condominiums/data/repositories/condominium_repository_impl.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium_block.dart';
import 'package:cond_manager/features/condominiums/domain/repositories/condominium_block_repository.dart';
import 'package:cond_manager/features/condominiums/domain/repositories/condominium_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final condominiumRepositoryProvider = Provider<CondominiumRepository>((ref) {
  return CondominiumRepositoryImpl(ref.watch(supabaseClientProvider));
});

final condominiumBlockRepositoryProvider = Provider<CondominiumBlockRepository>((ref) {
  return CondominiumBlockRepositoryImpl(ref.watch(supabaseClientProvider));
});

final condominiumBlocksProvider =
    FutureProvider.autoDispose.family<List<CondominiumBlock>, String>((ref, condominiumId) async {
  final result = await ref.watch(condominiumBlockRepositoryProvider).listByCondominium(condominiumId);
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});

final condominiumsListProvider = FutureProvider.autoDispose<List<Condominium>>((ref) async {
  return _loadAccessibleCondominiums(ref);
});

final condominiumListFilterProvider =
    StateProvider.autoDispose<CondominiumListFilter>((ref) => const CondominiumListFilter());

final condominiumDetailProvider =
    FutureProvider.autoDispose.family<Condominium, String>((ref, id) async {
  final repo = ref.watch(condominiumRepositoryProvider);
  final result = await repo.getById(id);
  return result.when(
    success: (c) => c,
    failure: (e) => throw e,
  );
});

/// Condomínios que o usuário pode usar em formulários (lista geral + vínculos do perfil).
final accessibleCondominiumsProvider = FutureProvider.autoDispose<List<Condominium>>((ref) async {
  return _loadAccessibleCondominiums(ref);
});

Future<List<Condominium>> _loadAccessibleCondominiums(Ref ref) async {
  final repo = ref.watch(condominiumRepositoryProvider);
  final listResult = await repo.list();
  var list = listResult.when(
    success: (items) => items,
    failure: (e) => throw e,
  );

  if (list.isNotEmpty) return list;

  final profile = ref.watch(currentProfileProvider).value;
  final roleIds = profile?.condominiumRoles
          .where((r) => r.status == 'active')
          .map((r) => r.condominiumId)
          .toSet()
          .toList() ??
      [];

  if (roleIds.isEmpty) return list;

  final byIdsResult = await repo.listByIds(roleIds);
  return byIdsResult.when(
    success: (items) => items,
    failure: (e) => throw e,
  );
}
