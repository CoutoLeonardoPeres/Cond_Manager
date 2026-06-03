import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';

abstract interface class CondominiumRepository {
  Future<Result<List<Condominium>>> list();

  Future<Result<List<Condominium>>> listByIds(List<String> ids);

  Future<Result<Condominium>> getById(String id);

  Future<Result<Condominium>> create(CondominiumCreateInput input);

  Future<Result<Condominium>> update(String id, CondominiumCreateInput input);
}
