// lib/screens/map_screen.dart
// ignore_for_file: discarded_futures, prefer_const_constructors, curly_braces_in_flow_control_structures, undefined_hidden_name, unused_import

import 'dart:async' as async;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide AnimatedContainer, Container, Icon, Text;
import '../widgets/adaptive_widgets.dart';
import 'package:flutter/services.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart' hide Timer;       
import 'package:flame/components.dart' hide Timer; 
import 'package:flame/events.dart';

import '../providers/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/achievements.dart'; 
import '../widgets/prestige_dialog.dart';
import '../widgets/tasks.dart'; 
import '../widgets/wheel.dart';
import '../widgets/factory_drawings.dart';
import 'factory_screen.dart' show FactoryInsideModal;
import '../services/admob_service.dart';
import '../services/audio_service.dart'; 
import '../services/translation_service.dart';
import 'main_menu_screen.dart';
import 'research_screen.dart';
import 'stock_screen.dart';
import 'settings_screen.dart';
import 'office_screen.dart';

const Color themeOceanBlue = Color(0xFF38BDF8);

Color _uiSurface(BuildContext context) => AppColors.surfaceFor(context.watch<GameState>().useDarkTheme);
Color _uiSoftSurface(BuildContext context) => AppColors.softSurfaceFor(context.watch<GameState>().useDarkTheme);
Color _uiMutedSurface(BuildContext context) => AppColors.mutedSurfaceFor(context.watch<GameState>().useDarkTheme);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override 
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _holdingName = 'Holding';
  int _holdingLogoIndex = 0; 
  late final HoldingTycoonGame _game;
  bool _pendingFrameScheduled = false;
  bool _worldEventDialogOpen = false;
  
  final List<IconData> _defaultLogos = const [
    Icons.domain_rounded, Icons.account_balance_rounded, Icons.factory_rounded,
    Icons.rocket_launch_rounded, Icons.local_shipping_rounded, Icons.bolt_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _game = HoldingTycoonGame(onFactoryTap: _handleFactoryTap, onBagTapped: _handleBagTapped);
    _loadHoldingData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndShowDialogs());
  }

  void _checkAndShowDialogs() {
    if (!mounted) return;
    final state = context.read<GameState>();
    if (state.starterFactoryId.isEmpty) {
      _showSectorSelectionDialog();
    } else if (state.offlineEarningsToClaim > 0) {
      _showOfflineEarningsDialog(state);
    }
  }
  
  void _showSectorSelectionDialog() {
    String selectedId = '1';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _uiSurface(context),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.black, width: 4.0),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.neonCyan, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 3)),
                    child: SizedBox(width: 40, height: 40, child: CustomPaint(painter: HeavyIconPainter(type: 'factory', color: adaptiveIconColor(context, Colors.white) ?? Colors.white))), 
                  ),
                  const SizedBox(height: 20),
                  FittedBox(fit: BoxFit.scaleDown, child: Text('SEKTÖR SEÇİMİ', textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 24).copyWith(color: Colors.black, shadows: []))),
                  const SizedBox(height: 12),
                  const Text('Holdinginizin faaliyetlerine başlayacağı ilk sanayi kolunu seçin. Seçtiğiniz ilk tesis size bedelsiz olarak tahsis edilecektir.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold, height: 1.4)),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      _buildFactoryChoiceCard('1', 'Tekstil', 'tekstil', selectedId, (val) { 
                        HapticFeedback.selectionClick(); 
                        AudioService.instance.playSfx('click.mp3'); 
                        setDialogState(() => selectedId = val); 
                      }),
                      _buildFactoryChoiceCard('2', 'Mobilya', 'mobilya', selectedId, (val) { 
                        HapticFeedback.selectionClick(); 
                        AudioService.instance.playSfx('click.mp3'); 
                        setDialogState(() => selectedId = val); 
                      }),
                      _buildFactoryChoiceCard('3', 'Tarım', 'tarim', selectedId, (val) { 
                        HapticFeedback.selectionClick(); 
                        AudioService.instance.playSfx('click.mp3'); 
                        setDialogState(() => selectedId = val); 
                      }),
                    ],
                  ),
                  const SizedBox(height: 36),
                  HeavyTycoonButton(
                    width: double.infinity, height: 60, color: AppColors.gold, shadowColor: Colors.orange.shade700,
                    onPressed: () async {
                      AudioService.instance.playSfx('click.mp3');
                      await context.read<GameState>().applyStarterSector(selectedId);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const FittedBox(fit: BoxFit.scaleDown, child: Text('SEKTÖRE GİRİŞ YAP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0))),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildFactoryChoiceCard(String id, String name, String iconType, String selectedId, Function(String) onSelect) {
    bool isSel = selectedId == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSel ? AppColors.gold : _uiSoftSurface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 3.0),
            boxShadow: isSel ? const [BoxShadow(color: Colors.black26, offset: Offset(0, 4))] : [],
          ),
          child: Column(
            children: [
              SizedBox(width: 32, height: 32, child: CustomPaint(painter: HeavyIconPainter(type: iconType, color: isSel ? Colors.black : (context.watch<GameState>().useDarkTheme ? Colors.white : AppColors.textMuted)))),
              const SizedBox(height: 12),
              FittedBox(fit: BoxFit.scaleDown, child: Text(name, style: TextStyle(color: isSel ? Colors.black : AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w900))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadHoldingData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { 
      _holdingName = prefs.getString('holding_name') ?? 'Holding'; 
      _holdingLogoIndex = prefs.getInt('holding_logo_index') ?? 0; 
    });
  }

  String _formatNum(double value) {
    double absVal = value.abs();
    if (absVal >= 1e33) return '${(absVal / 1e33).toStringAsFixed(2)} Dc';
    if (absVal >= 1e30) return '${(absVal / 1e30).toStringAsFixed(2)} No';
    if (absVal >= 1e27) return '${(absVal / 1e27).toStringAsFixed(2)} Oc';
    if (absVal >= 1e24) return '${(absVal / 1e24).toStringAsFixed(2)} Sp';
    if (absVal >= 1e21) return '${(absVal / 1e21).toStringAsFixed(2)} Sx';
    if (absVal >= 1e18) return '${(absVal / 1e18).toStringAsFixed(2)} Qi';
    if (absVal >= 1e15) return '${(absVal / 1e15).toStringAsFixed(2)} Qa';
    if (absVal >= 1e12) return '${(absVal / 1e12).toStringAsFixed(2)} T';
    if (absVal >= 1e9) return '${(absVal / 1e9).toStringAsFixed(2)} B';
    if (absVal >= 1e6) return '${(absVal / 1e6).toStringAsFixed(2)} M';
    if (absVal >= 1e3) return '${(absVal / 1e3).toStringAsFixed(1)} K';
    if (absVal > 0 && absVal < 10) return absVal.toStringAsFixed(1);
    return absVal.toStringAsFixed(0);
  }

  void _showOfflineEarningsDialog(GameState state) {
    bool has3xNode = state.researchNodes.firstWhere((n) => n.id == 'node_088', orElse: () => state.researchNodes[0]).currentLevel > 0;
    String adBtnText = has3xNode ? 'REKLAMLA 3X AL' : 'REKLAMLA 2X AL';

    int hours = state.offlineSecondsCapped ~/ 3600;
    int minutes = (state.offlineSecondsCapped % 3600) ~/ 60;
    String timeStr = hours > 0 ? '$hours Saat $minutes Dk' : '$minutes Dakika';
    int effPercent = (state.offlineEfficiencyApplied * 100).toInt();

    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _uiSurface(context), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32), side: const BorderSide(color: Colors.black, width: 4)),
        title: Text('GECE MESAİSİ', textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 24).copyWith(color: Colors.black, shadows: [])),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.profit, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 3)), child: SizedBox(width: 48, height: 48, child: CustomPaint(painter: HeavyIconPainter(type: 'chart', color: adaptiveIconColor(context, Colors.white) ?? Colors.white)))), 
            const SizedBox(height: 20),
            const Text('Siz yokken üretim bantları çalışmaya devam etti ancak verim düştü!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _uiSoftSurface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 2.5)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kayıtlı Mesai:', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900)),
                      Text(timeStr, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.black26, height: 1, thickness: 2)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Otonom Verimlilik:', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900)),
                      Text('%$effPercent', style: TextStyle(color: effPercent < 50 ? AppColors.loss : AppColors.profit, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), border: Border.all(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(16)), child: FittedBox(fit: BoxFit.scaleDown, child: AnimatedMoneyText(money: state.offlineEarningsToClaim, formatNum: _formatNum, style: const TextStyle(color: AppColors.profit, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')))),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          HeavyTycoonButton(
            height: 55, color: _uiSoftSurface(context), shadowColor: Colors.grey.shade400, padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: () { 
              AudioService.instance.playSfx('cash.mp3');
              state.claimOfflineEarnings(false); 
              Navigator.pop(context); 
            }, 
            child: const FittedBox(fit: BoxFit.scaleDown, child: Text('TAHSİL ET', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)))
          ),
          HeavyTycoonButton(
            height: 55, color: AppColors.gold, shadowColor: Colors.orange.shade700, padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: () { 
              AdMobService.showRewardedAd(
                context: context, 
                onRewardEarned: () { 
                  AudioService.instance.playSfx('cash.mp3');
                  state.incrementAdsWatched(); 
                  state.claimOfflineEarnings(true); 
                  Navigator.pop(context); 
                }
              ); 
            },
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(adBtnText, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12))),
          ),
        ],
      )
    );
  }

  void _handleFactoryTap(String factoryId) {
    HapticFeedback.selectionClick();
    AudioService.instance.playSfx('click.mp3');
    final gameState = context.read<GameState>();
    final fac = gameState.factories.firstWhere((f) => f.id == factoryId);
    if (!fac.isUnlocked) {
      _showPurchaseDialog(fac); 
    } else {
      _showFactoryInsideSheet(fac);
    }
  }

  void _handleBagTapped(double reward) {
    HapticFeedback.lightImpact();
    AudioService.instance.playSfx('click.mp3');
    final state = context.read<GameState>();
    showDialog(
      context: context, barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: _uiSurface(context), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32), side: const BorderSide(color: Colors.black, width: 4)),
        title: Text('FİNANSMAN', textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 24).copyWith(color: Colors.black, shadows: [])),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sahada harici finansman bulundu:', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: const Color(0xFFFEF3C7), border: Border.all(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(16)), child: FittedBox(fit: BoxFit.scaleDown, child: Text('\$${_formatNum(reward)}', style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')))),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          HeavyTycoonButton(
            height: 55, color: _uiSoftSurface(context), shadowColor: Colors.grey.shade400, padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () { 
              AudioService.instance.playSfx('cash.mp3');
              state.claimBagReward(false, reward); 
              Navigator.pop(c); 
            }, 
            child: const FittedBox(fit: BoxFit.scaleDown, child: Text('TAHSİL ET', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)))
          ),
          HeavyTycoonButton(
            height: 55, color: AppColors.gold, shadowColor: Colors.orange.shade700, padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () { 
              AdMobService.showRewardedAd(
                context: context, 
                onRewardEarned: () { 
                  AudioService.instance.playSfx('cash.mp3');
                  state.incrementAdsWatched(); 
                  state.claimBagReward(true, reward); 
                  Navigator.pop(c); 
                }
              ); 
            },
            child: const FittedBox(fit: BoxFit.scaleDown, child: Text('3X KATLA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13))),
          )
        ],
      )
    );
  }

  void _showPurchaseDialog(FactoryData fac) {
    showDialog(
      context: context,
      builder: (context) {
        final state = context.read<GameState>();
        final double finalPrice = state.factoryUnlockCost(fac.id) ?? fac.price;

        return AlertDialog(
          backgroundColor: _uiSurface(context), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32), side: const BorderSide(color: Colors.black, width: 4)),
          title: Text('ARSA SATIN ALIMI', textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 22).copyWith(color: Colors.black, shadows: [])),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _uiMutedSurface(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 3)), child: SizedBox(width: 48, height: 48, child: CustomPaint(painter: HeavyIconPainter(type: 'land', color: context.watch<GameState>().useDarkTheme ? Colors.white : Colors.black)))), 
              const SizedBox(height: 20),
              Text(
                '${TranslationService.instance.factoryName(fac.id, fallback: fac.name)} inşası için arsa bedeli:',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.bold),
              ), 
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: const Color(0xFFFEF3C7), border: Border.all(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(16)), child: FittedBox(fit: BoxFit.scaleDown, child: Text(finalPrice == 0 ? 'BEDELSİZ' : '\$${_formatNum(finalPrice)}', style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')))),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            HeavyTycoonButton(
              height: 55, color: _uiSoftSurface(context), shadowColor: Colors.grey.shade400, padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: () {
                AudioService.instance.playSfx('click.mp3');
                Navigator.pop(context);
              }, 
              child: const FittedBox(fit: BoxFit.scaleDown, child: Text('İPTAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)))
            ),
            HeavyTycoonButton(
              height: 55, color: AppColors.gold, shadowColor: Colors.orange.shade700, padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: () {
                if (state.money >= finalPrice) { 
                  HapticFeedback.mediumImpact();
                  AudioService.instance.playSfx('cash.mp3');
                  state.unlockFactory(fac.id); 
                  Navigator.pop(context); 
                } else { 
                  HapticFeedback.heavyImpact();
                  AudioService.instance.playSfx('click.mp3');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.black, width: 3)), content: const Text('Yetersiz Bakiye', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)), backgroundColor: AppColors.loss)); 
                  Navigator.pop(context); 
                }
              },
              child: const FittedBox(fit: BoxFit.scaleDown, child: Text('ONAYLA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14))),
            ),
          ],
        );
      }
    );
  }

  void _showFactoryInsideSheet(FactoryData fac) {
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent, 
      isScrollControlled: true,
      builder: (context) => FactoryInsideModal(factoryId: fac.id, formatNum: _formatNum),
    );
  }

  void _showTaxDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: _uiSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32), side: const BorderSide(color: Colors.black, width: 4)),
        title: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.loss, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2)), child: SizedBox(width: 32, height: 32, child: CustomPaint(painter: HeavyIconPainter(type: 'receipt', color: adaptiveIconColor(context, Colors.white) ?? Colors.white)))),
            const SizedBox(width: 12),
            const Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('VERGİ TAHAKKUKU', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900)))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), decoration: BoxDecoration(color: const Color(0xFFFEE2E2), border: Border.all(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(16)), child: FittedBox(fit: BoxFit.scaleDown, child: AnimatedMoneyText(money: gameState.currentTaxDebt, formatNum: _formatNum, style: const TextStyle(color: AppColors.loss, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _uiSoftSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.loss, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        gameState.isUnderPenalty
                            ? 'SÜRE DOLDU (HACİZ SÜRECİ)'
                            : 'Kalan Süre: ${gameState.taxTimeLeftFormatted}',
                        style: const TextStyle(color: AppColors.loss, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 24, height: 24, child: CustomPaint(painter: HeavyIconPainter(type: 'speed', color: AppColors.gold))),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Verginizi 12 saat dolmadan zamanında öderseniz 30 dakika boyunca %20 ek gelir takviyesi kazanırsınız!',
                      style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          HeavyTycoonButton(
            height: 55, color: _uiSoftSurface(context), shadowColor: Colors.grey.shade400, padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: gameState.money >= gameState.currentTaxDebt
                ? () {
                    HapticFeedback.lightImpact();
                    AudioService.instance.playSfx('cash.mp3');
                    gameState.payTax();
                    Navigator.pop(c);
                  }
                : null,
            child: const FittedBox(fit: BoxFit.scaleDown, child: Text('NAKİT ÖDE', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900))),
          ),
          HeavyTycoonButton(
            height: 55, color: AppColors.gold, shadowColor: Colors.orange.shade700, padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () {
              AudioService.instance.playSfx('click.mp3');
              AdMobService.showRewardedAd(
                context: context,
                onRewardEarned: () {
                  AudioService.instance.playSfx('cash.mp3');
                  gameState.incrementAdsWatched();
                  gameState.payTaxWithAd();
                  Navigator.pop(c);
                },
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_fill_rounded, size: 20, color: Colors.black),
                SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('REKLAMLA ÖDE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ]
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    _game.updateState(gameState);
    _schedulePendingWorldEvents(gameState);
    final bool hasTopStatuses = gameState.hasTaxDebt || gameState.isBoostActive || gameState.isTaxBonusActive || gameState.isEventActive;
    final double topPanelHeight = _mapTopPanelHeight(context, hasTopStatuses);
    final double sideButtonsTop = topPanelHeight + 14;
    final double notificationTop = topPanelHeight + 8;

    return Scaffold(
      backgroundColor: themeOceanBlue, 
      body: Stack(
        children: [
          GameWidget(game: _game),
          Positioned(top: 0, left: 0, right: 0, child: _buildPremiumTopPanel(context, gameState)),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildPremiumBottomBar(context)),
          Positioned(
            right: 16,
            top: sideButtonsTop,
            bottom: MediaQuery.of(context).padding.bottom + 90,
            child: SingleChildScrollView(child: _buildSideActionButtons(gameState)),
          ),
          
          Positioned(
            top: notificationTop,
            left: 16, right: 16,
            child: Column(
              children: gameState.notifications.take(3).map((n) => TopNotificationItem(
                key: ValueKey(n.id),
                notification: n,
                onClaim: () {
                  if (n.type == 'task') {
                    gameState.claimTask(n.index);
                  } else if (n.type == 'achievement') {
                    gameState.claimAchievement(n.index);
                  }
                  HapticFeedback.heavyImpact();
                  AudioService.instance.playSfx('cash.mp3');
                  gameState.removeNotification(n);
                },
                onDismiss: () {
                  gameState.removeNotification(n);
                }
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _schedulePendingWorldEvents(GameState gameState) {
    if (_pendingFrameScheduled) return;
    _pendingFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingFrameScheduled = false;
      if (!mounted) return;
      if (!_worldEventDialogOpen) {
        final ev = gameState.consumeUnhandledEvent();
        if (ev != null) {
          _worldEventDialogOpen = true;
          _presentWorldEvent(ev, gameState);
        }
      }
      final bagReward = gameState.consumeUnhandledBagReward();
      if (bagReward > 0) _game.spawnFlyingBag(bagReward);
    });
  }

  Future<void> _presentWorldEvent(GameEvent ev, GameState gameState) async {
    try {
      final result = await showDialog<EventDialogResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => EventTimerDialog(ev: ev, gameState: gameState, formatNum: _formatNum),
      );
      if (!mounted || result == null) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => EventResultDialog(result: result, gameState: gameState, formatNum: _formatNum),
      );
    } finally {
      _worldEventDialogOpen = false;
      if (mounted) setState(() {});
    }
  }

  double _mapTopPanelHeight(BuildContext context, bool hasStatuses) {
    final width = MediaQuery.sizeOf(context).width;
    final safeTop = MediaQuery.paddingOf(context).top;
    final bool narrow = width < 360;
    final double headerHeight = narrow ? 44 : 50;
    final double metricsHeight = narrow ? 42 : 46;
    final double statusHeight = hasStatuses ? (narrow ? 36 : 38) : 0;
    final double statusGap = hasStatuses ? 8 : 0;

    // Safe area + top/bottom padding + header + row gaps + metrics + optional statuses + bottom border.
    return safeTop + 8 + headerHeight + 8 + metricsHeight + statusGap + statusHeight + 10 + 4;
  }

  Widget _buildPremiumTopPanel(BuildContext context, GameState gameState) {
    final IconData holdingIcon = _defaultLogos.isNotEmpty &&
            _holdingLogoIndex >= 0 &&
            _holdingLogoIndex < _defaultLogos.length
        ? _defaultLogos[_holdingLogoIndex]
        : Icons.domain_rounded;
    final bool hasStatuses = gameState.hasTaxDebt ||
        gameState.isBoostActive ||
        gameState.isTaxBonusActive ||
        gameState.isEventActive;
    final Color panelColor = _uiSurface(context);
    final Color softColor = _uiSoftSurface(context);
    final Color moneyGreen = gameState.useDarkTheme
        ? AppColors.profit
        : const Color(0xFF16A34A);

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        border: const Border(bottom: BorderSide(color: Colors.black, width: 4)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final bool narrow = width < 360;
                  final bool compact = width < 430;
                  final double headerHeight = narrow ? 44 : 50;
                  final double logoSize = narrow ? 42 : compact ? 46 : 50;
                  final double logoIconSize = narrow ? 25 : compact ? 28 : 30;
                  final double menuSize = narrow ? 42 : 46;
                  final double metricsHeight = narrow ? 42 : 46;
                  final double moneyFont = narrow ? 20 : compact ? 23 : 26;
                  final double incomeFont = narrow ? 10.5 : compact ? 11.5 : 12.5;
                  final double chipFont = narrow ? 11 : 12;

                  Widget statusChip({
                    required Widget icon,
                    required String text,
                    required Color background,
                    double? maxWidth,
                  }) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth ?? 240),
                      child: Container(
                        height: narrow ? 34 : 36,
                        padding: EdgeInsets.symmetric(horizontal: narrow ? 8 : 10),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 16, height: 16, child: icon),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: chipFont,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'SpaceMono',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: headerHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                color: AppColors.neonCyan,
                                borderRadius: BorderRadius.circular(narrow ? 12 : 15),
                                border: Border.all(color: Colors.black, width: 3),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, offset: Offset(0, 3)),
                                ],
                              ),
                              child: Icon(holdingIcon, size: logoIconSize, color: Colors.white),
                            ),
                            SizedBox(width: narrow ? 8 : 12),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _holdingName.toUpperCase(),
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: narrow ? 17 : compact ? 20 : 23,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: narrow ? .45 : .8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: narrow ? 4 : 8),
                            SizedBox(
                              width: menuSize,
                              height: menuSize,
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  popupMenuTheme: PopupMenuThemeData(
                                    color: panelColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(color: Colors.black, width: 3),
                                    ),
                                  ),
                                ),
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Menü'.tl(),
                                  icon: Icon(Icons.menu_rounded, size: narrow ? 29 : 32, color: Colors.black),
                                  offset: Offset(0, menuSize),
                                  onSelected: (value) {
                                    AudioService.instance.playSfx('click.mp3');
                                    if (value == 'settings') {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                      );
                                    } else if (value == 'main_menu') {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(builder: (_) => const MainMenuScreen(isInitialLaunch: false)),
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'settings',
                                      child: Row(
                                        children: [
                                          Icon(Icons.settings_rounded, color: Colors.black87, size: 24),
                                          SizedBox(width: 12),
                                          Text('Ayarlar', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuDivider(height: 2),
                                    PopupMenuItem(
                                      value: 'main_menu',
                                      child: Row(
                                        children: [
                                          Icon(Icons.exit_to_app_rounded, color: AppColors.loss, size: 24),
                                          SizedBox(width: 12),
                                          Text('Oturumu Kapat', style: TextStyle(color: AppColors.loss, fontSize: 16, fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: metricsHeight,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: metricsHeight,
                                padding: EdgeInsets.symmetric(horizontal: narrow ? 10 : 14),
                                decoration: BoxDecoration(
                                  color: gameState.useDarkTheme
                                      ? const Color(0xFF2E654D)
                                      : const Color(0xFFEAF8EE),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(color: Colors.black, width: 3),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedMoneyText(
                                      money: gameState.money,
                                      formatNum: _formatNum,
                                      style: TextStyle(
                                        color: moneyGreen,
                                        fontSize: moneyFont,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'SpaceMono',
                                        shadows: const [],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: narrow ? 7 : 10),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: narrow ? 100 : 116,
                                maxWidth: narrow ? 126 : compact ? 148 : 170,
                              ),
                              child: Container(
                                height: metricsHeight,
                                padding: EdgeInsets.symmetric(horizontal: narrow ? 7 : 10),
                                decoration: BoxDecoration(
                                  color: softColor,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(color: Colors.black, width: 3),
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      gameState.incomePerSecond > 0
                                          ? '+\$${_formatNum(gameState.incomePerSecond)}/s'
                                          : 'Beklemede',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(
                                        color: gameState.currentMultiplier > 1
                                            ? AppColors.gold
                                            : Colors.black87,
                                        fontSize: incomeFont,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'SpaceMono',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasStatuses) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: narrow ? 36 : 38,
                          width: double.infinity,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (gameState.hasTaxDebt) ...[
                                  PulsingTaxIcon(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      AudioService.instance.playSfx('click.mp3');
                                      _showTaxDialog(context, gameState);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (gameState.isBoostActive) ...[
                                  statusChip(
                                    background: const Color(0xFFFEF3C7),
                                    icon: CustomPaint(painter: HeavyIconPainter(type: 'boost', color: AppColors.gold)),
                                    text: '2X (${gameState.boostTimeLeft})',
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (gameState.isTaxBonusActive) ...[
                                  statusChip(
                                    background: const Color(0xFFDCFCE7),
                                    icon: CustomPaint(painter: HeavyIconPainter(type: 'speed', color: AppColors.profit)),
                                    text: '+%20 (${gameState.taxBonusTimeLeft})',
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (gameState.isEventActive)
                                  statusChip(
                                    maxWidth: narrow ? 200 : 255,
                                    background: gameState.activeEvent!.multiplier > 1
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEE2E2),
                                    icon: CustomPaint(
                                      painter: HeavyIconPainter(
                                        type: gameState.activeEvent!.multiplier > 1 ? 'trend_up' : 'trend_down',
                                        color: gameState.activeEvent!.multiplier > 1 ? AppColors.profit : AppColors.loss,
                                      ),
                                    ),
                                    text: '${gameState.activeEvent!.title} (${gameState.activeEventTimeLeft})',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBottomBar(BuildContext context) {
    final double botSafe = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 80 + botSafe,
      padding: EdgeInsets.only(bottom: botSafe),
      decoration: BoxDecoration(
        color: _uiSurface(context), 
        border: const Border(top: BorderSide(color: Colors.black, width: 4.0)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPremiumTab("Ar-Ge", 'research', () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ResearchScreen())); 
          }),
          Container(width: 4, height: 40, color: Colors.black),
          _buildPremiumTab("Borsa", 'stock', () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StockScreen())); 
          }),
          Container(width: 4, height: 40, color: Colors.black),
          _buildPremiumTab("Yazıhane", 'office', () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OfficeScreen())); 
          }),
        ],
      ),
    );
  }

  Widget _buildPremiumTab(String title, String iconType, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32, height: 32,
              child: CustomPaint(painter: HeavyIconPainter(type: iconType, color: context.watch<GameState>().useDarkTheme ? Colors.white : Colors.black)),
            ),
            const SizedBox(height: 8),
            Text(title.toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildSideActionButtons(GameState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSideButton(
          iconType: 'boost', 
          onTap: () { 
            HapticFeedback.selectionClick();
            AudioService.instance.playSfx('click.mp3');
            AdMobService.showRewardedAd(
              context: context, 
              onRewardEarned: () { 
                AudioService.instance.playSfx('cash.mp3');
                state.incrementAdsWatched(); 
                state.activate2xBoost(); 
              }
            ); 
          }
        ),
        const SizedBox(height: 20),
        AnimatedSideButton(
          iconType: 'wheel', 
          onTap: () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            WheelDialog.show(context); 
          }
        ),
        const SizedBox(height: 20),
        AnimatedSideButton(
          iconType: 'achievements', 
          badgeCount: state.unclaimedAchievementsCount,
          onTap: () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            AchievementsDialog.show(context); 
          }
        ),
        const SizedBox(height: 20),
        AnimatedSideButton(
          iconType: 'tasks', 
          badgeCount: state.unclaimedTasksCount,
          onTap: () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            TasksDialog.show(context); 
          }
        ),
        const SizedBox(height: 20),
        AnimatedSideButton(
          iconType: 'prestige', 
          onTap: () { 
            HapticFeedback.selectionClick();
            AudioService.instance.playSfx('click.mp3');
            PrestigeDialog.show(
              context, 
              onPrestigeConfirmed: () { 
                AudioService.instance.playSfx('cash.mp3');
                state.executePrestige(); 
              }
            ); 
          }
        ),
      ],
    );
  }
}

class TopNotificationItem extends StatefulWidget {
  final InGameNotification notification;
  final VoidCallback onClaim;
  final VoidCallback onDismiss;

  const TopNotificationItem({super.key, required this.notification, required this.onClaim, required this.onDismiss});

  @override
  State<TopNotificationItem> createState() => _TopNotificationItemState();
}

class _TopNotificationItemState extends State<TopNotificationItem> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  async.Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _animCtrl.forward();

    _timer = async.Timer(const Duration(seconds: 5), () {
      _closeAndDismiss();
    });
  }

  void _closeAndDismiss() {
    if (!mounted || _closing) return;
    _closing = true;
    _animCtrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _uiSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 3.5),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (_closing) return;
              _closing = true;
              _timer?.cancel();
              widget.onClaim();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: widget.notification.type == 'task' ? AppColors.neonCyan : AppColors.gold, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2)), child: Icon(widget.notification.type == 'task' ? Icons.assignment_turned_in_rounded : Icons.emoji_events_rounded, color: Colors.white, size: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.notification.header, style: TextStyle(color: widget.notification.type == 'task' ? AppColors.neonCyan : AppColors.gold, fontSize: 13, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(widget.notification.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 96),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('ÖDÜLÜ AL', style: TextStyle(color: AppColors.profit, fontSize: 12, fontWeight: FontWeight.w900)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum EventOutcome {
  crisisPrevented,
  crisisPreventedByAd,
  crisisAccepted,
  chanceAccepted,
  chanceAcceptedByAd,
  chanceRejected,
  crisisTimedOut,
  chanceTimedOut,
}

class EventDialogResult {
  final GameEvent event;
  final EventOutcome outcome;

  const EventDialogResult({required this.event, required this.outcome});
}

class EventTimerDialog extends StatefulWidget {
  final GameEvent ev;
  final GameState gameState;
  final String Function(double) formatNum;

  const EventTimerDialog({super.key, required this.ev, required this.gameState, required this.formatNum});

  @override
  State<EventTimerDialog> createState() => _EventTimerDialogState();
}

class _EventTimerDialogState extends State<EventTimerDialog> with SingleTickerProviderStateMixin {
  static const int eventDecisionSeconds = 15;
  late AnimationController _controller;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: eventDecisionSeconds));
    _controller.reverse(from: 1.0).then((_) {
      if (mounted && !_resolved) _handleTimeout();
    });
  }

  void _finish(EventOutcome outcome) {
    if (_resolved || !mounted) return;
    _resolved = true;
    _controller.stop();
    Navigator.pop(context, EventDialogResult(event: widget.ev, outcome: outcome));
  }

  void _handleTimeout() {
    final isCrisis = widget.ev.preventCost > 0;
    if (isCrisis) {
      widget.gameState.resolveEvent(false, widget.ev);
      _finish(EventOutcome.crisisTimedOut);
    } else {
      _finish(EventOutcome.chanceTimedOut);
    }
  }

  void _watchAdToPreventCrisis() {
    if (_resolved || widget.ev.preventCost <= 0) return;
    final gameState = widget.gameState;
    final event = widget.ev;
    AudioService.instance.playSfx('click.mp3');
    AdMobService.showRewardedAd(
      context: context,
      onRewardEarned: () {
        gameState.incrementAdsWatched();
        gameState.resolveEventWithAd(event);
        if (mounted && !_resolved) {
          _finish(EventOutcome.crisisPreventedByAd);
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCrisis = widget.ev.preventCost > 0;
    final canAffordPrevent = widget.gameState.money >= widget.ev.preventCost;

    return AlertDialog(
      backgroundColor: _uiSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: const BorderSide(color: Colors.black, width: 4.0),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCrisis ? AppColors.loss : AppColors.profit,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: SizedBox(
              width: 28,
              height: 28,
              child: CustomPaint(painter: HeavyIconPainter(type: 'warning', color: adaptiveIconColor(context, Colors.white) ?? Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.ev.title, style: AppTheme.titleStyle(fontSize: 22).copyWith(color: Colors.black, shadows: []))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.ev.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.4, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        minHeight: 16,
                        backgroundColor: _uiSoftSurface(context),
                        valueColor: AlwaysStoppedAnimation<Color>(isCrisis ? AppColors.loss : AppColors.profit),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kalan Süre: ${(_controller.value * eventDecisionSeconds).ceil()}s',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'),
                  ),
                ],
              );
            },
          ),
          if (isCrisis) ...[
            const SizedBox(height: 16),
            HeavyTycoonButton(
              width: double.infinity,
              height: 50,
              color: AppColors.gold,
              shadowColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: _watchAdToPreventCrisis,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill_rounded, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'REKLAMLA ÖNLE',
                        style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        if (isCrisis)
          HeavyTycoonButton(
            height: 55,
            color: _uiSoftSurface(context),
            shadowColor: Colors.grey.shade400,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: canAffordPrevent
                ? () {
                    AudioService.instance.playSfx('cash.mp3');
                    widget.gameState.resolveEvent(true, widget.ev);
                    _finish(EventOutcome.crisisPrevented);
                  }
                : null,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'ÖNLE (\$${widget.formatNum(widget.ev.preventCost)})',
                style: TextStyle(color: canAffordPrevent ? Colors.black : Colors.black38, fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ),
          )
        else
          HeavyTycoonButton(
            height: 55,
            color: _uiSoftSurface(context),
            shadowColor: Colors.grey.shade400,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () {
              AudioService.instance.playSfx('click.mp3');
              _finish(EventOutcome.chanceRejected);
            },
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('REDDET', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
            ),
          ),
        HeavyTycoonButton(
          height: 55,
          color: isCrisis ? AppColors.loss : AppColors.profit,
          shadowColor: isCrisis ? Colors.red.shade900 : Colors.green.shade900,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onPressed: () {
            AudioService.instance.playSfx('click.mp3');
            widget.gameState.resolveEvent(false, widget.ev);
            _finish(isCrisis ? EventOutcome.crisisAccepted : EventOutcome.chanceAccepted);
          },
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(isCrisis ? 'KATLAN' : 'KABUL ET', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}

class EventResultDialog extends StatefulWidget {
  final EventDialogResult result;
  final GameState gameState;
  final String Function(double) formatNum;

  const EventResultDialog({super.key, required this.result, required this.gameState, required this.formatNum});

  @override
  State<EventResultDialog> createState() => _EventResultDialogState();
}

class _EventResultDialogState extends State<EventResultDialog> {
  bool _recoveredByAd = false;

  String _multiplierText(double multiplier) {
    if (multiplier == multiplier.roundToDouble()) return multiplier.toStringAsFixed(0);
    return multiplier.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  void _watchRecoveryAd() {
    final ev = widget.result.event;
    final state = widget.gameState;
    AudioService.instance.playSfx('click.mp3');
    AdMobService.showRewardedAd(
      context: context,
      onRewardEarned: () {
        state.incrementAdsWatched();
        state.resolveEventWithAd(ev);
        if (mounted) setState(() => _recoveredByAd = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.gameState,
      builder: (context, _) {
        final ev = widget.result.event;
        final outcome = widget.result.outcome;
        final bool timedOutCrisis = outcome == EventOutcome.crisisTimedOut;
        final bool timedOutChance = outcome == EventOutcome.chanceTimedOut;
        final bool recoveredFromTimeout = _recoveredByAd ||
            (timedOutCrisis && !widget.gameState.isEventActiveFor(ev)) ||
            (timedOutChance && widget.gameState.isEventActiveFor(ev));

        late final String title;
        late final String message;
        late final Color accent;
        late final IconData icon;

        if (recoveredFromTimeout && timedOutCrisis) {
          title = 'KRİZ REKLAMLA ÖNLENDİ';
          message = '${ev.title} son anda engellendi. Reklam ödülü sayesinde kriz etkisi kaldırıldı ve önleme bedeli ödenmedi.';
          accent = AppColors.profit;
          icon = Icons.shield_rounded;
        } else if (recoveredFromTimeout && timedOutChance) {
          title = 'FIRSAT GERİ KAZANILDI';
          message = '${ev.title} reklam ödülüyle kabul edildi. Gelir ${_multiplierText(ev.multiplier)}x oldu ve bu etki ${ev.durationMinutes} dakika sürecek.';
          accent = AppColors.profit;
          icon = Icons.replay_circle_filled_rounded;
        } else {
          switch (outcome) {
            case EventOutcome.crisisPrevented:
              title = 'KRİZ ÖNLENDİ';
              message = '${ev.title} engellendi. \$${widget.formatNum(ev.preventCost)} ödendi ve gelir düşüşü uygulanmadı.';
              accent = AppColors.profit;
              icon = Icons.shield_rounded;
              break;
            case EventOutcome.crisisPreventedByAd:
              title = 'KRİZ REKLAMLA ÖNLENDİ';
              message = '${ev.title} reklam ödülüyle ücretsiz engellendi. Önleme bedeli ödenmedi ve gelir düşüşü uygulanmadı.';
              accent = AppColors.profit;
              icon = Icons.play_circle_fill_rounded;
              break;
            case EventOutcome.crisisAccepted:
              title = 'KRİZ KABUL EDİLDİ';
              message = '${ev.title} devreye girdi. Gelir ${_multiplierText(ev.multiplier)}x seviyesine düştü ve bu etki ${ev.durationMinutes} dakika sürecek.';
              accent = AppColors.loss;
              icon = Icons.trending_down_rounded;
              break;
            case EventOutcome.chanceAccepted:
              title = 'FIRSAT KABUL EDİLDİ';
              message = '${ev.title} etkinleştirildi. Gelir ${_multiplierText(ev.multiplier)}x oldu ve bu etki ${ev.durationMinutes} dakika sürecek.';
              accent = AppColors.profit;
              icon = Icons.trending_up_rounded;
              break;
            case EventOutcome.chanceAcceptedByAd:
              title = 'FIRSAT REKLAMLA KABUL EDİLDİ';
              message = '${ev.title} reklam ödülüyle etkinleştirildi. Gelir ${_multiplierText(ev.multiplier)}x oldu ve bu etki ${ev.durationMinutes} dakika sürecek.';
              accent = AppColors.profit;
              icon = Icons.play_circle_fill_rounded;
              break;
            case EventOutcome.chanceRejected:
              title = 'FIRSAT REDDEDİLDİ';
              message = '${ev.title} reddedildi. Herhangi bir gelir etkisi uygulanmadı.';
              accent = AppColors.textMuted;
              icon = Icons.close_rounded;
              break;
            case EventOutcome.crisisTimedOut:
              title = 'SÜRE DOLDU — KRİZ DEVREDE';
              message = '15 saniye içinde karar verilmedi. ${ev.title} otomatik olarak devreye girdi; gelir ${_multiplierText(ev.multiplier)}x seviyesinde ${ev.durationMinutes} dakika etkilenecek. İstersen reklam izleyerek krizi şimdi kaldırabilirsin.';
              accent = AppColors.loss;
              icon = Icons.timer_off_rounded;
              break;
            case EventOutcome.chanceTimedOut:
              title = 'SÜRE DOLDU — FIRSAT KAÇTI';
              message = '15 saniye içinde karar verilmedi. ${ev.title} kabul edilmedi. İstersen reklam izleyerek fırsatı geri kazanabilirsin.';
              accent = AppColors.textMuted;
              icon = Icons.timer_off_rounded;
              break;
          }
        }

        final bool canRecoverByAd = (timedOutCrisis || timedOutChance) && !recoveredFromTimeout;

        return AlertDialog(
          backgroundColor: _uiSurface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: const BorderSide(color: Colors.black, width: 4)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2)),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppTheme.titleStyle(fontSize: 18).copyWith(color: Colors.black, shadows: []))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _uiSoftSurface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 2.5)),
                child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold, height: 1.45)),
              ),
              if (canRecoverByAd) ...[
                const SizedBox(height: 16),
                HeavyTycoonButton(
                  width: double.infinity,
                  height: 52,
                  color: AppColors.gold,
                  shadowColor: Colors.orange.shade700,
                  onPressed: _watchRecoveryAd,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_fill_rounded, color: Colors.black, size: 21),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            timedOutCrisis ? 'REKLAMLA KRİZİ ÖNLE' : 'REKLAMLA FIRSATI KABUL ET',
                            style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            HeavyTycoonButton(
              height: 52,
              color: recoveredFromTimeout ? AppColors.profit : AppColors.gold,
              shadowColor: recoveredFromTimeout ? Colors.green.shade900 : Colors.orange.shade700,
              onPressed: () {
                AudioService.instance.playSfx('click.mp3');
                Navigator.pop(context);
              },
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(recoveredFromTimeout ? 'TAMAM — UYGULANDI' : 'TAMAM', style: TextStyle(color: recoveredFromTimeout ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.w900))),
            ),
          ],
        );
      },
    );
  }
}

class PulsingTaxIcon extends StatefulWidget {
  final VoidCallback onTap;
  const PulsingTaxIcon({super.key, required this.onTap});

  @override
  State<PulsingTaxIcon> createState() => _PulsingTaxIconState();
}

class _PulsingTaxIconState extends State<PulsingTaxIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.loss, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2)),
          child: SizedBox(
            width: 24, height: 24,
            child: CustomPaint(painter: HeavyIconPainter(type: 'warning', color: adaptiveIconColor(context, Colors.white) ?? Colors.white)),
          ),
        ),
      ),
    );
  }
}

