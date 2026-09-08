// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/game_state.dart';
import 'screens/main_menu_screen.dart';
import 'screens/map_screen.dart'; // Harita ekranını import ediyoruz
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // GameState'i başlat ve telefondaki verileri yükle
  final gameState = GameState();
  await gameState.loadData();

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

  runApp(
    ChangeNotifierProvider.value(
      value: gameState,
      child: const HoldingTycoonApp(),
    ),
  );
}

class HoldingTycoonApp extends StatelessWidget {
  const HoldingTycoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Uygulama açıldığında veritabanındaki ilk giriş bilgisini sadece bir kez okuyoruz
    final isFirstLaunch = context.read<GameState>().isFirstLaunch;

    return MaterialApp(
      title: 'Holding Tycoon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // EĞER İLK GİRİŞ İSE: Ana Menüyü (İlk kurulum moduyla) aç
      // DEĞİLSE: Doğrudan Harita Ekranını aç
      home: isFirstLaunch 
          ? const MainMenuScreen(isInitialLaunch: true)
          : const MapScreen(),
    );
  }
}