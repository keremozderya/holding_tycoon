// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/game_state.dart';
import 'screens/main_menu_screen.dart';
import 'screens/map_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final gameState = GameState();
  await gameState.loadData();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
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
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return MaterialApp(
          key: ValueKey(gameState.language), 
          title: 'Holding Tycoon',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.tycoonTheme, // DÜZELTİLDİ: darkTheme yerine tycoonTheme oldu
          home: gameState.isFirstLaunch 
              ? const MainMenuScreen(isInitialLaunch: true)
              : const MapScreen(),
        );
      },
    );
  }
}