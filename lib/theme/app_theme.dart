// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F1115); 
  static const Color surface = Color(0xFF1A1C23);    
  static const Color surfaceElevated = Color(0xFF242731); 
  
  static const Color gold = Color(0xFFC5A059);       
  static const Color darkBrown = Color(0xFF1E1814);  
  static const Color border = Color(0xFF383E4C);     

  static const Color profit = Color(0xFF388E3C);     
  static const Color loss = Color(0xFFB71C1C);       
  static const Color textPrimary = Color(0xFFE2E8F0); 
  static const Color textSecondary = Color(0xFF94A3B8); 
  static const Color textMuted = Color(0xFF64748B);

  static const Color neonCyan = Color(0xFF0EA5E9); 
}

class AppTheme {
  static ThemeData get tycoonTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter', 
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        titleLarge: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900),
      ),
    );
  }

  static TextStyle titleStyle({double fontSize = 24}) {
    return TextStyle(
      fontFamily: 'Times New Roman', 
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
      color: AppColors.gold,
    );
  }
}