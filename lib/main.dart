// lib/main.dart
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/game_state.dart';
import 'screens/main_menu_screen.dart';
import 'screens/map_screen.dart';
import 'services/admob_service.dart';
import 'services/audio_service.dart';
import 'services/translation_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final gameState = GameState();
  await gameState.loadData();

  try {
    await AdMobService.initialize();
  } catch (error) {
    debugPrint('Ads could not be initialized: $error');
  }

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ChangeNotifierProvider<GameState>.value(
      value: gameState,
      child: const HoldingTycoonApp(),
    ),
  );
}

class HoldingTycoonApp extends StatefulWidget {
  const HoldingTycoonApp({super.key});

  @override
  State<HoldingTycoonApp> createState() => _HoldingTycoonAppState();
}

class _HoldingTycoonAppState extends State<HoldingTycoonApp>
    with WidgetsBindingObserver {
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      AudioService.instance.pauseBgm(reason: 'app_lifecycle');
    } else if (state == AppLifecycleState.resumed) {
      AudioService.instance.resumeBgm(reason: 'app_lifecycle');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final dark = gameState.useDarkTheme;
        final overlay = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              dark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: AppColors.surfaceFor(dark),
          systemNavigationBarIconBrightness:
              dark ? Brightness.light : Brightness.dark,
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: MaterialApp(
            title: 'app_title'.tr(),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: gameState.isFirstLaunch
                ? const MainMenuScreen(isInitialLaunch: true)
                : const MapScreen(),
          ),
        );
      },
    );
  }
}
