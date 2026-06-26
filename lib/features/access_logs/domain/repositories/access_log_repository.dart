import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/access_logs/domain/entities/access_session_log.dart';

abstract class AccessLogRepository {
  Future<Result<String>> startSession({String? condominiumId});

  Future<Result<void>> endSession({String? sessionId});

  Future<Result<List<AccessSessionLog>>> listSessions(AccessLogFilter filter);

  Future<Result<AccessLogSummary>> summary(AccessLogFilter filter);
}
