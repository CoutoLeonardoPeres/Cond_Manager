import 'package:cond_manager/features/condominiums/domain/entities/condominium.dart';
import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:cond_manager/features/work_orders/domain/entities/work_order.dart';
import 'package:cond_manager/shared/domain/enums/location_type.dart';
import 'package:cond_manager/shared/domain/enums/priority_level.dart';
import 'package:cond_manager/shared/domain/enums/service_type.dart';

/// Dados do formulário de OS preenchidos a partir de um chamado.
class WorkOrderDraftFromTicket {
  const WorkOrderDraftFromTicket({
    required this.condominium,
    required this.linkedTicket,
    required this.title,
    required this.description,
    required this.serviceType,
    required this.priority,
    required this.locationType,
    required this.locationDescription,
    required this.requesterId,
    this.unitId,
    this.commonAreaId,
  });

  final Condominium? condominium;
  final TicketLinkOption linkedTicket;
  final String title;
  final String description;
  final ServiceType serviceType;
  final PriorityLevel priority;
  final LocationType locationType;
  final String locationDescription;
  final String requesterId;
  final String? unitId;
  final String? commonAreaId;
}

WorkOrderDraftFromTicket buildWorkOrderDraftFromTicket(
  Ticket ticket,
  List<Condominium> condos,
) {
  Condominium? condominium;
  for (final c in condos) {
    if (c.id == ticket.condominiumId) {
      condominium = c;
      break;
    }
  }

  return WorkOrderDraftFromTicket(
    condominium: condominium,
    linkedTicket: TicketLinkOption(
      id: ticket.id,
      label: '${ticket.displayNumber} · ${ticket.title}',
      displayNumber: ticket.displayNumber,
    ),
    title: ticket.title,
    description: ticket.description,
    serviceType: ticket.serviceType,
    priority: ticket.priority,
    locationType: ticket.locationType,
    locationDescription: ticket.locationDescription ?? '',
    requesterId: ticket.requesterId,
    unitId: ticket.unitId,
    commonAreaId: ticket.commonAreaId,
  );
}
