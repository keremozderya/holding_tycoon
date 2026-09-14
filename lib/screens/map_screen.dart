// lib/screens/map_screen.dart
// ignore_for_file: discarded_futures, prefer_const_constructors, curly_braces_in_flow_control_structures, undefined_hidden_name, unused_import

import 'dart:async' as async;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
import '../services/admob_service.dart';
import '../services/audio_service.dart'; 
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
                    child: SizedBox(width: 40, height: 40, child: CustomPaint(painter: HeavyIconPainter(type: 'factory', color: Colors.white))), 
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
                    child: const Text('SEKTÖRE GİRİŞ YAP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
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
              SizedBox(width: 32, height: 32, child: CustomPaint(painter: HeavyIconPainter(type: iconType, color: isSel ? Colors.black : AppColors.textMuted))),
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
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.profit, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 3)), child: SizedBox(width: 48, height: 48, child: CustomPaint(painter: HeavyIconPainter(type: 'chart', color: Colors.white)))), 
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
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _uiMutedSurface(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 3)), child: SizedBox(width: 48, height: 48, child: CustomPaint(painter: HeavyIconPainter(type: 'land', color: Colors.black)))), 
              const SizedBox(height: 20),
              Text('${fac.name} inşası için arsa bedeli:', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.bold)), 
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
              child: const Text('İPTAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14))
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
              child: const Text('ONAYLA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
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
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.loss, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2)), child: SizedBox(width: 32, height: 32, child: CustomPaint(painter: HeavyIconPainter(type: 'receipt', color: Colors.white)))),
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
                FittedBox(fit: BoxFit.scaleDown, child: Text('REKLAMLA ÖDE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13))),
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
                                  tooltip: 'Menü',
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
              child: CustomPaint(painter: HeavyIconPainter(type: iconType, color: Colors.black)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)),
                    child: const Text('ÖDÜLÜ AL', style: TextStyle(color: AppColors.profit, fontSize: 12, fontWeight: FontWeight.w900)),
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
              child: CustomPaint(painter: HeavyIconPainter(type: 'warning', color: Colors.white)),
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
              child: Text(recoveredFromTimeout ? 'TAMAM — UYGULANDI' : 'TAMAM', style: TextStyle(color: recoveredFromTimeout ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
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
            child: CustomPaint(painter: HeavyIconPainter(type: 'warning', color: Colors.white)),
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
                    child: CustomPaint(painter: HeavyIconPainter(type: widget.iconType, color: Colors.black)),
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
          text: TextSpan(text: '2X', style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
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

class ProductSvgIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;

  const ProductSvgIcon({
    super.key,
    required this.name,
    this.size = 20,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '$name ürün ikonu',
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            isComplex: true,
            willChange: false,
            painter: _ProductVectorPainter(name: name, tint: color),
          ),
        ),
      ),
    );
  }
}


class _ProductVectorPainter extends CustomPainter {
  final String name;
  final Color tint;

  _ProductVectorPainter({required this.name, required this.tint});

  static const Map<String, String> _legacyNames = {
    'Tereyağ': 'Tereyağı',
    'Motorsiklet': 'Motosiklet',
    'Vip Limuzin': 'VIP Limuzin',
    'Covi-19 Aşısı': 'COVID-19 Aşısı',
    'Rüzgar Tribünü': 'Rüzgar Türbini',
  };

  Paint _fill(Color c) => Paint()..color = c..style = PaintingStyle.fill;
  Paint _stroke(Color c, [double w = 1.25]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  Paint _grad(Color a, Color b, Rect r, {Alignment begin = Alignment.topLeft, Alignment end = Alignment.bottomRight}) {
    return Paint()
      ..shader = LinearGradient(begin: begin, end: end, colors: [a, b]).createShader(r)
      ..style = PaintingStyle.fill;
  }

  Paint _metal(Rect r) => _grad(const Color(0xFFF8FAFC), const Color(0xFF475569), r);
  Paint _darkMetal(Rect r) => _grad(const Color(0xFF64748B), const Color(0xFF111827), r);
  Paint _glass(Rect r) => _grad(const Color(0xFFBAE6FD), const Color(0xFF075985), r);
  Paint _gold(Rect r) => _grad(const Color(0xFFFFE38A), const Color(0xFFB7791F), r);
  Paint _wood(Rect r) => _grad(const Color(0xFFD9A066), const Color(0xFF6B3417), r);

  void _shadow(Canvas c, Rect r) {
    c.drawOval(
      Rect.fromLTWH(r.left - 1, r.bottom - 1, r.width + 2, math.max(2.0, r.height * .22)),
      _fill(Colors.black26),
    );
  }

  void _card(Canvas c, Rect r) {
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(2.5)),
      _fill(const Color(0xFF111827)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(2.5)),
      _stroke(const Color(0xFF334155), .8),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);
    // Every product illustration owns the same 24x24 drawing surface. Clipping
    // here prevents strokes and shadows from leaking into adjacent cards.
    canvas.clipRect(const Rect.fromLTWH(0, 0, 24, 24));
    final bool muted = tint != Colors.black && tint != Colors.black87;
    if (muted) {
      canvas.saveLayer(
        const Rect.fromLTWH(0, 0, 24, 24),
        Paint()..colorFilter = ColorFilter.mode(tint, BlendMode.modulate),
      );
    }

    final outline = _stroke(Colors.black87, 1.1);
    final hi = _stroke(Colors.white54, .65);

