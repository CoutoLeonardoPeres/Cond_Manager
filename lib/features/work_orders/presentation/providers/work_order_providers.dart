import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/work_orders/data/repositories/work_order_repository_impl.dart';
import 'package:cond_manager/features/tickets/domain/entities/status_change_log.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/features/work_orders/domain/repositories/work_order_repository.dart';
import 'package:cond_manager/shared/domain/enums/work_order_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final workOrderRepositoryProvider = Provider<WorkOrderRepository>((ref) {
  return WorkOrderRepositoryImpl(ref.watch(supabaseClientProvider));
});

final workOrderListFilterProvider = StateProvider<WorkOrderListFilter>(
  (ref) => const WorkOrderListFilter(),
);

final workOrdersListProvider = FutureProvider.autoDispose<List<WorkOrder>>((ref) async {
  final filter = ref.watch(workOrderListFilterProvider);
  final repo = ref.watch(workOrderRepositoryProvider);
  final result = await repo.list(filter);
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});

final workOrderStatusChangesProvider =
    FutureProvider.autoDispose.family<List<StatusChangeLog>, String>((ref, workOrderId) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  final result = await repo.listStatusChanges(workOrderId);
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});

final workOrderDetailProvider =
    FutureProvider.autoDispose.family<WorkOrder, String>((ref, id) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  final result = await repo.getById(id);
  return result.when(
    success: (wo) => wo,
    failure: (e) => throw e,
  );
});

final workOrderInternalStaffProvider =
    FutureProvider.autoDispose.family<List<InternalStaffOption>, String>(
  (ref, condominiumId) async {
    final repo = ref.watch(workOrderRepositoryProvider);
    final result = await repo.listInternalStaff(condominiumId);
    return result.when(
      success: (list) => list,
      failure: (e) => throw e,
    );
  },
);

final workOrderLinkableTicketsProvider =
    FutureProvider.autoDispose.family<List<TicketLinkOption>, String>(
  (ref, condominiumId) async {
    final repo = ref.watch(workOrderRepositoryProvider);
    final result = await repo.listLinkableTickets(condominiumId);
    return result.when(
      success: (list) => list,
      failure: (e) => throw e,
    );
  },
);

final workOrderFilterStatuses = [
  null,
  WorkOrderStatus.open,
  WorkOrderStatus.triage,
  WorkOrderStatus.inProgress,
  WorkOrderStatus.waitingApproval,
  WorkOrderStatus.completed,
  WorkOrderStatus.closed,
];
