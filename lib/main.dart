// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_menu_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final bool isInitialLaunch = prefs.getBool('is_initial_launch') ?? true;

  runApp(HoldingTycoonApp(isInitialLaunch: isInitialLaunch));
}

class HoldingTycoonApp extends StatelessWidget {
  final bool isInitialLaunch;

  const HoldingTycoonApp({
    super.key,
    this.isInitialLaunch = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Holding Tycoon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: MainMenuScreen(isInitialLaunch: isInitialLaunch),
    );
  }
}