class AnimatedSideButton extends StatefulWidget {
  final String iconType; 
  final VoidCallback onTap; 
  final int badgeCount;
  
  const AnimatedSideButton({
    super.key, 
    required this.iconType, 
    required this.onTap, 
    this.badgeCount = 0
  });

  @override
  State<AnimatedSideButton> createState() => _AnimatedSideButtonState();
}

class _AnimatedSideButtonState extends State<AnimatedSideButton> {
  bool _isPressed = false;

  @override 
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        widget.onTap();
      },
      child: SizedBox(
        width: 56, height: 56,
        child: Stack(
          children: [
            Positioned(
              bottom: 0, left: 0, right: 0, top: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 3),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              bottom: _isPressed ? 0 : 6,
              left: 0, right: 0, top: _isPressed ? 6 : 0,
              child: Container(
                decoration: BoxDecoration(
                  color: _uiSurface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Center(
                  child: SizedBox(
                    width: 28, height: 28,
                    child: CustomPaint(painter: HeavyIconPainter(type: widget.iconType, color: context.watch<GameState>().useDarkTheme ? Colors.white : Colors.black)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.badgeCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: -8, top: -8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.loss, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 3)),
              child: Text(widget.badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      );
    }
    return button;
  }
}

class HeavyIconPainter extends CustomPainter {
  final String type;
  final Color color;

  HeavyIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case 'boost':
        final textPainter = TextPainter(
          text: TextSpan(text: '2X'.tl(), style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(12 - textPainter.width / 2, 12 - textPainter.height / 2));
        break;
      case 'wheel':
        canvas.drawCircle(const Offset(12, 12), 10, stroke);
        for(int i=0; i<8; i++) {
          canvas.save(); canvas.translate(12, 12); canvas.rotate(i * math.pi / 4);
          canvas.drawLine(const Offset(0, 7), const Offset(0, 10), stroke);
          canvas.restore();
        }
        final qText = TextPainter(
          text: TextSpan(text: '?', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
          textDirection: TextDirection.ltr,
        )..layout();
        qText.paint(canvas, Offset(12 - qText.width / 2, 12 - qText.height / 2));
        break;
      case 'achievements':
        canvas.drawPath(Path()..moveTo(6, 4)..lineTo(18, 4)..lineTo(18, 10)..quadraticBezierTo(18, 16, 12, 16)..quadraticBezierTo(6, 16, 6, 10)..close(), stroke);
        canvas.drawPath(Path()..moveTo(12, 16)..lineTo(12, 20), stroke..strokeWidth = 3.0);
        canvas.drawPath(Path()..moveTo(8, 20)..lineTo(16, 20), stroke..strokeWidth = 3.0);
        canvas.drawPath(Path()..moveTo(6, 6)..lineTo(3, 6)..lineTo(3, 10)..lineTo(6, 12), stroke);
        canvas.drawPath(Path()..moveTo(18, 6)..lineTo(21, 6)..lineTo(21, 10)..lineTo(18, 12), stroke);
        break;
      case 'tasks':
        canvas.drawRect(const Rect.fromLTWH(4, 5, 5, 5), stroke);
        canvas.drawPath(Path()..moveTo(3, 7)..lineTo(5, 9)..lineTo(10, 3), stroke..strokeWidth=2.5);
        canvas.drawLine(const Offset(12, 7), const Offset(20, 7), stroke);
        
        canvas.drawRect(const Rect.fromLTWH(4, 15, 5, 5), stroke);
        canvas.drawLine(const Offset(12, 17), const Offset(20, 17), stroke);
        break;
      case 'prestige':
        // Five-piece faceted diamond. The outer silhouette now reads clearly
        // as a gemstone while preserving the reference image's bold cutouts.
        final topLeft = Path()
          ..moveTo(2.4, 10.55)
          ..lineTo(6.45, 4.15)
          ..lineTo(10.25, 4.15)
          ..lineTo(8.55, 10.55)
          ..close();

        final topCenter = Path()
          ..moveTo(12.0, 3.35)
          ..lineTo(15.0, 10.55)
          ..lineTo(9.0, 10.55)
          ..close();

        final topRight = Path()
          ..moveTo(13.75, 4.15)
          ..lineTo(17.55, 4.15)
          ..lineTo(21.6, 10.55)
          ..lineTo(15.45, 10.55)
          ..close();

        final bottomLeft = Path()
          ..moveTo(2.75, 12.65)
          ..lineTo(10.85, 12.65)
          ..lineTo(11.45, 21.65)
          ..close();

        final bottomRight = Path()
          ..moveTo(13.15, 12.65)
          ..lineTo(21.25, 12.65)
          ..lineTo(12.55, 21.65)
          ..close();

        canvas.drawPath(topLeft, fill);
        canvas.drawPath(topCenter, fill);
        canvas.drawPath(topRight, fill);
        canvas.drawPath(bottomLeft, fill);
        canvas.drawPath(bottomRight, fill);
        break;
      case 'research':
        canvas.drawPath(Path()..moveTo(12, 22)..lineTo(12, 8)..lineTo(6, 2), stroke..strokeWidth = 3.0);
        canvas.drawLine(const Offset(12, 8), const Offset(18, 2), stroke..strokeWidth = 3.0);
        canvas.drawLine(const Offset(12, 14), const Offset(6, 8), stroke..strokeWidth = 3.0);
        canvas.drawRect(Rect.fromCenter(center: const Offset(12, 22), width: 6, height: 2), fill);
        canvas.drawRect(Rect.fromCenter(center: const Offset(6, 2), width: 4, height: 4), fill);
        canvas.drawRect(Rect.fromCenter(center: const Offset(18, 2), width: 4, height: 4), fill);
        canvas.drawRect(Rect.fromCenter(center: const Offset(6, 8), width: 4, height: 4), fill);
        break;
      case 'stock':
        canvas.drawLine(const Offset(4, 2), const Offset(4, 20), stroke..strokeWidth = 3.0);
        canvas.drawLine(const Offset(4, 20), const Offset(22, 20), stroke..strokeWidth = 3.0);
        canvas.drawPath(Path()..moveTo(6, 16)..lineTo(11, 10)..lineTo(15, 14)..lineTo(21, 6), stroke..strokeWidth=2.5);
        canvas.drawCircle(const Offset(6, 16), 2.0, fill);
        canvas.drawCircle(const Offset(11, 10), 2.0, fill);
        canvas.drawCircle(const Offset(15, 14), 2.0, fill);
        canvas.drawCircle(const Offset(21, 6), 2.0, fill);
        break;
      case 'office':
        canvas.drawRect(const Rect.fromLTWH(8, 2, 8, 20), stroke);
        canvas.drawRect(const Rect.fromLTWH(3, 8, 5, 14), stroke);
        canvas.drawRect(const Rect.fromLTWH(16, 12, 5, 10), stroke);
        for(int y=6; y<=16; y+=4) {
          canvas.drawRect(Rect.fromLTWH(10, y.toDouble(), 4, 2), fill);
        }
        break;
      case 'warning':
        canvas.drawPath(Path()..moveTo(12, 2)..lineTo(22, 20)..lineTo(2, 20)..close(), stroke);
        canvas.drawLine(const Offset(12, 8), const Offset(12, 14), stroke);
        canvas.drawRect(const Rect.fromLTWH(11, 16, 2, 2), fill);
        break;
      case 'factory':
        canvas.drawRect(const Rect.fromLTWH(4, 10, 16, 12), stroke);
        canvas.drawPath(Path()..moveTo(4, 10)..lineTo(8, 4)..lineTo(8, 10)..lineTo(14, 4)..lineTo(14, 10)..lineTo(20, 4)..lineTo(20, 10), stroke);
        canvas.drawLine(const Offset(16, 10), const Offset(16, 2), stroke);
        canvas.drawLine(const Offset(18, 10), const Offset(18, 2), stroke);
        break;
      case 'land':
        canvas.drawPath(Path()..moveTo(12, 6)..lineTo(22, 12)..lineTo(12, 18)..lineTo(2, 12)..close(), stroke);
        canvas.drawLine(const Offset(7, 9), const Offset(17, 15), stroke);
        canvas.drawLine(const Offset(7, 15), const Offset(17, 9), stroke);
        break;
      case 'chart':
        canvas.drawRect(const Rect.fromLTWH(4, 4, 16, 16), stroke);
        canvas.drawRect(const Rect.fromLTWH(6, 14, 3, 6), fill);
        canvas.drawRect(const Rect.fromLTWH(10, 10, 3, 10), fill);
        canvas.drawRect(const Rect.fromLTWH(14, 6, 3, 14), fill);
        break;
      case 'receipt':
        canvas.drawRect(const Rect.fromLTWH(6, 2, 12, 20), stroke);
        canvas.drawLine(const Offset(6, 22), const Offset(8, 20), stroke);
        canvas.drawLine(const Offset(8, 20), const Offset(10, 22), stroke);
        canvas.drawLine(const Offset(10, 22), const Offset(12, 20), stroke);
        canvas.drawLine(const Offset(12, 20), const Offset(14, 22), stroke);
        canvas.drawLine(const Offset(14, 22), const Offset(16, 20), stroke);
        canvas.drawLine(const Offset(16, 20), const Offset(18, 22), stroke);
        canvas.drawLine(const Offset(9, 6), const Offset(15, 6), stroke);
        canvas.drawLine(const Offset(9, 10), const Offset(15, 10), stroke);
        canvas.drawLine(const Offset(9, 14), const Offset(12, 14), stroke);
        break;
      case 'speed':
        canvas.drawPath(Path()..moveTo(6, 4)..lineTo(14, 12)..lineTo(6, 20), stroke..strokeWidth=3.0);
        canvas.drawPath(Path()..moveTo(12, 4)..lineTo(20, 12)..lineTo(12, 20), stroke..strokeWidth=3.0);
        break;
      case 'trend_up':
        canvas.drawLine(const Offset(4, 18), const Offset(10, 12), stroke..strokeWidth=3.0);
        canvas.drawLine(const Offset(10, 12), const Offset(14, 16), stroke..strokeWidth=3.0);
        canvas.drawLine(const Offset(14, 16), const Offset(20, 6), stroke..strokeWidth=3.0);
        canvas.drawPath(Path()..moveTo(14, 6)..lineTo(20, 6)..lineTo(20, 12), stroke..strokeWidth=3.0);
        break;
      case 'trend_down':
        canvas.drawLine(const Offset(4, 6), const Offset(10, 12), stroke..strokeWidth=3.0);
        canvas.drawLine(const Offset(10, 12), const Offset(14, 8), stroke..strokeWidth=3.0);
        canvas.drawLine(const Offset(14, 8), const Offset(20, 18), stroke..strokeWidth=3.0);
        canvas.drawPath(Path()..moveTo(14, 18)..lineTo(20, 18)..lineTo(20, 12), stroke..strokeWidth=3.0);
        break;
      case 'upgrade':
        canvas.drawPath(Path()..moveTo(6, 12)..lineTo(12, 4)..lineTo(18, 12), stroke..strokeWidth=3.0);
        canvas.drawPath(Path()..moveTo(6, 20)..lineTo(12, 12)..lineTo(18, 20), stroke..strokeWidth=3.0);
        break;
      case 'touch':
        canvas.drawPath(Path()..moveTo(12, 2)..lineTo(6, 12)..lineTo(10, 12)..lineTo(10, 22)..lineTo(14, 22)..lineTo(14, 12)..lineTo(18, 12)..close(), stroke..strokeWidth=2.5);
        break;
      case 'tekstil':
        canvas.drawRect(const Rect.fromLTWH(7, 3, 10, 3), stroke);
        canvas.drawRect(const Rect.fromLTWH(7, 18, 10, 3), stroke);
        canvas.drawRect(const Rect.fromLTWH(9, 6, 6, 12), stroke);
        canvas.drawLine(const Offset(9, 8), const Offset(15, 12), stroke);
        canvas.drawLine(const Offset(15, 8), const Offset(9, 12), stroke);
        canvas.drawLine(const Offset(9, 12), const Offset(15, 16), stroke);
        canvas.drawLine(const Offset(15, 12), const Offset(9, 16), stroke);
        break;
      case 'mobilya':
        canvas.drawRect(const Rect.fromLTWH(3, 16, 18, 5), stroke);
        canvas.drawArc(const Rect.fromLTWH(7, 7, 10, 10), math.pi, math.pi, false, stroke);
        canvas.drawLine(const Offset(7, 12), const Offset(5, 9), stroke);
        canvas.drawLine(const Offset(10, 8), const Offset(9, 5), stroke);
        canvas.drawLine(const Offset(14, 8), const Offset(15, 5), stroke);
        canvas.drawLine(const Offset(17, 12), const Offset(19, 9), stroke);
        break;
      case 'tarim':
        canvas.drawRect(const Rect.fromLTWH(3, 10, 7, 6), stroke); 
        canvas.drawRect(const Rect.fromLTWH(10, 5, 9, 11), stroke); 
        canvas.drawRect(const Rect.fromLTWH(12, 7, 5, 4), fill); 
        canvas.drawRect(const Rect.fromLTWH(2, 16, 5, 5), stroke); 
        canvas.drawRect(const Rect.fromLTWH(12, 14, 7, 7), stroke); 
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HeavyIconPainter oldDelegate) => oldDelegate.type != type || oldDelegate.color != color;
}


class HeavyTycoonButton extends StatefulWidget {
  final VoidCallback? onTap; final Widget child; final Color color; final Color shadowColor; final double height; final double? width; final EdgeInsetsGeometry? padding; final VoidCallback? onPressed; 
  const HeavyTycoonButton({super.key, this.onTap, this.onPressed, required this.child, required this.color, required this.shadowColor, this.height = 50, this.width, this.padding});
  @override State<HeavyTycoonButton> createState() => _HeavyTycoonButtonState();
}

class _HeavyTycoonButtonState extends State<HeavyTycoonButton> {
  bool _isPressed = false;
  @override Widget build(BuildContext context) {
    final VoidCallback? action = widget.onTap ?? widget.onPressed;
    final bool isDisabled = action == null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: isDisabled ? null : (_) { setState(() => _isPressed = true); },
      onTapUp: isDisabled ? null : (_) { setState(() => _isPressed = false); },
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: isDisabled ? null : () { HapticFeedback.lightImpact(); action(); },
      child: SizedBox(
        width: widget.width, height: widget.height,
        child: Stack(
          children: [
            Positioned(bottom: 0, left: 0, right: 0, top: 8, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade400 : widget.shadowColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3.0)))),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              bottom: _isPressed || isDisabled ? 0 : 8, left: 0, right: 0, top: _isPressed || isDisabled ? 8 : 0,
              child: Container(padding: widget.padding, decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade300 : widget.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3.0)), child: Center(child: widget.child)),
            ),
          ],
        ),
      ),
    );
  }
}


