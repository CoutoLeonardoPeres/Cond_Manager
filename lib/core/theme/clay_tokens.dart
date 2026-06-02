import 'package:flutter/material.dart';

/// Tokens visuais do design system Claymorphism ultramoderno.
abstract final class ClayTokens {
  // Fundo (gradiente mesh)
  static const bgTop = Color(0xFFE8EEFF);
  static const bgMid = Color(0xFFF3E8FF);
  static const bgBottom = Color(0xFFE6FAF5);

  // Superfícies clay
  static const surface = Color(0xFFF6F8FD);
  static const surfaceRaised = Color(0xFFFCFDFF);
  static const surfacePressed = Color(0xFFECEFF8);

  // Marca
  static const primary = Color(0xFF6C5CE7);
  static const primaryDark = Color(0xFF5849D4);
  static const primaryLight = Color(0xFF9B8FFF);
  static const secondary = Color(0xFF00CEC9);
  static const accent = Color(0xFFFF7675);
  static const accentWarm = Color(0xFFFDCB6E);

  // Semânticas
  static const success = Color(0xFF00B894);
  static const warning = Color(0xFFE17055);
  static const error = Color(0xFFD63031);
  static const info = Color(0xFF74B9FF);

  // Texto
  static const textPrimary = Color(0xFF2D3436);
  static const textSecondary = Color(0xFF636E72);
  static const textMuted = Color(0xFF95A5A6);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Sombras clay (neutras azuladas)
  static const shadowDark = Color(0xFFB8C4DB);
  static const shadowDeep = Color(0xFF9AABC8);
  static const highlight = Color(0xFFFFFFFF);

  // Raios
  static const radiusXs = 12.0;
  static const radiusSm = 16.0;
  static const radiusMd = 22.0;
  static const radiusLg = 28.0;
  static const radiusXl = 36.0;
  static const radiusFull = 999.0;

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgTop, bgMid, bgBottom],
    stops: [0.0, 0.45, 1.0],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B7CF6), primary, Color(0xFF5B8DEF)],
  );

  static const brandPanelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C6CF0), Color(0xFF5B7CFA), Color(0xFF48C6EF)],
  );
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
