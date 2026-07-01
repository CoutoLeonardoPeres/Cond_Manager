import 'dart:async';
import 'dart:convert';

import 'package:cond_manager/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool _isSupabaseReady() {
  try {
    return Supabase.instance.isInitialized;
  } catch (_) {
    return false;
  }
}

String _authStorageKey(AppConfig config) {
  final projectRef = Uri.parse(config.supabaseUrl).host.split('.').first;
  return 'sb-$projectRef-auth-token';
}

/// Remove tokens Supabase/GoTrue corrompidos que podem derrubar o app no iOS.
Future<void> clearPersistedSupabaseAuth(AppConfig config) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final authKey = _authStorageKey(config);
    await prefs.remove(authKey);

    final staleKeys = prefs.getKeys().where(
      (key) =>
          key == authKey ||
          key.startsWith('sb-') ||
          key.startsWith('supabase.auth') ||
          key.contains('gotrue'),
    );
    for (final key in staleKeys) {
      await prefs.remove(key);
    }
  } catch (e, stack) {
    debugPrint('clearPersistedSupabaseAuth ignorou erro: $e\n$stack');
  }
}

Future<void> _validatePersistedAuthPayload(AppConfig config) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_authStorageKey(config));
    if (raw == null || raw.trim().isEmpty) return;

    jsonDecode(raw);
  } catch (e, stack) {
    debugPrint('Sessão persistida inválida — limpando storage: $e\n$stack');
    await clearPersistedSupabaseAuth(config);
  }
}

/// Inicialização idempotente do Supabase (segura em relançamentos iOS).
Future<void> ensureSupabaseInitialized(AppConfig config) async {
  if (_isSupabaseReady()) return;

  await _validatePersistedAuthPayload(config);

  try {
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } catch (e, stack) {
    debugPrint('Supabase.initialize falhou — limpando storage e tentando de novo: $e\n$stack');
    await clearPersistedSupabaseAuth(config);
    if (_isSupabaseReady()) return;

    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  // Aguarda recoverSession paralelo do SDK antes de validar a sessão.
  await Future<void>.delayed(const Duration(milliseconds: 150));
}

/// Valida sessão persistida; limpa localmente se inválida ou travada.
Future<void> sanitizePersistedAuthSession([AppConfig? config]) async {
  try {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) return;

    try {
      await auth.getUser().timeout(const Duration(seconds: 8));
    } catch (e, stack) {
      debugPrint('Sessão inválida ou expirada — limpando auth local: $e\n$stack');
      await _clearAuthSession(auth, config);
    }
  } catch (e, stack) {
    debugPrint('sanitizePersistedAuthSession ignorou erro: $e\n$stack');
  }
}

Future<void> _clearAuthSession(GoTrueClient auth, AppConfig? config) async {
  try {
    await auth
        .signOut(scope: SignOutScope.local)
        .timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('signOut(local) falhou — tentando global: $e');
    try {
      await auth.signOut().timeout(const Duration(seconds: 3));
    } catch (e2) {
      debugPrint('signOut(global) também falhou: $e2');
    }
  }

  if (config != null) {
    await clearPersistedSupabaseAuth(config);
  }
}
