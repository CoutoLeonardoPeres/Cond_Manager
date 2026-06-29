import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Poppins (headings) + Inter (body) — Soft Dark & Mint dashboard.
abstract final class AppTypography {
  static const double contentScale = 1.0;
  static const double navScale = 1.0;

  static TextScaler get contentTextScaler => TextScaler.linear(contentScale);
  static TextScaler get navTextScaler => TextScaler.noScaling;

  static String get headingFamily => GoogleFonts.poppins().fontFamily!;
  static String get bodyFamily => GoogleFonts.inter().fontFamily!;

  static TextStyle heading({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing ?? (fontSize != null && fontSize > 28 ? -0.5 : -0.2),
        height: height ?? 1.2,
      );

  static TextStyle body({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.5,
      );

  static TextTheme buildTextTheme() {
    final bodyBase = GoogleFonts.interTextTheme();
    return bodyBase.copyWith(
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
}
