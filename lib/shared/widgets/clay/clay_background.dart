import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

/// Fundo mesh gradiente com orbes decorativos (clay ultramoderno).
class ClayBackground extends StatelessWidget {
  const ClayBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  final Widget child;
  final bool showOrbs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: ClayTokens.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showOrbs) ...[
            Positioned(
              top: -80,
              right: -60,
              child: _orb(220, const Color(0xFF8B7CF6), 0.22),
            ),
            Positioned(
              bottom: 120,
              left: -100,
              child: _orb(280, const Color(0xFF00CEC9), 0.18),
            ),
            Positioned(
              top: 280,
              left: 40,
              child: _orb(140, const Color(0xFFFF7675), 0.12),
            ),
          ],
          child,
        ],
      ),
    );
  }

  Widget _orb(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
