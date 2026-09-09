// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Ortağın MapScreen'den gelen ana renkleri
  static const Color oceanBlue = Color(0xFF22CECE);
  static const Color islandGreen = Color(0xFFA5C05B);
  static const Color sandYellow = Color(0xFFF3D78F);
  static const Color asphaltDark = Color(0xFF2D2D2D);
  static const Color lighthouseRed = Color(0xFFD64D4D);

  // Ahşap ve UI Renkleri
  static const Color classicBrown = Color(0xFF5D4037);
  static const Color lightBrown = Color(0xFF7A574A);
  static const Color darkBrown = Color(0xFF3D2821);

  // --- SİSTEM RENK EŞLEŞTİRMELERİ ---
  static const Color background = asphaltDark; 
  static const Color surface = classicBrown;   
  static const Color surfaceElevated = lightBrown;
  static const Color border = darkBrown;

  static const Color gold = sandYellow;
  static const Color goldMuted = Color(0xFFDABF75);
  static const Color profit = islandGreen;
  static const Color loss = lighthouseRed;
  static const Color neonCyan = oceanBlue;

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = sandYellow; 
  static const Color textMuted = Colors.white60;

  static const LinearGradient tycoonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFB59A45), sandYellow, Color(0xFFF2DC8F)],
    stops: [0.0, 0.4, 1.0],
  );
}

class AppTheme {
  static ThemeData get tycoonTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface,
      dividerColor: AppColors.border,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),
    );
  }

  static TextStyle titleStyle({double fontSize = 32}) {
    return TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
      letterSpacing: 0.5,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.5),
          offset: const Offset(1, 2),
          blurRadius: 2,
        )
      ],
    );
  }

  static TextStyle subtitleStyle({double fontSize = 14}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: AppColors.gold,
      letterSpacing: 1.0,
    );
  }

  static TextStyle get moneyStyle => GoogleFonts.spaceMono(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.profit,
        letterSpacing: 0.5,
      );
}