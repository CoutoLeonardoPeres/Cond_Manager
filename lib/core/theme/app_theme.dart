import 'package:cond_manager/core/theme/app_typography.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export 'clay_decorations.dart';
export 'clay_tokens.dart';

class AppTheme {
  static ThemeData get light {
    final textTheme = AppTypography.buildTextTheme();

    final colorScheme = ColorScheme.light(
      primary: ClayTokens.accent,
      onPrimary: ClayTokens.textOnPrimary,
      secondary: ClayTokens.tertiary,
      onSecondary: ClayTokens.foreground,
      surface: ClayTokens.surfaceRaised,
      onSurface: ClayTokens.foreground,
      error: ClayTokens.error,
      onError: ClayTokens.textOnPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ClayTokens.canvas,
      fontFamily: AppTypography.bodyFamily,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: ClayTokens.foreground,
        centerTitle: false,
        titleTextStyle: AppTypography.heading(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: ClayTokens.foreground,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ClayTokens.cardGlass,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusCard),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ClayTokens.inputBg,
        labelStyle: AppTypography.body(
          fontWeight: FontWeight.w600,
          color: ClayTokens.muted,
        ),
        hintStyle: AppTypography.body(color: ClayTokens.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusButton),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusButton),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusButton),
          borderSide: BorderSide(color: ClayTokens.accent.withValues(alpha: 0.4), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusButton),
          borderSide: const BorderSide(color: ClayTokens.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: ClayTokens.textOnPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClayTokens.radiusButton),
          ),
          textStyle: AppTypography.body(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ClayTokens.accent,
          textStyle: AppTypography.body(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 80,
        backgroundColor: Colors.transparent,
        indicatorColor: ClayTokens.accent.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? ClayTokens.accent : ClayTokens.muted,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedIconTheme: const IconThemeData(color: ClayTokens.accent, size: 26),
        unselectedIconTheme: IconThemeData(color: ClayTokens.muted.withValues(alpha: 0.9)),
        selectedLabelTextStyle: GoogleFonts.dmSans(
          color: ClayTokens.accent,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: GoogleFonts.dmSans(
          color: ClayTokens.muted,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: ClayTokens.shadowDark.withValues(alpha: 0.35),
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: ClayTokens.accent),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(ClayTokens.surfaceRaised),
          elevation: const WidgetStatePropertyAll(12),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
            ),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(ClayTokens.surfaceRaised),
          elevation: const WidgetStatePropertyAll(12),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
            ),
          ),
        ),
      ),
    );
  }
}
