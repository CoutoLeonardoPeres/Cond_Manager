import 'package:cond_manager/core/errors/app_exception.dart'
    show AppAuthException, AppException, NetworkException, PermissionException;
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/preventive/data/models/preventive_plan_model.dart';
import 'package:cond_manager/features/preventive/domain/entities/preventive_plan.dart';
import 'package:cond_manager/features/preventive/domain/repositories/preventive_repository.dart';
import 'package:cond_manager/features/preventive/utils/preventive_schedule.dart';
import 'package:cond_manager/features/work_orders/data/models/work_order_model.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/location_type.dart';
import 'package:cond_manager/shared/domain/enums/preventive_execution_status.dart';
import 'package:cond_manager/shared/domain/enums/preventive_frequency.dart';
import 'package:cond_manager/shared/domain/enums/priority_level.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';
import 'package:cond_manager/shared/domain/enums/work_order_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PreventiveRepositoryImpl implements PreventiveRepository {
  PreventiveRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<PreventivePlan>>> listPlans(PreventivePlanListFilter filter) async {
    try {
      var query = _client.from('preventive_plans').select(PreventivePlanModel.planSelect);

      if (filter.condominiumId != null) {
        query = query.eq('condominium_id', filter.condominiumId!);
      }
      if (filter.status != null) {
        query = query.eq('status', filter.status!.value);
      }

      final data = await query.order('next_due_date');

      final list = <PreventivePlan>[];
      for (final raw in data as List<dynamic>) {
        final map = raw as Map<String, dynamic>;
        final checklist = await _loadChecklist(map['id'] as String);
        list.add(
          PreventivePlanModel.fromJson(map, checklist: checklist).toEntity(),
        );
      }

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar planos: $e'));
    }
  }

  @override
  Future<Result<PreventivePlan>> getPlan(String id) async {
    try {
      final row = await _client
          .from('preventive_plans')
          .select(PreventivePlanModel.planSelect)
          .eq('id', id)
          .single();

      final checklist = await _loadChecklist(id);
      return Success(
        PreventivePlanModel.fromJson(row as Map<String, dynamic>, checklist: checklist)
            .toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar plano: $e'));
    }
  }

  @override
  Future<Result<PreventivePlan>> createPlan(PreventivePlanCreateInput input) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      if (input.responsibleId != null && input.providerId != null) {
        return const Failure(
          NetworkException('Informe apenas equipe interna ou prestador.'),
        );
      }

      final nextDue = PreventiveSchedule.initialNextDue(
        input.startDate,
        input.frequency,
      );

      final row = await _client
          .from('preventive_plans')
          .insert(
            PreventivePlanModel.createPayload(
              input,
              createdBy: userId,
              nextDueDate: nextDue,
            ),
          )
          .select(PreventivePlanModel.planSelect)
          .single();

      final planId = row['id'] as String;
      await _saveChecklist(planId, input.checklistItems);

      return getPlan(planId);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao criar plano: $e'));
    }
  }

  @override
  Future<Result<PreventivePlan>> updatePlan(
    String id,
    PreventivePlanUpdateInput input,
  ) async {
    try {
      if (input.responsibleId != null && input.providerId != null) {
        return const Failure(
          NetworkException('Informe apenas equipe interna ou prestador.'),
        );
      }

      await _client
          .from('preventive_plans')
          .update(PreventivePlanModel.updatePayload(input))
          .eq('id', id);

      await _client.from('preventive_checklist_items').delete().eq('plan_id', id);
      await _saveChecklist(id, input.checklistItems);

      return getPlan(id);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao atualizar plano: $e'));
    }
  }

  @override
  Future<Result<List<PreventiveBacklogItem>>> listBacklog({
    String? condominiumId,
  }) async {
    try {
      final data = await _client
          .from('preventive_executions')
          .select('''
            *,
            preventive_plans!inner (
              id, name, condominium_id, service_type, lead_time_days,
              auto_generate_os, responsible_id, provider_id,
              condominiums ( name ),
              responsible:profiles!preventive_plans_responsible_id_fkey ( full_name ),
              provider:providers ( trade_name, legal_name )
            ),
            work_orders ( os_number )
          ''')
          .inFilter('status', ['pending', 'overdue'])
          .order('scheduled_date');

      final items = <PreventiveBacklogItem>[];
      for (final raw in data as List<dynamic>) {
        final item = _backlogFromJson(raw as Map<String, dynamic>);
        if (condominiumId != null && item.condominiumId != condominiumId) continue;
        items.add(item);
      }

      return Success(items);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar backlog: $e'));
    }
  }

  @override
  Future<Result<PreventiveAgendaSyncResult>> syncAgenda({String? condominiumId}) async {
    try {
      var query = _client
          .from('preventive_plans')
          .select(PreventivePlanModel.planSelect)
          .eq('status', EntityStatus.active.value);

      if (condominiumId != null) {
        query = query.eq('condominium_id', condominiumId);
      }

      final plansData = await query;
      final today = PreventiveSchedule.todayLocal();
      var executionsCreated = 0;
      var workOrdersCreated = 0;
      var notificationsCreated = 0;

      for (final raw in plansData as List<dynamic>) {
        final map = raw as Map<String, dynamic>;
        final plan = PreventivePlanModel.fromJson(map);
        final nextDue = PreventiveSchedule.dateOnly(plan.nextDueDate);

        if (!PreventiveSchedule.shouldAppearInBacklog(nextDue, plan.leadTimeDays, today)) {
          continue;
        }

        final status = PreventiveSchedule.isOverdue(nextDue, today)
            ? PreventiveExecutionStatus.overdue
            : PreventiveExecutionStatus.pending;

        final scheduledStr = _dateStr(nextDue);
        var executionId = await _findExecutionId(plan.id, scheduledStr);

        if (executionId == null) {
          final ins = await _client
              .from('preventive_executions')
              .insert({
                'plan_id': plan.id,
                'scheduled_date': scheduledStr,
                'status': status.value,
              })
              .select('id')
              .single();
          executionId = ins['id'] as String;
          executionsCreated++;
        } else {
          await _client
              .from('preventive_executions')
              .update({'status': status.value})
              .eq('id', executionId);
        }

        final execRow = await _client
            .from('preventive_executions')
            .select('work_order_id')
            .eq('id', executionId)
            .single();

        final existingWoId = execRow['work_order_id'] as String?;

        if (plan.autoGenerateOs && existingWoId == null) {
          final woResult = await _createWorkOrderForPlan(plan, nextDue, executionId);
          if (woResult != null) workOrdersCreated++;
        }

        notificationsCreated += await _notifyPlanStakeholders(plan, executionId, nextDue);
      }

      return Success(
        PreventiveAgendaSyncResult(
          executionsCreated: executionsCreated,
          workOrdersCreated: workOrdersCreated,
          notificationsCreated: notificationsCreated,
        ),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao processar agenda: $e'));
    }
  }

  @override
  Future<Result<String>> generateWorkOrder(String executionId) async {
    try {
      final exec = await _client
          .from('preventive_executions')
          .select('*, plan:preventive_plans(*)')
          .eq('id', executionId)
          .single();

      final map = exec as Map<String, dynamic>;
      if (map['work_order_id'] != null) {
        return Success(map['work_order_id'] as String);
      }

      final planMap = map['plan'] as Map<String, dynamic>;
      final plan = PreventivePlanModel.fromJson(planMap);
      final scheduled = DateTime.parse(map['scheduled_date'] as String);
      final woId = await _createWorkOrderForPlan(plan, scheduled, executionId);
      if (woId == null) {
        return const Failure(NetworkException('Não foi possível gerar a OS.'));
      }
      return Success(woId);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao gerar OS: $e'));
    }
  }

  @override
  Future<Result<void>> completeExecution(String executionId, {String? notes}) async {
    return _finishExecution(executionId, PreventiveExecutionStatus.completed, notes);
  }

  @override
  Future<Result<void>> skipExecution(String executionId, {String? notes}) async {
    return _finishExecution(executionId, PreventiveExecutionStatus.skipped, notes);
  }

  Future<Result<void>> _finishExecution(
    String executionId,
    PreventiveExecutionStatus status,
    String? notes,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      final exec = await _client
          .from('preventive_executions')
          .select('*, plan:preventive_plans(*)')
          .eq('id', executionId)
          .single();

      final map = exec as Map<String, dynamic>;
      final planMap = map['plan'] as Map<String, dynamic>;
      final plan = PreventivePlanModel.fromJson(planMap);
      final scheduled = DateTime.parse(map['scheduled_date'] as String);
      final nextDue = PreventiveSchedule.advanceDue(
        scheduled,
        PreventiveFrequency.fromValue(plan.frequency),
      );

      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('preventive_executions').update({
        'status': status.value,
        'executed_at': status == PreventiveExecutionStatus.completed ? now : null,
        'executed_by': userId,
        'notes': notes?.trim(),
      }).eq('id', executionId);

      await _client.from('preventive_plans').update({
        'last_executed_at': now,
        'next_due_date': _dateStr(nextDue),
      }).eq('id', plan.id);

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao atualizar execução: $e'));
    }
  }

  Future<String?> _createWorkOrderForPlan(
    PreventivePlanModel plan,
    DateTime dueDate,
    String executionId,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final checklist = await _loadChecklist(plan.id);
    final checklistText = checklist.isEmpty
        ? ''
        : '\n\nChecklist:\n${checklist.map((c) => '• ${c.description}').join('\n')}';

    final locationType = plan.unitId != null
        ? LocationType.unit
        : plan.commonAreaId != null
            ? LocationType.commonArea
            : LocationType.other;

    final input = WorkOrderCreateInput(
      condominiumId: plan.condominiumId,
      title: 'Preventiva: ${plan.name}',
      description: (plan.description ?? 'Manutenção preventiva agendada.') + checklistText,
      serviceType: ServiceType.fromValue(plan.serviceType),
      priority: PriorityLevel.medium,
      locationType: locationType,
      internalResponsibleId: plan.responsibleId,
      providerId: plan.providerId,
      unitId: plan.unitId,
      commonAreaId: plan.commonAreaId,
      dueDate: dueDate,
      requesterId: userId,
    );

    final payload = WorkOrderModel.createPayload(input, createdBy: userId);
    payload['status'] = WorkOrderStatus.open.value;

    final woRow = await _client
        .from('work_orders')
        .insert(payload)
        .select('id')
        .single();

    final woId = woRow['id'] as String;

    await _client.from('preventive_executions').update({
      'work_order_id': woId,
      'status': PreventiveExecutionStatus.pending.value,
    }).eq('id', executionId);

    return woId;
  }

  Future<int> _notifyPlanStakeholders(
    PreventivePlanModel plan,
    String executionId,
    DateTime dueDate,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final targets = <String>{userId};
    if (plan.responsibleId != null) targets.add(plan.responsibleId!);

    var count = 0;
    final dueLabel = _dateStr(dueDate);
    for (final uid in targets) {
      try {
        await _client.from('notifications').insert({
          'user_id': uid,
          'condominium_id': plan.condominiumId,
          'title': 'Preventiva: ${plan.name}',
          'body': 'Manutenção preventiva prevista para $dueLabel. Verifique o backlog.',
          'reference_type': 'preventive_execution',
          'reference_id': executionId,
        });
        count++;
      } catch (_) {
        // RLS pode bloquear notificação para outros usuários
      }
    }
    return count;
  }

  Future<String?> _findExecutionId(String planId, String scheduledDate) async {
    final row = await _client
        .from('preventive_executions')
        .select('id')
        .eq('plan_id', planId)
        .eq('scheduled_date', scheduledDate)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<List<PreventiveChecklistItem>> _loadChecklist(String planId) async {
    final data = await _client
        .from('preventive_checklist_items')
        .select()
        .eq('plan_id', planId)
        .order('sort_order');

    return (data as List<dynamic>)
        .map((e) => PreventiveChecklistItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveChecklist(
    String planId,
    List<PreventiveChecklistItemInput> items,
  ) async {
    if (items.isEmpty) return;
    final payload = items
        .asMap()
        .entries
        .map(
          (e) => {
            'plan_id': planId,
            'description': e.value.description.trim(),
            'is_required': e.value.isRequired,
            'sort_order': e.value.sortOrder != 0 ? e.value.sortOrder : e.key,
          },
        )
        .toList();
    await _client.from('preventive_checklist_items').insert(payload);
  }

  PreventiveBacklogItem _backlogFromJson(Map<String, dynamic> json) {
    final plan = json['preventive_plans'] as Map<String, dynamic>;
    String? condoName;
    final condo = plan['condominiums'];
    if (condo is Map<String, dynamic>) condoName = condo['name'] as String?;

    String? assignee;
    final resp = plan['responsible'];
    if (resp is Map<String, dynamic>) assignee = resp['full_name'] as String?;
    final prov = plan['provider'];
    if (prov is Map<String, dynamic>) {
      assignee = (prov['trade_name'] as String?) ?? prov['legal_name'] as String?;
    }

    int? osNumber;
    final woId = json['work_order_id'] as String?;
    final wo = json['work_orders'];
    if (wo is Map<String, dynamic>) {
      osNumber = wo['os_number'] as int?;
    }

    return PreventiveBacklogItem(
      id: json['id'] as String,
      planId: plan['id'] as String,
      planName: plan['name'] as String,
      condominiumId: plan['condominium_id'] as String,
      condominiumName: condoName,
      serviceType: ServiceType.fromValue(plan['service_type'] as String),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      status: PreventiveExecutionStatus.fromValue(json['status'] as String),
      workOrderId: woId,
      osNumber: osNumber,
      assigneeLabel: assignee,
      autoGenerateOs: plan['auto_generate_os'] as bool? ?? true,
      leadTimeDays: plan['lead_time_days'] as int? ?? 7,
    );
  }

  static String _dateStr(DateTime d) {
    final x = DateTime(d.year, d.month, d.day);
    return x.toIso8601String().split('T').first;
  }

  AppException _mapError(PostgrestException e) {
    if (e.code == '42501' || e.message.contains('permission')) {
      return PermissionException(e.message);
    }
    return NetworkException(e.message);
  }
}