    switch (_legacyNames[name] ?? name) {
      // =========================
      // 1) TEKSTİL
      // =========================
      case 'T-shirt':
        _shadow(canvas, const Rect.fromLTWH(4, 5, 16, 16));
        Path t = Path()
          ..moveTo(8, 5)..lineTo(10, 4)..lineTo(12, 6)..lineTo(14, 4)..lineTo(16, 5)
          ..lineTo(19, 9)..lineTo(16.5, 11)..lineTo(15.5, 9.5)..lineTo(15.5, 20)
          ..lineTo(8.5, 20)..lineTo(8.5, 9.5)..lineTo(7.5, 11)..lineTo(5, 9)..close();
        canvas.drawPath(t, _grad(const Color(0xFF60A5FA), const Color(0xFF1D4ED8), const Rect.fromLTWH(5, 4, 14, 16)));
        canvas.drawPath(t, outline);
        canvas.drawArc(const Rect.fromLTWH(9.5, 4.5, 5, 3), 0, math.pi, false, hi);
        break;

      case 'Pantolon':
        _shadow(canvas, const Rect.fromLTWH(5, 4, 14, 17));
        Path p = Path()..moveTo(7, 5)..lineTo(17, 5)..lineTo(15, 11)..lineTo(16, 20)..lineTo(12.5, 20)
          ..lineTo(12, 12)..lineTo(11.5, 20)..lineTo(8, 20)..lineTo(9, 11)..close();
        canvas.drawPath(p, _grad(const Color(0xFF3B82F6), const Color(0xFF172554), const Rect.fromLTWH(7, 5, 10, 15)));
        canvas.drawPath(p, outline);
        canvas.drawLine(const Offset(12, 6), const Offset(12, 11), hi);
        break;

      case 'Ayakkabı':
        _shadow(canvas, const Rect.fromLTWH(3, 10, 18, 10));
        Path s = Path()..moveTo(5, 15)..lineTo(10, 15)..lineTo(12, 10)..lineTo(15, 13)..lineTo(19, 15)
          ..lineTo(20, 18)..lineTo(4, 19)..lineTo(3.5, 17)..close();
        canvas.drawPath(s, _grad(const Color(0xFFF8FAFC), const Color(0xFFCBD5E1), const Rect.fromLTWH(3, 10, 17, 9)));
        canvas.drawPath(s, outline);
        canvas.drawLine(const Offset(11, 14), const Offset(17, 16), _stroke(const Color(0xFF475569), .8));
        canvas.drawLine(const Offset(9, 13), const Offset(15, 15), _stroke(const Color(0xFF475569), .8));
        canvas.drawPath(Path()..moveTo(4,18)..lineTo(20,17.3), _stroke(const Color(0xFF0F172A), 1.4));
        break;

      case 'Çanta':
        _shadow(canvas, const Rect.fromLTWH(4, 6, 16, 15));
        Rect b = const Rect.fromLTWH(5, 8, 14, 12);
        canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(2.5)), _grad(const Color(0xFFF59E0B), const Color(0xFF78350F), b));
        canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(2.5)), outline);
        canvas.drawArc(const Rect.fromLTWH(8, 4, 8, 7), math.pi, math.pi, false, _stroke(const Color(0xFF451A03), 1.7));
        canvas.drawLine(const Offset(6, 12), const Offset(18, 12), _stroke(const Color(0xFFFFE4A3), .8));
        break;

      case 'Takım Elbise':
        _shadow(canvas, const Rect.fromLTWH(5, 3, 14, 19));
        Path suit = Path()..moveTo(8, 5)..lineTo(10.5, 4)..lineTo(12, 6)..lineTo(13.5, 4)..lineTo(16, 5)
          ..lineTo(18, 9)..lineTo(15.5, 11)..lineTo(15, 20)..lineTo(9, 20)..lineTo(8.5, 11)..lineTo(6, 9)..close();
        canvas.drawPath(suit, _grad(const Color(0xFF475569), const Color(0xFF0F172A), const Rect.fromLTWH(6, 4, 12, 16)));
        canvas.drawPath(suit, outline);
        canvas.drawPath(Path()..moveTo(10,5)..lineTo(12,10)..lineTo(14,5), _fill(const Color(0xFFF8FAFC)));
        canvas.drawPath(Path()..moveTo(12,8)..lineTo(13,13)..lineTo(11,13)..close(), _gold(const Rect.fromLTWH(11,8,2,5)));
        break;

      // =========================
      // 2) MOBİLYA
      // =========================
      case 'Sandalye':
        _shadow(canvas, const Rect.fromLTWH(4, 5, 16, 16));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 7, 8, 6), const Radius.circular(1.2)), _wood(const Rect.fromLTWH(8,7,8,6)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 7, 8, 6), const Radius.circular(1.2)), outline);
        canvas.drawLine(const Offset(8.5, 12.5), const Offset(7, 20), _stroke(const Color(0xFF7C3F20), 1.5));
        canvas.drawLine(const Offset(15.5, 12.5), const Offset(17, 20), _stroke(const Color(0xFF7C3F20), 1.5));
        canvas.drawLine(const Offset(9, 7), const Offset(9, 4), _stroke(const Color(0xFF7C3F20), 1.5));
        canvas.drawLine(const Offset(15, 7), const Offset(15, 4), _stroke(const Color(0xFF7C3F20), 1.5));
        canvas.drawLine(const Offset(9, 4.5), const Offset(15, 4.5), _stroke(const Color(0xFFD9A066), 1));
        break;

      case 'Masa':
        _shadow(canvas, const Rect.fromLTWH(2, 7, 20, 15));
        Rect top = const Rect.fromLTWH(3, 7, 18, 4);
        canvas.drawRRect(RRect.fromRectAndRadius(top, const Radius.circular(1)), _wood(top));
        canvas.drawRRect(RRect.fromRectAndRadius(top, const Radius.circular(1)), outline);
        for (final x in [4.2, 19.2]) {
          canvas.drawLine(Offset(x, 10.5), Offset(x - 1.1, 20), _stroke(const Color(0xFF6B3417), 1.5));
        }
        break;

      case 'Koltuk':
        _shadow(canvas, const Rect.fromLTWH(3, 8, 18, 13));
        Rect base = const Rect.fromLTWH(5, 10, 14, 9);
        canvas.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(2.5)), _grad(const Color(0xFFE2E8F0), const Color(0xFF64748B), base));
        canvas.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(2.5)), outline);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 7, 5.5, 8), const Radius.circular(2)), _fill(const Color(0xFFC7D2FE)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12.5, 7, 5.5, 8), const Radius.circular(2)), _fill(const Color(0xFFC7D2FE)));
        canvas.drawLine(const Offset(7, 18.5), const Offset(6.5, 20.5), outline);
        canvas.drawLine(const Offset(17, 18.5), const Offset(17.5, 20.5), outline);
        break;

      case 'Yatak':
        _shadow(canvas, const Rect.fromLTWH(2, 8, 20, 13));
        Rect mattress = const Rect.fromLTWH(4, 10, 16, 8);
        canvas.drawRRect(RRect.fromRectAndRadius(mattress, const Radius.circular(1.5)), _grad(const Color(0xFFDBEAFE), const Color(0xFF93C5FD), mattress));
        canvas.drawRRect(RRect.fromRectAndRadius(mattress, const Radius.circular(1.5)), outline);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 6, 7, 6), const Radius.circular(1.5)), _fill(Colors.white));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, 6, 7, 6), const Radius.circular(1.5)), _fill(Colors.white));
        canvas.drawRect(const Rect.fromLTWH(4, 17, 16, 2), _darkMetal(const Rect.fromLTWH(4,17,16,2)));
        break;

      case 'Dolap':
        _shadow(canvas, const Rect.fromLTWH(5, 3, 14, 18));
        Rect d = const Rect.fromLTWH(6, 4, 12, 16);
        canvas.drawRect(d, _wood(d));
        canvas.drawRect(d, outline);
        canvas.drawLine(const Offset(12, 4), const Offset(12, 20), outline);
        canvas.drawCircle(const Offset(10.8, 12), .6, _fill(const Color(0xFFFFD66D)));
        canvas.drawCircle(const Offset(13.2, 12), .6, _fill(const Color(0xFFFFD66D)));
        canvas.drawRect(const Rect.fromLTWH(7, 5, 4, .7), _fill(Colors.white24));
        break;

      // =========================
      // 3) TARIM
      // =========================
      case 'Buğday':
        _shadow(canvas, const Rect.fromLTWH(6, 5, 12, 17));
        canvas.drawLine(const Offset(12, 20), const Offset(12, 8), _stroke(const Color(0xFF3F6212), 1.2));
        for (int i = 0; i < 4; i++) {
          final y = 8.5 + i * 2.6;
          canvas.drawOval(Rect.fromLTWH(8.2, y, 3.8, 2), _gold(Rect.fromLTWH(8.2,y,3.8,2)));
          canvas.drawOval(Rect.fromLTWH(12.0, y + .6, 3.8, 2), _gold(Rect.fromLTWH(12,y+.6,3.8,2)));
        }
        break;

      case 'Mısır':
        _shadow(canvas, const Rect.fromLTWH(6, 6, 12, 15));
        Path leaf1 = Path()..moveTo(9,20)..quadraticBezierTo(5,14,8,8)..quadraticBezierTo(10,13,11,20)..close();
        Path leaf2 = Path()..moveTo(15,20)..quadraticBezierTo(19,14,16,8)..quadraticBezierTo(14,13,13,20)..close();
        canvas.drawPath(leaf1, _fill(const Color(0xFF65A30D)));
        canvas.drawPath(leaf2, _fill(const Color(0xFF84CC16)));
        Rect cob = const Rect.fromLTWH(9,6,6,12);
        canvas.drawOval(cob, _grad(const Color(0xFFFDE047), const Color(0xFFCA8A04), cob));
        canvas.drawOval(cob, outline);
        for (int i=0;i<4;i++) {
          canvas.drawLine(Offset(10,8+i*2), Offset(14,8.7+i*2), _stroke(const Color(0xFFFEF08A), .5));
        }
        break;

      case 'Pamuk':
        _shadow(canvas, const Rect.fromLTWH(5, 7, 14, 14));
        canvas.drawLine(const Offset(12,20), const Offset(12,12), _stroke(const Color(0xFF166534), 1.1));
        for (final p in [const Offset(9,10), const Offset(12,8), const Offset(15,10), const Offset(10,13), const Offset(14,13)]) {
          canvas.drawCircle(p, 2.3, _fill(Colors.white));
          canvas.drawCircle(p, 2.3, outline);
        }
        break;

      case 'Safran':
        _shadow(canvas, const Rect.fromLTWH(6, 8, 12, 13));
        canvas.drawLine(const Offset(12,20), const Offset(12,11), _stroke(const Color(0xFF166534), 1.1));
        for (int i=0;i<3;i++) {
          final a = -0.8 + i*.8;
          final p = Offset(12 + math.cos(a)*4, 9 + math.sin(a)*3.4);
          canvas.drawOval(Rect.fromCenter(center:p, width:4.6, height:3.2), _grad(const Color(0xFFF0ABFC), const Color(0xFF86198F), Rect.fromCenter(center:p,width:5,height:4)));
        }
        canvas.drawCircle(const Offset(12,10), 1.0, _fill(const Color(0xFFF59E0B)));
        break;

      case 'Hibrit Tohum':
        _shadow(canvas, const Rect.fromLTWH(6, 7, 12, 13));
        Path seed = Path()..moveTo(12,4.5)..cubicTo(16,7,18,11,15,16)..cubicTo(13,20,8,18.5,7,14)..cubicTo(6,9,8.5,6,12,4.5)..close();
        canvas.drawPath(seed, _grad(const Color(0xFF86EFAC), const Color(0xFF14532D), const Rect.fromLTWH(7,5,11,14)));
        canvas.drawPath(seed, outline);
        canvas.drawArc(const Rect.fromLTWH(8,8,8,8), 0.2, 1.7, false, _stroke(const Color(0xFFD1FAE5), 1));
        break;

      // =========================
      // 4) SÜT
      // =========================
      case 'Süt':
        _shadow(canvas, const Rect.fromLTWH(6, 3, 12, 18));
        Rect bottle = const Rect.fromLTWH(8,6,8,14);
        canvas.drawRRect(RRect.fromRectAndRadius(bottle,const Radius.circular(1.8)),_fill(Colors.white));
        canvas.drawRRect(RRect.fromRectAndRadius(bottle,const Radius.circular(1.8)),outline);
        canvas.drawRect(const Rect.fromLTWH(8.5,10,7,4),_fill(const Color(0xFF38BDF8)));
        canvas.drawRect(const Rect.fromLTWH(10,3.8,4,2.4),_fill(const Color(0xFFCBD5E1)));
        break;

      case 'Yoğurt':
        _shadow(canvas, const Rect.fromLTWH(5, 9, 14, 11));
        Rect cup = const Rect.fromLTWH(6,9,12,10);
        canvas.drawRRect(RRect.fromRectAndRadius(cup,const Radius.circular(2)),_fill(Colors.white));
        canvas.drawRRect(RRect.fromRectAndRadius(cup,const Radius.circular(2)),outline);
        canvas.drawRect(const Rect.fromLTWH(6.6,12,10.8,4),_fill(const Color(0xFFBAE6FD)));
        canvas.drawLine(const Offset(7,9),const Offset(17,9),_stroke(const Color(0xFF7DD3FC),1.2));
        break;

      case 'Tereyağı':
        _shadow(canvas, const Rect.fromLTWH(4, 7, 16, 13));
        Rect butter = const Rect.fromLTWH(5,8,14,9);
        canvas.drawRRect(RRect.fromRectAndRadius(butter,const Radius.circular(1.5)),_grad(const Color(0xFFFFF7C2),const Color(0xFFF59E0B),butter));
        canvas.drawRRect(RRect.fromRectAndRadius(butter,const Radius.circular(1.5)),outline);
        canvas.drawLine(const Offset(6,11),const Offset(18,11),_stroke(const Color(0xFFFFFDE7),.7));
        break;

      case 'Arı Sütü':
        _shadow(canvas, const Rect.fromLTWH(5, 4, 14, 17));
        Rect jar = const Rect.fromLTWH(7,6,10,13);
        canvas.drawRRect(RRect.fromRectAndRadius(jar,const Radius.circular(2)),_fill(const Color(0xFFFFFBEB)));
        canvas.drawRRect(RRect.fromRectAndRadius(jar,const Radius.circular(2)),outline);
        canvas.drawRect(const Rect.fromLTWH(8,10,8,4),_fill(const Color(0xFFF59E0B)));
        canvas.drawCircle(const Offset(12,8),1.7,_fill(const Color(0xFFFFD66D)));
        break;

      case 'Pule Peyniri':
        _shadow(canvas, const Rect.fromLTWH(4, 8, 16, 12));
        Path cheese = Path()..moveTo(5,17)..lineTo(7,9)..lineTo(19,9)..lineTo(17,18)..close();
        canvas.drawPath(cheese,_grad(const Color(0xFFFFF7AE),const Color(0xFFD4A017),const Rect.fromLTWH(5,9,14,9)));
        canvas.drawPath(cheese,outline);
        for(final p in [const Offset(9,12),const Offset(14,14),const Offset(16,11)]) {
          canvas.drawCircle(p, .65, _fill(const Color(0xFFB7791F)));
        }
        break;

      // =========================
      // 5) ET / MEZBAHA
      // =========================
      case 'Sosis':
        _shadow(canvas, const Rect.fromLTWH(3, 8, 18, 12));
        Path sausage = Path()..moveTo(5,10)..cubicTo(7,7,10,8,12,10)..cubicTo(14,12,17,8,19,11)
          ..cubicTo(20,13,18,16,15,17)..cubicTo(12,18,9,15,7,16)..cubicTo(4,17,3,13,5,10)..close();
        canvas.drawPath(sausage,_grad(const Color(0xFFF87171),const Color(0xFF991B1B),const Rect.fromLTWH(4,8,16,9)));
        canvas.drawPath(sausage,outline);
        for(int i=0;i<4;i++) canvas.drawCircle(Offset(7+i*3.0,12+(i.isEven?0.5:-.3)),.35,_fill(const Color(0xFFFECACA)));
        break;

      case 'Tavuk':
        _shadow(canvas, const Rect.fromLTWH(4, 7, 16, 14));
        Path drum = Path()..moveTo(11,7)..cubicTo(16,6,18,10,16,14)..lineTo(13,18)..lineTo(15,19)
          ..lineTo(13,21)..lineTo(10,19)..lineTo(11,16)..cubicTo(7,14,7,8,11,7)..close();
        canvas.drawPath(drum,_grad(const Color(0xFFFFEDD5),const Color(0xFFEA580C),const Rect.fromLTWH(7,7,10,14)));
        canvas.drawPath(drum,outline);
        canvas.drawCircle(const Offset(14.2,18.8),1.1,_fill(const Color(0xFFF5F5F4)));
        break;

      case 'Kebap':
        _shadow(canvas, const Rect.fromLTWH(4, 8, 16, 12));
        canvas.drawLine(const Offset(5,18),const Offset(19,6),_stroke(const Color(0xFF92400E),1.7));
        for(int i=0;i<6;i++) {
          final p=Offset(7+i*1.8,16-i*1.7);
          canvas.drawCircle(p,1.25,_grad(const Color(0xFFFB923C),const Color(0xFF7C2D12),Rect.fromCircle(center:p,radius:2)));
        }
        canvas.drawCircle(const Offset(18.5,6.4),.8,_fill(const Color(0xFFE5E7EB)));
        break;

      case 'Timsah Derisi':
        _shadow(canvas, const Rect.fromLTWH(3, 5, 18, 16));
        Path hide = Path()..moveTo(4,8)..quadraticBezierTo(7,4,11,6)..quadraticBezierTo(14,3,20,7)
          ..lineTo(18,18)..lineTo(6,20)..close();
        canvas.drawPath(hide,_grad(const Color(0xFF84A98C),const Color(0xFF14532D),const Rect.fromLTWH(4,4,16,16)));
        canvas.drawPath(hide,outline);
        for(int r=0;r<3;r++) for(int c=0;c<5;c++) {
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(6+c*2.5,8+r*3,1.6,1.4),const Radius.circular(.5)),_fill(const Color(0xFF166534)));
        }
        break;

      case 'Wagyu Eti':
        _shadow(canvas, const Rect.fromLTWH(4, 8, 16, 12));
        Path steak = Path()..moveTo(5,10)..quadraticBezierTo(8,7,12,9)..quadraticBezierTo(16,7,19,10)
          ..quadraticBezierTo(20,14,17,18)..quadraticBezierTo(13,20,9,18)..quadraticBezierTo(5,17,5,10)..close();
        canvas.drawPath(steak,_grad(const Color(0xFFFCA5A5),const Color(0xFF7F1D1D),const Rect.fromLTWH(5,8,15,11)));
        canvas.drawPath(steak,outline);
        for(final p in [const Offset(8,11),const Offset(12,10),const Offset(15,13),const Offset(10,15),const Offset(16,16)]) {
          canvas.drawOval(Rect.fromCenter(center:p,width:1.6,height:.6),_fill(const Color(0xFFFDE68A)));
        }
        break;

      // =========================
      // 6) GIDA
      // =========================
      case 'Un':
        _shadow(canvas, const Rect.fromLTWH(4, 5, 16, 16));
        Path sack=Path()..moveTo(6,7)..lineTo(18,7)..lineTo(19,19)..lineTo(5,19)..close();
        canvas.drawPath(sack,_fill(const Color(0xFFEDE9D5))); canvas.drawPath(sack,outline);
        canvas.drawLine(const Offset(7,9),const Offset(17,9),_stroke(const Color(0xFFB7A77A),.8));
        canvas.drawLine(const Offset(8,12),const Offset(16,12),_stroke(const Color(0xFFB7A77A),.6));
        break;

      case 'Şeker':
        _shadow(canvas, const Rect.fromLTWH(4, 6, 16, 14));
        for(int r=0;r<3;r++) for(int c=0;c<4;c++) {
          Rect q=Rect.fromLTWH(6+c*3,8+r*3,2.6,2.6);
          canvas.drawRRect(RRect.fromRectAndRadius(q,const Radius.circular(.6)),_fill(const Color(0xFFF8FAFC)));
          canvas.drawRRect(RRect.fromRectAndRadius(q,const Radius.circular(.6)),outline);
        }
        break;

      case 'Konserve':
        _shadow(canvas, const Rect.fromLTWH(5, 4, 14, 17));
        Rect can=const Rect.fromLTWH(7,5,10,15);
        canvas.drawRRect(RRect.fromRectAndRadius(can,const Radius.circular(2)),_metal(can));
        canvas.drawRRect(RRect.fromRectAndRadius(can,const Radius.circular(2)),outline);
        canvas.drawRect(const Rect.fromLTWH(7.7,10,8.6,5),_fill(const Color(0xFFDC2626)));
        canvas.drawLine(const Offset(8,11),const Offset(16,11),_stroke(const Color(0xFFFECACA),.7));
        break;

      case 'Havyar':
        _shadow(canvas, const Rect.fromLTWH(5, 7, 14, 13));
        Rect jar=const Rect.fromLTWH(7,8,10,11);
        canvas.drawRRect(RRect.fromRectAndRadius(jar,const Radius.circular(2)),_fill(const Color(0xFF0F172A)));
        canvas.drawRRect(RRect.fromRectAndRadius(jar,const Radius.circular(2)),outline);
        for(int r=0;r<4;r++) for(int c=0;c<4;c++) canvas.drawCircle(Offset(9+c*2,10.2+r*2),.65,_fill(const Color(0xFFE5E7EB)));
        canvas.drawRect(const Rect.fromLTWH(7,6,10,2),_gold(const Rect.fromLTWH(7,6,10,2)));
        break;

      case 'Gurme Çikolata':
        _shadow(canvas, const Rect.fromLTWH(4, 6, 16, 15));
        Rect ch=const Rect.fromLTWH(5,8,14,10);
        canvas.drawRRect(RRect.fromRectAndRadius(ch,const Radius.circular(1.5)),_grad(const Color(0xFF8B5E34),const Color(0xFF3B1D0B),ch));
        canvas.drawRRect(RRect.fromRectAndRadius(ch,const Radius.circular(1.5)),outline);
        for(int r=0;r<2;r++) for(int c=0;c<4;c++) canvas.drawLine(Offset(6+c*3,8+r*5),Offset(6+c*3,18-r*5),_stroke(const Color(0xFFD7A86E),.35));
        break;

      // =========================
      // 7) MADEN
      // =========================
      case 'Kömür':
        _shadow(canvas, const Rect.fromLTWH(4, 8, 16, 12));
        Path ore=Path()..moveTo(5,14)..lineTo(8,8)..lineTo(14,7)..lineTo(19,11)..lineTo(17,18)..lineTo(10,20)..close();
        canvas.drawPath(ore,_grad(const Color(0xFF475569),const Color(0xFF020617),const Rect.fromLTWH(5,7,14,13))); canvas.drawPath(ore,outline);
        canvas.drawPath(Path()..moveTo(8,10)..lineTo(13,9)..lineTo(16,11),_stroke(const Color(0xFF94A3B8),.7));
        break;

      case 'Demir':
        _shadow(canvas, const Rect.fromLTWH(3, 7, 18, 12));
        Path beam=Path()..moveTo(4,7)..lineTo(9,7)..lineTo(9,10)..lineTo(17,10)..lineTo(17,14)..lineTo(9,14)..lineTo(9,18)..lineTo(4,18)..lineTo(4,14)..lineTo(12,14)..lineTo(12,10)..lineTo(4,10)..close();
        canvas.drawPath(beam,_metal(const Rect.fromLTWH(4,7,13,11))); canvas.drawPath(beam,outline);
        break;

      case 'Gümüş':
        _shadow(canvas, const Rect.fromLTWH(4, 8, 16, 11));
        Path bar=Path()..moveTo(6,10)..lineTo(17,8)..lineTo(19,11)..lineTo(8,14)..close();
        canvas.drawPath(bar,_metal(const Rect.fromLTWH(6,8,13,6))); canvas.drawPath(bar,outline);
        canvas.drawLine(const Offset(9,11),const Offset(16,9.5),_stroke(Colors.white,.6));
        break;

      case 'Altın':
        _shadow(canvas, const Rect.fromLTWH(4, 7, 16, 13));
        Rect ing=const Rect.fromLTWH(6,8,12,8);
        canvas.drawRRect(RRect.fromRectAndRadius(ing,const Radius.circular(1.4)),_gold(ing));
        canvas.drawRRect(RRect.fromRectAndRadius(ing,const Radius.circular(1.4)),outline);
        canvas.drawLine(const Offset(8,10),const Offset(15,10),_stroke(const Color(0xFFFFF2B2),.7));
        break;

      case 'Elmas':
        _shadow(canvas, const Rect.fromLTWH(5, 5, 14, 16));
        Path gem=Path()..moveTo(5,9)..lineTo(8,5)..lineTo(16,5)..lineTo(19,9)..lineTo(12,20)..close();
        canvas.drawPath(gem,_grad(const Color(0xFFE0F2FE),const Color(0xFF0EA5E9),const Rect.fromLTWH(5,5,14,15))); canvas.drawPath(gem,outline);
        canvas.drawLine(const Offset(8,5),const Offset(12,20),hi);
        canvas.drawLine(const Offset(16,5),const Offset(12,20),hi);
        canvas.drawLine(const Offset(5,9),const Offset(19,9),hi);
        break;

      // =========================
      // 8) KİMYA
      // =========================
      case 'Gübre':
        _shadow(canvas, const Rect.fromLTWH(4, 7, 16, 14));
        Rect sack=const Rect.fromLTWH(5,9,14,10);
        canvas.drawRRect(RRect.fromRectAndRadius(sack,const Radius.circular(1.5)),_fill(const Color(0xFFE7E5E4)));
        canvas.drawRRect(RRect.fromRectAndRadius(sack,const Radius.circular(1.5)),outline);
        canvas.drawRect(const Rect.fromLTWH(6,12,12,3),_fill(const Color(0xFF65A30D)));
        canvas.drawCircle(const Offset(12,10),1.5,_fill(const Color(0xFF84CC16)));
        break;

      case 'Plastik':
        _shadow(canvas, const Rect.fromLTWH(5, 8, 14, 12));
        for(int i=0;i<14;i++) {
          double x=6+(i%7)*2, y=10+(i~/7)*3.5;
          canvas.drawCircle(Offset(x,y),1.2,_fill(i.isEven?const Color(0xFF60A5FA):const Color(0xFF2563EB)));
          canvas.drawCircle(Offset(x,y),1.2,_stroke(const Color(0xFF1E3A8A),.4));
        }
        break;

      case 'Boya':
        _shadow(canvas, const Rect.fromLTWH(4, 5, 16, 16));
        for(int i=0;i<3;i++) {
          Rect can=Rect.fromLTWH(5+i*5,8-(i==1?2:0),5,10);
          canvas.drawRRect(RRect.fromRectAndRadius(can,const Radius.circular(1.2)),_grad(
            i==0?const Color(0xFFEF4444):i==1?const Color(0xFF60A5FA):const Color(0xFFFBBF24),
            i==0?const Color(0xFF991B1B):i==1?const Color(0xFF1D4ED8):const Color(0xFFB45309),can));
          canvas.drawRRect(RRect.fromRectAndRadius(can,const Radius.circular(1.2)),outline);
        }
        canvas.drawLine(const Offset(7,7),const Offset(7,4),_stroke(const Color(0xFF7C3AED),1.1));
        break;

      case 'Lüks Parfüm':
        _shadow(canvas, const Rect.fromLTWH(5, 4, 14, 17));
        Rect bottle=const Rect.fromLTWH(8,8,8,11);
        canvas.drawRRect(RRect.fromRectAndRadius(bottle,const Radius.circular(1.8)),_grad(const Color(0xFFFDE68A),const Color(0xFFB45309),bottle));
        canvas.drawRRect(RRect.fromRectAndRadius(bottle,const Radius.circular(1.8)),outline);
        canvas.drawRect(const Rect.fromLTWH(10,5,4,3),_gold(const Rect.fromLTWH(10,5,4,3)));
        canvas.drawRect(const Rect.fromLTWH(10.2,2.8,3.6,2.2),_metal(const Rect.fromLTWH(10.2,2.8,3.6,2.2)));
        break;

      case 'Karbonfiber':
        _shadow(canvas, const Rect.fromLTWH(4, 6, 16, 15));
        Rect cf=const Rect.fromLTWH(5,7,14,12);
        canvas.drawRRect(RRect.fromRectAndRadius(cf,const Radius.circular(1.5)),_darkMetal(cf));
        canvas.drawRRect(RRect.fromRectAndRadius(cf,const Radius.circular(1.5)),outline);
        for (int i = -3; i < 18; i += 3) {
          canvas.drawLine(
            Offset(5.0 + i.toDouble(), 8.0),
            Offset(9.0 + i.toDouble(), 18.0),
            _stroke(const Color(0xFF94A3B8), .45),
          );
        }
        for (int i = 0; i < 18; i += 3) {
          canvas.drawLine(
            Offset(6.0 + i.toDouble(), 8.0),
            Offset(16.0 + i.toDouble(), 18.0),
            _stroke(const Color(0xFF0F172A), .45),
          );
        }
        break;

      // =========================
      // 9) OTOMOTİV
      // =========================
      case 'Lastik':
        _shadow(canvas, const Rect.fromLTWH(4, 4, 16, 18));
        canvas.drawCircle(const Offset(12,13),7,_fill(const Color(0xFF111827)));
        canvas.drawCircle(const Offset(12,13),7,outline);
        canvas.drawCircle(const Offset(12,13),3.2,_fill(const Color(0xFF94A3B8)));
        canvas.drawCircle(const Offset(12,13),1.2,_fill(const Color(0xFF1E293B)));
        for(int i=0;i<8;i++){double a=i*math.pi/4; canvas.drawLine(Offset(12+3.5*math.cos(a),13+3.5*math.sin(a)),Offset(12+6.2*math.cos(a),13+6.2*math.sin(a)),_stroke(const Color(0xFF334155),.65));}
        break;

      case 'Motosiklet':
        _shadow(canvas, const Rect.fromLTWH(2, 7, 20, 14));
        canvas.drawCircle(const Offset(6.5,17),3,_fill(const Color(0xFF0F172A)));
        canvas.drawCircle(const Offset(17.5,17),3,_fill(const Color(0xFF0F172A)));
        canvas.drawLine(const Offset(8.5,16),const Offset(12,11),_stroke(const Color(0xFFEF4444),1.6));
        canvas.drawLine(const Offset(12,11),const Offset(16,16),_stroke(const Color(0xFFEF4444),1.6));
        canvas.drawLine(const Offset(10,13),const Offset(16,13),_stroke(const Color(0xFF475569),1.2));
        canvas.drawRect(const Rect.fromLTWH(10,9,5,3),_darkMetal(const Rect.fromLTWH(10,9,5,3)));
        break;

      case 'Otomobil':
        _shadow(canvas, const Rect.fromLTWH(2, 8, 20, 13));
        Path car=Path()..moveTo(4,16)..lineTo(6,11)..quadraticBezierTo(7,9,10,9)..lineTo(15,9)..quadraticBezierTo(18,10,20,16)
          ..lineTo(20,18)..lineTo(4,18)..close();
        canvas.drawPath(car,_grad(const Color(0xFF60A5FA),const Color(0xFF1D4ED8),const Rect.fromLTWH(4,9,16,9)));
        canvas.drawPath(car,outline);
        canvas.drawRect(const Rect.fromLTWH(9,10,6,3),_glass(const Rect.fromLTWH(9,10,6,3)));
        for(final x in [7.0,17.0]){canvas.drawCircle(Offset(x,18),2,_fill(const Color(0xFF0F172A)));canvas.drawCircle(Offset(x,18),.8,_fill(const Color(0xFFCBD5E1)));}
        break;

      case 'VIP Limuzin':
        _shadow(canvas, const Rect.fromLTWH(1, 8, 22, 13));
        Path limo=Path()..moveTo(3,15)..lineTo(5,11)..lineTo(9,10)..lineTo(16,10)..lineTo(19,12)..lineTo(21,15)..lineTo(21,18)..lineTo(3,18)..close();
        canvas.drawPath(limo,_grad(const Color(0xFF111827),const Color(0xFF020617),const Rect.fromLTWH(3,10,18,8)));
        canvas.drawPath(limo,outline);
        canvas.drawRect(const Rect.fromLTWH(6,11,12,2.5),_glass(const Rect.fromLTWH(6,11,12,2.5)));
        for(final x in [6.5,17.5]) canvas.drawCircle(Offset(x,18),2,_fill(const Color(0xFF0F172A)));
        break;

      case 'Süper Spor Araç':
        _shadow(canvas, const Rect.fromLTWH(2, 8, 20, 13));
        Path sp=Path()..moveTo(3,16)..lineTo(7,10)..lineTo(14,8)..lineTo(19,11)..lineTo(21,16)..lineTo(20,18)..lineTo(4,18)..close();
        canvas.drawPath(sp,_grad(const Color(0xFFF87171),const Color(0xFF7F1D1D),const Rect.fromLTWH(3,8,18,10)));
        canvas.drawPath(sp,outline);
        canvas.drawPath(Path()..moveTo(8,11)..lineTo(13,9)..lineTo(17,11),_stroke(const Color(0xFFBAE6FD),.9));
        for(final x in [6.5,17.5]) canvas.drawCircle(Offset(x,18),2.1,_fill(const Color(0xFF020617)));
        break;

      // =========================
      // 10) İLAÇ
      // =========================
      case 'Vitamin Hapı':
        _shadow(canvas,const Rect.fromLTWH(4,7,16,12));
        canvas.save(); canvas.translate(12,13); canvas.rotate(-.35); canvas.translate(-12,-13);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6,10,12,6),const Radius.circular(3)),_fill(const Color(0xFFF59E0B)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6,10,12,6),const Radius.circular(3)),outline);
        canvas.drawRect(const Rect.fromLTWH(12,10,6,6),_fill(Colors.white));
        canvas.restore();
        break;

      case 'Ağrı Kesici':
        _shadow(canvas,const Rect.fromLTWH(4,6,16,13));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7,8,10,12),const Radius.circular(2)),_fill(Colors.white));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7,8,10,12),const Radius.circular(2)),outline);
        for(final p in [const Offset(10,11),const Offset(14,11),const Offset(10,15),const Offset(14,15)]) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:p,width:2,height:1.1),const Radius.circular(.5)),_fill(const Color(0xFF60A5FA)));
        break;

      case 'Antibiyotik':
        _shadow(canvas,const Rect.fromLTWH(4,7,16,13));
        canvas.save(); canvas.translate(12,13); canvas.rotate(.55); canvas.translate(-12,-13);
        Rect cap=const Rect.fromLTWH(6,10,6,3.8), body=const Rect.fromLTWH(12,10,6,3.8);
        canvas.drawRRect(RRect.fromRectAndRadius(cap,const Radius.circular(2)),_fill(Colors.white));
        canvas.drawRRect(RRect.fromRectAndRadius(body,const Radius.circular(2)),_fill(const Color(0xFF2563EB)));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(9,10,6,3.8),const Radius.circular(2)),_stroke(Colors.black87,.8));
        canvas.restore();
        break;

      case 'COVID-19 Aşısı':
        _shadow(canvas,const Rect.fromLTWH(6,4,12,18));
        canvas.drawRect(const Rect.fromLTWH(9,7,6,12),_glass(const Rect.fromLTWH(9,7,6,12)));
        canvas.drawRect(const Rect.fromLTWH(9,7,6,12),outline);
        canvas.drawRect(const Rect.fromLTWH(8,4.5,8,3),_metal(const Rect.fromLTWH(8,4.5,8,3)));
        canvas.drawLine(const Offset(12,7),const Offset(12,2.5),_stroke(const Color(0xFFE2E8F0),1));
        break;

      case 'Kanser İlacı':
        _shadow(canvas,const Rect.fromLTWH(5,5,14,16));
        Rect bottle=const Rect.fromLTWH(8,8,8,11);
        canvas.drawRRect(RRect.fromRectAndRadius(bottle,const Radius.circular(1.5)),_fill(Colors.white));
        canvas.drawRRect(RRect.fromRectAndRadius(bottle,const Radius.circular(1.5)),outline);
        canvas.drawRect(const Rect.fromLTWH(8.5,12,7,3),_fill(const Color(0xFFA855F7)));
        canvas.drawRect(const Rect.fromLTWH(10,5,4,3),_darkMetal(const Rect.fromLTWH(10,5,4,3)));
        break;

      // =========================
      // 11) ELEKTRONİK
      // =========================
      case 'Hesap Makinesi':
        _shadow(canvas,const Rect.fromLTWH(3,4,18,18));
        Rect calc=const Rect.fromLTWH(5,5,14,16);
        canvas.drawRRect(RRect.fromRectAndRadius(calc,const Radius.circular(2)),_darkMetal(calc));
        canvas.drawRRect(RRect.fromRectAndRadius(calc,const Radius.circular(2)),outline);
        canvas.drawRect(const Rect.fromLTWH(7,7,10,4),_fill(const Color(0xFFDCFCE7)));
        for(int r=0;r<3;r++) for(int c=0;c<4;c++) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(7+c*2.5,12+r*2.4,1.7,1.5),const Radius.circular(.4)),_fill(const Color(0xFFE2E8F0)));
        break;

      case 'Telefon':
        _shadow(canvas,const Rect.fromLTWH(5,3,14,19));
        Rect ph=const Rect.fromLTWH(7,4,10,17);
        canvas.drawRRect(RRect.fromRectAndRadius(ph,const Radius.circular(2)),_darkMetal(ph));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7.8,5,8.4,13),const Radius.circular(1.4)),_grad(const Color(0xFF93C5FD),const Color(0xFF7C3AED),const Rect.fromLTWH(7.8,5,8.4,13)));
        canvas.drawCircle(const Offset(12,19.3),.6,_fill(Colors.white70));
        break;

      case 'Televizyon':
        _shadow(canvas,const Rect.fromLTWH(2,5,20,16));
        Rect tv=const Rect.fromLTWH(4,6,16,11);
        canvas.drawRRect(RRect.fromRectAndRadius(tv,const Radius.circular(1.5)),_darkMetal(tv));
        canvas.drawRRect(RRect.fromRectAndRadius(tv,const Radius.circular(1.5)),outline);
        canvas.drawRect(const Rect.fromLTWH(5,7,14,9),_grad(const Color(0xFF0EA5E9),const Color(0xFF1E1B4B),const Rect.fromLTWH(5,7,14,9)));
        canvas.drawLine(const Offset(10,18),const Offset(14,18),_stroke(const Color(0xFF94A3B8),1.2));
        canvas.drawLine(const Offset(12,17),const Offset(12,20),_stroke(const Color(0xFF94A3B8),1.2));
        break;

      case 'İnsansız Hava Aracı':
        _shadow(canvas,const Rect.fromLTWH(3,7,18,14));
        Path drone=Path()..moveTo(8,11)..lineTo(11,10)..lineTo(13,10)..lineTo(16,11)..lineTo(15,14)..lineTo(9,14)..close();
        canvas.drawPath(drone,_darkMetal(const Rect.fromLTWH(8,10,8,5)));canvas.drawPath(drone,outline);
        for(final p in [const Offset(5,8),const Offset(19,8),const Offset(5,18),const Offset(19,18)]) {
          canvas.drawLine(Offset(p.dx<12?p.dx+1.5:p.dx-1.5,p.dy),Offset(p.dx,p.dy),_stroke(const Color(0xFF64748B),1));
          canvas.drawCircle(p,1.7,_stroke(const Color(0xFF0F172A),.8));
        }
        break;

      case 'Kuantum PC':
        _shadow(canvas,const Rect.fromLTWH(3,4,18,18));
        Rect q=const Rect.fromLTWH(5,6,14,14);
        canvas.drawRRect(RRect.fromRectAndRadius(q,const Radius.circular(1.5)),_darkMetal(q));
        canvas.drawRRect(RRect.fromRectAndRadius(q,const Radius.circular(1.5)),outline);
        for(int i=0;i<4;i++) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(7+i*2.2,8,1.5,5),const Radius.circular(.4)),_fill(const Color(0xFF38BDF8)));
        canvas.drawLine(const Offset(7,15),const Offset(17,15),_stroke(const Color(0xFFFBBF24),.9));
        break;

      // =========================
      // 12) YAPAY ZEKA
      // =========================
      case 'Sohbet Botu':
        _shadow(canvas,const Rect.fromLTWH(4,7,16,13));
        Rect bubble=const Rect.fromLTWH(5,7,14,10);
        canvas.drawRRect(RRect.fromRectAndRadius(bubble,const Radius.circular(3)),_fill(const Color(0xFF0EA5E9)));
        canvas.drawRRect(RRect.fromRectAndRadius(bubble,const Radius.circular(3)),outline);
        canvas.drawPath(Path()..moveTo(8,17)..lineTo(7,20)..lineTo(11,17),_fill(const Color(0xFF0EA5E9)));
        for (final x in const <double>[8.5, 12, 15.5]) canvas.drawCircle(Offset(x, 12), .7, _fill(Colors.white));
        break;

      case 'Satranç Botu':
        _shadow(canvas,const Rect.fromLTWH(4,4,16,18));
        Path king=Path()..moveTo(9,20)..lineTo(15,20)..lineTo(14,16)..lineTo(16,13)..lineTo(14,11)..lineTo(14,8)..lineTo(15,8)..lineTo(15,6)..lineTo(13,6)..lineTo(13,4)..lineTo(11,4)..lineTo(11,6)..lineTo(9,6)..lineTo(9,8)..lineTo(10,8)..lineTo(10,11)..lineTo(8,13)..lineTo(10,16)..close();
        canvas.drawPath(king,_metal(const Rect.fromLTWH(8,4,8,16)));canvas.drawPath(king,outline);
        break;

      case 'Görsel Oluşturma Botu':
        _shadow(canvas,const Rect.fromLTWH(3,5,18,16));
        Rect art=const Rect.fromLTWH(5,6,14,13);
        canvas.drawRRect(RRect.fromRectAndRadius(art,const Radius.circular(2)),_fill(const Color(0xFF111827)));
        canvas.drawRRect(RRect.fromRectAndRadius(art,const Radius.circular(2)),outline);
        Path m=Path()..moveTo(6,17)..lineTo(10,12)..lineTo(13,15)..lineTo(15,11)..lineTo(18,17)..close();
        canvas.drawPath(m,_grad(const Color(0xFF38BDF8),const Color(0xFF7C3AED),const Rect.fromLTWH(6,11,12,6)));
        canvas.drawCircle(const Offset(15.5,9.2),1.3,_fill(const Color(0xFFFBBF24)));
        break;

      case 'Kodlama Botu':
        _shadow(canvas,const Rect.fromLTWH(3,7,18,14));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5,8,14,10),const Radius.circular(2)),_darkMetal(const Rect.fromLTWH(5,8,14,10)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5,8,14,10),const Radius.circular(2)),outline);
        final codePaint = TextPainter(
          text: const TextSpan(text: '</>', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 6.5, fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr,
        )..layout();
        codePaint.paint(canvas, const Offset(8.7, 10.6));
        break;

      case 'Humanoid Robot':
        _shadow(canvas,const Rect.fromLTWH(5,3,14,19));
        canvas.drawCircle(const Offset(12,6),3,_metal(Rect.fromCircle(center:Offset(12,6),radius:3)));
        canvas.drawCircle(const Offset(11,6),.55,_fill(const Color(0xFF38BDF8)));
        canvas.drawCircle(const Offset(13,6),.55,_fill(const Color(0xFF38BDF8)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8,9,8,8),const Radius.circular(1.7)),_darkMetal(const Rect.fromLTWH(8,9,8,8)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8,9,8,8),const Radius.circular(1.7)),outline);
        canvas.drawLine(const Offset(8,11),const Offset(5.5,14),outline);canvas.drawLine(const Offset(16,11),const Offset(18.5,14),outline);
        canvas.drawLine(const Offset(10,17),const Offset(9,21),outline);canvas.drawLine(const Offset(14,17),const Offset(15,21),outline);
        break;

      // =========================
      // 13) ENERJİ
      // =========================
      case 'Güneş Paneli':
        _shadow(canvas,const Rect.fromLTWH(3,6,18,14));
        Rect panel=const Rect.fromLTWH(5,6,14,9);
        canvas.drawRect(panel,_grad(const Color(0xFF2563EB),const Color(0xFF0C4A6E),panel));
        canvas.drawRect(panel,outline);
        for(int i=1;i<4;i++) canvas.drawLine(Offset(5+i*3.5,6),Offset(5+i*3.5,15),_stroke(const Color(0xFF93C5FD),.45));
        for(int i=1;i<3;i++) canvas.drawLine(Offset(5,6+i*3),Offset(19,6+i*3),_stroke(const Color(0xFF93C5FD),.45));
        canvas.drawLine(const Offset(12,15),const Offset(12,20),_stroke(const Color(0xFF64748B),1.1));
        break;

      case 'Rüzgar Türbini':
        _shadow(canvas,const Rect.fromLTWH(4,4,16,18));
        canvas.drawLine(const Offset(12,8),const Offset(12,20),_stroke(const Color(0xFFE2E8F0),1.3));
        canvas.drawCircle(const Offset(12,8),1.2,_fill(const Color(0xFFE2E8F0)));
        for(int i=0;i<3;i++){double a=i*2*math.pi/3; canvas.drawLine(const Offset(12,8),Offset(12+5*math.cos(a),8+5*math.sin(a)),_stroke(const Color(0xFFBAE6FD),1.2));}
        break;

      case 'Nükleer Santral':
        _shadow(canvas,const Rect.fromLTWH(3,7,18,14));
        Path tower=Path()..moveTo(7,20)..quadraticBezierTo(8,14,9,9)..quadraticBezierTo(12,7,15,9)..quadraticBezierTo(16,14,17,20)..close();
        canvas.drawPath(tower,_metal(const Rect.fromLTWH(7,8,10,12)));canvas.drawPath(tower,outline);
        canvas.drawCircle(const Offset(12,12),1.3,_fill(const Color(0xFFFBBF24)));
        break;

      case 'Parçacık Hızlandırıcı':
        _shadow(canvas,const Rect.fromLTWH(3,5,18,16));
        canvas.drawOval(const Rect.fromLTWH(4,7,16,10),_stroke(const Color(0xFF0EA5E9),2));
        canvas.drawOval(const Rect.fromLTWH(7,9,10,6),_stroke(const Color(0xFFFBBF24),1));
        canvas.drawCircle(const Offset(12,12),1.1,_fill(const Color(0xFF38BDF8)));
        break;

      case 'Füzyon Çekirdeği':
        _shadow(canvas,const Rect.fromLTWH(4,5,16,17));
        canvas.drawCircle(const Offset(12,13),5,_fill(const Color(0xFF0F172A)));
        canvas.drawCircle(const Offset(12,13),2,_fill(const Color(0xFFF59E0B)));
        for(int i=0;i<3;i++){
          canvas.save();
          canvas.translate(12,13);
          canvas.rotate(i*math.pi/3);
          canvas.translate(-12,-13);
          canvas.drawOval(Rect.fromCenter(center:const Offset(12,13),width:10-i*1.8,height:4+i*1.2),_stroke(const Color(0xFF38BDF8),1));
          canvas.restore();
        }
        break;

      // =========================
      // 14) BİYOTEKNOLOJİ
      // =========================
      case 'Kök Hücre':
        _shadow(canvas,const Rect.fromLTWH(4,5,16,17));
        canvas.drawCircle(const Offset(12,13),5,_fill(const Color(0xFFDBEAFE)));canvas.drawCircle(const Offset(12,13),5,outline);
        canvas.drawCircle(const Offset(10.5,11.5),1.2,_fill(const Color(0xFF60A5FA)));
        canvas.drawCircle(const Offset(13.7,12.8),1.5,_fill(const Color(0xFF34D399)));
        canvas.drawCircle(const Offset(11.8,15.2),1.1,_fill(const Color(0xFFA78BFA)));
        break;

      case '3D Biyo-Yazıcı':
        _shadow(canvas,const Rect.fromLTWH(3,4,18,18));
        Rect frame=const Rect.fromLTWH(5,5,14,15);
        canvas.drawRect(frame,_metal(frame));canvas.drawRect(frame,outline);
        canvas.drawLine(const Offset(12,6),const Offset(12,14),_stroke(const Color(0xFF38BDF8),1.1));
        canvas.drawLine(const Offset(8,15),const Offset(16,15),_stroke(const Color(0xFF94A3B8),1.1));
        canvas.drawCircle(const Offset(12,15.5),1.4,_fill(const Color(0xFF34D399)));
        break;

      case 'Biyonik Organ':
        _shadow(canvas,const Rect.fromLTWH(4,4,16,18));
        Path heart=Path()..moveTo(12,19)..cubicTo(4,14,6,7,10,9)..cubicTo(12,4,15,7,14,9)..cubicTo(18,7,20,14,12,19)..close();
        canvas.drawPath(heart,_grad(const Color(0xFFFCA5A5),const Color(0xFFBE123C),const Rect.fromLTWH(6,6,12,13)));canvas.drawPath(heart,outline);
        canvas.drawLine(const Offset(12,10),const Offset(12,17),_stroke(const Color(0xFF93C5FD),.9));
        break;

      case 'Biyoçip':
        _shadow(canvas,const Rect.fromLTWH(4,4,16,17));
        Rect chip=const Rect.fromLTWH(6,6,12,12);
        canvas.drawRRect(RRect.fromRectAndRadius(chip,const Radius.circular(1.2)),_gold(chip));canvas.drawRRect(RRect.fromRectAndRadius(chip,const Radius.circular(1.2)),outline);
        canvas.drawCircle(const Offset(12,12),2,_fill(const Color(0xFF0F172A)));
        for(int i=0;i<4;i++){canvas.drawLine(Offset(6,8+i*2.7),Offset(4.5,8+i*2.7),outline);canvas.drawLine(Offset(18,8+i*2.7),Offset(19.5,8+i*2.7),outline);}
        break;

      case 'Klon Canlı':
        _shadow(canvas,const Rect.fromLTWH(4,4,16,18));
        canvas.drawOval(const Rect.fromLTWH(6,5,12,15),_fill(const Color(0xFFECFCCB)));canvas.drawOval(const Rect.fromLTWH(6,5,12,15),outline);
        canvas.drawOval(const Rect.fromLTWH(10,6.5,2,12),_stroke(const Color(0xFF65A30D),1));
        canvas.drawOval(const Rect.fromLTWH(12,6.5,2,12),_stroke(const Color(0xFF22C55E),1));
        break;

      // =========================
      // 15) UZAY
      // =========================
      case 'Roket Motoru':
        _shadow(canvas,const Rect.fromLTWH(4,4,16,18));
        Path motor=Path()..moveTo(8,6)..lineTo(16,6)..lineTo(15,11)..lineTo(17,16)..lineTo(7,16)..lineTo(9,11)..close();
        canvas.drawPath(motor,_metal(const Rect.fromLTWH(7,6,10,10)));canvas.drawPath(motor,outline);
        Path flame=Path()..moveTo(9,16)..quadraticBezierTo(12,19,11,22)..quadraticBezierTo(15,19,15,16)..close();
        canvas.drawPath(flame,_grad(const Color(0xFFFDE047),const Color(0xFFEA580C),const Rect.fromLTWH(9,16,6,6)));
        break;

      case 'Uydu':
        _shadow(canvas,const Rect.fromLTWH(2,7,20,14));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8,9,8,7),const Radius.circular(1)),_metal(const Rect.fromLTWH(8,9,8,7)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8,9,8,7),const Radius.circular(1)),outline);
        canvas.drawRect(const Rect.fromLTWH(3,8,5,9),_glass(const Rect.fromLTWH(3,8,5,9)));
        canvas.drawRect(const Rect.fromLTWH(16,8,5,9),_glass(const Rect.fromLTWH(16,8,5,9)));
        break;

      case 'Uzay Mekiği':
        _shadow(canvas,const Rect.fromLTWH(2,5,20,16));
        Path shuttle=Path()..moveTo(12,4)..lineTo(17,11)..lineTo(15,17)..lineTo(12,20)..lineTo(9,17)..lineTo(7,11)..close();
        canvas.drawPath(shuttle,_metal(const Rect.fromLTWH(7,4,10,16)));canvas.drawPath(shuttle,outline);
        canvas.drawLine(const Offset(10,9),const Offset(14,9),_stroke(const Color(0xFF0EA5E9),.9));
        break;

      case 'Ay İniş Aracı':
        _shadow(canvas,const Rect.fromLTWH(3,8,18,13));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8,8,8,7),const Radius.circular(1)),_gold(const Rect.fromLTWH(8,8,8,7)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8,8,8,7),const Radius.circular(1)),outline);
        for(final x in [7.0,17.0]){canvas.drawLine(Offset(x,15),Offset(x-2,20),outline);canvas.drawLine(Offset(x,15),Offset(x+2,20),outline);}
        canvas.drawCircle(const Offset(12,11),1,_fill(const Color(0xFF0F172A)));
        break;

      case 'Yıldız Gemisi':
        _shadow(canvas,const Rect.fromLTWH(2,5,20,16));
        Path ship=Path()..moveTo(3,15)..lineTo(12,4)..lineTo(21,15)..lineTo(17,17)..lineTo(7,17)..close();
        canvas.drawPath(ship,_grad(const Color(0xFFE2E8F0),const Color(0xFF334155),const Rect.fromLTWH(3,4,18,13)));canvas.drawPath(ship,outline);
        canvas.drawCircle(const Offset(12,12),2,_fill(const Color(0xFF38BDF8)));
        canvas.drawPath(Path()..moveTo(7,17)..lineTo(9,21)..lineTo(12,17)..lineTo(15,21)..lineTo(17,17)..close(),_grad(const Color(0xFFFDE047),const Color(0xFFEA580C),const Rect.fromLTWH(7,17,10,4)));
        break;

      default:
        _card(canvas, const Rect.fromLTWH(5,5,14,14));
        canvas.drawCircle(const Offset(12,12),4,_fill(const Color(0xFF38BDF8)));
        canvas.drawCircle(const Offset(12,12),4,outline);
        break;
    }

    if (muted) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProductVectorPainter oldDelegate) =>
      oldDelegate.name != name || oldDelegate.tint != tint;
}

