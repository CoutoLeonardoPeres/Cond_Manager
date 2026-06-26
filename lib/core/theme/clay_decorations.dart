import 'dart:ui';

import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

enum ClayDepth { flat, raised, floating, pressed, card, button }

abstract final class ClayDecorations {
  /// Deep clay — large containers / hero sections.
  static List<BoxShadow> deepClayShadows() => [
        BoxShadow(
          color: ClayTokens.shadowAmbient.withValues(alpha: 1),
          offset: const Offset(30, 30),
          blurRadius: 60,
        ),
        BoxShadow(
          color: ClayTokens.highlight.withValues(alpha: 1),
          offset: const Offset(-30, -30),
          blurRadius: 60,
        ),
      ];

  /// Clay Card — 4-layer floating stack.
  static List<BoxShadow> clayCardShadows({bool hover = false}) => [
        BoxShadow(
          color: ClayTokens.shadowCard.withValues(alpha: hover ? 0.28 : 0.2),
          offset: Offset(16, hover ? 20 : 16),
          blurRadius: hover ? 40 : 32,
        ),
        BoxShadow(
          color: ClayTokens.highlight.withValues(alpha: 0.9),
          offset: const Offset(-10, -10),
          blurRadius: 24,
        ),
        BoxShadow(
          color: ClayTokens.shadowPurple.withValues(alpha: 0.03),
          offset: const Offset(6, 6),
          blurRadius: 12,
        ),
        BoxShadow(
          color: ClayTokens.highlight.withValues(alpha: 0.5),
          offset: const Offset(-2, -2),
          blurRadius: 8,
        ),
      ];

  /// Clay Button — high convexity.
  static List<BoxShadow> clayButtonShadows({bool hover = false}) => [
        BoxShadow(
          color: ClayTokens.shadowPurple.withValues(alpha: hover ? 0.38 : 0.3),
          offset: Offset(12, hover ? 16 : 12),
          blurRadius: hover ? 28 : 24,
        ),
        BoxShadow(
          color: ClayTokens.highlight.withValues(alpha: 0.4),
          offset: const Offset(-8, -8),
          blurRadius: 16,
        ),
        BoxShadow(
          color: ClayTokens.highlight.withValues(alpha: 0.4),
          offset: const Offset(4, 4),
          blurRadius: 8,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          offset: const Offset(-4, -4),
          blurRadius: 8,
        ),
      ];

  /// Clay Pressed — recessed inputs & active buttons.
  static List<BoxShadow> clayPressedShadows() => [
        BoxShadow(
          color: ClayTokens.shadowDark,
          offset: const Offset(5, 5),
          blurRadius: 12,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: ClayTokens.highlight,
          offset: const Offset(-5, -5),
          blurRadius: 12,
          spreadRadius: -2,
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
          Border.all(
            color: ClayTokens.highlight.withValues(alpha: glass ? 0.7 : 0.65),
            width: 1.5,
          ),
      boxShadow: switch (depth) {
        ClayDepth.flat => null,
        ClayDepth.raised => clayCardShadows(),
        ClayDepth.floating => clayCardShadows(hover: true),
        ClayDepth.pressed => clayPressedShadows(),
        ClayDepth.card => clayCardShadows(),
        ClayDepth.button => clayButtonShadows(),
      },
    );
  }

  static BoxDecoration primaryButton({double radius = ClayTokens.radiusButton}) {
    return BoxDecoration(
      gradient: ClayTokens.primaryGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.35),
        width: 1.2,
      ),
      boxShadow: clayButtonShadows(),
    );
  }

  static BoxDecoration glassOverlay({double radius = ClayTokens.radiusCard}) {
    return BoxDecoration(
      color: ClayTokens.cardGlass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.6),
        width: 1.5,
      ),
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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: child,
      ),
    );
  }
}
