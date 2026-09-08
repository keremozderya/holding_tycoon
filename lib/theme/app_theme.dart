// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  static const Color gold = Color(0xFF9A7326);
  static const Color goldMuted = Color(0xFFB58F45);
  static const Color profit = Color(0xFF047857);
  static const Color loss = Color(0xFFB91C1C);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFB38B38), Color(0xFF8B641C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface,
      dividerColor: AppColors.border,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ),
    );
  }

  static TextStyle titleStyle({double fontSize = 32}) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: 1.2,
    );
  }

  static TextStyle subtitleStyle({double fontSize = 14}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: AppColors.gold,
      letterSpacing: 1.0,
    );
  }

  static TextStyle get moneyStyle => GoogleFonts.spaceMono(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.profit,
        letterSpacing: 0.5,
      );
}