import 'package:cond_manager/core/theme/app_typography.dart';
import 'package:cond_manager/core/theme/clay_tokens.dart';
import 'package:flutter/material.dart';

export 'clay_decorations.dart';
export 'clay_tokens.dart';

class AppTheme {
  static ThemeData get light {
    final textTheme = AppTypography.buildTextTheme();

    final colorScheme = ColorScheme.light(
      primary: ClayTokens.accent,
      onPrimary: ClayTokens.textOnPrimary,
      secondary: ClayTokens.accentAlt,
      onSecondary: ClayTokens.foreground,
      surface: ClayTokens.surfaceRaised,
      onSurface: ClayTokens.foreground,
      surfaceContainerHighest: ClayTokens.cardMint,
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
          fontWeight: FontWeight.w700,
          color: ClayTokens.foreground,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ClayTokens.cardBg,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusCard),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ClayTokens.inputBg,
        labelStyle: AppTypography.body(
          fontWeight: FontWeight.w500,
          color: ClayTokens.muted,
        ),
        hintStyle: AppTypography.body(color: ClayTokens.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
          borderSide: BorderSide(color: ClayTokens.divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
          borderSide: BorderSide(color: ClayTokens.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
          borderSide: const BorderSide(color: ClayTokens.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusFull),
          borderSide: const BorderSide(color: ClayTokens.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: ClayTokens.accent,
          shadowColor: Colors.transparent,
          foregroundColor: ClayTokens.textOnPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClayTokens.radiusButton),
          ),
          textStyle: AppTypography.body(fontWeight: FontWeight.w600, fontSize: 15),
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
        height: 72,
        backgroundColor: ClayTokens.sidebar,
        indicatorColor: ClayTokens.sidebarActive.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.body(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? ClayTokens.accent : ClayTokens.sidebarMuted,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: ClayTokens.sidebar,
        selectedIconTheme: const IconThemeData(color: ClayTokens.accent, size: 24),
        unselectedIconTheme: const IconThemeData(color: ClayTokens.sidebarMuted, size: 24),
        selectedLabelTextStyle: AppTypography.body(
          color: ClayTokens.accent,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: AppTypography.body(
          color: ClayTokens.sidebarMuted,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ClayTokens.divider,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: ClayTokens.accent),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ClayTokens.foreground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(ClayTokens.surfaceRaised),
          elevation: const WidgetStatePropertyAll(8),
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
          elevation: const WidgetStatePropertyAll(8),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ClayTokens.radiusMd),
            ),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClayTokens.radiusSm),
        ),
      ),
    );
  }
}
