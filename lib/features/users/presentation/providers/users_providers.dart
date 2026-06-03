import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/users/data/repositories/users_repository_impl.dart';
import 'package:cond_manager/features/users/domain/entities/organization_user.dart';
import 'package:cond_manager/features/users/domain/repositories/users_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepositoryImpl(ref.watch(supabaseClientProvider));
});

final organizationUserListFilterProvider = StateProvider<OrganizationUserListFilter>(
  (ref) => const OrganizationUserListFilter(),
);

final managementCompaniesProvider = FutureProvider.autoDispose<List<ManagementCompany>>((ref) async {
  final repo = ref.watch(usersRepositoryProvider);
  final result = await repo.listCompanies();
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final organizationUsersListProvider =
    FutureProvider.autoDispose<List<OrganizationUser>>((ref) async {
  final filter = ref.watch(organizationUserListFilterProvider);
  final repo = ref.watch(usersRepositoryProvider);
  final result = await repo.listUsers(filter);
  return result.when(success: (l) => l, failure: (e) => throw e);
});

final organizationUserDetailProvider =
    FutureProvider.autoDispose.family<OrganizationUser, String>((ref, id) async {
  final repo = ref.watch(usersRepositoryProvider);
  final result = await repo.getUser(id);
  return result.when(success: (u) => u, failure: (e) => throw e);
});
