import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF161F30);
  static const Color surfaceElevated = Color(0xFF202B42);
  static const Color gold = Color(0xFFE2B857);
  static const Color profit = Color(0xFF10B981);
  static const Color loss = Color(0xFFF43F5E);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),
    );
  }

  static TextStyle titleStyle({double fontSize = 32}) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: 2,
    );
  }

  static TextStyle subtitleStyle({double fontSize = 14}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.gold,
      letterSpacing: 1,
    );
  }

  static TextStyle get moneyStyle => GoogleFonts.spaceMono(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.profit,
        letterSpacing: 0.5,
      );
}