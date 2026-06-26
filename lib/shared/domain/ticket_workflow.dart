import 'package:cond_manager/shared/domain/enums/ticket_status.dart';
import 'package:cond_manager/shared/domain/enums/work_order_status.dart';

/// Regras de sincronização chamado ↔ ordem de serviço.
abstract final class TicketWorkOrderWorkflow {
  /// Status operacionais da OS no fluxo principal.
  static const operationalWorkOrderStatuses = [
    WorkOrderStatus.open,
    WorkOrderStatus.waitingMaterial,
    WorkOrderStatus.inProgress,
    WorkOrderStatus.completed,
    WorkOrderStatus.cancelled,
  ];

  /// Chamado com OS vinculada: status segue a OS.
  static bool isManagedByWorkOrder(String? workOrderId) => workOrderId != null;

  static TicketStatus? ticketStatusFromWorkOrder(WorkOrderStatus woStatus) {
    return switch (woStatus) {
      WorkOrderStatus.open => TicketStatus.inAnalysis,
      WorkOrderStatus.waitingMaterial => TicketStatus.waitingMaterial,
      WorkOrderStatus.inProgress => TicketStatus.inProgress,
      WorkOrderStatus.completed ||
      WorkOrderStatus.closed =>
        TicketStatus.completed,
      WorkOrderStatus.cancelled => TicketStatus.cancelled,
      _ => null,
    };
  }

  /// Transições manuais permitidas no chamado (sem OS).
  static List<TicketStatus> manualTransitionsFrom(TicketStatus current) {
    if (current.isTerminal) return [];
    return switch (current) {
      TicketStatus.open => [TicketStatus.inAnalysis, TicketStatus.cancelled],
      TicketStatus.inAnalysis => [TicketStatus.cancelled],
      TicketStatus.waitingMaterial => [
        TicketStatus.inProgress,
        TicketStatus.cancelled,
      ],
      TicketStatus.inProgress => [
        TicketStatus.waitingMaterial,
        TicketStatus.completed,
        TicketStatus.cancelled,
      ],
      _ => [],
    };
  }
}