class _SeagullModel {
  final Vector2 offset;
  final double scale;
  final double phase;
  final double flapSpeed;

  const _SeagullModel({required this.offset, required this.scale, required this.phase, required this.flapSpeed});
}

/// Keeps the map alive without flooding it with animation components.
/// Flocks are deliberately drawn below factory markers, so labels and taps stay
/// unobstructed even when a bird crosses the island.
class SeagullFlockController extends Component {
  final double mapWidth;
  final double mapHeight;
  final math.Random _random = math.Random();
  double _spawnTimer = 0;
  double _nextSpawn = 7;

  SeagullFlockController({required this.mapWidth, required this.mapHeight});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _spawn(initial: true, yFraction: .18);
    _spawn(initial: true, yFraction: .72);
  }

  @override
  void update(double dt) {
    _spawnTimer += dt;
    if (_spawnTimer < _nextSpawn) return;
    _spawnTimer = 0;
    _nextSpawn = 8 + _random.nextDouble() * 7;
    final activeFlocks = parent?.children.whereType<SeagullFlockComponent>().length ?? 0;
    if (activeFlocks < 3) _spawn();
  }

  void _spawn({bool initial = false, double? yFraction}) {
    final bool fromLeft = _random.nextBool();
    final double y = yFraction == null
        ? 150 + _random.nextDouble() * math.max(100.0, mapHeight - 300.0)
        : mapHeight * yFraction;
    final double speed = 58 + _random.nextDouble() * 34;
    final double initialInset = initial ? mapWidth * (.12 + _random.nextDouble() * .5) : 0;
    parent?.add(
      SeagullFlockComponent(
        startPos: Vector2(fromLeft ? -250 + initialInset : mapWidth + 250 - initialInset, y),
        velocity: Vector2(fromLeft ? speed : -speed, -6 + _random.nextDouble() * 12),
        birdCount: 3 + _random.nextInt(4),
        seed: _random.nextInt(1 << 31),
        mapWidth: mapWidth,
      ),
    );
  }
}

