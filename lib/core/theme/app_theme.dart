import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export 'clay_decorations.dart';
export 'clay_tokens.dart';

class AppTheme {
  static ThemeData get light {
    final baseText = GoogleFonts.plusJakartaSansTextTheme();
    final textTheme = baseText.apply(
      bodyColor: ClayTokens.textPrimary,
      displayColor: ClayTokens.textPrimary,
    );

    final colorScheme = ColorScheme.light(
      primary: ClayTokens.primary,
      onPrimary: ClayTokens.textOnPrimary,
      secondary: ClayTokens.secondary,
      onSecondary: ClayTokens.textPrimary,
      surface: ClayTokens.surfaceRaised,
      onSurface: ClayTokens.textPrimary,
      error: ClayTokens.error,
      onError: ClayTokens.textOnPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ClayTokens.bgTop,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: ClayTokens.textPrimary,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: ClayTokens.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ClayTokens.surfaceRaised,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ClayTokens.surface,
        labelStyle: const TextStyle(color: ClayTokens.textSecondary),
        hintStyle: const TextStyle(color: ClayTokens.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
          borderSide: const BorderSide(color: ClayTokens.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
          borderSide: const BorderSide(color: ClayTokens.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: ClayTokens.textOnPrimary,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ClayTokens.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: Colors.transparent,
        indicatorColor: ClayTokens.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? ClayTokens.primary : ClayTokens.textMuted,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedIconTheme: const IconThemeData(color: ClayTokens.primary, size: 26),
        unselectedIconTheme: IconThemeData(color: ClayTokens.textMuted.withValues(alpha: 0.9)),
        selectedLabelTextStyle: const TextStyle(
          color: ClayTokens.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: ClayTokens.textMuted,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: ClayTokens.shadowDark.withValues(alpha: 0.25),
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ClayTokens.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
        ),
      ),
    );
  }
}
