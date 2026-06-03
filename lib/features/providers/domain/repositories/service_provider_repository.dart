import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/providers/domain/entities/service_provider.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';

abstract class ServiceProviderRepository {
  Future<Result<List<ServiceProvider>>> list(ServiceProviderListFilter filter);

  Future<Result<ServiceProvider>> getById(String id);

  Future<Result<ServiceProvider>> create(ServiceProviderCreateInput input);

  Future<Result<ServiceProvider>> update(String id, ServiceProviderUpdateInput input);

  Future<Result<List<ProviderPickerOption>>> listForWorkOrder({
    required String condominiumId,
    ServiceType? serviceType,
  });
}
