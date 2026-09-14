// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppColors {
  // Shared game background. This stays the same in both themes so the theme
  // option only changes the white/light UI surfaces.
  static const Color background = Color(0xFF38BDF8); // Vibrant cartoon sky blue

  // ---------------------------------------------------------------------------
  // LIGHT THEME SURFACES
  // ---------------------------------------------------------------------------
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFF8FAFC);
  static const Color surfaceSoft = Color(0xFFF1F5F9);
  static const Color surfaceMuted = Color(0xFFE2E8F0);

  // ---------------------------------------------------------------------------
  // DARK CARTOON-BLUE THEME SURFACES
  // ---------------------------------------------------------------------------
  // These are intentionally darker than the previous blue palette while still
  // remaining bright enough for the game's black text and thick comic outlines.
  static const Color darkSurface = Color(0xFF4A78B0);
  static const Color darkSurfaceElevated = Color(0xFF477AB8);
  static const Color darkSurfaceSoft = Color(0xFF5C90CA);
  static const Color darkSurfaceMuted = Color(0xFF4779B5);

  // Shared accent colors.
  static const Color gold = Color(0xFFFBBF24); // Cartoon bright yellow
  static const Color darkBrown = Colors.black; // Text and borders are strictly black
  static const Color border = Colors.black; // Thick comic outlines

  static const Color profit = Color(0xFF4ADE80); // Playful green
  static const Color loss = Color(0xFFF87171); // Playful red
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);

  static const Color neonCyan = Color(0xFF0EA5E9);

  // ---------------------------------------------------------------------------
  // THEME-AWARE SURFACE HELPERS
  // ---------------------------------------------------------------------------
  // Existing screens can call these helpers instead of duplicating theme logic.
  static Color surfaceFor(bool darkSurfaces) =>
      darkSurfaces ? darkSurface : surface;

  static Color elevatedSurfaceFor(bool darkSurfaces) =>
      darkSurfaces ? darkSurfaceElevated : surfaceElevated;

  static Color softSurfaceFor(bool darkSurfaces) =>
      darkSurfaces ? darkSurfaceSoft : surfaceSoft;

  static Color mutedSurfaceFor(bool darkSurfaces) =>
      darkSurfaces ? darkSurfaceMuted : surfaceMuted;
}

class AppTheme {
  // Backward-compatible default used by existing code.
  static ThemeData get tycoonTheme => lightTheme;

  // Explicit light theme.
  static ThemeData get lightTheme => _buildTheme(darkSurfaces: false);

  // Explicit dark cartoon-blue theme.
  static ThemeData get darkTheme => _buildTheme(darkSurfaces: true);

  // Existing theme-aware entry point used by the game.
  static ThemeData tycoonThemeFor({bool darkSurfaces = false}) {
    return darkSurfaces ? darkTheme : lightTheme;
  }

  static ThemeData _buildTheme({required bool darkSurfaces}) {
    final Color selectedSurface = AppColors.surfaceFor(darkSurfaces);
    final Color selectedElevatedSurface =
        AppColors.elevatedSurfaceFor(darkSurfaces);

    // Brightness intentionally remains light because this game's visual system
    // uses black text and heavy black outlines even on its darker cartoon-blue
    // surfaces. Switching Flutter to Brightness.dark would alter many controls
    // beyond the intended white -> blue surface change.
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: selectedSurface,
      cardColor: selectedSurface,
      dialogTheme: DialogThemeData(
        backgroundColor: selectedSurface,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: selectedElevatedSurface,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
        titleLarge: TextStyle(
          color: AppColors.gold,
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
      shadows: const [
        Shadow(color: Colors.black, offset: Offset(2, 2)),
      ],
    );
  }
}
