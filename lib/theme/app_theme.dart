// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Canlı Zeminler
  static const Color background = Color(0xFF0B0F28);
  static const Color surface = Color(0xFF171F42);
  static const Color surfaceElevated = Color(0xFF222B59);

  // Enerjik Neon Vurgular
  static const Color gold = Color(0xFFFFB800);
  static const Color profit = Color(0xFF00E676);
  static const Color techCyan = Color(0xFF00D2FF);
  static const Color loss = Color(0xFFFF3366);

  // Canlı Metinler
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA5B4FC);

  // Canlı Gradyanlar (Kartlar ve Butonlar İçin)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD000), Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient profitGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
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

  // Dinamik Başlık Stili
  static TextStyle titleStyle({double fontSize = 32}) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimary,
      letterSpacing: 1.8,
      shadows: [
        Shadow(
          color: AppColors.gold.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Canlı Alt Başlık
  static TextStyle subtitleStyle({double fontSize = 14}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: AppColors.gold,
      letterSpacing: 1.2,
    );
  }

  // Para ve Sayı Akışları İçin Neon Sayaç
  static TextStyle get moneyStyle => GoogleFonts.spaceMono(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: AppColors.profit,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: AppColors.profit.withValues(alpha: 0.5),
            blurRadius: 10,
          ),
        ],
      );
}