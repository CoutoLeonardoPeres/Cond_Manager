import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Nunito (headings) + DM Sans (body) — High-Fidelity Claymorphism.
abstract final class AppTypography {
  static const double contentScale = 1.0;
  static const double navScale = 1.0;

  static TextScaler get contentTextScaler => TextScaler.linear(contentScale);
  static TextScaler get navTextScaler => TextScaler.noScaling;

  static String get headingFamily => GoogleFonts.nunito().fontFamily!;
  static String get bodyFamily => GoogleFonts.dmSans().fontFamily!;

  static TextStyle heading({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w800,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.nunito(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing ?? (fontSize != null && fontSize > 28 ? -0.5 : 0),
        height: height ?? 1.1,
      );

  static TextStyle body({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.dmSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.625,
      );

  static TextTheme buildTextTheme() {
    final bodyBase = GoogleFonts.dmSansTextTheme();
    return bodyBase.copyWith(
      displayLarge: heading(fontSize: 57, fontWeight: FontWeight.w900),
      displayMedium: heading(fontSize: 45, fontWeight: FontWeight.w900),
      displaySmall: heading(fontSize: 36, fontWeight: FontWeight.w800),
      headlineLarge: heading(fontSize: 32, fontWeight: FontWeight.w900),
      headlineMedium: heading(fontSize: 28, fontWeight: FontWeight.w800),
      headlineSmall: heading(fontSize: 24, fontWeight: FontWeight.w800),
      titleLarge: heading(fontSize: 22, fontWeight: FontWeight.w700),
      titleMedium: heading(fontSize: 18, fontWeight: FontWeight.w700),
      titleSmall: heading(fontSize: 16, fontWeight: FontWeight.w700),
      bodyLarge: body(fontSize: 18),
      bodyMedium: body(fontSize: 16),
      bodySmall: body(fontSize: 14),
      labelLarge: body(fontSize: 15, fontWeight: FontWeight.w700),
      labelMedium: body(fontSize: 13, fontWeight: FontWeight.w600),
      labelSmall: body(fontSize: 11, fontWeight: FontWeight.w600),
    ).apply(
      bodyColor: const Color(0xFF332F3A),
      displayColor: const Color(0xFF332F3A),
    );
  }
}
