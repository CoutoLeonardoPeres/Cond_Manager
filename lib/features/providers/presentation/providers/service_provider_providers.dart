import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/providers/data/repositories/service_provider_repository_impl.dart';
import 'package:cond_manager/features/providers/domain/entities/service_provider.dart';
import 'package:cond_manager/features/providers/domain/repositories/service_provider_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceProviderRepositoryProvider = Provider<ServiceProviderRepository>((ref) {
  return ServiceProviderRepositoryImpl(ref.watch(supabaseClientProvider));
});

final serviceProviderListFilterProvider = StateProvider<ServiceProviderListFilter>(
  (ref) => const ServiceProviderListFilter(),
);

final serviceProvidersListProvider =
    FutureProvider.autoDispose<List<ServiceProvider>>((ref) async {
  final filter = ref.watch(serviceProviderListFilterProvider);
  final repo = ref.watch(serviceProviderRepositoryProvider);
  final result = await repo.list(filter);
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});

final serviceProviderDetailProvider =
    FutureProvider.autoDispose.family<ServiceProvider, String>((ref, id) async {
  final repo = ref.watch(serviceProviderRepositoryProvider);
  final result = await repo.getById(id);
  return result.when(
    success: (p) => p,
    failure: (e) => throw e,
  );
});

final workOrderProviderPickerProvider = FutureProvider.autoDispose
    .family<List<ProviderPickerOption>, ProviderPickerQuery>((ref, query) async {
  final repo = ref.watch(serviceProviderRepositoryProvider);
  final result = await repo.listForWorkOrder(
    condominiumId: query.condominiumId,
    serviceType: query.serviceType,
  );
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});
