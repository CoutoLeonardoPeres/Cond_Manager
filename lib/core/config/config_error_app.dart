import 'package:cond_manager/core/theme/app_typography.dart';
import 'package:cond_manager/shared/widgets/app_loading_scaffold.dart';
import 'package:flutter/material.dart';

/// Tela exibida quando Supabase não está configurado (evita página branca).
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: AppTypography.contentTextScaler),
          child: child ?? const AppLoadingScaffold(),
        );
      },
      home: Scaffold(
        backgroundColor: const Color(0xFFF6F8FD),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.settings_suggest_rounded, size: 56, color: Color(0xFF6C5CE7)),
                    const SizedBox(height: 20),
                    const Text(
                      'Configuração necessária',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF636E72), height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    const _Step(text: '1. Confirme que existe o arquivo .env na raiz do projeto'),
                    const _Step(text: '2. Ou use Run → Cond Manager (Web) no Cursor'),
                    const _Step(text: '3. Ou: flutter run -d chrome --dart-define=SUPABASE_URL=...'),
                    const SizedBox(height: 16),
                    const Text(
                      'Depois rode fix_admin_profile.sql no Supabase se o login falhar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF95A5A6)),
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
}

class _Step extends StatelessWidget {
  const _Step({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
