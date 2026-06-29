import 'package:cond_manager/core/errors/app_exception.dart';
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium_block.dart';
import 'package:cond_manager/features/condominiums/domain/repositories/condominium_block_repository.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CondominiumBlockRepositoryImpl implements CondominiumBlockRepository {
  CondominiumBlockRepositoryImpl(this._client);

  final SupabaseClient _client;

  CondominiumBlock _fromRow(Map<String, dynamic> row) {
    return CondominiumBlock(
      id: row['id'] as String,
      condominiumId: row['condominium_id'] as String,
      name: row['name'] as String,
      sortOrder: row['sort_order'] as int? ?? 0,
      status: EntityStatus.fromValue(row['status'] as String? ?? 'active'),
    );
  }

  @override
  Future<Result<List<CondominiumBlock>>> listByCondominium(String condominiumId) async {
    try {
      final data = await _client
          .from('blocks')
          .select()
          .eq('condominium_id', condominiumId)
          .eq('status', 'active')
          .order('sort_order')
          .order('name');

      final list = (data as List<dynamic>)
          .map((e) => _fromRow(e as Map<String, dynamic>))
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar blocos/torres: $e'));
    }
  }

  @override
  Future<Result<CondominiumBlock>> create(String condominiumId, CondominiumBlockInput input) async {
    try {
      final row = await _client
          .from('blocks')
          .insert({
            'condominium_id': condominiumId,
            'name': input.name.trim(),
            'sort_order': input.sortOrder,
            'status': 'active',
          })
          .select()
          .single();

      return Success(_fromRow(Map<String, dynamic>.from(row)));
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao cadastrar bloco/torre: $e'));
    }
  }

  @override
  Future<Result<CondominiumBlock>> update(String id, CondominiumBlockInput input) async {
    try {
      final row = await _client
          .from('blocks')
          .update({
            'name': input.name.trim(),
            'sort_order': input.sortOrder,
          })
          .eq('id', id)
          .select()
          .single();

      return Success(_fromRow(Map<String, dynamic>.from(row)));
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao atualizar bloco/torre: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _client.from('blocks').update({'status': 'inactive'}).eq('id', id);
      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao remover bloco/torre: $e'));
    }
  }

  AppException _mapPostgrestError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('permission') || e.code == '42501') {
      return const PermissionException('Sem permissão para gerenciar blocos/torres.');
    }
    if (msg.contains('duplicate') || e.code == '23505') {
      return const ValidationException('Já existe um bloco/torre com este nome.');
    }
    return NetworkException(e.message);
  }
}
