// lib/theme/app_theme.dart

import 'package:flutter/material.dart';



class AppColors {

  static const Color background = Color(0xFF38BDF8); // Vibrant cartoon sky blue

  static const Color surface = Colors.white;    

  static const Color surfaceElevated = Color(0xFFF8FAFC);

 

  static const Color gold = Color(0xFFFBBF24); // Cartoon bright yellow      

  static const Color darkBrown = Colors.black; // Text and borders are strictly black  

  static const Color border = Colors.black; // Thick comic outlines    



  static const Color profit = Color(0xFF4ADE80); // Playful green    

  static const Color loss = Color(0xFFF87171); // Playful red      

  static const Color textPrimary = Colors.black;

  static const Color textSecondary = Color(0xFF334155);

  static const Color textMuted = Color(0xFF64748B);



  static const Color neonCyan = Color(0xFF0EA5E9);

}



class AppTheme {

  static ThemeData get tycoonTheme {

    return ThemeData(

      brightness: Brightness.light,

      scaffoldBackgroundColor: AppColors.background,

      fontFamily: 'Inter',

      textTheme: const TextTheme(

        bodyMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900),

        titleLarge: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900),

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

      ]

    );

  }

}