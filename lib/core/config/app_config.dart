import 'package:cond_manager/core/config/env_loader.dart';

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Lidos em compile-time (--dart-define). Não chamar [String.fromEnvironment] em runtime.
  static const _defineSupabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const _defineSupabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// dart-define (build) → `.env` no bundle (runtime iOS/Android/Web).
  static Future<AppConfig> load() async {
    var url = _defineValue(_defineSupabaseUrl);
    var key = _defineValue(_defineSupabaseAnonKey);

    if (!_isComplete(url, key)) {
      final asset = await EnvLoader.loadDotEnvAsset();
      if (url.isEmpty) url = _clean(asset['SUPABASE_URL']);
      if (key.isEmpty) key = _clean(asset['SUPABASE_ANON_KEY']);
    }

    if (url.isEmpty || key.isEmpty) {
      throw StateError(
        'Configure SUPABASE_URL e SUPABASE_ANON_KEY no .env ou dart_defines.json '
        'e rode Cond Manager (iOS Release).',
      );
    }

    if (!_isValidAnonKey(key)) {
      throw StateError(
        'SUPABASE_ANON_KEY inválida ou truncada. '
        'Atualize o .env e reinstale o app.',
      );
    }

    if (!url.startsWith('https://') || !url.contains('.supabase.co')) {
      throw StateError('SUPABASE_URL inválida: $url');
    }

    return AppConfig(supabaseUrl: url, supabaseAnonKey: key);
  }

  static bool _isComplete(String url, String key) =>
      url.isNotEmpty && key.isNotEmpty && _isValidAnonKey(key);

  static String _defineValue(String raw) {
    final value = _clean(raw);
    if (value.isEmpty || _looksTruncated(value)) return '';
    return value;
  }

  static String _clean(String? value) {
    if (value == null) return '';
    var v = value.trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
      v = v.substring(1, v.length - 1).trim();
    }
    return v;
  }

  static bool _looksTruncated(String value) =>
      value.contains('...') || value.length < 80;

  static bool _isValidAnonKey(String key) =>
      !_looksTruncated(key) && key.split('.').length == 3;
}