class SeagullFlockComponent extends PositionComponent {
  final Vector2 velocity;
  final int birdCount;
  final int seed;
  final double mapWidth;
  final List<_SeagullModel> _birds = [];
  double _time = 0;

  SeagullFlockComponent({
    required Vector2 startPos,
    required this.velocity,
    required this.birdCount,
    required this.seed,
    required this.mapWidth,
  }) {
    position = startPos;
    size = Vector2(245, 145);
    priority = 12;
    final random = math.Random(seed);
    for (int i = 0; i < birdCount; i++) {
      final int row = (i + 1) ~/ 2;
      final bool upper = i.isOdd;
      _birds.add(
        _SeagullModel(
          offset: Vector2(105 - row * 48 + random.nextDouble() * 8, 64 + (upper ? -1 : 1) * row * 24 + random.nextDouble() * 7),
          scale: .82 + random.nextDouble() * .34,
          phase: random.nextDouble() * math.pi * 2,
          flapSpeed: 4.7 + random.nextDouble() * 1.8,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    _time += dt;
    position.add(velocity * dt);
    if (position.x < -size.x - 280 || position.x > mapWidth + 280) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    if (velocity.x < 0) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    for (final bird in _birds) {
      // Do not render birds underneath the right-side action buttons. When only
      // a wing was visible from behind those buttons it looked like an
      // unexplained white swoosh, especially beside the prestige button.
      final double renderedLocalX = velocity.x < 0 ? size.x - bird.offset.x : bird.offset.x;
      final double birdWorldX = position.x + renderedLocalX;
      if (birdWorldX > mapWidth - 300) continue;

      final double bob = math.sin(_time * 2.2 + bird.phase) * 2.2;
      _drawSeagull(canvas, bird.offset.x, bird.offset.y + bob, bird.scale, math.sin(_time * bird.flapSpeed + bird.phase));
    }
    canvas.restore();
  }

  void _drawSeagull(Canvas canvas, double x, double y, double scale, double flap) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale, scale);

    final shadow = Paint()
      ..color = const Color(0xFF075985).withValues(alpha: .18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(const Rect.fromLTWH(-13, 10, 32, 7), shadow);

    final outline = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final feather = Paint()..color = const Color(0xFFF8FAFC);
    final shadedFeather = Paint()..color = const Color(0xFFCBD5E1);

    // Tail feathers sit behind the body.
    final tail = Path()
      ..moveTo(-11, 2)
      ..lineTo(-19, -2)
      ..lineTo(-16, 5)
      ..lineTo(-20, 9)
      ..lineTo(-9, 7)
      ..close();
    canvas.drawPath(tail, shadedFeather);
    canvas.drawPath(tail, outline);

    // Far wing first, near wing second: both are filled silhouettes rather than
    // two strokes, so the bird remains readable at every flap angle.
    final double wingLift = 10 + flap * 8;
    final farWing = Path()
      ..moveTo(-3, 2)
      ..quadraticBezierTo(-8, -wingLift * .65, -18, -wingLift)
      ..quadraticBezierTo(-12, 1, 3, 7)
      ..close();
    canvas.drawPath(farWing, shadedFeather);
    canvas.drawPath(farWing, outline);

    final body = Path()
      ..moveTo(-12, 2)
      ..cubicTo(-5, -3, 7, -3, 14, 2)
      ..cubicTo(17, 5, 12, 10, 3, 11)
      ..cubicTo(-6, 12, -12, 8, -12, 2)
      ..close();
    canvas.drawPath(body, feather);
    canvas.drawPath(body, outline);

    final nearWing = Path()
      ..moveTo(-2, 3)
      ..quadraticBezierTo(2, -wingLift, 15, -wingLift - 4)
      ..quadraticBezierTo(12, -2, 4, 8)
      ..close();
    canvas.drawPath(nearWing, feather);
    canvas.drawPath(nearWing, outline);
    canvas.drawCircle(const Offset(14, 2), 4.4, feather);
    canvas.drawCircle(const Offset(14, 2), 4.4, outline);
    final beak = Path()..moveTo(18, 2)..lineTo(24, 4)..lineTo(18, 6)..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFF59E0B));
    canvas.drawPath(beak, outline);
    canvas.drawCircle(const Offset(15.2, .8), .72, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(const Offset(15.45, .55), .2, Paint()..color = Colors.white);

    canvas.restore();
  }
}


class PlaneFlyoverComponent extends PositionComponent {
  final Vector2 velocity;
  final double mapWidth;
  double _time = 0.0;

