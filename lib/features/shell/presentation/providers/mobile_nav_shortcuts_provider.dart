import 'package:cond_manager/features/shell/data/mobile_nav_shortcuts_storage.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mobileNavShortcutsProvider =
    StateNotifierProvider.family<MobileNavShortcutsNotifier, List<String>, AppModule>(
  (ref, module) => MobileNavShortcutsNotifier(module),
);

class MobileNavShortcutsNotifier extends StateNotifier<List<String>> {
  MobileNavShortcutsNotifier(this.module) : super(const []) {
    _load();
  }

  final AppModule module;

  Future<void> _load() async {
    state = await MobileNavShortcutsStorage.load(module);
  }

  Future<void> save(List<String> paths) async {
    final trimmed = paths.take(MobileNavShortcutsStorage.maxShortcuts).toList();
    await MobileNavShortcutsStorage.save(module, trimmed);
    state = trimmed;
  }

  Future<void> reset() async {
    await MobileNavShortcutsStorage.save(module, const []);
    state = const [];
  }
}
