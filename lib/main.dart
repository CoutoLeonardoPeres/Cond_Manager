import 'package:cond_manager/app.dart';
import 'package:cond_manager/core/config/app_config.dart';
import 'package:cond_manager/core/config/config_error_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  try {
    final config = await AppConfig.load();

    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
    );

    runApp(
      const ProviderScope(
        child: CondManagerApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('Falha ao iniciar Cond Manager: $e\n$stack');
    runApp(ConfigErrorApp(message: e.toString()));
  }
}
