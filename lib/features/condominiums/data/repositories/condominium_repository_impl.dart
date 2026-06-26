import 'package:cond_manager/core/errors/app_exception.dart';
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/condominiums/data/models/condominium_model.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/condominiums/domain/repositories/condominium_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CondominiumRepositoryImpl implements CondominiumRepository {
  CondominiumRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<Condominium>>> list() async {
    try {
      final data = await _client
          .from('condominiums')
          .select()
          .eq('status', 'active')
          .order('name');

      final list = (data as List<dynamic>)
          .map((e) => CondominiumModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar condomínios: $e'));
    }
  }

  @override
  Future<Result<List<Condominium>>> listByIds(List<String> ids) async {
    if (ids.isEmpty) return const Success([]);

    try {
      final data = await _client
          .from('condominiums')
          .select()
          .inFilter('id', ids)
          .eq('status', 'active')
          .order('name');

      final list = (data as List<dynamic>)
          .map((e) => CondominiumModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar condomínios: $e'));
    }
  }

  @override
  Future<Result<Condominium>> getById(String id) async {
    try {
      final row = await _client.from('condominiums').select().eq('id', id).single();
      return Success(
        CondominiumModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar condomínio: $e'));
    }
  }

  @override
  Future<Result<Condominium>> update(String id, CondominiumCreateInput input) async {
    try {
      final model = CondominiumModel.fromCreateInput(input);
      final payload = model.toUpdateJson();

      final row = await _client
          .from('condominiums')
          .update(payload)
          .eq('id', id)
          .select()
          .single();

      return Success(
        CondominiumModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao atualizar condomínio: $e'));
    }
  }

  @override
  Future<Result<Condominium>> create(
    CondominiumCreateInput input, {
    String? managementCompanyId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      final model = CondominiumModel.fromCreateInput(input);
      final payload = model.toInsertJson(
        createdBy: userId,
        managementCompanyId: managementCompanyId,
      );

      _putIfNotEmpty(payload, 'complement', input.complement);
      _putIfNotEmpty(payload, 'manager_number', input.managerNumber);
      _putIfNotEmpty(payload, 'manager_complement', input.managerComplement);
      _putIfNotEmpty(payload, 'manager_neighborhood', input.managerNeighborhood);
      _putIfNotEmpty(payload, 'manager_zip_code', input.managerZipCode);

      final row = await _client.from('condominiums').insert(payload).select().single();

      final condominium = CondominiumModel.fromJson(row as Map<String, dynamic>).toEntity();

      if (userId != null) {
        await _client.from('user_condominium_roles').upsert({
          'user_id': userId,
          'condominium_id': condominium.id,
          'role': 'condominium_admin',
          'is_primary': true,
          'status': 'active',
          'accepted_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,condominium_id,role');
      }

      return Success(condominium);
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao cadastrar condomínio: $e'));
    }
  }

  void _putIfNotEmpty(Map<String, dynamic> map, String key, String? value) {
    final s = value?.trim();
    if (s != null && s.isNotEmpty) map[key] = s;
  }

  AppException _mapPostgrestError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('permission') || e.code == '42501') {
      return const PermissionException(
        'Sem permissão para cadastrar condomínios.',
      );
    }
    if (msg.contains('duplicate') || e.code == '23505') {
      return const ValidationException('Já existe um condomínio com estes dados.');
    }
    if (msg.contains('column') && msg.contains('does not exist')) {
      return const NetworkException(
        'Banco desatualizado. Execute supabase/apply_manager_fields.sql no Supabase.',
      );
    }
    return NetworkException(e.message);
  }
}
