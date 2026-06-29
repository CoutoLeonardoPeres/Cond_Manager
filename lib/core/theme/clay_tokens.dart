import 'package:flutter/material.dart';

/// Soft Dark & Mint — medical-dashboard design tokens.
abstract final class ClayTokens {
  // Canvas & surfaces
  static const canvas = Color(0xFFE8F4F2);
  static const canvasLight = Color(0xFFF0F9F7);
  static const cardBg = Color(0xFFFFFFFF);
  static const cardMint = Color(0xFFF5FBFA);
  static const cardGlass = Color(0xFFFFFFFF);
  static const inputBg = Color(0xFFFFFFFF);
  static const surface = canvas;
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const surfacePressed = Color(0xFFDCEFEA);

  // Sidebar
  static const sidebar = Color(0xFF2C3E50);
  static const sidebarMuted = Color(0xFF8FA3B1);
  static const sidebarActive = Color(0xFFFFFFFF);

  // Foreground
  static const foreground = Color(0xFF1A2B2E);
  static const textPrimary = foreground;
  static const muted = Color(0xFF6B8A8E);
  static const textSecondary = muted;
  static const textMuted = Color(0xFF8FA3A8);
  static const textOnPrimary = Color(0xFFFFFFFF);
  static const textOnSidebar = Color(0xFFB8C9D0);

  // Accents
  static const accent = Color(0xFF00BFA5);
  static const accentAlt = Color(0xFF00ACC1);
  static const accentLight = Color(0xFFB2DFDB);
  static const accentSurface = Color(0xFFE0F2F1);
  static const tertiary = accentAlt;
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);

  // Legacy aliases (compat)
  static const primary = accent;
  static const primaryDark = Color(0xFF00897B);
  static const primaryLight = Color(0xFF4DB6AC);
  static const secondary = accentAlt;
  static const accentWarm = warning;
  static const info = accentAlt;

  // Shadow palette — soft, low-opacity
  static const shadowPurple = Color(0xFF1A2B2E);
  static const shadowAmbient = Color(0xFF1A2B2E);
  static const shadowCard = Color(0xFF1A2B2E);
  static const shadowDark = Color(0xFF1A2B2E);
  static const shadowDeep = Color(0xFF1A2B2E);
  static const highlight = Color(0xFFFFFFFF);

  // Rounded corners (16–24px)
  static const radiusButton = 20.0;
  static const radiusMd = 20.0;
  static const radiusCard = 20.0;
  static const radiusLg = 24.0;
  static const radiusXl = 24.0;
  static const radiusHero = 24.0;
  static const radiusSm = 16.0;
  static const radiusXs = 12.0;
  static const radiusFull = 999.0;

  static double gap(double value) => value;

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [canvas, canvasLight, Color(0xFFE0F0EC)],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF26C6B5), accent],
  );

  static const primaryGradientHover = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4DD0C7), Color(0xFF00A896)],
  );

  static const brandPanelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sidebar, Color(0xFF34495E), Color(0xFF2C3E50)],
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
      colors: [Color(0xFF4DD0C7), accent],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF80DEEA), accentAlt],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFA7FFEB), Color(0xFF00BFA5)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6EE7B7), success],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF5EEAD4), Color(0xFF14B8A6)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF67E8F9), Color(0xFF0891B2)],
    ),
  ];

  static Gradient iconGradientAt(int index) =>
      iconGradients[index % iconGradients.length];

  static const divider = Color(0xFFE2ECEA);
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
