import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium_block.dart';

abstract interface class CondominiumBlockRepository {
  Future<Result<List<CondominiumBlock>>> listByCondominium(String condominiumId);

  Future<Result<CondominiumBlock>> create(String condominiumId, CondominiumBlockInput input);

  Future<Result<CondominiumBlock>> update(String id, CondominiumBlockInput input);

  Future<Result<void>> delete(String id);
}
