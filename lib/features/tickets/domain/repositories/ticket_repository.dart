import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:cond_manager/shared/domain/enums/ticket_status.dart';

abstract class TicketRepository {
  Future<Result<List<Ticket>>> list(TicketListFilter filter);

  Future<Result<Ticket>> getById(String id);

  Future<Result<Ticket>> create(
    TicketCreateInput input, {
    List<PendingTicketFile> attachments = const [],
  });

  Future<Result<Ticket>> updateStatus(String id, TicketStatus status);

  Future<Result<List<TicketInteraction>>> listInteractions(String ticketId);

  Future<Result<TicketInteraction>> addInteraction({
    required String ticketId,
    required String message,
    bool isInternal = false,
  });

  Future<Result<List<TicketAttachment>>> listAttachments(String ticketId);

  Future<Result<List<UnitOption>>> listUnits(String condominiumId);

  Future<Result<List<CommonAreaOption>>> listCommonAreas(String condominiumId);
}
