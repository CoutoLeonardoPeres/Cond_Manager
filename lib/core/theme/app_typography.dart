import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Poppins (headings) + Inter (body) na web; fontes do sistema no mobile (sem rede).
abstract final class AppTypography {
  static const double contentScale = 1.0;
  static const double navScale = 1.0;

  static TextScaler get contentTextScaler => TextScaler.linear(contentScale);
  static TextScaler get navTextScaler => TextScaler.noScaling;

  static bool get _useGoogleFonts => kIsWeb;

  static String get headingFamily => _useGoogleFonts ? _googleHeadingFamily() : 'sans-serif';
  static String get bodyFamily => _useGoogleFonts ? _googleBodyFamily() : 'sans-serif';

  static String _googleHeadingFamily() {
    try {
      return GoogleFonts.poppins().fontFamily ?? 'sans-serif';
    } catch (_) {
      return 'sans-serif';
    }
  }

  static String _googleBodyFamily() {
    try {
      return GoogleFonts.inter().fontFamily ?? 'sans-serif';
    } catch (_) {
      return 'sans-serif';
    }
  }

  static TextStyle heading({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    final spacing = letterSpacing ?? (fontSize != null && fontSize > 28 ? -0.5 : -0.2);
    if (!_useGoogleFonts) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: spacing,
        height: height ?? 1.2,
      );
    }
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: spacing,
      height: height ?? 1.2,
    );
  }

  static TextStyle body({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
  }) {
    if (!_useGoogleFonts) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.5,
      );
    }
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height ?? 1.5,
    );
  }

  static TextTheme buildTextTheme() {
    final base = _useGoogleFonts ? _googleBaseTextTheme() : ThemeData.light().textTheme;

    return base.copyWith(
      displayLarge: heading(fontSize: 57, fontWeight: FontWeight.w700),
      displayMedium: heading(fontSize: 45, fontWeight: FontWeight.w700),
      displaySmall: heading(fontSize: 36, fontWeight: FontWeight.w700),
      headlineLarge: heading(fontSize: 32, fontWeight: FontWeight.w700),
      headlineMedium: heading(fontSize: 28, fontWeight: FontWeight.w700),
      headlineSmall: heading(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: heading(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: heading(fontSize: 18, fontWeight: FontWeight.w600),
      titleSmall: heading(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: body(fontSize: 16),
      bodyMedium: body(fontSize: 14),
      bodySmall: body(fontSize: 12, color: ClayTokens.muted),
      labelLarge: body(fontSize: 15, fontWeight: FontWeight.w600),
      labelMedium: body(fontSize: 13, fontWeight: FontWeight.w500, color: ClayTokens.muted),
      labelSmall: body(fontSize: 11, fontWeight: FontWeight.w500, color: ClayTokens.muted),
    ).apply(
      bodyColor: ClayTokens.foreground,
      displayColor: ClayTokens.foreground,
    );
  }

  static TextTheme _googleBaseTextTheme() {
    try {
      return GoogleFonts.interTextTheme();
    } catch (_) {
      return ThemeData.light().textTheme;
    }
  }
}
