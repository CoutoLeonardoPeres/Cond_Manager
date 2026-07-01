import 'package:cond_manager/features/access_logs/presentation/providers/access_log_providers.dart';
import 'package:cond_manager/features/auth/domain/entities/user_profile.dart';
import 'package:cond_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inicia e encerra sessões de acesso para o log de uso.
class AccessSessionScope extends ConsumerStatefulWidget {
  const AccessSessionScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AccessSessionScope> createState() => _AccessSessionScopeState();
}

class _AccessSessionScopeState extends ConsumerState<AccessSessionScope>
    with WidgetsBindingObserver {
  String? _trackedSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _startTracking(UserProfile profile) async {
    final repo = ref.read(accessLogRepositoryProvider);
    final condoId = primaryCondominiumIdForAccessLog(profile);
    final result = await repo.startSession(condominiumId: condoId);
    result.when(
      success: (id) {
        _trackedSessionId = id;
        ref.read(activeAccessSessionIdProvider.notifier).state = id;
      },
      failure: (_) {},
    );
  }

  Future<void> _endTracking() async {
    if (!mounted) return;
    final sessionId = _trackedSessionId;
    if (sessionId == null) return;
    _trackedSessionId = null;
    if (!mounted) return;
    ref.read(activeAccessSessionIdProvider.notifier).state = null;
    final result = await ref.read(accessLogRepositoryProvider).endSession(sessionId: sessionId);
    result.when(success: (_) {}, failure: (_) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) return;

    if (state == AppLifecycleState.resumed) {
      _startTracking(profile);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _endTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentProfileProvider, (previous, next) {
      next.whenData((profile) {
        if (profile != null) {
          _startTracking(profile);
        }
      });
    });

    final profile = ref.watch(currentProfileProvider).value;
    if (profile != null && _trackedSessionId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _trackedSessionId == null) {
          _startTracking(profile);
        }
      });
    }

    return widget.child;
  }
}