class FactoryInsideModal extends StatefulWidget {
  final String factoryId; 
  final String Function(double) formatNum;
  const FactoryInsideModal({super.key, required this.factoryId, required this.formatNum});
  @override State<FactoryInsideModal> createState() => _FactoryInsideModalState();
}

class _FactoryInsideModalState extends State<FactoryInsideModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override 
  void initState() { 
    super.initState(); 
    _tabController = TabController(length: 2, vsync: this); 
  }
  
  @override 
  void dispose() { 
    _tabController.dispose(); 
    super.dispose(); 
  }

  @override 
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final currentFac = gameState.factories.firstWhere((f) => f.id == widget.factoryId);
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.86, 
          decoration: BoxDecoration(
            color: _uiSurface(context), 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.black, width: 4.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -6))],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 56, height: 8,
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.neonCyan, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)),
                      child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: HeavyIconPainter(type: 'factory', color: Colors.white))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              currentFac.name.toUpperCase(), 
                              style: AppTheme.titleStyle(fontSize: 20).copyWith(color: Colors.black, shadows: []),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Aşama ${currentFac.currentStage + 1}  •  Tesis: ${currentFac.totalLevel}/300', 
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: AnimatedMoneyText(money: gameState.money, formatNum: widget.formatNum, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(color: _uiSoftSurface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.black,
                    unselectedLabelColor: AppColors.textMuted,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 18, height: 18, child: CustomPaint(painter: HeavyIconPainter(type: 'touch', color: Colors.black))), const SizedBox(width: 8), const Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text("ÜRETİM BANDI")))])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 18, height: 18, child: CustomPaint(painter: HeavyIconPainter(type: 'upgrade', color: Colors.black))), const SizedBox(width: 8), const Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text("TESİS GELİŞTİRME")))])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: currentFac.products.length, 
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final prod = currentFac.products[index];
                        if (prod.level == 0) return const SizedBox.shrink(); 
                        return ProductionLineWidget(
                          key: ValueKey('prodline_${currentFac.id}_${prod.name}'),
                          product: prod, 
                          multiplier: gameState.manualProductionMultiplier(currentFac.id, index),
                          formatNum: widget.formatNum, 
                          onProduceComplete: () => gameState.completeManualProduction(currentFac.id, index),
                        );
                      },
                    ),

                    ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: currentFac.products.length, 
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final prod = currentFac.products[index];
                        const unlockLevels = <int>[0, 30, 60, 90, 120];
                        bool canUnlock = prod.level > 0 || currentFac.totalLevel >= unlockLevels[index];

                        if (!canUnlock) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: _uiSoftSurface(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 3)),
                            child: Row(
                              children: [
                                SizedBox.square(
                                  dimension: 52,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(color: _uiSurface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 2)),
                                    child: Stack(
                                      clipBehavior: Clip.hardEdge,
                                      children: [
                                        Center(child: ProductSvgIcon(name: prod.name, size: 28, color: AppColors.textMuted)),
                                        Positioned(
                                          right: 3,
                                          bottom: 3,
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                                            child: const Icon(Icons.lock_rounded, size: 11, color: Colors.black),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(prod.name, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 15)),
                                      const SizedBox(height: 6),
                                      FittedBox(fit: BoxFit.scaleDown, child: Text('Tesisi toplam Seviye ${unlockLevels[index]} yapın', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        double cost = gameState.productUpgradeCost(currentFac.id, index) ?? prod.upgradeCost;
                        bool isMax = prod.level >= 60;
                        bool canAfford = gameState.money >= cost && !isMax;
                        double progressRatio = (prod.level / 60.0).clamp(0.0, 1.0);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _uiSurface(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: canAfford ? AppColors.neonCyan : Colors.black, width: 3.0),
                            boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                      color: canAfford ? const Color(0xFFE0F2FE) : _uiSoftSurface(context),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: canAfford ? AppColors.neonCyan : Colors.black, width: 3),
                                    ),
                                    child: Center(
                                      child: ProductSvgIcon(
                                        name: prod.name,
                                        size: 28,
                                        color: canAfford ? Colors.black : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(prod.name, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8, runSpacing: 6,
                                          children: [
                                            Text('Lvl ${prod.level}/60', style: TextStyle(color: isMax ? AppColors.profit : Colors.black, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)),
                                              child: Text('+\$${widget.formatNum(prod.passiveIncome)}/s', style: const TextStyle(color: AppColors.profit, fontSize: 11, fontWeight: FontWeight.w900)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  HeavyTycoonButton(
                                    width: 90, height: 52,
                                    color: isMax ? _uiMutedSurface(context) : (canAfford ? AppColors.gold : _uiSoftSurface(context)),
                                    shadowColor: isMax ? Colors.grey.shade400 : (canAfford ? Colors.orange.shade700 : Colors.grey.shade400),
                                    onPressed: isMax || !canAfford 
                                        ? null 
                                        : () {
                                            HapticFeedback.lightImpact();
                                            AudioService.instance.playSfx('cash.mp3');
                                            gameState.upgradeProduct(currentFac.id, index);
                                          },
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(isMax ? 'MAKS' : 'GELİŞTİR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: isMax || !canAfford ? Colors.grey.shade600 : Colors.black)),
                                        if (!isMax) ...[
                                          const SizedBox(height: 4),
                                          FittedBox(fit: BoxFit.scaleDown, child: Text('\$${widget.formatNum(cost)}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono', color: canAfford ? Colors.black : Colors.grey.shade600))),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(8)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progressRatio,
                                    minHeight: 10,
                                    backgroundColor: _uiSoftSurface(context),
                                    valueColor: AlwaysStoppedAnimation<Color>(isMax ? AppColors.profit : (canAfford ? AppColors.neonCyan : Colors.grey.shade400)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProductionLineWidget extends StatefulWidget {
  final FactoryProduct product; 
  final double multiplier; 
  final String Function(double) formatNum; 
  final VoidCallback onProduceComplete;
  
  const ProductionLineWidget({
    super.key, 
    required this.product, 
    required this.multiplier, 
    required this.formatNum, 
    required this.onProduceComplete,
  });

  @override 
  State<ProductionLineWidget> createState() => _ProductionLineWidgetState();
}

class _ProductionLineWidgetState extends State<ProductionLineWidget> with TickerProviderStateMixin {
  final List<int> _tokenIds = [];
  final List<_FloatingTextItem> _floatingTexts = [];
  int _counter = 0;
  int _packingTrigger = 0;

  late final AnimationController _beltAnimController;

  @override
  void initState() {
    super.initState();
    _beltAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _beltAnimController.dispose();
    super.dispose();
  }

  void _triggerProduction() {
    final int currentId = _counter++;
    final double rewardAmount = widget.product.manualIncome * widget.multiplier;
    final double randomOffsetX = (math.Random().nextDouble() * 30) - 15;
    widget.onProduceComplete();
    try { AudioService.instance.playSfx('cash.mp3'); } catch (_) {}

    setState(() {
      _tokenIds.add(currentId);
      _floatingTexts.add(_FloatingTextItem(key: UniqueKey(), id: currentId, text: '+\$${widget.formatNum(rewardAmount)}', offsetX: randomOffsetX));
      if (_tokenIds.length > 8) _tokenIds.removeAt(0);
      if (_floatingTexts.length > 8) _floatingTexts.removeAt(0);
    });
  }

  void _onTokenReachedEnd(int id) {
    if (!mounted) return;
    setState(() {
      _tokenIds.remove(id);
      _packingTrigger++;
    });
  }

  void _onTextAnimationComplete(int id) {
    if (!mounted) return;
    setState(() { _floatingTexts.removeWhere((item) => item.id == id); });
  }

  @override 
  Widget build(BuildContext context) {
    final double incomePerClick = widget.product.manualIncome * widget.multiplier;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _uiSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 4.0),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 0, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)),
                child: Text('Lvl ${widget.product.level}', style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.trending_up_rounded, color: AppColors.profit, size: 18),
                      const SizedBox(width: 6),
                      Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('+\$${widget.formatNum(incomePerClick)}', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'SpaceMono')))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final double btnWidth = constraints.maxWidth < 340 ? 90.0 : 100.0;
              final double depotWidth = constraints.maxWidth < 340 ? 52.0 : 60.0;

              return SizedBox(
                height: 70,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 64,
                      decoration: BoxDecoration(color: _uiMutedSurface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3.0)),
                      child: Row(
                        children: [
                          SizedBox(width: btnWidth),
                          Expanded(
                            child: ClipRect(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: AnimatedBuilder(
                                      animation: _beltAnimController,
                                      builder: (context, child) {
                                        return CustomPaint(painter: ContinuousConveyorTrackPainter(progress: _beltAnimController.value));
                                      },
                                    ),
                                  ),
                                  ..._tokenIds.map((id) => SelfDismissingToken(
                                    key: ValueKey('token_$id'), id: id, productName: widget.product.name, onComplete: _onTokenReachedEnd,
                                  )),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: depotWidth,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: _uiSurface(context),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                              border: const Border(left: BorderSide(color: Colors.black, width: 3.0)),
                            ),
                            child: PackingTransferStation(
                              productName: widget.product.name,
                              trigger: _packingTrigger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: -2, top: -2, bottom: 4, width: btnWidth + 4,
                      child: PreciseIndustrialButton(
                        width: btnWidth + 4, height: 68, onTap: _triggerProduction,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CustomPaint(painter: HeavyIconPainter(type: 'touch', color: Colors.black))),
                            const SizedBox(width: 8),
                            const Text('ÜRET', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          ],
                        ),
                      ),
                    ),
                    ..._floatingTexts.map((fItem) => Positioned(
                      key: fItem.key, left: (btnWidth / 2 - 24) + fItem.offsetX, bottom: 50,
                      child: SelfDismissingIncomeText(id: fItem.id, text: fItem.text, onComplete: _onTextAnimationComplete),
                    )),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PackingTransferStation extends StatefulWidget {
  final String productName;
  final int trigger;

  const PackingTransferStation({
    super.key,
    required this.productName,
    required this.trigger,
  });

  @override
  State<PackingTransferStation> createState() => _PackingTransferStationState();
}

class _PackingTransferStationState extends State<PackingTransferStation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _playing = false;
  bool _pendingReplay = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
  }

  @override
  void didUpdateWidget(covariant PackingTransferStation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger > oldWidget.trigger) {
      // Collapse a burst of arrivals into at most one additional cycle. This
      // keeps the station alive while the player is producing rapidly without
      // leaving a long queue of boxes running after production has stopped.
      if (_playing) {
        _pendingReplay = true;
      } else {
        _playCycle();
      }
    }
  }

  void _playCycle() {
    if (!mounted || _playing) return;
    setState(() => _playing = true);
    _controller.forward(from: 0.0).whenComplete(() {
      if (!mounted) return;

      final bool replayLatest = _pendingReplay;
      _pendingReplay = false;
      setState(() => _playing = false);

      if (replayLatest) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _playCycle();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(double value, double start, double end) {
    return ((value - start) / (end - start)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_playing) {
      return Center(
        child: SizedBox(
          width: 42,
          height: 42,
          child: CustomPaint(
            painter: _PackingBoxPainter(closeProgress: 0.0),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final drop = Curves.easeIn.transform(_phase(t, 0.00, 0.30));
        final close = Curves.easeInOut.transform(_phase(t, 0.24, 0.58));
        final transfer = Curves.easeIn.transform(_phase(t, 0.58, 1.00));
        final fade = 1.0 - Curves.easeIn.transform(_phase(t, 0.82, 1.00));

        return Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(transfer * 20.0, 0),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 26,
                  child: SizedBox(
                    width: 44,
                    height: 36,
                    child: CustomPaint(
                      painter: _PackingBoxPainter(closeProgress: close),
                    ),
                  ),
                ),
                Positioned(
                  top: ui.lerpDouble(2.0, 27.0, drop)!,
                  child: Opacity(
                    opacity: (1.0 - close).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: ui.lerpDouble(1.0, 0.70, drop)!,
                      child: DepthProductIcon(
                        name: widget.productName,
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PackingBoxPainter extends CustomPainter {
  final double closeProgress;

  const _PackingBoxPainter({required this.closeProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;
    final body = Paint()
      ..color = const Color(0xFFD99A4E)
      ..style = PaintingStyle.fill;
    final flap = Paint()
      ..color = const Color(0xFFF2BD6C)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final top = h * 0.34;
    final bottom = h * 0.94;
    final left = w * 0.10;
    final right = w * 0.90;
    final mid = w * 0.50;

    final boxRect = Rect.fromLTRB(left, top, right, bottom);
    canvas.drawRect(boxRect, body);
    canvas.drawRect(boxRect, outline);
    canvas.drawLine(Offset(mid, top), Offset(mid, bottom), outline);

    final openLift = h * 0.23 * (1.0 - closeProgress);
    final closedInset = h * 0.12 * closeProgress;

    final leftFlap = Path()
      ..moveTo(left, top)
      ..lineTo(mid, top)
      ..lineTo(mid - w * 0.08, top - openLift - closedInset)
      ..lineTo(left - w * 0.06 * (1.0 - closeProgress), top - openLift * 0.55 - closedInset)
      ..close();
    final rightFlap = Path()
      ..moveTo(mid, top)
      ..lineTo(right, top)
      ..lineTo(right + w * 0.06 * (1.0 - closeProgress), top - openLift * 0.55 - closedInset)
      ..lineTo(mid + w * 0.08, top - openLift - closedInset)
      ..close();

    canvas.drawPath(leftFlap, flap);
    canvas.drawPath(leftFlap, outline);
    canvas.drawPath(rightFlap, flap);
    canvas.drawPath(rightFlap, outline);

    if (closeProgress > 0.70) {
      final tapeOpacity = ((closeProgress - 0.70) / 0.30).clamp(0.0, 1.0);
      final tape = Paint()
        ..color = const Color(0xFFFDE68A).withValues(alpha: tapeOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(mid, top - h * 0.06), width: w * 0.13, height: h * 0.14),
        tape,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PackingBoxPainter oldDelegate) => oldDelegate.closeProgress != closeProgress;
}

class _FloatingTextItem { final Key key; final int id; final String text; final double offsetX; _FloatingTextItem({required this.key, required this.id, required this.text, required this.offsetX}); }

class ContinuousConveyorTrackPainter extends CustomPainter {
  final double progress;
  ContinuousConveyorTrackPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint railPaint = Paint()..color = Colors.black..strokeWidth = 3.0..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 10), Offset(size.width, 10), railPaint);
    canvas.drawLine(Offset(0, size.height - 10), Offset(size.width, size.height - 10), railPaint);

    final Paint rollerShadow = Paint()..color = Colors.black26..strokeWidth = 6.0..strokeCap = StrokeCap.round;
    final Paint rollerPaint = Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 4.0..strokeCap = StrokeCap.round;
    const double step = 24.0;
    final double offset = progress * step;

    for (double x = -step + offset; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x + 2, 12), Offset(x + 2, size.height - 12), rollerShadow);
      canvas.drawLine(Offset(x, 12), Offset(x, size.height - 12), rollerPaint);
    }
  }
  @override bool shouldRepaint(covariant ContinuousConveyorTrackPainter oldDelegate) => oldDelegate.progress != progress;
}


class DepthProductIcon extends StatelessWidget {
  final String name;
  final double size;

  const DepthProductIcon({
    super.key,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final double depthOffset = math.max(1.8, size * 0.075);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(depthOffset, depthOffset),
            child: Opacity(
              opacity: 0.72,
              child: ProductSvgIcon(
                name: name,
                size: size,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          ProductSvgIcon(
            name: name,
            size: size,
            color: Colors.black,
          ),
        ],
      ),
    );
  }
}

class SelfDismissingToken extends StatefulWidget {
  final int id;
  final String productName;
  final void Function(int id) onComplete;

  const SelfDismissingToken({super.key, required this.id, required this.productName, required this.onComplete});

  @override
  State<SelfDismissingToken> createState() => _SelfDismissingTokenState();
}

class _SelfDismissingTokenState extends State<SelfDismissingToken> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final double _rotation;
  late final double _verticalOffset;
  late final double _scale;

  @override
  void initState() {
    super.initState();
    final random = math.Random(widget.id * 7919 + widget.productName.hashCode);
    _rotation = random.nextDouble() * math.pi * 2.0; // Full 0-360 degree rotation
    _verticalOffset = (random.nextDouble() * 8.0) - 4.0;
    _scale = 0.92 + (random.nextDouble() * 0.16);

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    _slideAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onComplete(widget.id);
        });
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Align(
          alignment: Alignment(_slideAnimation.value, 0.0),
          child: Transform.translate(
            offset: Offset(0, _verticalOffset),
            child: Transform.rotate(
              angle: _rotation,
              child: Transform.scale(
                scale: _scale,
                child: DepthProductIcon(
                  name: widget.productName,
                  size: 30,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SelfDismissingIncomeText extends StatefulWidget {
  final int id; final String text; final void Function(int id) onComplete;
  const SelfDismissingIncomeText({super.key, required this.id, required this.text, required this.onComplete});
  @override State<SelfDismissingIncomeText> createState() => _SelfDismissingIncomeTextState();
}

class _SelfDismissingIncomeTextState extends State<SelfDismissingIncomeText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller; late final Animation<double> _fadeAnimation; late final Animation<Offset> _slideAnimation; late final Animation<double> _scaleAnimation;
  @override void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -1.9)).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scaleAnimation = TweenSequence<double>([TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)), weight: 35), TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 65)]).animate(_controller);
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)));
    _controller.addStatusListener((status) { if (status == AnimationStatus.completed) { WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) widget.onComplete(widget.id); }); } });
    _controller.forward();
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return SlideTransition(position: _slideAnimation, child: FadeTransition(opacity: _fadeAnimation, child: ScaleTransition(scale: _scaleAnimation, child: Text(widget.text, style: const TextStyle(color: Color(0xFF22C55E), fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono', shadows: [Shadow(color: Colors.black, blurRadius: 0, offset: Offset(1, 2))])))));
  }
}

class PreciseIndustrialButton extends StatefulWidget {
  final VoidCallback onTap; final Widget child; final double width; final double height;
  const PreciseIndustrialButton({super.key, required this.onTap, required this.child, required this.width, required this.height});
  @override State<PreciseIndustrialButton> createState() => _PreciseIndustrialButtonState();
}

class _PreciseIndustrialButtonState extends State<PreciseIndustrialButton> {
  bool _isPressed = false;
  @override Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () { HapticFeedback.lightImpact(); setState(() => _isPressed = false); widget.onTap(); },
      child: SizedBox(
        width: widget.width, height: widget.height,
        child: Stack(
          children: [
            Positioned(bottom: 0, left: 0, right: 0, top: 6, child: Container(decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3.0)))),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 30),
              bottom: _isPressed ? 0 : 6, left: 0, right: 0, top: _isPressed ? 6 : 0,
              child: Container(decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3.0)), child: Center(child: widget.child)),
            ),
          ],
        ),
      ),
    );
  }
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
        child.updateData(_currentState!.factories.firstWhere((f) => f.id == child.factoryId)); 
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
    final List<Vector2> plotPositions = [Vector2(340, 420), Vector2(330, 520), Vector2(445, 1290), Vector2(320, 220), Vector2(800, 1450), Vector2(310, 130), Vector2(680, 250), Vector2(60, 1080), Vector2(50, 1180), Vector2(60, 1000), Vector2(330, 880), Vector2(820, 1990), Vector2(800, 1040), Vector2(920, 1550), Vector2(1080, 1680)];
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
  
  FactoryPlotComponent({required this.factoryId, required Vector2 position, required this.onTap}) : super(position: position, size: Vector2(250, 250), anchor: Anchor.center) {
    priority = 30;
  }
  
  void updateData(FactoryData data) { _data = data; } 
  
  @override void onTapUp(TapUpEvent event) { onTap(factoryId); }
  
  @override void render(Canvas canvas) {
    final currentData = _data; 
    
    if (currentData == null) {
      return; 
    }
    
    if (!currentData.isUnlocked) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, size.x-20, size.y-20), const Radius.circular(20)), Paint()..color = Colors.white.withValues(alpha: 0.85)..style=PaintingStyle.fill);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, size.x-20, size.y-20), const Radius.circular(20)), Paint()..color = Colors.black..style=PaintingStyle.stroke..strokeWidth=5);
      final iconPainter = TextPainter(textDirection: TextDirection.ltr)..text = TextSpan(text: String.fromCharCode(Icons.lock_rounded.codePoint), style: TextStyle(fontSize: 40, fontFamily: Icons.lock_rounded.fontFamily, color: Colors.black))..layout(); 
      iconPainter.paint(canvas, Offset(size.x/2 - 20, size.y/2 - 20));
    } else {
      // The unlocked plot is rendered by the dedicated vector-art system.
      // FactoryData.currentStage is already the game's 3-step progression
      // (0 = beginning, 1 = middle, 2 = max), so the map visual stays in
      // sync with the existing upgrade logic without a second threshold system.
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