  PlaneFlyoverComponent({
    required Vector2 startPos,
    required this.velocity,
    required this.mapWidth,
  }) {
    position = startPos;
    size = Vector2(176, 82);
    anchor = Anchor.center;
    priority = 18; // Above the map, below factory markers.
  }

  @override
  void update(double dt) {
    _time += dt;
    position.add(velocity * dt);
    if (position.x < -size.x - 180 || position.x > mapWidth + size.x + 180) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2 + math.sin(_time * 2.4) * 1.5);
    if (velocity.x < 0) canvas.scale(-1, 1);
    canvas.translate(-size.x / 2, -size.y / 2);

    final shadowPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: .22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(const Rect.fromLTWH(27, 57, 126, 13), shadowPaint);

    final outline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final bodyPaint = Paint()..color = const Color(0xFF2563EB);
    final lightBlue = Paint()..color = const Color(0xFF38BDF8);
    final darkBlue = Paint()..color = const Color(0xFF1E3A8A);
    final gold = Paint()..color = AppColors.gold;

    // Main fuselage: chunky, readable silhouette matching the game's comic assets.
    final fuselage = Path()
      ..moveTo(20, 37)
      ..quadraticBezierTo(24, 29, 42, 28)
      ..lineTo(133, 28)
      ..quadraticBezierTo(150, 29, 165, 40)
      ..quadraticBezierTo(151, 52, 133, 53)
      ..lineTo(41, 53)
      ..quadraticBezierTo(25, 52, 20, 44)
      ..close();
    canvas.drawPath(fuselage, bodyPaint);
    canvas.drawPath(fuselage, outline);

