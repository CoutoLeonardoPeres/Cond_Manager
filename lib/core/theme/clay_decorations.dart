import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

enum ClayDepth { flat, raised, floating, pressed, card, button }

abstract final class ClayDecorations {
  /// Soft ambient shadow for large containers.
  static List<BoxShadow> deepClayShadows() => softShadows(blur: 32, offsetY: 8);

  /// Card shadow — high blur, low opacity (~0.05).
  static List<BoxShadow> clayCardShadows({bool hover = false}) => softShadows(
        blur: hover ? 28 : 24,
        offsetY: hover ? 6 : 4,
        opacity: hover ? 0.08 : 0.05,
      );

  /// Button shadow — slightly more pronounced.
  static List<BoxShadow> clayButtonShadows({bool hover = false}) => softShadows(
        blur: hover ? 20 : 16,
        offsetY: hover ? 4 : 3,
        opacity: hover ? 0.12 : 0.08,
      );

  /// Pressed / inset feel for inputs.
  static List<BoxShadow> clayPressedShadows() => [
        BoxShadow(
          color: ClayTokens.shadowDark.withValues(alpha: 0.04),
          offset: const Offset(0, 1),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> softShadows({
    double blur = 24,
    double offsetY = 4,
    double opacity = 0.05,
    Color? color,
  }) =>
      [
        BoxShadow(
          color: (color ?? ClayTokens.shadowCard).withValues(alpha: opacity),
          offset: Offset(0, offsetY),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> raisedShadows({double depth = 1, Color? darkColor}) =>
      clayCardShadows();

  static List<BoxShadow> insetShadows({double depth = 1}) => clayPressedShadows();

  static BoxDecoration surface({
    ClayDepth depth = ClayDepth.raised,
    Color? color,
    double radius = ClayTokens.radiusCard,
    Gradient? gradient,
    Border? border,
    bool glass = false,
  }) {
    final bg = color ?? (glass ? ClayTokens.cardGlass : ClayTokens.surfaceRaised);
    return BoxDecoration(
      color: gradient == null ? bg : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: border ??
          (depth == ClayDepth.flat
              ? null
              : Border.all(
                  color: ClayTokens.divider.withValues(alpha: 0.8),
                  width: 1,
                )),
      boxShadow: switch (depth) {
        ClayDepth.flat => null,
        ClayDepth.raised => clayCardShadows(),
        ClayDepth.floating => clayCardShadows(hover: true),
        ClayDepth.pressed => null,
        ClayDepth.card => clayCardShadows(),
        ClayDepth.button => clayButtonShadows(),
      },
    );
  }

  static BoxDecoration primaryButton({double radius = ClayTokens.radiusButton}) {
    return BoxDecoration(
      gradient: ClayTokens.primaryGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: clayButtonShadows(),
    );
  }

  static BoxDecoration glassOverlay({double radius = ClayTokens.radiusCard}) {
    return BoxDecoration(
      color: ClayTokens.cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: ClayTokens.divider, width: 1),
      boxShadow: clayCardShadows(),
    );
  }

  static Widget glassWrapper({
    required Widget child,
    required double radius,
    Color? color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: child,
    );
  }
}
