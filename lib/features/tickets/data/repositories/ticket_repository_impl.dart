import 'dart:typed_data';

import 'package:cond_manager/core/errors/app_exception.dart' show AppAuthException, AppException, NetworkException, PermissionException;
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/core/utils/unit_display_label.dart';
import 'package:cond_manager/features/tickets/data/models/status_change_log_model.dart';
import 'package:cond_manager/features/tickets/data/models/ticket_model.dart';
import 'package:cond_manager/features/tickets/domain/entities/status_change_log.dart';
import 'package:cond_manager/features/tickets/domain/entities/ticket.dart';
import 'package:cond_manager/features/tickets/domain/repositories/ticket_repository.dart';
import 'package:cond_manager/shared/domain/enums/ticket_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class TicketRepositoryImpl implements TicketRepository {
  TicketRepositoryImpl(this._client);

  final SupabaseClient _client;
  static const _ticketSelect = '''
    *,
    condominiums ( name ),
    requester:profiles!tickets_requester_id_fkey ( full_name ),
    assignee:profiles!tickets_assigned_to_fkey ( full_name )
  ''';

  @override
  Future<Result<List<Ticket>>> list(TicketListFilter filter) async {
    try {
      var query = _client.from('tickets').select(_ticketSelect);

      if (filter.condominiumId != null) {
        query = query.eq('condominium_id', filter.condominiumId!);
      }
      if (filter.status != null) {
        query = query.eq('status', filter.status!.value);
      }
      if (filter.priority != null) {
        query = query.eq('priority', filter.priority!.value);
      }

      final data = await query.order('created_at', ascending: false);

      final list = (data as List<dynamic>)
          .map((e) => TicketModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar chamados: $e'));
    }
  }

  @override
  Future<Result<Ticket>> getById(String id) async {
    try {
      final row = await _client
          .from('tickets')
          .select(_ticketSelect)
          .eq('id', id)
          .single();

      return Success(
        TicketModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar chamado: $e'));
    }
  }

  @override
  Future<Result<Ticket>> create(
    TicketCreateInput input, {
    List<PendingTicketFile> attachments = const [],
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      final payload = TicketModel.createPayload(input, requesterId: userId);
      final row = await _client.from('tickets').insert(payload).select(_ticketSelect).single();
      final ticket = TicketModel.fromJson(row as Map<String, dynamic>).toEntity();

      if (attachments.isNotEmpty) {
        await _uploadAttachments(
          ticketId: ticket.id,
          condominiumId: ticket.condominiumId,
          uploadedBy: userId,
          files: attachments,
        );
      }

      return Success(ticket);
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao abrir chamado: $e'));
    }
  }

  @override
  Future<Result<Ticket>> updateStatus(
    String id,
    TicketStatus status, {
    String? notes,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }
      final current = await _fetchTicketRow(id);
      final from = current['status'] as String;
      if (from == status.value) {
        return Success(TicketModel.fromJson(current).toEntity());
      }

      final payload = _statusPayload(status);
      final row = await _client
          .from('tickets')
          .update(payload)
          .eq('id', id)
          .select(_ticketSelect)
          .single();

      await _recordTicketStatusChange(
        ticketId: id,
        fromStatus: from,
        toStatus: status.value,
        changedBy: userId,
        notes: notes,
        metadata: metadata,
      );

      return Success(
        TicketModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao atualizar status: $e'));
    }
  }

  @override
  Future<Result<Ticket>> beginAnalysis(String id) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }
      final current = await _fetchTicketRow(id);
      final status = current['status'] as String;
      if (status != TicketStatus.open.value) {
        return Success(TicketModel.fromJson(current).toEntity());
      }
      final now = DateTime.now().toUtc().toIso8601String();
      final row = await _client
          .from('tickets')
          .update({
            'status': TicketStatus.inAnalysis.value,
            'analysis_started_at': now,
          })
          .eq('id', id)
          .select(_ticketSelect)
          .single();

      await _recordTicketStatusChange(
        ticketId: id,
        fromStatus: status,
        toStatus: TicketStatus.inAnalysis.value,
        changedBy: userId,
        notes: 'Chamado aberto para análise',
      );

      return Success(
        TicketModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao iniciar análise: $e'));
    }
  }

  @override
  Future<Result<Ticket>> acceptAsProblem(String id) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }
      final current = await _fetchTicketRow(id);
      if (current['problem_accepted_at'] != null) {
        return Success(TicketModel.fromJson(current).toEntity());
      }
      final now = DateTime.now().toUtc().toIso8601String();
      final row = await _client
          .from('tickets')
          .update({'problem_accepted_at': now})
          .eq('id', id)
          .select(_ticketSelect)
          .single();

      await _client
          .from('ticket_status_durations')
          .update({'ended_at': now})
          .eq('ticket_id', id)
          .isFilter('ended_at', null);

      await _client.from('ticket_status_changes').insert({
        'ticket_id': id,
        'from_status': current['status'] as String,
        'to_status': current['status'] as String,
        'changed_by': userId,
        'notes': 'Aceito como problema da gestora — início da métrica de atendimento',
        'metadata': {'event': 'problem_accepted'},
      });

      await _client.from('ticket_status_durations').insert({
        'ticket_id': id,
        'status': current['status'] as String,
        'changed_by': userId,
        'metadata': {'metric': 'problem_accepted'},
      });

      return Success(
        TicketModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao aceitar chamado: $e'));
    }
  }

  @override
  Future<Result<Ticket>> rejectAsProblem(String id, {String? notes}) async {
    return updateStatus(
      id,
      TicketStatus.cancelled,
      notes: notes ?? 'Não caracterizado como problema da gestora',
    );
  }

  @override
  Future<Result<List<StatusChangeLog>>> listStatusChanges(String ticketId) async {
    try {
      final data = await _client
          .from('ticket_status_changes')
          .select(
            '*, changer:profiles!ticket_status_changes_changed_by_fkey(full_name)',
          )
          .eq('ticket_id', ticketId)
          .order('created_at');

      final list = (data as List<dynamic>)
          .map(
            (e) => StatusChangeLogModel.fromJson(e as Map<String, dynamic>).toEntity(),
          )
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar auditoria: $e'));
    }
  }

  Map<String, dynamic> _statusPayload(TicketStatus status) {
    final payload = <String, dynamic>{'status': status.value};
    final now = DateTime.now().toUtc().toIso8601String();
    if (status == TicketStatus.completed) {
      payload['resolved_at'] = now;
    } else if (status != TicketStatus.inProgress) {
      payload['resolved_at'] = null;
    }
    return payload;
  }

  Future<Map<String, dynamic>> _fetchTicketRow(String id) async {
    final row = await _client.from('tickets').select().eq('id', id).single();
    return row as Map<String, dynamic>;
  }

  Future<void> _recordTicketStatusChange({
    required String ticketId,
    required String? fromStatus,
    required String toStatus,
    required String changedBy,
    String? notes,
    Map<String, dynamic> metadata = const {},
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    if (fromStatus != null && fromStatus != toStatus) {
      await _client
          .from('ticket_status_durations')
          .update({'ended_at': now})
          .eq('ticket_id', ticketId)
          .isFilter('ended_at', null);
    }

    await _client.from('ticket_status_changes').insert({
      'ticket_id': ticketId,
      'from_status': fromStatus,
      'to_status': toStatus,
      'changed_by': changedBy,
      'notes': notes,
      'metadata': metadata,
    });

    if (fromStatus != toStatus) {
      await _client.from('ticket_status_durations').insert({
        'ticket_id': ticketId,
        'status': toStatus,
        'changed_by': changedBy,
        'metadata': metadata,
      });
    }
  }

  @override
  Future<Result<List<TicketInteraction>>> listInteractions(String ticketId) async {
    try {
      final data = await _client
          .from('ticket_interactions')
          .select('*, author:profiles!ticket_interactions_author_id_fkey(full_name)')
          .eq('ticket_id', ticketId)
          .order('created_at');

      final list = (data as List<dynamic>)
          .map(
            (e) => TicketInteractionModel.fromJson(e as Map<String, dynamic>).toEntity(),
          )
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar mensagens: $e'));
    }
  }

  @override
  Future<Result<TicketInteraction>> addInteraction({
    required String ticketId,
    required String message,
    bool isInternal = false,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      final row = await _client
          .from('ticket_interactions')
          .insert({
            'ticket_id': ticketId,
            'author_id': userId,
            'message': message.trim(),
            'is_internal': isInternal,
          })
          .select('*, author:profiles!ticket_interactions_author_id_fkey(full_name)')
          .single();

      return Success(
        TicketInteractionModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao enviar mensagem: $e'));
    }
  }

  @override
  Future<Result<List<TicketAttachment>>> listAttachments(String ticketId) async {
    try {
      final data = await _client
          .from('ticket_attachments')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at');

      final attachments = <TicketAttachment>[];
      for (final raw in data as List<dynamic>) {
        final model = TicketAttachmentModel.fromJson(raw as Map<String, dynamic>);
        var url = model.fileUrl;
        if (url.isEmpty && model.filePath.isNotEmpty) {
          url = await _client.storage
              .from('tickets')
              .createSignedUrl(model.filePath, 3600);
        }
        attachments.add(
          TicketAttachment(
            id: model.id,
            ticketId: model.ticketId,
            fileUrl: url,
            filePath: model.filePath,
            fileName: model.fileName,
            mimeType: model.mimeType,
            createdAt: model.createdAt,
          ),
        );
      }

      return Success(attachments);
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar anexos: $e'));
    }
  }

  @override
  Future<Result<List<UnitOption>>> listUnits(String condominiumId) async {
    try {
      return Success(await _fetchUnits(condominiumId, withStructureLabels: true));
    } on PostgrestException catch (e) {
      try {
        return Success(await _fetchUnits(condominiumId, withStructureLabels: false));
      } on PostgrestException {
        return Failure(_mapPostgrestError(e));
      }
    } catch (e) {
      return Failure(NetworkException('Erro ao listar unidades: $e'));
    }
  }

  Future<List<UnitOption>> _fetchUnits(
    String condominiumId, {
    required bool withStructureLabels,
  }) async {
    final select = withStructureLabels
        ? 'id, identifier, area_sqm, block:blocks(name), tower:towers(name)'
        : 'id, identifier, area_sqm';

    final data = await _client
        .from('units')
        .select(select)
        .eq('condominium_id', condominiumId)
        .eq('status', 'active')
        .order('identifier');

    return (data as List<dynamic>)
        .map(
          (e) {
            final block = withStructureLabels ? e['block'] as Map<String, dynamic>? : null;
            final tower = withStructureLabels ? e['tower'] as Map<String, dynamic>? : null;
            final identifier = e['identifier'] as String;
            return UnitOption(
              id: e['id'] as String,
              label: withStructureLabels
                  ? formatUnitDisplayLabel(
                      identifier: identifier,
                      blockName: block?['name'] as String?,
                      towerName: tower?['name'] as String?,
                    )
                  : identifier,
              areaSqm: e['area_sqm'] != null
                  ? double.tryParse(e['area_sqm'].toString())
                  : null,
            );
          },
        )
        .toList();
  }

  @override
  Future<Result<List<CommonAreaOption>>> listCommonAreas(String condominiumId) async {
    try {
      final data = await _client
          .from('common_areas')
          .select('id, name')
          .eq('condominium_id', condominiumId)
          .eq('status', 'active')
          .order('name');

      final list = (data as List<dynamic>)
          .map(
            (e) => CommonAreaOption(
              id: e['id'] as String,
              label: e['name'] as String,
            ),
          )
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar áreas comuns: $e'));
    }
  }

  Future<void> _uploadAttachments({
    required String ticketId,
    required String condominiumId,
    required String uploadedBy,
    required List<PendingTicketFile> files,
  }) async {
    const uuid = Uuid();
    for (final file in files) {
      final safeName = file.fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
      final path = '$condominiumId/$ticketId/${uuid.v4()}_$safeName';

      await _client.storage.from('tickets').uploadBinary(
            path,
            Uint8List.fromList(file.bytes),
            fileOptions: FileOptions(contentType: file.mimeType, upsert: false),
          );

      final signedUrl =
          await _client.storage.from('tickets').createSignedUrl(path, 86400);

      await _client.from('ticket_attachments').insert({
        'ticket_id': ticketId,
        'file_url': signedUrl,
        'file_path': path,
        'file_name': file.fileName,
        'mime_type': file.mimeType,
        'uploaded_by': uploadedBy,
      });
    }
  }

  AppException _mapPostgrestError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('permission') || e.code == '42501') {
      return const PermissionException(
        'Sem permissão para esta operação no chamado.',
      );
    }
    return NetworkException(e.message);
  }
}
