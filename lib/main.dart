// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/game_state.dart';
import 'screens/main_menu_screen.dart';
import 'screens/map_screen.dart';
import 'theme/app_theme.dart';
import 'services/audio_service.dart'; // AudioService eklendi

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

// YENİ: Arka plana atılmayı dinleyebilmek için StatefulWidget'a dönüştürüldü
class HoldingTycoonApp extends StatefulWidget {
  const HoldingTycoonApp({super.key});

  @override
  State<HoldingTycoonApp> createState() => _HoldingTycoonAppState();
}

class _HoldingTycoonAppState extends State<HoldingTycoonApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // YENİ: Uygulamanın anlık durumu değiştiğinde tetiklenen sistem (Arka plan/Ön plan)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      AudioService.instance.pauseBgm();
    } else if (state == AppLifecycleState.resumed) {
      AudioService.instance.resumeBgm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return MaterialApp(
          key: ValueKey(gameState.language), 
          title: 'Holding Tycoon',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.tycoonTheme, 
          home: gameState.isFirstLaunch 
              ? const MainMenuScreen(isInitialLaunch: true)
              : const MapScreen(),
        );
      },
    );
  }
}