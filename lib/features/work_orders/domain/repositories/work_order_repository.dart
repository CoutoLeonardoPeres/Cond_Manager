import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/tickets/domain/entities/status_change_log.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order_labor.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order_material.dart';
import 'package:cond_manager/shared/domain/enums/work_order_status.dart';

abstract class WorkOrderRepository {
  Future<Result<List<WorkOrder>>> list(WorkOrderListFilter filter);

  Future<Result<WorkOrder>> getById(String id);

  Future<Result<WorkOrder>> create(WorkOrderCreateInput input);

  Future<Result<WorkOrder>> updateHeader(String id, WorkOrderHeaderUpdateInput input);

  Future<Result<WorkOrder>> updateStatus(
    String id,
    WorkOrderStatus status, {
    String? notes,
    Map<String, dynamic> metadata = const {},
  });

  Future<Result<List<StatusChangeLog>>> listStatusChanges(String workOrderId);

  Future<Result<List<InternalStaffOption>>> listInternalStaff(String condominiumId);

  Future<Result<List<TicketLinkOption>>> listLinkableTickets(String condominiumId);

  Future<Result<WorkOrderMaterialsTotals>> listMaterials(String workOrderId);

  Future<Result<WorkOrderMaterialLine>> addMaterial(AddWorkOrderMaterialInput input);

  Future<Result<void>> removeMaterial(String lineId, String workOrderId);

  Future<Result<WorkOrderLaborTotals>> listLabor(String workOrderId);

  Future<Result<WorkOrderLaborLine>> addLabor(AddWorkOrderLaborInput input);

  Future<Result<void>> removeLabor(String lineId, String workOrderId);
}
