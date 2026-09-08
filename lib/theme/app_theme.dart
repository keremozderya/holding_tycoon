// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Premium Koyu Borsa & Holding Teması (Göz yormayan, lüks koyu gri/lacivert palet)
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF131C2E);
  static const Color surfaceElevated = Color(0xFF1E293B);
  static const Color border = Color(0xFF334155);

  static const Color gold = Color(0xFFF59E0B);
  static const Color goldMuted = Color(0xD9F59E0B);
  static const Color profit = Color(0xFF10B981);
  static const Color loss = Color(0xFFEF4444);
  static const Color neonCyan = Color(0xFF2DD4BF);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
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