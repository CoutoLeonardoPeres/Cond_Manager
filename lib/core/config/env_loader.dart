import 'package:flutter/services.dart';

/// Lê `.env` do bundle sem depender do flutter_dotenv (mais estável no iOS).
abstract final class EnvLoader {
  static Future<Map<String, String>> loadDotEnvAsset({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final raw = await rootBundle.loadString('.env').timeout(timeout);
      return _parse(raw);
    } catch (_) {
      return const {};
    }
  }

  static Map<String, String> _parse(String raw) {
    final map = <String, String>{};
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eq = trimmed.indexOf('=');
      if (eq <= 0) continue;
      final key = trimmed.substring(0, eq).trim();
      final value = _clean(trimmed.substring(eq + 1));
      if (key.isNotEmpty && value.isNotEmpty) {
        map[key] = value;
      }
    }
    return map;
  }

  static String _clean(String value) {
    var v = value.trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
      v = v.substring(1, v.length - 1).trim();
    }
    return v;
  }
}
