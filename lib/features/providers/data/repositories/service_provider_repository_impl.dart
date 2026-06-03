import 'package:cond_manager/core/errors/app_exception.dart'
    show AppAuthException, AppException, NetworkException, PermissionException;
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/providers/data/models/service_provider_model.dart';
import 'package:cond_manager/features/providers/domain/entities/service_provider.dart';
import 'package:cond_manager/features/providers/domain/repositories/service_provider_repository.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceProviderRepositoryImpl implements ServiceProviderRepository {
  ServiceProviderRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<ServiceProvider>>> list(ServiceProviderListFilter filter) async {
    try {
      var query = _client.from('providers').select(ServiceProviderModel.selectWithCondo);

      if (filter.condominiumId != null) {
        query = query.eq('condominium_id', filter.condominiumId!);
      }
      if (filter.status != null) {
        query = query.eq('status', filter.status!.value);
      }
      if (filter.serviceType != null) {
        query = query.contains('specialties', [filter.serviceType!.value]);
      }

      final data = await query.order('legal_name');

      final list = (data as List<dynamic>)
          .map((e) => ServiceProviderModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar prestadores: $e'));
    }
  }

  @override
  Future<Result<ServiceProvider>> getById(String id) async {
    try {
      final row = await _client
          .from('providers')
          .select(ServiceProviderModel.selectWithCondo)
          .eq('id', id)
          .single();

      return Success(
        ServiceProviderModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar prestador: $e'));
    }
  }

  @override
  Future<Result<ServiceProvider>> create(ServiceProviderCreateInput input) async {
    try {
      if (_client.auth.currentUser == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      final payload = ServiceProviderModel.createPayload(input);
      final row = await _client
          .from('providers')
          .insert(payload)
          .select(ServiceProviderModel.selectWithCondo)
          .single();

      return Success(
        ServiceProviderModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao cadastrar prestador: $e'));
    }
  }

  @override
  Future<Result<ServiceProvider>> update(
    String id,
    ServiceProviderUpdateInput input,
  ) async {
    try {
      final payload = ServiceProviderModel.updatePayload(input);
      final row = await _client
          .from('providers')
          .update(payload)
          .eq('id', id)
          .select(ServiceProviderModel.selectWithCondo)
          .single();

      return Success(
        ServiceProviderModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao atualizar prestador: $e'));
    }
  }

  @override
  Future<Result<List<ProviderPickerOption>>> listForWorkOrder({
    required String condominiumId,
    ServiceType? serviceType,
  }) async {
    try {
      var query = _client
          .from('providers')
          .select('id, trade_name, legal_name, provider_type, specialties')
          .eq('condominium_id', condominiumId)
          .eq('status', EntityStatus.active.value);

      if (serviceType != null) {
        query = query.contains('specialties', [serviceType.value]);
      }

      final data = await query.order('legal_name');

      final list = (data as List<dynamic>).map((raw) {
        final map = raw as Map<String, dynamic>;
        final label = (map['trade_name'] as String?)?.trim().isNotEmpty == true
            ? map['trade_name'] as String
            : map['legal_name'] as String;
        final specs = ServiceProviderModel.parseSpecialties(map['specialties'])
            .map(ServiceType.fromValue)
            .toList();
        return ProviderPickerOption(
          id: map['id'] as String,
          label: label,
          providerType: map['provider_type'] as String,
          specialties: specs,
        );
      }).toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar prestadores: $e'));
    }
  }

  AppException _mapError(PostgrestException e) {
    if (e.code == '42501' || e.message.contains('permission')) {
      return PermissionException(e.message);
    }
    return NetworkException(e.message);
  }
}
