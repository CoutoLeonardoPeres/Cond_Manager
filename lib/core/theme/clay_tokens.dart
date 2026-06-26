import 'package:flutter/material.dart';

/// High-Fidelity Claymorphism — design tokens (candy shop palette).
abstract final class ClayTokens {
  // Canvas & surfaces
  static const canvas = Color(0xFFF4F1FA);
  static const cardBg = Color(0xFFFFFFFF);
  static const cardGlass = Color(0x99FFFFFF); // white/60
  static const inputBg = Color(0xFFEFEBF5);
  static const surface = Color(0xFFF4F1FA);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const surfacePressed = Color(0xFFEFEBF5);

  // Foreground
  static const foreground = Color(0xFF332F3A);
  static const textPrimary = foreground;
  static const muted = Color(0xFF635F69);
  static const textSecondary = muted;
  static const textMuted = Color(0xFF7A7580);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Candy accents
  static const accent = Color(0xFF7C3AED);
  static const accentAlt = Color(0xFFDB2777);
  static const tertiary = Color(0xFF0EA5E9);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);

  // Legacy aliases (compat)
  static const primary = accent;
  static const primaryDark = Color(0xFF6D28D9);
  static const primaryLight = Color(0xFFA78BFA);
  static const secondary = tertiary;
  static const accentWarm = warning;
  static const info = tertiary;

  // Shadow palette
  static const shadowPurple = Color(0xFF8B5CF6);
  static const shadowAmbient = Color(0xFFCDC6D9);
  static const shadowCard = Color(0xFFA096B4);
  static const shadowDark = Color(0xFFD9D4E3);
  static const shadowDeep = Color(0xFFCDC6D9);
  static const highlight = Color(0xFFFFFFFF);

  // Super-rounded radii (minimum 20px)
  static const radiusButton = 20.0;
  static const radiusMd = 24.0;
  static const radiusCard = 32.0;
  static const radiusLg = 40.0;
  static const radiusXl = 48.0;
  static const radiusHero = 60.0;
  static const radiusSm = 20.0;
  static const radiusXs = 20.0;
  static const radiusFull = 999.0;

  static double gap(double value) => value;

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [canvas, Color(0xFFF0ECF8), canvas],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA78BFA), accent],
  );

  static const primaryGradientHover = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC4B5FD), Color(0xFF8B5CF6)],
  );

  static const brandPanelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA78BFA), accent, Color(0xFFDB2777)],
  );

  static const textGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [foreground, accent, accentAlt],
    stops: [0.2, 0.6, 1.0],
  );

  static const iconGradients = [
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFC084FC), accent],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF472B6), accentAlt],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF34D399), success],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF22D3EE), tertiary],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFBBF24), warning],
    ),
  ];

  static Gradient iconGradientAt(int index) =>
      iconGradients[index % iconGradients.length];
}

/// Compatibilidade com imports legados de `AppColors`.
abstract final class AppColors {
  static const primary = ClayTokens.primary;
  static const primaryLight = ClayTokens.primaryLight;
  static const secondary = ClayTokens.secondary;
  static const surface = ClayTokens.surface;
  static const error = ClayTokens.error;
  static const success = ClayTokens.success;
  static const warning = ClayTokens.warning;
  static const textPrimary = ClayTokens.textPrimary;
  static const textSecondary = ClayTokens.textSecondary;
}
