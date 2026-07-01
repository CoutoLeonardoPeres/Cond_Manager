import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistência dos atalhos da barra inferior no mobile.
abstract final class MobileNavShortcutsStorage {
  static const maxShortcuts = 4;

  static String _key(AppModule module) =>
      'mobile_nav_shortcuts_v1_${module.name}';

  static Future<List<String>> load(AppModule module) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key(module)) ?? const [];
  }

  static Future<void> save(AppModule module, List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(module), paths.take(maxShortcuts).toList());
  }
}