    // Near wing.
    final nearWing = Path()
      ..moveTo(77, 49)
      ..lineTo(117, 73)
      ..lineTo(92, 73)
      ..lineTo(58, 50)
      ..close();
    canvas.drawPath(nearWing, darkBlue);
    canvas.drawPath(nearWing, outline);

    // Far wing.
    final farWing = Path()
      ..moveTo(75, 31)
      ..lineTo(104, 8)
      ..lineTo(124, 8)
      ..lineTo(96, 32)
      ..close();
    canvas.drawPath(farWing, lightBlue);
    canvas.drawPath(farWing, outline);

    // Tail fin and rear stabilizer.
    final tailFin = Path()
      ..moveTo(33, 31)
      ..lineTo(20, 10)
      ..lineTo(42, 10)
      ..lineTo(58, 31)
      ..close();
    canvas.drawPath(tailFin, darkBlue);
    canvas.drawPath(tailFin, outline);
    final tailWing = Path()
      ..moveTo(37, 48)
      ..lineTo(18, 63)
      ..lineTo(49, 58)
      ..lineTo(62, 49)
      ..close();
    canvas.drawPath(tailWing, lightBlue);
    canvas.drawPath(tailWing, outline);

    // Gold company stripe ties the aircraft into the tycoon UI palette.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(45, 42, 91, 6), const Radius.circular(3)),
      gold,
    );

