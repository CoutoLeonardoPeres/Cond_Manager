import 'package:cond_manager/features/dashboard/domain/dashboard_filter.dart';
import 'package:cond_manager/features/materials/presentation/providers/material_providers.dart';
import 'package:cond_manager/features/preventive/presentation/providers/preventive_providers.dart';
import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:cond_manager/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:cond_manager/shared/domain/enums/ticket_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardStats {
  const DashboardStats({
    required this.openTicketsCount,
    required this.activeWorkOrdersCount,
    required this.preventiveDueCount,
    required this.lowStockCount,
  });

  final int openTicketsCount;
  final int activeWorkOrdersCount;
  final int preventiveDueCount;
  final int lowStockCount;
}

bool _isOpenTicket(TicketStatus status) =>
    status == TicketStatus.open ||
    status == TicketStatus.inAnalysis ||
    status == TicketStatus.waitingInfo;

final dashboardFilterProvider = StateProvider<DashboardFilter>(
  (ref) => DashboardFilter.initial(),
);

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final filter = ref.watch(dashboardFilterProvider);
  final range = filter.dateRange;
  final condoId = filter.condominiumId;

  final ticketRepo = ref.watch(ticketRepositoryProvider);
  final workOrderRepo = ref.watch(workOrderRepositoryProvider);
  final preventiveRepo = ref.watch(preventiveRepositoryProvider);
  final materialRepo = ref.watch(materialRepositoryProvider);

  final ticketsFuture = ticketRepo.list(TicketListFilter(condominiumId: condoId));
  final workOrdersFuture = workOrderRepo.list(WorkOrderListFilter(condominiumId: condoId));
  final preventiveFuture = preventiveRepo.listBacklog(condominiumId: condoId);
  final balanceFuture = materialRepo.balanceSummary(condominiumId: condoId);

  final ticketsResult = await ticketsFuture;
  final workOrdersResult = await workOrdersFuture;
  final preventiveResult = await preventiveFuture;
  final balanceResult = await balanceFuture;

  final tickets = ticketsResult.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
  final workOrders = workOrdersResult.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
  final preventive = preventiveResult.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
  final balance = balanceResult.when(
    success: (s) => s,
    failure: (e) => throw e,
  );

  final openTickets = tickets.where(
    (t) => _isOpenTicket(t.status) && range.containsDateTime(t.createdAt),
  );

  final activeWorkOrders = workOrders.where(
    (w) => !w.status.isTerminal && range.containsDateTime(w.createdAt),
  );

  final preventiveInRange = preventive.where(
    (p) => range.containsDate(p.scheduledDate),
  );

  return DashboardStats(
    openTicketsCount: openTickets.length,
    activeWorkOrdersCount: activeWorkOrders.length,
    preventiveDueCount: preventiveInRange.length,
    lowStockCount: balance.lowStockCount,
  );
});
