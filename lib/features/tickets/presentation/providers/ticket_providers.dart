import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/tickets/data/repositories/ticket_repository_impl.dart';
import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:cond_manager/features/tickets/domain/repositories/ticket_repository.dart';
import 'package:cond_manager/shared/domain/enums/ticket_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepositoryImpl(ref.watch(supabaseClientProvider));
});

final ticketListFilterProvider = StateProvider<TicketListFilter>((ref) {
  return const TicketListFilter();
});

final ticketsListProvider = FutureProvider.autoDispose<List<Ticket>>((ref) async {
  final filter = ref.watch(ticketListFilterProvider);
  final repo = ref.watch(ticketRepositoryProvider);
  final result = await repo.list(filter);
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});

final ticketDetailProvider = FutureProvider.autoDispose.family<Ticket, String>((ref, id) async {
  final repo = ref.watch(ticketRepositoryProvider);
  final result = await repo.getById(id);
  return result.when(
    success: (ticket) => ticket,
    failure: (e) => throw e,
  );
});

final ticketInteractionsProvider =
    FutureProvider.autoDispose.family<List<TicketInteraction>, String>((ref, ticketId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  final result = await repo.listInteractions(ticketId);
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});

final ticketAttachmentsProvider =
    FutureProvider.autoDispose.family<List<TicketAttachment>, String>((ref, ticketId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  final result = await repo.listAttachments(ticketId);
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});

final ticketUnitsProvider =
    FutureProvider.autoDispose.family<List<UnitOption>, String>((ref, condominiumId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  final result = await repo.listUnits(condominiumId);
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});

final ticketCommonAreasProvider =
    FutureProvider.autoDispose.family<List<CommonAreaOption>, String>((ref, condominiumId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  final result = await repo.listCommonAreas(condominiumId);
  return result.when(
    success: (list) => list,
    failure: (e) => throw e,
  );
});

/// Statuses disponíveis para filtro rápido na listagem.
final ticketFilterStatuses = [
  null,
  TicketStatus.open,
  TicketStatus.inAnalysis,
  TicketStatus.waitingInfo,
  TicketStatus.resolved,
];