    // Cartoon cockpit and windows. Cyan is used instead of white so the plane
    // cannot be confused with the removed white map artifacts.
    final cockpit = Path()
      ..moveTo(137, 31)
      ..quadraticBezierTo(151, 32, 158, 39)
      ..lineTo(139, 39)
      ..close();
    canvas.drawPath(cockpit, Paint()..color = const Color(0xFF7DD3FC));
    canvas.drawPath(cockpit, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2.2);
    for (final x in const <double>[60, 76, 92, 108, 124]) {
      canvas.drawCircle(Offset(x, 35), 3.4, Paint()..color = const Color(0xFFBAE6FD));
      canvas.drawCircle(Offset(x, 35), 3.4, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.6);
    }

    // Tiny gold beacon adds life without introducing another large animation.
    final beaconAlpha = .55 + (math.sin(_time * 8) + 1) * .225;
    canvas.drawCircle(Offset(86, 24), 3.0, Paint()..color = AppColors.gold.withValues(alpha: beaconAlpha));
    canvas.drawCircle(Offset(86, 24), 3.0, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.4);

    canvas.restore();
  }
}

class FlyingBagComponent extends PositionComponent with TapCallbacks {
  final double reward; final Function(double) onBagTap; double _time = 0; final Vector2 velocity;
  FlyingBagComponent({required this.reward, required this.onBagTap, required Vector2 startPos, required this.velocity}) { position = startPos; size = Vector2(80, 80); anchor = Anchor.center; priority = 40; }
  @override void update(double dt) { _time += dt; position.add(velocity * dt); position.y += math.sin(_time * 6) * 3; if (position.x < -200 || position.x > 1300) { removeFromParent(); } }
  @override void onTapUp(TapUpEvent event) { onBagTap(reward); removeFromParent(); }
  @override void render(Canvas canvas) {
    canvas.drawRect(Rect.fromCenter(center: Offset(size.x/2, size.y/2), width: 70, height: 70), Paint()..color=Colors.white.withValues(alpha: 0.5)..maskFilter=const MaskFilter.blur(BlurStyle.normal, 10));
    Path bag = Path()..moveTo(size.x/2 - 25, size.y/2 + 25)..lineTo(size.x/2 - 25, size.y/2)..lineTo(size.x/2 - 15, size.y/2 - 20)..lineTo(size.x/2 + 15, size.y/2 - 20)..lineTo(size.x/2 + 25, size.y/2)..lineTo(size.x/2 + 25, size.y/2 + 25)..close();
    canvas.drawPath(bag, Paint()..color = AppColors.gold); canvas.drawPath(bag, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth=4);
    canvas.drawRect(Rect.fromLTWH(size.x/2 - 12, size.y/2 - 32, 24, 12), Paint()..color = Colors.orange.shade700); canvas.drawLine(Offset(size.x/2 - 14, size.y/2 - 20), Offset(size.x/2 + 14, size.y/2 - 20), Paint()..color = Colors.black..strokeWidth=4);
    final textPainter = TextPainter(text: const TextSpan(text: '\$', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, offset: Offset(2,2), blurRadius: 0)])), textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, Offset(size.x/2 - textPainter.width/2, size.y/2 - 16));
  }
}

