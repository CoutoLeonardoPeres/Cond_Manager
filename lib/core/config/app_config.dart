import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Lê credenciais de `--dart-define` ou do arquivo `.env` (dev local).
  static Future<AppConfig> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env ausente em release ou asset não embutido — usa dart-define.
    }

    var url = const String.fromEnvironment('SUPABASE_URL');
    var key = const String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty) url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    if (key.isEmpty) key = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

    if (url.isEmpty || key.isEmpty) {
      throw StateError(
        'Configure SUPABASE_URL e SUPABASE_ANON_KEY no arquivo .env '
        'ou via --dart-define / launch.json.',
      );
    }

    return AppConfig(supabaseUrl: url, supabaseAnonKey: key);
  }
}
