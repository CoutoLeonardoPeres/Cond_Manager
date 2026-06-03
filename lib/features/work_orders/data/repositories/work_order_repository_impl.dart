import 'package:cond_manager/core/errors/app_exception.dart'
    show AppAuthException, AppException, NetworkException, PermissionException;
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/materials/data/models/material_model.dart';
import 'package:cond_manager/features/work_orders/data/models/work_order_labor_model.dart';
import 'package:cond_manager/features/work_orders/data/models/work_order_material_model.dart';
import 'package:cond_manager/features/work_orders/data/models/work_order_model.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order_labor.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order_material.dart';
import 'package:cond_manager/shared/domain/enums/labor_source.dart';
import 'package:cond_manager/features/work_orders/domain/repositories/work_order_repository.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/stock_movement_type.dart';
import 'package:cond_manager/shared/utils/material_pricing.dart';
import 'package:cond_manager/shared/domain/enums/ticket_status.dart';
import 'package:cond_manager/shared/domain/enums/work_order_status.dart';
import 'package:cond_manager/shared/domain/enums/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkOrderRepositoryImpl implements WorkOrderRepository {
  WorkOrderRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _select = '''
    *,
    condominiums ( name ),
    ticket:tickets!work_orders_ticket_id_fkey ( ticket_number, title ),
    internal:profiles!work_orders_internal_responsible_id_fkey ( full_name ),
    provider:providers ( trade_name, legal_name ),
    creator:profiles!work_orders_created_by_fkey ( full_name )
  ''';

  static const _internalRoles = [
    'internal_employee',
    'caretaker',
    'maintenance_manager',
    'condominium_admin',
    'syndic',
  ];

  @override
  Future<Result<List<WorkOrder>>> list(WorkOrderListFilter filter) async {
    try {
      var query = _client.from('work_orders').select(_select);

      if (filter.condominiumId != null) {
        query = query.eq('condominium_id', filter.condominiumId!);
      }
      if (filter.status != null) {
        query = query.eq('status', filter.status!.value);
      }

      final data = await query.order('created_at', ascending: false);

      final list = (data as List<dynamic>)
          .map((e) => WorkOrderModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar ordens de serviço: $e'));
    }
  }

  @override
  Future<Result<WorkOrder>> getById(String id) async {
    try {
      final row = await _client.from('work_orders').select(_select).eq('id', id).single();
      return Success(
        WorkOrderModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar OS: $e'));
    }
  }

  @override
  Future<Result<WorkOrder>> create(WorkOrderCreateInput input) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      if (input.internalResponsibleId != null && input.providerId != null) {
        return const Failure(
          NetworkException('Informe apenas funcionário interno ou prestador, não ambos.'),
        );
      }

      final payload = WorkOrderModel.createPayload(
        input,
        createdBy: userId,
        requesterId: input.requesterId,
      );
      final row = await _client.from('work_orders').insert(payload).select(_select).single();
      final workOrder = WorkOrderModel.fromJson(row as Map<String, dynamic>).toEntity();

      if (input.ticketId != null) {
        await _client.from('tickets').update({
          'work_order_id': workOrder.id,
          'status': TicketStatus.convertedToOs.value,
        }).eq('id', input.ticketId!);
      }

      return Success(workOrder);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao criar ordem de serviço: $e'));
    }
  }

  @override
  Future<Result<WorkOrder>> updateStatus(String id, WorkOrderStatus status) async {
    try {
      final payload = <String, dynamic>{'status': status.value};
      final now = DateTime.now().toUtc().toIso8601String();

      if (status == WorkOrderStatus.inProgress) {
        payload['started_at'] = now;
      } else if (status == WorkOrderStatus.completed) {
        payload['completed_at'] = now;
      } else if (status == WorkOrderStatus.closed) {
        payload['closed_at'] = now;
      }

      final row = await _client
          .from('work_orders')
          .update(payload)
          .eq('id', id)
          .select(_select)
          .single();

      return Success(
        WorkOrderModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao atualizar status: $e'));
    }
  }

  @override
  Future<Result<List<InternalStaffOption>>> listInternalStaff(
    String condominiumId,
  ) async {
    try {
      final data = await _client
          .from('user_condominium_roles')
          .select(
            'user_id, role, profiles!user_condominium_roles_user_id_fkey ( full_name )',
          )
          .eq('condominium_id', condominiumId)
          .eq('status', 'active')
          .inFilter('role', _internalRoles);

      final list = <InternalStaffOption>[];
      for (final raw in data as List<dynamic>) {
        final map = raw as Map<String, dynamic>;
        final profile = map['profiles'];
        final name = profile is Map ? profile['full_name'] as String? : null;
        if (name == null) continue;
        final role = UserRole.fromValue(map['role'] as String);
        list.add(
          InternalStaffOption(
            profileId: map['user_id'] as String,
            fullName: name,
            roleLabel: role.label,
          ),
        );
      }

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar equipe: $e'));
    }
  }

  @override
  Future<Result<List<TicketLinkOption>>> listLinkableTickets(
    String condominiumId,
  ) async {
    try {
      final data = await _client
          .from('tickets')
          .select('id, ticket_number, title')
          .eq('condominium_id', condominiumId)
          .isFilter('work_order_id', null)
          .inFilter('status', [
            'open',
            'in_analysis',
            'waiting_info',
          ])
          .order('created_at', ascending: false);

      final list = (data as List<dynamic>).map((raw) {
        final map = raw as Map<String, dynamic>;
        final num = map['ticket_number'] as int;
        final ch = 'CH-${num.toString().padLeft(5, '0')}';
        return TicketLinkOption(
          id: map['id'] as String,
          label: '$ch · ${map['title'] as String}',
          displayNumber: ch,
        );
      }).toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar chamados: $e'));
    }
  }

  @override
  Future<Result<WorkOrderMaterialsTotals>> listMaterials(String workOrderId) async {
    try {
      final data = await _client
          .from('work_order_materials')
          .select()
          .eq('work_order_id', workOrderId)
          .order('created_at');

      final lines = (data as List<dynamic>)
          .map((e) =>
              WorkOrderMaterialModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();

      var cost = 0.0;
      var costTax = 0.0;
      var resale = 0.0;
      var resaleTax = 0.0;
      for (final l in lines) {
        cost += l.totalCost;
        costTax += l.totalCostWithTax;
        resale += l.totalResale;
        resaleTax += l.totalResaleWithTax;
      }

      return Success(
        WorkOrderMaterialsTotals(
          lines: lines,
          totalCost: cost,
          totalCostWithTax: costTax,
          totalResale: resale,
          totalResaleWithTax: resaleTax,
          marginWithTax: resaleTax - costTax,
        ),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar materiais da OS: $e'));
    }
  }

  @override
  Future<Result<WorkOrderMaterialLine>> addMaterial(AddWorkOrderMaterialInput input) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      if (input.quantity <= 0) {
        return const Failure(NetworkException('Quantidade deve ser maior que zero.'));
      }

      final matRow = await _client
          .from('materials')
          .select()
          .eq('id', input.materialId)
          .eq('condominium_id', input.condominiumId)
          .eq('status', EntityStatus.active.value)
          .maybeSingle();

      if (matRow == null) {
        return const Failure(NetworkException('Material não encontrado ou inativo.'));
      }

      final material = MaterialModel.fromJson(matRow as Map<String, dynamic>).toEntity();

      if (material.isStorable && material.currentStock < input.quantity) {
        return Failure(
          NetworkException(
            'Estoque insuficiente. Disponível: ${material.currentStock} ${material.unitOfMeasure}.',
          ),
        );
      }

      final unitCost = material.unitCost;
      final purchaseTax = material.purchaseTaxPercent;
      final resale = material.resaleUnitPrice;
      final resaleTax = material.resaleTaxPercent;
      final qty = input.quantity;

      final totalCost = MaterialPricing.lineTotal(unitCost, qty);
      final totalCostWithTax =
          MaterialPricing.lineTotal(MaterialPricing.withTax(unitCost, purchaseTax), qty);
      final totalResale = MaterialPricing.lineTotal(resale, qty);
      final totalResaleWithTax =
          MaterialPricing.lineTotal(MaterialPricing.withTax(resale, resaleTax), qty);

      String? stockMovementId;
      if (material.isStorable) {
        final mov = await _client
            .from('stock_movements')
            .insert({
              'material_id': material.id,
              'condominium_id': input.condominiumId,
              'movement_type': StockMovementType.exit.value,
              'quantity': qty,
              'unit_cost': unitCost,
              'total_cost': totalCostWithTax,
              'reference_type': 'work_order',
              'reference_id': input.workOrderId,
              'notes': 'Consumo na OS',
              'performed_by': userId,
            })
            .select('id')
            .single();
        stockMovementId = mov['id'] as String;
      }

      final lineRow = await _client
          .from('work_order_materials')
          .insert(
            WorkOrderMaterialModel.insertPayload(
              workOrderId: input.workOrderId,
              materialId: material.id,
              materialName: material.name,
              quantity: qty,
              unitOfMeasure: material.unitOfMeasure,
              unitCost: unitCost,
              purchaseTaxPercent: purchaseTax,
              totalCost: totalCost,
              totalCostWithTax: totalCostWithTax,
              unitResalePrice: resale,
              resaleTaxPercent: resaleTax,
              totalResale: totalResale,
              totalResaleWithTax: totalResaleWithTax,
              stockMovementId: stockMovementId,
            ),
          )
          .select()
          .single();

      await _syncWorkOrderMaterialCost(input.workOrderId);

      return Success(
        WorkOrderMaterialModel.fromJson(lineRow as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao lançar material: $e'));
    }
  }

  @override
  Future<Result<void>> removeMaterial(String lineId, String workOrderId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      final lineRow = await _client
          .from('work_order_materials')
          .select()
          .eq('id', lineId)
          .eq('work_order_id', workOrderId)
          .maybeSingle();

      if (lineRow == null) {
        return const Failure(NetworkException('Lançamento não encontrado.'));
      }

      final line =
          WorkOrderMaterialModel.fromJson(lineRow as Map<String, dynamic>).toEntity();

      if (line.stockMovementId != null && line.materialId != null) {
        await _client.from('stock_movements').insert({
          'material_id': line.materialId,
          'condominium_id': (await _client
                  .from('work_orders')
                  .select('condominium_id')
                  .eq('id', workOrderId)
                  .single())['condominium_id'],
          'movement_type': StockMovementType.entry.value,
          'quantity': line.quantity,
          'unit_cost': line.unitCost,
          'total_cost': line.totalCostWithTax,
          'reference_type': 'work_order_reversal',
          'reference_id': workOrderId,
          'notes': 'Estorno de material removido da OS',
          'performed_by': userId,
        });
      }

      await _client.from('work_order_materials').delete().eq('id', lineId);
      await _syncWorkOrderMaterialCost(workOrderId);

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao remover material: $e'));
    }
  }

  Future<void> _syncWorkOrderMaterialCost(String workOrderId) async {
    final data = await _client
        .from('work_order_materials')
        .select('total_cost_with_tax')
        .eq('work_order_id', workOrderId);

    var sum = 0.0;
    for (final row in data as List<dynamic>) {
      sum += WorkOrderMaterialModel.parseNum(
        (row as Map<String, dynamic>)['total_cost_with_tax'],
      );
    }

    await _client.from('work_orders').update({'material_cost': sum}).eq('id', workOrderId);
    await _refreshWorkOrderActualCost(workOrderId);
  }

  @override
  Future<Result<WorkOrderLaborTotals>> listLabor(String workOrderId) async {
    try {
      final data = await _client
          .from('work_order_labor')
          .select(WorkOrderLaborModel.selectQuery)
          .eq('work_order_id', workOrderId)
          .order('created_at');

      final lines = (data as List<dynamic>)
          .map((e) =>
              WorkOrderLaborModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();

      var manHours = 0.0;
      var laborSub = 0.0;
      var travel = 0.0;
      var third = 0.0;
      var internal = 0.0;

      for (final l in lines) {
        manHours += l.totalManHours;
        laborSub += l.laborSubtotal;
        travel += l.travelCost;
        if (l.laborSource == LaborSource.thirdParty) {
          third += l.totalCost;
        } else {
          internal += l.totalCost;
        }
      }

      return Success(
        WorkOrderLaborTotals(
          lines: lines,
          totalManHours: manHours,
          totalLaborSubtotal: laborSub,
          totalTravel: travel,
          grandTotal: laborSub + travel,
          thirdPartyTotal: third,
          internalTotal: internal,
        ),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar mão de obra: $e'));
    }
  }

  @override
  Future<Result<WorkOrderLaborLine>> addLabor(AddWorkOrderLaborInput input) async {
    try {
      if (_client.auth.currentUser?.id == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }
      if (input.workerCount < 1) {
        return const Failure(NetworkException('Informe ao menos 1 profissional.'));
      }
      if (input.hours <= 0) {
        return const Failure(NetworkException('Horas devem ser maiores que zero.'));
      }
      if (input.hourlyRate < 0) {
        return const Failure(NetworkException('Valor/hora inválido.'));
      }

      final row = await _client
          .from('work_order_labor')
          .insert(WorkOrderLaborModel.insertPayload(input))
          .select(WorkOrderLaborModel.selectQuery)
          .single();

      return Success(
        WorkOrderLaborModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao lançar mão de obra: $e'));
    }
  }

  @override
  Future<Result<void>> removeLabor(String lineId, String workOrderId) async {
    try {
      await _client
          .from('work_order_labor')
          .delete()
          .eq('id', lineId)
          .eq('work_order_id', workOrderId);
      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao remover mão de obra: $e'));
    }
  }

  Future<void> _refreshWorkOrderActualCost(String workOrderId) async {
    final wo = await _client
        .from('work_orders')
        .select('material_cost, labor_cost, travel_cost')
        .eq('id', workOrderId)
        .single();

    final map = wo as Map<String, dynamic>;
    final material = WorkOrderMaterialModel.parseNum(map['material_cost']);
    final labor = WorkOrderMaterialModel.parseNum(map['labor_cost']);
    final travel = WorkOrderMaterialModel.parseNum(map['travel_cost']);

    await _client.from('work_orders').update({
      'actual_cost': material + labor + travel,
    }).eq('id', workOrderId);
  }

  AppException _mapError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('permission') || e.code == '42501') {
      return const PermissionException(
        'Sem permissão para ordens de serviço neste condomínio.',
      );
    }
    return NetworkException(e.message);
  }
}
