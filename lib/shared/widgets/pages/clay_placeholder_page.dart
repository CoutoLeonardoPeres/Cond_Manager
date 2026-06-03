import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:cond_manager/shared/widgets/clay/clay.dart';
import 'package:flutter/material.dart';

class ClayPlaceholderPage extends StatelessWidget {
  const ClayPlaceholderPage({
    super.key,
    required this.title,
    this.subtitle = 'Em breve — módulo ainda não implementado no app',
    this.icon = Icons.auto_awesome_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ClaySurface(
          depth: ClayDepth.floating,
          radius: ClayTokens.radiusXl,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: ClayTokens.primaryGradient,
                  borderRadius: BorderRadius.circular(ClayTokens.radiusLg),
                ),
                child: Icon(icon, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ClayTokens.textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
