import 'package:cond_manager/core/errors/app_exception.dart'
    show AppAuthException, AppException, NetworkException, PermissionException;
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/access_logs/data/models/access_session_log_model.dart';
import 'package:cond_manager/features/access_logs/domain/entities/access_session_log.dart';
import 'package:cond_manager/features/access_logs/domain/repositories/access_log_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccessLogRepositoryImpl implements AccessLogRepository {
  AccessLogRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<String>> startSession({String? condominiumId}) async {
    try {
      if (_client.auth.currentUser == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      final sessionId = await _client.rpc<String>(
        'start_user_access_session',
        params: {'p_condominium_id': condominiumId},
      );

      return Success(sessionId);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao iniciar sessão de acesso: $e'));
    }
  }

  @override
  Future<Result<void>> endSession({String? sessionId}) async {
    try {
      if (_client.auth.currentUser == null) {
        return const Success(null);
      }

      await _client.rpc<void>(
        'end_user_access_session',
        params: {'p_session_id': sessionId},
      );

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao encerrar sessão de acesso: $e'));
    }
  }

  @override
  Future<Result<List<AccessSessionLog>>> listSessions(AccessLogFilter filter) async {
    try {
      var query = _client.from('user_access_sessions').select();

      if (filter.companyId != null) {
        query = query.eq('company_id', filter.companyId!);
      }
      if (filter.condominiumId != null) {
        query = query.eq('condominium_id', filter.condominiumId!);
      }
      if (filter.year != null) {
        query = query.eq('access_year', filter.year!);
      }
      if (filter.month != null) {
        query = query.eq('access_month', filter.month!);
      }
      if (filter.day != null) {
        query = query.eq('access_day', filter.day!);
      }
      if (filter.userNameQuery?.trim().isNotEmpty == true) {
        query = query.ilike('user_full_name', '%${filter.userNameQuery!.trim()}%');
      }

      final data = await query.order('started_at', ascending: false).limit(500);

      final list = (data as List<dynamic>)
          .map(
            (e) => AccessSessionLogModel.fromJson(e as Map<String, dynamic>).toEntity(),
          )
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar log de acesso: $e'));
    }
  }

  @override
  Future<Result<AccessLogSummary>> summary(AccessLogFilter filter) async {
    final result = await listSessions(filter);
    return result.when(
      success: (sessions) {
        final users = <String>{};
        var total = 0;
        for (final s in sessions) {
          users.add(s.userId);
          total += s.durationSeconds ?? 0;
        }
        return Success(
          AccessLogSummary(
            sessionCount: sessions.length,
            totalDurationSeconds: total,
            uniqueUsers: users.length,
          ),
        );
      },
      failure: Failure.new,
    );
  }

  AppException _mapError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (e.code == '42501' || msg.contains('permission')) {
      return PermissionException(e.message);
    }
    return NetworkException(e.message);
  }
}
