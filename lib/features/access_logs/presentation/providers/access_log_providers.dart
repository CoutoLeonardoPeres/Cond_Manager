import 'package:cond_manager/core/providers/supabase_provider.dart';
import 'package:cond_manager/features/access_logs/data/repositories/access_log_repository_impl.dart';
import 'package:cond_manager/features/access_logs/domain/entities/access_session_log.dart';
import 'package:cond_manager/features/access_logs/domain/repositories/access_log_repository.dart';
import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accessLogRepositoryProvider = Provider<AccessLogRepository>((ref) {
  return AccessLogRepositoryImpl(ref.watch(supabaseClientProvider));
});

final activeAccessSessionIdProvider = StateProvider<String?>((ref) => null);

final accessLogFilterProvider = StateProvider<AccessLogFilter>(
  (ref) => AccessLogFilter(year: DateTime.now().year),
);

final accessSessionsListProvider =
    FutureProvider.autoDispose<List<AccessSessionLog>>((ref) async {
  final filter = ref.watch(accessLogFilterProvider);
  final repo = ref.watch(accessLogRepositoryProvider);
  final result = await repo.listSessions(filter);
  return result.when(success: (list) => list, failure: (e) => throw e);
});

final accessLogSummaryProvider =
    FutureProvider.autoDispose<AccessLogSummary>((ref) async {
  final filter = ref.watch(accessLogFilterProvider);
  final repo = ref.watch(accessLogRepositoryProvider);
  final result = await repo.summary(filter);
  return result.when(success: (s) => s, failure: (e) => throw e);
});

String? primaryCondominiumIdForAccessLog(UserProfile profile) {
  final active = profile.condominiumRoles.where((r) => r.status == 'active').toList();
  if (active.isEmpty) {
    return profile.accessibleCondominiumIds.isNotEmpty
        ? profile.accessibleCondominiumIds.first
        : null;
  }
  final primary = active.where((r) => r.isPrimary).toList();
  return (primary.isNotEmpty ? primary.first : active.first).condominiumId;
}

Future<void> startAccessSessionTracking(WidgetRef ref, UserProfile profile) async {
  final repo = ref.read(accessLogRepositoryProvider);
  final condoId = primaryCondominiumIdForAccessLog(profile);
  final result = await repo.startSession(condominiumId: condoId);
  result.when(
    success: (id) => ref.read(activeAccessSessionIdProvider.notifier).state = id,
    failure: (_) {},
  );
}

Future<void> endAccessSessionTracking(WidgetRef ref) async {
  final sessionId = ref.read(activeAccessSessionIdProvider);
  await ref.read(accessLogRepositoryProvider).endSession(sessionId: sessionId);
  ref.read(activeAccessSessionIdProvider.notifier).state = null;
}
