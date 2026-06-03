import 'dart:typed_data';

import 'package:cond_manager/core/errors/app_exception.dart' show AppAuthException, AppException, NetworkException, PermissionException;
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/tickets/data/models/ticket_model.dart';
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
  Future<Result<Ticket>> updateStatus(String id, TicketStatus status) async {
    try {
      final payload = <String, dynamic>{'status': status.value};
      if (status == TicketStatus.resolved) {
        payload['resolved_at'] = DateTime.now().toUtc().toIso8601String();
      } else if (status != TicketStatus.convertedToOs) {
        payload['resolved_at'] = null;
      }

      final row = await _client
          .from('tickets')
          .update(payload)
          .eq('id', id)
          .select(_ticketSelect)
          .single();

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
      final data = await _client
          .from('units')
          .select('id, identifier')
          .eq('condominium_id', condominiumId)
          .eq('status', 'active')
          .order('identifier');

      final list = (data as List<dynamic>)
          .map(
            (e) => UnitOption(
              id: e['id'] as String,
              label: e['identifier'] as String,
            ),
          )
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapPostgrestError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar unidades: $e'));
    }
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
