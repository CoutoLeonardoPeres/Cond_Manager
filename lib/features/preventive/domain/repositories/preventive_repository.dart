import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/preventive/domain/entities/preventive_plan.dart';

abstract class PreventiveRepository {
  Future<Result<List<PreventivePlan>>> listPlans(PreventivePlanListFilter filter);

  Future<Result<PreventivePlan>> getPlan(String id);

  Future<Result<PreventivePlan>> createPlan(PreventivePlanCreateInput input);

  Future<Result<PreventivePlan>> updatePlan(String id, PreventivePlanUpdateInput input);

  Future<Result<List<PreventiveBacklogItem>>> listBacklog({String? condominiumId});

  Future<Result<PreventiveAgendaSyncResult>> syncAgenda({String? condominiumId});

  Future<Result<String>> generateWorkOrder(String executionId);

  Future<Result<void>> completeExecution(String executionId, {String? notes});

  Future<Result<void>> skipExecution(String executionId, {String? notes});
}
