// lib/screens/map_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/prestige_dialog.dart';
import 'main_menu_screen.dart';
import 'research_screen.dart';
import 'stock_screen.dart'; // Borsa ekranını içeri aktardık

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _holdingName = 'Holding';
  int _logoIndex = 0;
  double _currentTurnover = 2.45e20;

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
        elevation: 0,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_rounded, size: 72, color: AppColors.gold),
              const SizedBox(height: 14),
              Text(
                'Sanayi Haritası',
                style: AppTheme.titleStyle(fontSize: 22),
              ),
              const SizedBox(height: 6),
              const Text(
                'Holding haritası ve arsa alanları burada yer alacak.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'TEST KONTROLLERİ',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.science_rounded, color: AppColors.gold, size: 20),
                        label: const Text(
                          'Araştırma Ağacı (Ar-Ge)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ResearchScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // YENİ EKLENEN BORSA TEST BUTONU
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.candlestick_chart_rounded, color: AppColors.profit, size: 20),
                        label: const Text(
                          'Küresel Borsa (Test)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const StockScreen()),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold.withValues(alpha: 0.12),
                          foregroundColor: AppColors.gold,
                          side: const BorderSide(color: AppColors.gold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                        label: const Text(
                          'Prestij Pop-up (100 Qi)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () {
                          PrestigeDialog.show(
                            context,
                            currentTurnover: _currentTurnover,
                            onPrestigeConfirmed: () {
                              setState(() {
                                final ratio = _currentTurnover / 1.0e20;
                                final int rp = (10 * math.sqrt(ratio)).floor();
                                _currentTurnover = 0;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.surface,
                                    content: Text(
                                      'Holding başarıyla tasfiye edildi! +$rp RP kazanıldı.',
                                      style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.textSecondary,
                  shadowColor: Colors.transparent,
                ),
                icon: const Icon(Icons.arrow_back, size: 18),
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
      ),
    );
  }
}