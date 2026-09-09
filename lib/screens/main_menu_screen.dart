// lib/screens/main_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/game_state.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatefulWidget {
  final bool isInitialLaunch;
  const MainMenuScreen({super.key, this.isInitialLaunch = true});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    // Oyun açıldığında verileri anında yükle
    if (widget.isInitialLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GameState>().loadData();
      });
    }
  }

  void _goToMap() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }

  void _handleContinue() {
    final state = context.read<GameState>();
    if (state.isFirstLaunch) {
      _showHoldingSetupDialog();
    } else {
      _goToMap(); // Animasyonsuz, direkt haritaya geçiş
    }
  }

  void _showHoldingSetupDialog() {
    String compName = 'Köse Holding';
    int logoIndex = 0;
    final List<IconData> logos = [
      Icons.domain_rounded, Icons.account_balance_rounded, Icons.factory_rounded,
      Icons.rocket_launch_rounded, Icons.local_shipping_rounded, Icons.bolt_rounded,
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.gold, width: 2)),
            title: Text('menu.setup_holding'.tr(), textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 22).copyWith(color: AppColors.gold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'menu.company_name'.tr(),
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.profit)),
                  ),
                  onChanged: (val) => compName = val,
                ),
                const SizedBox(height: 24),
                Text('menu.choose_logo'.tr(), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
                  children: List.generate(logos.length, (i) {
                    bool isSel = logoIndex == i;
                    return GestureDetector(
                      onTap: () => setDialogState(() => logoIndex = i),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.gold.withValues(alpha: 0.2) : Colors.black45,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSel ? AppColors.gold : Colors.white24, width: 2),
                        ),
                        child: Icon(logos[i], color: isSel ? AppColors.gold : Colors.white54, size: 32),
                      ),
                    );
                  }),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold, foregroundColor: AppColors.darkBrown,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('holding_name', compName.isEmpty ? 'Köse Holding' : compName);
                  await prefs.setInt('holding_logo_index', logoIndex);
                  
                  if (context.mounted) {
                    context.read<GameState>().completeFirstLaunch();
                    Navigator.pop(context);
                    _goToMap(); // Kurulum biter bitmez anında haritaya geç
                  }
                },
                child: Text('menu.start'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return Scaffold(
      body: Stack(
        children: [
          // 1. YENİ PREMIUM KOYU ARKAPLAN (Diğer ekranlarla tam uyumlu)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, 
                end: Alignment.bottomRight,
                colors: [Color(0xFF14141C), Color(0xFF0A0A10)], 
              ),
            ),
          ),
          
          // 2. UI ELEMANLARI (Hızlı ve Keskin)
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Oyun Logosu / Başlık
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 2),
                      boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.05), blurRadius: 40, spreadRadius: 20)],
                    ),
                    child: const Icon(Icons.public_rounded, size: 100, color: AppColors.gold),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'app_title'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      color: AppColors.gold,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'menu.subtitle'.tr(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // OYUNA BAŞLA / DEVAM ET BUTONU
                  SizedBox(
                    width: 240, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.darkBrown,
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.darkBrown, width: 2)),
                      ),
                      onPressed: _handleContinue,
                      child: Text(
                        state.isFirstLaunch ? 'menu.new_game'.tr() : 'menu.return_to_game'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AYARLAR BUTONU
                  SizedBox(
                    width: 240, height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3), width: 1.5)),
                      ),
                      icon: const Icon(Icons.settings_rounded, size: 20, color: AppColors.gold),
                      label: Text('menu.settings'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}