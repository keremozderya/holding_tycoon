// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF38BDF8);

  // Light surfaces.
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFF8FAFC);
  static const Color surfaceSoft = Color(0xFFF1F5F9);
  static const Color surfaceMuted = Color(0xFFE2E8F0);

  // Dark cartoon-blue surfaces. These replace the old, relatively bright
  // #4A78B0 family and deliberately provide much stronger contrast.
  static const Color darkBackground = Color(0xFF071A2F);
  static const Color darkSurface = Color(0xFF12365C);
  static const Color darkSurfaceElevated = Color(0xFF19466F);
  static const Color darkSurfaceSoft = Color(0xFF205783);
  static const Color darkSurfaceMuted = Color(0xFF173F67);

  static const Color gold = Color(0xFFFBBF24);
  static const Color darkBrown = Colors.black;
  static const Color border = Colors.black;

  static const Color profit = Color(0xFF4ADE80);
  static const Color loss = Color(0xFFF87171);
  static const Color neonCyan = Color(0xFF0EA5E9);

  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);

  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFD7E9FF);
  static const Color darkTextMuted = Color(0xFFA9C7E6);

  static Color backgroundFor(bool dark) =>
      dark ? darkBackground : background;

  static Color surfaceFor(bool dark) => dark ? darkSurface : surface;

  static Color elevatedSurfaceFor(bool dark) =>
      dark ? darkSurfaceElevated : surfaceElevated;

  static Color softSurfaceFor(bool dark) =>
      dark ? darkSurfaceSoft : surfaceSoft;

  static Color mutedSurfaceFor(bool dark) =>
      dark ? darkSurfaceMuted : surfaceMuted;

  static Color textPrimaryFor(bool dark) =>
      dark ? darkTextPrimary : textPrimary;

  static Color textSecondaryFor(bool dark) =>
      dark ? darkTextSecondary : textSecondary;

  static Color textMutedFor(bool dark) =>
      dark ? darkTextMuted : textMuted;
}

class AppTheme {
  static ThemeData get tycoonTheme => lightTheme;

  static ThemeData get lightTheme => _buildTheme(dark: false);

  static ThemeData get darkTheme => _buildTheme(dark: true);

  static ThemeData tycoonThemeFor({bool darkSurfaces = false}) =>
      darkSurfaces ? darkTheme : lightTheme;

  static ThemeData _buildTheme({required bool dark}) {
    final surface = AppColors.surfaceFor(dark);
    final elevated = AppColors.elevatedSurfaceFor(dark);
    final primaryText = AppColors.textPrimaryFor(dark);
    final secondaryText = AppColors.textSecondaryFor(dark);

    final scheme = dark
        ? const ColorScheme.dark(
            primary: AppColors.gold,
            secondary: AppColors.neonCyan,
            surface: AppColors.darkSurface,
            onSurface: Colors.white,
            onPrimary: Colors.black,
            onSecondary: Colors.white,
            error: AppColors.loss,
            onError: Colors.black,
          )
        : const ColorScheme.light(
            primary: AppColors.gold,
            secondary: AppColors.neonCyan,
            surface: AppColors.surface,
            onSurface: Colors.black,
            onPrimary: Colors.black,
            onSecondary: Colors.white,
            error: AppColors.loss,
            onError: Colors.white,
          );

    return ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundFor(dark),
      canvasColor: surface,
      cardColor: surface,
      dialogTheme: DialogThemeData(backgroundColor: surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
      popupMenuTheme: PopupMenuThemeData(color: elevated),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevated,
        contentTextStyle: TextStyle(
          color: primaryText,
          fontWeight: FontWeight.w900,
        ),
      ),
      iconTheme: IconThemeData(color: dark ? Colors.white : primaryText),
      primaryIconTheme: IconThemeData(color: dark ? Colors.white : primaryText),
      appBarTheme: AppBarTheme(
        iconTheme: IconThemeData(color: dark ? Colors.white : primaryText),
        actionsIconTheme: IconThemeData(color: dark ? Colors.white : primaryText),
      ),
      dividerColor: dark ? const Color(0xFF6E92B8) : Colors.black26,
      fontFamily: 'Inter',
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: primaryText,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(
          color: primaryText,
          fontWeight: FontWeight.w900,
        ),
        bodySmall: TextStyle(
          color: secondaryText,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w900,
        ),
        titleMedium: TextStyle(
          color: primaryText,
          fontWeight: FontWeight.w900,
        ),
        labelLarge: TextStyle(
          color: primaryText,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  static TextStyle titleStyle({double fontSize = 24}) {
    return TextStyle(
      fontFamily: 'SpaceMono',
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 2.0,
      color: Colors.white,
      shadows: const <Shadow>[
        Shadow(color: Colors.black, offset: Offset(2, 2)),
      ],
    );
  }
}
