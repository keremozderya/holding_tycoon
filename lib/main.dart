import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_menu_screen.dart';
import 'screens/map_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

  runApp(HoldingTycoonApp(isFirstTime: isFirstTime));
}

class HoldingTycoonApp extends StatelessWidget {
  final bool isFirstTime;

  const HoldingTycoonApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Holding Tycoon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isFirstTime
          ? const MainMenuScreen(isInitialLaunch: true)
          : const MapScreen(),
    );
  }
}