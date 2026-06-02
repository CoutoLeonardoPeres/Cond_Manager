import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

enum ClayDepth { flat, raised, floating, pressed }

abstract final class ClayDecorations {
  static List<BoxShadow> raisedShadows({
    double depth = 1,
    Color? darkColor,
  }) {
    final d = depth.clamp(0.5, 2.0);
    return [
      BoxShadow(
        color: ClayTokens.highlight.withValues(alpha: 0.95),
        offset: Offset(-5 * d, -5 * d),
        blurRadius: 14 * d,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: (darkColor ?? ClayTokens.shadowDark).withValues(alpha: 0.55),
        offset: Offset(6 * d, 8 * d),
        blurRadius: 18 * d,
        spreadRadius: -2,
      ),
      BoxShadow(
        color: ClayTokens.shadowDeep.withValues(alpha: 0.18),
        offset: Offset(0, 12 * d),
        blurRadius: 24 * d,
        spreadRadius: -8,
      ),
    ];
  }

  static List<BoxShadow> insetShadows({double depth = 1}) {
    final d = depth.clamp(0.5, 1.5);
    return [
      BoxShadow(
        color: ClayTokens.shadowDeep.withValues(alpha: 0.22),
        offset: Offset(4 * d, 5 * d),
        blurRadius: 10 * d,
        spreadRadius: -2,
      ),
      BoxShadow(
        color: ClayTokens.highlight.withValues(alpha: 0.85),
        offset: Offset(-3 * d, -3 * d),
        blurRadius: 8 * d,
        spreadRadius: 0,
      ),
    ];
  }

  static BoxDecoration surface({
    ClayDepth depth = ClayDepth.raised,
    Color? color,
    double radius = ClayTokens.radiusMd,
    Gradient? gradient,
    Border? border,
  }) {
    final bg = color ?? ClayTokens.surfaceRaised;
    return BoxDecoration(
      color: gradient == null ? bg : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: border ??
          Border.all(
            color: ClayTokens.highlight.withValues(alpha: 0.65),
            width: 1.5,
          ),
      boxShadow: switch (depth) {
        ClayDepth.flat => null,
        ClayDepth.raised => raisedShadows(),
        ClayDepth.floating => raisedShadows(depth: 1.35),
        ClayDepth.pressed => insetShadows(),
      },
    );
  }

  static BoxDecoration primaryButton({double radius = ClayTokens.radiusMd}) {
    return BoxDecoration(
      gradient: ClayTokens.primaryGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.35),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: ClayTokens.primary.withValues(alpha: 0.45),
          offset: const Offset(0, 10),
          blurRadius: 22,
          spreadRadius: -4,
        ),
        ...raisedShadows(depth: 0.7),
      ],
    );
  }

  static BoxDecoration glassOverlay({double radius = ClayTokens.radiusLg}) {
    return BoxDecoration(
      color: ClayTokens.surfaceRaised.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.5),
        width: 1.5,
      ),
      boxShadow: raisedShadows(depth: 1.1),
    );
  }
}