class HoldingTycoonGame extends FlameGame with ScaleDetector {
  final Function(String) onFactoryTap; final Function(double) onBagTapped; 
  late final CameraComponent cam; final World mapWorld = World(); double mapWidth = 1080.0; double mapHeight = 1920.0; final double topPadding = 250.0; final double bottomPadding = 350.0;
  GameState? _currentState;
  double _scaleStartZoom = 1.0;
  double _minimumZoom = 1.0;
  double _maximumZoom = 2.75;
  bool _zoomInitialized = false;
  double _planeSpawnTimer = 0.0;
  static const double _planeIntervalSeconds = 300.0; // One flyover every 5 minutes.
  HoldingTycoonGame({required this.onFactoryTap, required this.onBagTapped}) { cam = CameraComponent(world: mapWorld); }
  
  void updateState(GameState state) { 
    _currentState = state; 
    for (var child in mapWorld.children) { 
      if (child is FactoryPlotComponent && _currentState != null) { 
        child.updateData(
          _currentState!.factories.firstWhere((f) => f.id == child.factoryId),
          darkMode: _currentState!.useDarkTheme,
        ); 
      } 
    } 
  }

  @override
  void update(double dt) {
    super.update(dt);
    _planeSpawnTimer += dt;
    if (_planeSpawnTimer >= _planeIntervalSeconds) {
      _planeSpawnTimer %= _planeIntervalSeconds;
      final hasActivePlane = mapWorld.children.whereType<PlaneFlyoverComponent>().isNotEmpty;
      if (!hasActivePlane) _spawnPlaneFlyover();
    }
  }

  void _spawnPlaneFlyover() {
    final random = math.Random();
    final fromLeft = random.nextBool();
    final viewTop = -cam.viewfinder.position.y;
    final viewHeight = size.y / cam.viewfinder.zoom;
    final double visibleMinY = math.max(140.0, viewTop + viewHeight * 0.18).toDouble();
    final double visibleMaxY = math.min(mapHeight - 140.0, viewTop + viewHeight * 0.58).toDouble();
    final double spawnY = visibleMaxY > visibleMinY
        ? visibleMinY + random.nextDouble() * (visibleMaxY - visibleMinY)
        : mapHeight * 0.35;
    final speed = 125.0 + random.nextDouble() * 25.0;

    mapWorld.add(
      PlaneFlyoverComponent(
        startPos: Vector2(fromLeft ? -210 : mapWidth + 210, spawnY),
        velocity: Vector2(fromLeft ? speed : -speed, -2.0 + random.nextDouble() * 4.0),
        mapWidth: mapWidth,
      ),
    );
  }

  void spawnFlyingBag(double reward) { 
    bool fromLeft = math.Random().nextBool(); 
    double viewTop = -cam.viewfinder.position.y; 
    double viewHeight = size.y / cam.viewfinder.zoom;
    double spawnY = viewTop + (viewHeight * 0.3) + (math.Random().nextDouble() * (viewHeight * 0.4));
    mapWorld.add(FlyingBagComponent(reward: reward, startPos: Vector2(fromLeft ? -100 : mapWidth + 100, spawnY), velocity: Vector2(fromLeft ? 200 : -200, 0), onBagTap: onBagTapped));
  }
  
  @override Color backgroundColor() => themeOceanBlue; 
  
  @override Future<void> onLoad() async {
    add(mapWorld);
    try {
      final mapSprite = await Sprite.load('map.png'); 
      mapHeight = mapWidth * (mapSprite.srcSize.y / mapSprite.srcSize.x);
      mapWorld.add(SpriteComponent(sprite: mapSprite, size: Vector2(mapWidth, mapHeight))..priority = 0);
    } catch (e) { 
      debugPrint('Map asset could not be loaded; using the interactive fallback: $e');
    }
    final List<Vector2> plotPositions = [Vector2(540, 420), Vector2(330, 520), Vector2(700, 560), Vector2(320, 720), Vector2(720, 750), Vector2(310, 930), Vector2(680, 950), Vector2(460, 1080), Vector2(650, 1180), Vector2(360, 1240), Vector2(530, 1280), Vector2(320, 1390), Vector2(500, 1440), Vector2(420, 1550), Vector2(580, 1680)];
    for (int i = 0; i < plotPositions.length; i++) {
      mapWorld.add(FactoryPlotComponent(factoryId: (i + 1).toString(), position: plotPositions[i], onTap: onFactoryTap));
    }
    mapWorld.add(SeagullFlockController(mapWidth: mapWidth, mapHeight: mapHeight));
    if (_currentState != null) updateState(_currentState!);
    cam.viewfinder.anchor = Anchor.topLeft; 
    cam.viewfinder.position = Vector2(0, -topPadding); 
    add(cam);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _minimumZoom = size.x / mapWidth;
    _maximumZoom = _minimumZoom * 2.75;
    if (!_zoomInitialized) {
      cam.viewfinder.zoom = _minimumZoom;
      _zoomInitialized = true;
    } else {
      cam.viewfinder.zoom = cam.viewfinder.zoom
          .clamp(_minimumZoom, _maximumZoom)
          .toDouble();
    }
    _clampCameraPosition();
  }

  void _clampCameraPosition() {
    final double zoom = cam.viewfinder.zoom;
    final double viewWidth = size.x / zoom;
    final double viewHeight = size.y / zoom;

    final double maxX = math.max(0.0, mapWidth - viewWidth);
    final double maxY = math.max(-topPadding, mapHeight - viewHeight + bottomPadding);

    cam.viewfinder.position = Vector2(
      cam.viewfinder.position.x.clamp(0.0, maxX).toDouble(),
      cam.viewfinder.position.y.clamp(-topPadding, maxY).toDouble(),
    );
  }

  @override
  void onScaleStart(ScaleStartInfo info) {
    _scaleStartZoom = cam.viewfinder.zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final Vector2 scale = info.scale.global;

    if (!scale.isIdentity()) {
      final double oldZoom = cam.viewfinder.zoom;
      final double oldViewWidth = size.x / oldZoom;
      final double oldViewHeight = size.y / oldZoom;
      final double centerX = cam.viewfinder.position.x + oldViewWidth / 2;
      final double centerY = cam.viewfinder.position.y + oldViewHeight / 2;

      final double nextZoom = (_scaleStartZoom * scale.y)
          .clamp(_minimumZoom, _maximumZoom)
          .toDouble();

      if ((nextZoom - oldZoom).abs() > 0.0001) {
        cam.viewfinder.zoom = nextZoom;
        final double newViewWidth = size.x / nextZoom;
        final double newViewHeight = size.y / nextZoom;
        cam.viewfinder.position = Vector2(
          centerX - newViewWidth / 2,
          centerY - newViewHeight / 2,
        );
        _clampCameraPosition();
      }
      return;
    }

    // ScaleDetector also receives ordinary one-finger pan updates. Keeping the
    // pan handling here avoids combining PanDetector and ScaleDetector, which
    // Flutter/Flame explicitly disallows because scale is a superset of pan.
    final Vector2 delta = info.delta.global;
    final double zoom = cam.viewfinder.zoom;
    cam.viewfinder.position = Vector2(
      cam.viewfinder.position.x - (delta.x / zoom),
      cam.viewfinder.position.y - (delta.y / zoom),
    );
    _clampCameraPosition();
  }
}

class FactoryPlotComponent extends PositionComponent with TapCallbacks {
  final String factoryId; 
  final Function(String) onTap; 
  FactoryData? _data;
  bool _darkMode = false;
  
  FactoryPlotComponent({required this.factoryId, required Vector2 position, required this.onTap}) : super(position: position, size: Vector2(250, 250), anchor: Anchor.center) {
    priority = 30;
  }
  
  void updateData(FactoryData data, {bool darkMode = false}) {
    _data = data;
    _darkMode = darkMode;
  } 
  
  @override void onTapUp(TapUpEvent event) { onTap(factoryId); }
  
  @override void render(Canvas canvas) {
    final currentData = _data; 
    
    if (currentData == null) {
      return; 
    }
    
    if (!currentData.isUnlocked) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(10, 10, size.x - 20, size.y - 20),
          const Radius.circular(20),
        ),
        Paint()
          ..color = (_darkMode ? AppColors.darkSurface : Colors.white)
              .withValues(alpha: 0.90)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, size.x-20, size.y-20), const Radius.circular(20)), Paint()..color = Colors.black..style=PaintingStyle.stroke..strokeWidth=5);
      final iconPainter = TextPainter(textDirection: TextDirection.ltr)..text = TextSpan(text: String.fromCharCode(Icons.lock_rounded.codePoint), style: TextStyle(fontSize: 40, fontFamily: Icons.lock_rounded.fontFamily, color: _darkMode ? Colors.white : Colors.black))..layout(); 
      iconPainter.paint(canvas, Offset(size.x/2 - 20, size.y/2 - 20));
    } else {
      // The unlocked plot is rendered by the dedicated vector-art system.
      // FactoryData.currentStage drives the 5-step visual progression:
      // 0-29 = stage 1, 30-59 = stage 2, 60-89 = stage 3,
      // 90-119 = stage 4, 120+ = stage 5 (maximum appearance).
      FactoryDrawingRenderer.paint(
        canvas,
        Size(size.x, size.y),
        factoryId: factoryId,
        stage: currentData.currentStage,
      );

    }
  }
}

class AnimatedMoneyText extends ImplicitlyAnimatedWidget {
  final double money;
  final TextStyle style;
  final String Function(double) formatNum;
  final String prefix;

  const AnimatedMoneyText({
    super.key,
    required this.money,
    required this.style,
    required this.formatNum,
    this.prefix = '\$',
    super.duration = const Duration(milliseconds: 500),
  });

  @override
  ImplicitlyAnimatedWidgetState<AnimatedMoneyText> createState() => _AnimatedMoneyTextState();
}

class _AnimatedMoneyTextState extends AnimatedWidgetBaseState<AnimatedMoneyText> {
  Tween<double>? _moneyTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _moneyTween = visitor(
      _moneyTween,
      widget.money,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final value = _moneyTween?.evaluate(animation) ?? widget.money;
    return Text(
      '${widget.prefix}${widget.formatNum(value)}', 
      style: widget.style, 
      overflow: TextOverflow.ellipsis,
    );
  }
}
