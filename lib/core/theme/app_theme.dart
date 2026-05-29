import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'paytrack_theme_extension.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF6C5CE7);
  static const primaryDark = Color(0xFF5B4FD6);
  static const primaryLight = Color(0xFFA29BFE);
  static const accent = Color(0xFF00CEC9);
  static const success = Color(0xFF00B894);
  static const warning = Color(0xFFE6A817);
  static const error = Color(0xFFE85D5D);

  static const darkBg = Color(0xFF0D0D12);
  static const darkSurface = Color(0xFF16161F);
  static const darkCard = Color(0xFF1E1E2A);

  // Light palette — warm neutral base, not flat white
  static const lightBg = Color(0xFFF0F2F8);
  static const lightSurface = Color(0xFFFAFBFE);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardMuted = Color(0xFFF5F6FA);
  static const lightBorder = Color(0xFFE4E7EF);
  static const lightBorderSubtle = Color(0xFFEDEFF5);

  static const lightTextPrimary = Color(0xFF1A1D26);
  static const lightTextSecondary = Color(0xFF5C6370);
  static const lightTextTertiary = Color(0xFF8B92A0);

  static const gradientStart = Color(0xFF6C5CE7);
  static const gradientEnd = Color(0xFF00CEC9);
}

class AppTheme {
  AppTheme._();

  static const _lightExtras = PayTrackThemeExtension(
    glassGradientStart: Color(0xFFFFFFFF),
    glassGradientEnd: Color(0xFFF6F4FF),
    glassBorder: Color(0xFFE4E7EF),
    cardShadow: Color(0x141A1D26),
    elevatedShadow: Color(0x1F1A1D26),
    tonalSurface: Color(0xFFEDE9FE),
    tonalBorder: Color(0xFFD4CCF7),
    tonalIconBackground: Color(0xFFE0DAFC),
    inputFill: Color(0xFFF5F6FA),
    inputBorder: Color(0xFFE4E7EF),
    inputFocusedBorder: Color(0xFF6C5CE7),
    navBarBackground: Color(0xFFFAFBFE),
    navIndicator: Color(0x1A6C5CE7),
    chartAreaFill: Color(0x336C5CE7),
    heroShadow: Color(0x406C5CE7),
    useSoftGlassBlur: true,
  );

  static const _darkExtras = PayTrackThemeExtension(
    glassGradientStart: Color(0x14FFFFFF),
    glassGradientEnd: Color(0x08FFFFFF),
    glassBorder: Color(0x1AFFFFFF),
    cardShadow: Color(0x4D000000),
    elevatedShadow: Color(0x66000000),
    tonalSurface: Color(0x1AFFFFFF),
    tonalBorder: Color(0x24FFFFFF),
    tonalIconBackground: Color(0x24FFFFFF),
    inputFill: AppColors.darkCard,
    inputBorder: Color(0x24FFFFFF),
    inputFocusedBorder: AppColors.primaryLight,
    navBarBackground: AppColors.darkSurface,
    navIndicator: Color(0x336C5CE7),
    chartAreaFill: Color(0x336C5CE7),
    heroShadow: Color(0x596C5CE7),
    useSoftGlassBlur: false,
  );

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryDark,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFEDE9FE),
      onPrimaryContainer: Color(0xFF3D2F9E),
      secondary: Color(0xFF0891A8),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD5F5F3),
      onSecondaryContainer: Color(0xFF0D5C6B),
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: Color(0xFFFFE8E8),
      onErrorContainer: Color(0xFF8B2E2E),
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightBorderSubtle,
      shadow: Color(0x1A1A1D26),
      scrim: Color(0x661A1D26),
      inverseSurface: AppColors.lightTextPrimary,
      onInverseSurface: AppColors.lightSurface,
      inversePrimary: AppColors.primaryLight,
      surfaceTint: AppColors.primary,
      surfaceContainerHighest: Color(0xFFE8EBF2),
      surfaceContainerHigh: Color(0xFFEEF0F5),
      surfaceContainer: Color(0xFFF3F4F8),
      surfaceContainerLow: AppColors.lightCardMuted,
      surfaceContainerLowest: AppColors.lightBg,
    );

    final textTheme = _textTheme(Brightness.light, scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: textTheme,
      extensions: const [_lightExtras],
      dividerColor: AppColors.lightBorderSubtle,
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorderSubtle,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorderSubtle),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.surfaceContainerHigh,
        labelStyle: textTheme.labelMedium!.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightBorderSubtle),
        ),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightExtras.inputFill,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.lightTextTertiary,
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.lightTextSecondary,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.8)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: _lightExtras.navBarBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _lightExtras.navIndicator,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall!.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : AppColors.lightTextTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.primary : AppColors.lightTextTertiary,
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightTextPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.lightTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.85);
          }
          return AppColors.lightBorder;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primaryContainer;
            }
            return scheme.surfaceContainerLow;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimaryContainer;
            }
            return scheme.onSurfaceVariant;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: const BorderSide(color: AppColors.lightBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.12),
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.darkBg,
      primaryContainer: Color(0xFF3D3380),
      onPrimaryContainer: Color(0xFFE8E4FF),
      secondary: AppColors.accent,
      onSecondary: AppColors.darkBg,
      secondaryContainer: Color(0xFF0D4A52),
      onSecondaryContainer: Color(0xFFB8F5F0),
      tertiary: AppColors.accent,
      onTertiary: AppColors.darkBg,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: Colors.white,
      onSurfaceVariant: Color(0xFFB2BEC3),
      outline: Color(0xFF2D3140),
      outlineVariant: Color(0xFF252836),
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: Colors.white,
      onInverseSurface: AppColors.darkBg,
      inversePrimary: AppColors.primary,
      surfaceTint: AppColors.primaryLight,
      surfaceContainerHighest: Color(0xFF2A2A38),
      surfaceContainerHigh: Color(0xFF222230),
      surfaceContainer: AppColors.darkCard,
      surfaceContainerLow: Color(0xFF1A1A24),
      surfaceContainerLowest: AppColors.darkBg,
    );

    final textTheme = _textTheme(Brightness.dark, scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: textTheme,
      extensions: const [_darkExtras],
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkExtras.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: _darkExtras.navBarBackground,
        indicatorColor: _darkExtras.navIndicator,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness, Color onSurface) {
    final primary = brightness == Brightness.dark
        ? Colors.white
        : AppColors.lightTextPrimary;
    final secondary = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.72)
        : AppColors.lightTextSecondary;
    final tertiary = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.lightTextTertiary;

    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -1,
        height: 1.15,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary.withValues(alpha: 0.92),
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: tertiary,
        height: 1.35,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: tertiary,
      ),
    );
  }
}
