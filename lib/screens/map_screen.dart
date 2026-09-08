import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'main_menu_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _holdingName = 'Holding';
  int _logoIndex = 0;

  final List<IconData> _defaultLogos = const [
    Icons.domain_rounded,
    Icons.account_balance_rounded,
    Icons.factory_rounded,
    Icons.rocket_launch_rounded,
    Icons.local_shipping_rounded,
    Icons.bolt_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadHoldingData();
  }

  Future<void> _loadHoldingData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _holdingName = prefs.getString('holding_name') ?? 'MyHolding';
      _logoIndex = prefs.getInt('holding_logo_index') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_defaultLogos[_logoIndex], color: AppColors.gold, size: 22),
            const SizedBox(width: 8),
            Text(
              _holdingName,
              style: AppTheme.titleStyle(fontSize: 18),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.gold),
          tooltip: 'Ana Menüye Dön',
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainMenuScreen(isInitialLaunch: false)),
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_rounded, size: 80, color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              'Harita Ekranı',
              style: AppTheme.titleStyle(fontSize: 22),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu ekranı ortağınız tasarlayacak.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Ana Menüye Dön'),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const MainMenuScreen(isInitialLaunch: false)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}