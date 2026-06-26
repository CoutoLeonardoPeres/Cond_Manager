import 'package:cond_manager/features/access_logs/presentation/providers/access_log_providers.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    endAccessSessionTracking(ref);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) return;

    if (state == AppLifecycleState.resumed) {
      startAccessSessionTracking(ref, profile);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      endAccessSessionTracking(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentProfileProvider, (previous, next) {
      next.whenData((profile) {
        if (profile != null) {
          startAccessSessionTracking(ref, profile);
        }
      });
    });

    final profile = ref.watch(currentProfileProvider).value;
    if (profile != null && ref.read(activeAccessSessionIdProvider) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) startAccessSessionTracking(ref, profile);
      });
    }

    return widget.child;
  }
}
