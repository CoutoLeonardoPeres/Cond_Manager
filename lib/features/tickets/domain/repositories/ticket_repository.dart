import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/tickets/domain/entities/status_change_log.dart';
import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:cond_manager/shared/domain/enums/ticket_status.dart';

abstract class TicketRepository {
  Future<Result<List<Ticket>>> list(TicketListFilter filter);

  Future<Result<Ticket>> getById(String id);

  Future<Result<Ticket>> create(
    TicketCreateInput input, {
    List<PendingTicketFile> attachments = const [],
  });

  Future<Result<Ticket>> updateStatus(
    String id,
    TicketStatus status, {
    String? notes,
    Map<String, dynamic> metadata = const {},
  });

  /// Analista/gestor abre o chamado para triagem.
  Future<Result<Ticket>> beginAnalysis(String id);

  /// Confirma que o chamado é problema da gestora (inicia métrica de atendimento).
  Future<Result<Ticket>> acceptAsProblem(String id);

  /// Não é problema da gestora — encerra o chamado.
  Future<Result<Ticket>> rejectAsProblem(String id, {String? notes});

  Future<Result<List<StatusChangeLog>>> listStatusChanges(String ticketId);

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
