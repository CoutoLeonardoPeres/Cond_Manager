import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

/// Placeholder enquanto o GoRouter resolve redirect ou carrega rota.
class AppLoadingScaffold extends StatelessWidget {
  const AppLoadingScaffold({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClayTokens.canvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.apartment_rounded, color: ClayTokens.accent, size: 48),
                const SizedBox(height: 20),
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: ClayTokens.accent,
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ClayTokens.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
