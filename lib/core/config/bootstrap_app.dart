import 'dart:async';

import 'package:cond_manager/app.dart';
import 'package:cond_manager/core/config/app_config.dart';
import 'package:cond_manager/core/config/config_error_app.dart';
import 'package:cond_manager/core/config/supabase_bootstrap.dart';
import 'package:cond_manager/core/config/url_strategy_stub.dart'
    if (dart.library.html) 'package:cond_manager/core/config/url_strategy_web.dart' as url_strategy;
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/widgets/app_loading_scaffold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  /// Evita crash silencioso no iOS quando exceções escapam do framework Flutter.
  static void installGlobalErrorHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PlatformDispatcher error: $error\n$stack');
      return true;
    };
  }

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  static const _bootWatchdog = Duration(seconds: 25);
  static const _retryDelay = Duration(milliseconds: 600);

  Widget? _readyApp;
  String _status = 'Iniciando Cond Manager…';
  String? _bootError;
  bool _isBooting = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    if (_isBooting) return;
    _isBooting = true;

    if (mounted) {
      setState(() {
        _readyApp = null;
        _bootError = null;
        _status = 'Iniciando Cond Manager…';
      });
    }

    Object? lastError;
    StackTrace? lastStack;

    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        if (attempt > 1 && mounted) {
          setState(() => _status = 'Tentando novamente…');
        }

        await _bootOnce().timeout(
          _bootWatchdog,
          onTimeout: () => throw TimeoutException('Inicialização demorou demais.'),
        );

        if (!mounted) return;
        setState(() => _readyApp = const CondManagerApp());
        _isBooting = false;
        return;
      } catch (e, stack) {
        lastError = e;
        lastStack = stack;
        debugPrint('Falha ao iniciar Cond Manager (tentativa $attempt): $e\n$stack');
        if (attempt < 2) {
          await Future<void>.delayed(_retryDelay);
        }
      }
    }

    _isBooting = false;
    if (!mounted) return;

    final message = lastError?.toString() ?? 'Erro desconhecido ao iniciar.';
    debugPrint('Boot abortado após 2 tentativas: $message\n$lastStack');

    if (lastError is StateError) {
      setState(() => _readyApp = ConfigErrorApp(message: message));
    } else {
      setState(() => _bootError = message);
    }
  }

  Future<void> _bootOnce() async {
    if (kIsWeb) {
      url_strategy.configureUrlStrategy();
    }

    if (mounted) setState(() => _status = 'Carregando configuração…');
    final config = await AppConfig.load().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Configuração demorou demais.'),
    );

    if (mounted) setState(() => _status = 'Conectando ao Supabase…');
    await ensureSupabaseInitialized(config).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException('Supabase não respondeu a tempo.'),
    );

    if (mounted) setState(() => _status = 'Verificando sessão…');
    await sanitizePersistedAuthSession(config);
  }

  @override
  Widget build(BuildContext context) {
    if (_readyApp != null) return _readyApp!;

    if (_bootError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: ClayTokens.canvas,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 48, color: ClayTokens.accent),
                      const SizedBox(height: 20),
                      const Text(
                        'Não foi possível iniciar',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _bootError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: ClayTokens.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _isBooting ? null : _boot,
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppLoadingScaffold(message: _status),
    );
  }
}
