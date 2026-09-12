// lib/screens/map_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../providers/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/achievements.dart'; 
import '../widgets/prestige_dialog.dart';
import '../widgets/tasks.dart'; 
import '../widgets/wheel.dart';
import '../services/admob_service.dart';
import '../services/audio_service.dart'; 
import 'main_menu_screen.dart';
import 'research_screen.dart';
import 'stock_screen.dart';
import 'settings_screen.dart';
import 'office_screen.dart';

const Color themeOceanBlue = Color(0xFF22CECE);
const Color themeIslandGreen = Color(0xFFA5C05B);
const Color themeSandYellow = Color(0xFFF3D78F);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override 
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _holdingName = 'Holding';
  int _holdingLogoIndex = 0; 
  late final HoldingTycoonGame _game;
  
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
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppColors.border, width: 3.0),
                    boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 16)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.border, width: 2)),
                        child: SizedBox(width: 36, height: 36, child: CustomPaint(painter: HeavyIconPainter(type: 'boost', color: AppColors.gold))),
                      ),
                      const SizedBox(height: 16),
                      Text('SEKTÖR SEÇİMİ', textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 20).copyWith(color: AppColors.textPrimary, letterSpacing: 2.0)),
                      const SizedBox(height: 8),
                      const Text('Holdinginizin faaliyetlerine başlayacağı ilk sanayi kolunu seçin. Seçtiğiniz ilk tesis size bedelsiz olarak tahsis edilecektir.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 32),
                      HeavyTycoonButton(
                        width: double.infinity,
                        height: 55,
                        color: AppColors.gold,
                        shadowColor: const Color(0xFF8B6B32),
                        onPressed: () {
                          AudioService.instance.playSfx('click.mp3');
                          context.read<GameState>().applyStarterSector(selectedId);
                          Navigator.pop(context);
                        },
                        child: const Text('SEKTÖRE GİRİŞ YAP', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
                      ),
                    ],
                  ),
                ),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSel ? AppColors.gold : AppColors.background,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: isSel ? AppColors.darkBrown : AppColors.border, width: 2.0),
            boxShadow: isSel ? const [BoxShadow(color: Colors.black54, offset: Offset(0, 4))] : [],
          ),
          child: Column(
            children: [
              SizedBox(width: 28, height: 28, child: CustomPaint(painter: HeavyIconPainter(type: iconType, color: isSel ? AppColors.darkBrown : AppColors.textMuted))),
              const SizedBox(height: 8),
              Text(name, style: TextStyle(color: isSel ? AppColors.darkBrown : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadHoldingData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { 
      _holdingName = prefs.getString('holding_name') ?? 'Holding'; 
      _holdingLogoIndex = prefs.getInt('holding_logo_index') ?? 0; 
    });
  }

  String _formatNum(double value) {
    if (value >= 1e33) return '${(value / 1e33).toStringAsFixed(2)} Dc';
    if (value >= 1e30) return '${(value / 1e30).toStringAsFixed(2)} No';
    if (value >= 1e27) return '${(value / 1e27).toStringAsFixed(2)} Oc';
    if (value >= 1e24) return '${(value / 1e24).toStringAsFixed(2)} Sp';
    if (value >= 1e21) return '${(value / 1e21).toStringAsFixed(2)} Sx';
    if (value >= 1e18) return '${(value / 1e18).toStringAsFixed(2)} Qi';
    if (value >= 1e15) return '${(value / 1e15).toStringAsFixed(2)} Qa';
    if (value >= 1e12) return '${(value / 1e12).toStringAsFixed(2)} T';
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(2)} B';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(2)} M';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(1)} K';
    return value.toStringAsFixed(0);
  }

  void _showOfflineEarningsDialog(GameState state) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface, 
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
        title: Text('GECE MESAİSİ', textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 20).copyWith(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.border, width: 2)), child: SizedBox(width: 40, height: 40, child: CustomPaint(painter: HeavyIconPainter(type: 'chart', color: AppColors.gold)))), 
            const SizedBox(height: 16),
            const Text('Tesisleriniz siz yokken üretime devam etti.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.black, border: Border.all(color: AppColors.profit, width: 2), borderRadius: BorderRadius.zero), child: AnimatedMoneyText(money: state.offlineEarningsToClaim, formatNum: _formatNum, style: const TextStyle(color: AppColors.profit, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          HeavyTycoonButton(
            height: 45, color: AppColors.surfaceElevated, shadowColor: const Color(0xFF14161C), padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: () { 
              AudioService.instance.playSfx('cash.mp3');
              state.claimOfflineEarnings(false); 
              Navigator.pop(context); 
            }, 
            child: const Text('NORMAL TAHSİL', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 11))
          ),
          HeavyTycoonButton(
            height: 45, color: AppColors.gold, shadowColor: const Color(0xFF8B6B32), padding: const EdgeInsets.symmetric(horizontal: 12),
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
            child: const Text('REKLAMLA 2X AL', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 11)),
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
        backgroundColor: AppColors.surface, 
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.gold, width: 3)),
        title: Text('FİNANSMAN', style: AppTheme.titleStyle(fontSize: 20).copyWith(color: AppColors.gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sahada harici finansman bulundu:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.black, border: Border.all(color: AppColors.gold, width: 2), borderRadius: BorderRadius.zero), child: Text('\$${_formatNum(reward)}', style: const TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          HeavyTycoonButton(
            height: 45, color: AppColors.surfaceElevated, shadowColor: const Color(0xFF14161C), padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: () { 
              AudioService.instance.playSfx('cash.mp3');
              state.claimBagReward(false, reward); 
              Navigator.pop(c); 
            }, 
            child: const Text('TAHSİL ET', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 11))
          ),
          HeavyTycoonButton(
            height: 45, color: AppColors.gold, shadowColor: const Color(0xFF8B6B32), padding: const EdgeInsets.symmetric(horizontal: 12),
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
            child: const Text('3X KATLA', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 11)),
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
        double finalPrice = fac.price;
        finalPrice *= (1.0 - state.officeStaff.firstWhere((s) => s.id == 'staff_3').currentEffectValue);

        return AlertDialog(
          backgroundColor: AppColors.surface, 
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
          title: Text('ARSA SATIN ALIMI', textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.border, width: 2)), child: SizedBox(width: 40, height: 40, child: CustomPaint(painter: HeavyIconPainter(type: 'land', color: AppColors.textMuted)))), 
              const SizedBox(height: 16),
              Text('${fac.name} inşası için arsa bedeli:', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)), 
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.black, border: Border.all(color: AppColors.gold, width: 2), borderRadius: BorderRadius.zero), child: Text(finalPrice == 0 ? 'BEDELSİZ' : '\$${_formatNum(finalPrice)}', style: const TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            HeavyTycoonButton(
              height: 45, color: AppColors.surfaceElevated, shadowColor: const Color(0xFF14161C), padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: () {
                AudioService.instance.playSfx('click.mp3');
                Navigator.pop(context);
              }, 
              child: const Text('İPTAL', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 12))
            ),
            HeavyTycoonButton(
              height: 45, color: AppColors.gold, shadowColor: const Color(0xFF8B6B32), padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: () {
                if (state.money >= finalPrice) { 
                  HapticFeedback.mediumImpact();
                  AudioService.instance.playSfx('cash.mp3');
                  state.unlockFactory(fac.id); 
                  Navigator.pop(context); 
                } else { 
                  HapticFeedback.heavyImpact();
                  AudioService.instance.playSfx('click.mp3');
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yetersiz Bakiye', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppColors.loss)); 
                  Navigator.pop(context); 
                }
              },
              child: const Text('ONAYLA', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 12)),
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
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.loss, width: 3)),
        title: Row(
          children: [
            SizedBox(width: 24, height: 24, child: CustomPaint(painter: HeavyIconPainter(type: 'receipt', color: AppColors.loss))),
            const SizedBox(width: 10),
            const Text('VERGİ TAHAKKUKU', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.black, border: Border.all(color: AppColors.loss, width: 2), borderRadius: BorderRadius.zero), child: AnimatedMoneyText(money: gameState.currentTaxDebt, formatNum: _formatNum, style: const TextStyle(color: AppColors.loss, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.loss.withValues(alpha: 0.6), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.loss, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    gameState.isUnderPenalty
                        ? 'SÜRE DOLDU (HACİZ SÜRECİ)'
                        : 'Kalan Süre: ${gameState.taxTimeLeftFormatted}',
                    style: const TextStyle(color: AppColors.loss, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 20, height: 20, child: CustomPaint(painter: HeavyIconPainter(type: 'boost', color: AppColors.gold))),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Verginizi 12 saat dolmadan zamanında öderseniz 30 dakika boyunca %20 ek gelir takviyesi kazanırsınız!',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, height: 1.4),
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
            height: 45, color: AppColors.background, shadowColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: gameState.money >= gameState.currentTaxDebt
                ? () {
                    HapticFeedback.lightImpact();
                    AudioService.instance.playSfx('cash.mp3');
                    gameState.payTax();
                    Navigator.pop(c);
                  }
                : null,
            child: const Text('NAKİT ÖDE', style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
          HeavyTycoonButton(
            height: 45, color: AppColors.gold, shadowColor: const Color(0xFF8B6B32), padding: const EdgeInsets.symmetric(horizontal: 12),
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
                Icon(Icons.play_circle_fill_rounded, size: 16, color: AppColors.darkBrown),
                SizedBox(width: 6),
                Text('REKLAMLA ÖDE', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 11)),
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

    final ev = gameState.consumeUnhandledEvent();
    if (ev != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context, 
          barrierDismissible: false,
          builder: (c) => EventTimerDialog(ev: ev, gameState: gameState, formatNum: _formatNum),
        );
      });
    }

    final bagReward = gameState.consumeUnhandledBagReward();
    if (bagReward > 0) {
      _game.spawnFlyingBag(bagReward);
    }

    return Scaffold(
      backgroundColor: themeOceanBlue, 
      body: Stack(
        children: [
          GameWidget(game: _game),
          Positioned(top: 0, left: 0, right: 0, child: _buildPremiumTopPanel(context, gameState)),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildPremiumBottomBar(context)),
          Positioned(right: 16, top: MediaQuery.of(context).padding.top + 140, child: _buildSideActionButtons(gameState)),
        ],
      ),
    );
  }

  Widget _buildPremiumTopPanel(BuildContext context, GameState gameState) {
    IconData holdingIcon = _defaultLogos.isNotEmpty && _holdingLogoIndex >= 0 && _holdingLogoIndex < _defaultLogos.length ? _defaultLogos[_holdingLogoIndex] : Icons.domain_rounded;
    final double topSafe = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(top: topSafe + 12, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.98), 
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 3.5)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 46, height: 46, 
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.gold, width: 2)), 
                    child: Center(child: Icon(holdingIcon, size: 24, color: AppColors.gold)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_holdingName.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      AnimatedMoneyText(money: gameState.money, formatNum: _formatNum, style: const TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.border, width: 2)),
                    child: Text(gameState.incomePerSecond > 0 ? '+\$${_formatNum(gameState.incomePerSecond)}/s' : 'Beklemede', style: TextStyle(color: gameState.currentMultiplier > 1 ? AppColors.gold : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                  ),
                  const SizedBox(width: 10),
                  if (gameState.hasTaxDebt) 
                    PulsingTaxIcon(
                      onTap: () { 
                        HapticFeedback.selectionClick(); 
                        AudioService.instance.playSfx('click.mp3');
                        _showTaxDialog(context, gameState); 
                      },
                    ),
                  const SizedBox(width: 10),
                  Theme(
                    data: Theme.of(context).copyWith(popupMenuTheme: const PopupMenuThemeData(color: AppColors.surfaceElevated, shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)))), 
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.menu_rounded, size: 28, color: AppColors.textPrimary), offset: const Offset(0, 44), 
                      onSelected: (value) { 
                        AudioService.instance.playSfx('click.mp3');
                        if (value == 'settings') {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen())); 
                        } else if (value == 'main_menu') {
                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainMenuScreen(isInitialLaunch: false))); 
                        }
                      }, 
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings_rounded, color: AppColors.textSecondary, size: 20), SizedBox(width: 12), Text('Ayarlar', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold))])), 
                        const PopupMenuDivider(height: 2), 
                        const PopupMenuItem(value: 'main_menu', child: Row(children: [Icon(Icons.exit_to_app_rounded, color: AppColors.loss, size: 20), SizedBox(width: 12), Text('Oturumu Kapat', style: TextStyle(color: AppColors.loss, fontSize: 14, fontWeight: FontWeight.bold))])),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (gameState.isBoostActive || gameState.isTaxBonusActive || gameState.isEventActive) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (gameState.isBoostActive)
                  Container(
                    margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.gold, width: 1.5)),
                    child: Row(children: [SizedBox(width: 14, height: 14, child: CustomPaint(painter: HeavyIconPainter(type: 'boost', color: AppColors.gold))), const SizedBox(width: 6), Text('2X (${gameState.boostTimeLeft})', style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))]),
                  ),
                if (gameState.isTaxBonusActive)
                  Container(
                    margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.profit, width: 1.5)),
                    child: Row(children: [SizedBox(width: 14, height: 14, child: CustomPaint(painter: HeavyIconPainter(type: 'speed', color: AppColors.profit))), const SizedBox(width: 6), Text('+%20 (${gameState.taxBonusTimeLeft})', style: const TextStyle(color: AppColors.profit, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))]),
                  ),
                if (gameState.isEventActive)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.zero, border: Border.all(color: gameState.activeEvent!.multiplier > 1 ? AppColors.profit : AppColors.loss, width: 1.5)),
                      child: Row(children: [SizedBox(width: 14, height: 14, child: CustomPaint(painter: HeavyIconPainter(type: gameState.activeEvent!.multiplier > 1 ? 'trend_up' : 'trend_down', color: gameState.activeEvent!.multiplier > 1 ? AppColors.profit : AppColors.loss))), const SizedBox(width: 6), Expanded(child: Text('${gameState.activeEvent!.title} (${gameState.activeEventTimeLeft})', overflow: TextOverflow.ellipsis, style: TextStyle(color: gameState.activeEvent!.multiplier > 1 ? AppColors.profit : AppColors.loss, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')))]),
                    ),
                  ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildPremiumBottomBar(BuildContext context) {
    final double botSafe = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 72 + botSafe,
      padding: EdgeInsets.only(bottom: botSafe),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.98), 
        border: const Border(top: BorderSide(color: AppColors.border, width: 3.5)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, -6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPremiumTab("Ar-Ge", 'research', () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ResearchScreen())); 
          }),
          Container(width: 2, height: 32, color: AppColors.border),
          _buildPremiumTab("Borsa", 'stock', () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StockScreen())); 
          }),
          Container(width: 2, height: 32, color: AppColors.border),
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
              width: 26, height: 26,
              child: CustomPaint(painter: HeavyIconPainter(type: iconType, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 6),
            Text(title.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
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
        const SizedBox(height: 16),
        AnimatedSideButton(
          iconType: 'wheel', 
          onTap: () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            WheelDialog.show(context); 
          }
        ),
        const SizedBox(height: 16),
        AnimatedSideButton(
          iconType: 'achievements', 
          badgeCount: state.unclaimedAchievementsCount,
          onTap: () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            AchievementsDialog.show(context); 
          }
        ),
        const SizedBox(height: 16),
        AnimatedSideButton(
          iconType: 'tasks', 
          badgeCount: state.unclaimedTasksCount,
          onTap: () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            TasksDialog.show(context); 
          }
        ),
        const SizedBox(height: 16),
        AnimatedSideButton(
          iconType: 'prestige', 
          onTap: () { 
            HapticFeedback.selectionClick();
            AudioService.instance.playSfx('click.mp3');
            PrestigeDialog.show(context, currentTurnover: state.money, onPrestigeConfirmed: () { 
              AudioService.instance.playSfx('cash.mp3');
              state.executePrestige((state.money/1e20).floor()); 
            }); 
          }
        ),
      ],
    );
  }
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
  late AnimationController _controller;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _controller.reverse(from: 1.0).then((_) {
      if (mounted && !_resolved) {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _resolved = true;
    bool isCrisis = widget.ev.preventCost > 0;
    if (isCrisis) {
      widget.gameState.resolveEvent(false, widget.ev);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isCrisis = widget.ev.preventCost > 0;
    bool canAffordPrevent = widget.gameState.money >= widget.ev.preventCost;

    return AlertDialog(
      backgroundColor: AppColors.surface, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, 
        side: BorderSide(color: isCrisis ? AppColors.loss : AppColors.profit, width: 3.0),
      ),
      title: Row(
        children: [
          SizedBox(width: 24, height: 24, child: CustomPaint(painter: HeavyIconPainter(type: 'warning', color: isCrisis ? AppColors.loss : AppColors.profit))),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.ev.title, style: AppTheme.titleStyle(fontSize: 18).copyWith(color: isCrisis ? AppColors.loss : AppColors.profit))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.ev.description, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2), borderRadius: BorderRadius.zero),
                    child: LinearProgressIndicator(
                      value: _controller.value,
                      minHeight: 12,
                      backgroundColor: Colors.black,
                      valueColor: AlwaysStoppedAnimation<Color>(isCrisis ? AppColors.loss : AppColors.profit),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kalan Süre: ${(_controller.value * 10).ceil()}s',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'),
                  )
                ],
              );
            }
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        if (isCrisis) 
          HeavyTycoonButton(
            height: 45, color: AppColors.background, shadowColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 10),
            onPressed: canAffordPrevent ? () { 
              _resolved = true;
              AudioService.instance.playSfx('cash.mp3');
              widget.gameState.resolveEvent(true, widget.ev); 
              Navigator.pop(context); 
            } : null, 
            child: Text('ÖNLE (\$${widget.formatNum(widget.ev.preventCost)})', style: TextStyle(color: canAffordPrevent ? AppColors.textPrimary : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w900)),
          )
        else
          HeavyTycoonButton(
            height: 45, color: AppColors.surfaceElevated, shadowColor: const Color(0xFF14161C), padding: const EdgeInsets.symmetric(horizontal: 10),
            onPressed: () { 
              _resolved = true;
              AudioService.instance.playSfx('click.mp3');
              Navigator.pop(context); 
            }, 
            child: const Text('REDDET', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900)),
          ),
        HeavyTycoonButton(
          height: 45, color: isCrisis ? AppColors.loss : AppColors.profit, shadowColor: isCrisis ? const Color(0xFF7A1010) : const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(horizontal: 12),
          onPressed: () { 
            _resolved = true;
            AudioService.instance.playSfx('click.mp3');
            widget.gameState.resolveEvent(false, widget.ev); 
            Navigator.pop(context); 
          }, 
          child: Text(isCrisis ? 'KATLAN' : 'KABUL ET', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
        ),
      ],
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
        child: SizedBox(
          width: 30, height: 30,
          child: CustomPaint(painter: HeavyIconPainter(type: 'warning', color: AppColors.loss)),
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
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: SizedBox(
        width: 48, height: 48,
        child: Stack(
          children: [
            Positioned(
              bottom: 0, left: 0, right: 0, top: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF14161C),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: Colors.black87, width: 2),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              bottom: _isPressed ? 0 : 4,
              left: 0, right: 0, top: _isPressed ? 4 : 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: Colors.black87, width: 2),
                ),
                child: Center(
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CustomPaint(painter: HeavyIconPainter(type: widget.iconType, color: AppColors.gold)),
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
            right: -6, top: -6,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.loss, shape: BoxShape.rectangle, border: Border.all(color: Colors.black, width: 2)),
              child: Text(widget.badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
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
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

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
        canvas.drawPath(Path()..moveTo(12, 16)..lineTo(12, 20), stroke..strokeWidth = 2.5);
        canvas.drawPath(Path()..moveTo(8, 20)..lineTo(16, 20), stroke..strokeWidth = 2.5);
        canvas.drawPath(Path()..moveTo(6, 6)..lineTo(3, 6)..lineTo(3, 10)..lineTo(6, 12), stroke);
        canvas.drawPath(Path()..moveTo(18, 6)..lineTo(21, 6)..lineTo(21, 10)..lineTo(18, 12), stroke);
        break;
      case 'tasks':
        canvas.drawRect(const Rect.fromLTWH(4, 5, 5, 5), stroke);
        canvas.drawPath(Path()..moveTo(3, 7)..lineTo(5, 9)..lineTo(10, 3), stroke..strokeWidth=2);
        canvas.drawLine(const Offset(12, 7), const Offset(20, 7), stroke);
        
        canvas.drawRect(const Rect.fromLTWH(4, 15, 5, 5), stroke);
        canvas.drawLine(const Offset(12, 17), const Offset(20, 17), stroke);
        break;
      case 'prestige':
        canvas.drawPath(Path()..moveTo(12, 2)..lineTo(22, 10)..lineTo(12, 22)..lineTo(2, 10)..close(), stroke);
        canvas.drawLine(const Offset(2, 10), const Offset(22, 10), stroke);
        canvas.drawLine(const Offset(7, 10), const Offset(12, 22), stroke);
        canvas.drawLine(const Offset(17, 10), const Offset(12, 22), stroke);
        canvas.drawLine(const Offset(12, 2), const Offset(12, 10), stroke);
        canvas.drawLine(const Offset(7, 10), const Offset(12, 2), stroke);
        canvas.drawLine(const Offset(17, 10), const Offset(12, 2), stroke);
        break;
      case 'research':
        canvas.drawPath(Path()..moveTo(12, 22)..lineTo(12, 8)..lineTo(6, 2), stroke..strokeWidth = 2.5);
        canvas.drawLine(const Offset(12, 8), const Offset(18, 2), stroke..strokeWidth = 2.5);
        canvas.drawLine(const Offset(12, 14), const Offset(6, 8), stroke..strokeWidth = 2.5);
        canvas.drawRect(Rect.fromCenter(center: const Offset(12, 22), width: 6, height: 2), fill);
        canvas.drawRect(Rect.fromCenter(center: const Offset(6, 2), width: 4, height: 4), fill);
        canvas.drawRect(Rect.fromCenter(center: const Offset(18, 2), width: 4, height: 4), fill);
        canvas.drawRect(Rect.fromCenter(center: const Offset(6, 8), width: 4, height: 4), fill);
        break;
      case 'stock':
        canvas.drawLine(const Offset(4, 2), const Offset(4, 20), stroke..strokeWidth = 2.5);
        canvas.drawLine(const Offset(4, 20), const Offset(22, 20), stroke..strokeWidth = 2.5);
        canvas.drawPath(Path()..moveTo(6, 16)..lineTo(11, 10)..lineTo(15, 14)..lineTo(21, 6), stroke..strokeWidth=2);
        canvas.drawCircle(const Offset(6, 16), 1.5, fill);
        canvas.drawCircle(const Offset(11, 10), 1.5, fill);
        canvas.drawCircle(const Offset(15, 14), 1.5, fill);
        canvas.drawCircle(const Offset(21, 6), 1.5, fill);
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
        canvas.drawPath(Path()..moveTo(6, 4)..lineTo(14, 12)..lineTo(6, 20), stroke..strokeWidth=2.5);
        canvas.drawPath(Path()..moveTo(12, 4)..lineTo(20, 12)..lineTo(12, 20), stroke..strokeWidth=2.5);
        break;
      case 'trend_up':
        canvas.drawLine(const Offset(4, 18), const Offset(10, 12), stroke..strokeWidth=2.5);
        canvas.drawLine(const Offset(10, 12), const Offset(14, 16), stroke..strokeWidth=2.5);
        canvas.drawLine(const Offset(14, 16), const Offset(20, 6), stroke..strokeWidth=2.5);
        canvas.drawPath(Path()..moveTo(14, 6)..lineTo(20, 6)..lineTo(20, 12), stroke..strokeWidth=2.5);
        break;
      case 'trend_down':
        canvas.drawLine(const Offset(4, 6), const Offset(10, 12), stroke..strokeWidth=2.5);
        canvas.drawLine(const Offset(10, 12), const Offset(14, 8), stroke..strokeWidth=2.5);
        canvas.drawLine(const Offset(14, 8), const Offset(20, 18), stroke..strokeWidth=2.5);
        canvas.drawPath(Path()..moveTo(14, 18)..lineTo(20, 18)..lineTo(20, 12), stroke..strokeWidth=2.5);
        break;
      case 'upgrade':
        canvas.drawPath(Path()..moveTo(6, 12)..lineTo(12, 4)..lineTo(18, 12), stroke..strokeWidth=2.5);
        canvas.drawPath(Path()..moveTo(6, 20)..lineTo(12, 12)..lineTo(18, 20), stroke..strokeWidth=2.5);
        break;
      case 'touch':
        canvas.drawPath(Path()..moveTo(12, 2)..lineTo(6, 12)..lineTo(10, 12)..lineTo(10, 22)..lineTo(14, 22)..lineTo(14, 12)..lineTo(18, 12)..close(), stroke..strokeWidth=2);
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
    this.color = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProductVectorPainter(name: name, color: color),
      ),
    );
  }
}

class _ProductVectorPainter extends CustomPainter {
  final String name;
  final Color color;

  _ProductVectorPainter({required this.name, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(const Rect.fromLTWH(4, 4, 16, 16), stroke);
    canvas.drawRect(const Rect.fromLTWH(10, 10, 4, 4), fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProductVectorPainter oldDelegate) =>
      oldDelegate.name != name || oldDelegate.color != color;
}

class FactoryInsideModal extends StatefulWidget {
  final String factoryId; final String Function(double) formatNum;
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

  @override Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final currentFac = gameState.factories.firstWhere((f) => f.id == widget.factoryId);
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.86, 
          decoration: BoxDecoration(
            color: AppColors.surface, 
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.border, width: 3.5),
            boxShadow: const [
              BoxShadow(color: Colors.black, blurRadius: 30, offset: Offset(0, -6)),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 50, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: AppColors.gold, width: 2),
                      ),
                      child: SizedBox(width: 24, height: 24, child: CustomPaint(painter: HeavyIconPainter(type: 'factory', color: AppColors.gold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentFac.name.toUpperCase(), 
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.textPrimary, letterSpacing: 1.0),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Aşama ${currentFac.currentStage + 1}  •  Tesis: ${currentFac.totalLevel}/300', 
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, color: AppColors.gold, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: AnimatedMoneyText(money: gameState.money, formatNum: widget.formatNum, style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: const BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.zero,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.darkBrown,
                    unselectedLabelColor: AppColors.textMuted,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 16, height: 16, child: CustomPaint(painter: HeavyIconPainter(type: 'boost', color: AppColors.gold))), const SizedBox(width: 6), const Flexible(child: Text("ÜRETİM BANDI", overflow: TextOverflow.ellipsis))])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 16, height: 16, child: CustomPaint(painter: HeavyIconPainter(type: 'upgrade', color: AppColors.gold))), const SizedBox(width: 6), const Flexible(child: Text("TESİS GELİŞTİRME", overflow: TextOverflow.ellipsis))])),
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
                        if (prod.level == 0) {
                          return const SizedBox.shrink(); 
                        }
                        return ProductionLineWidget(
                          product: prod, 
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
                        bool canUnlock = index == 0 || currentFac.products[index - 1].level >= 10;

                        if (!canUnlock) {
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(color: AppColors.border, width: 2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.zero,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: SizedBox(width: 22, height: 22, child: CustomPaint(painter: HeavyIconPainter(type: 'warning', color: AppColors.textMuted))),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(prod.name, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      const Text('Önceki bandı Seviye 10 yapın', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        double cost = prod.upgradeCost; 
                        bool isMax = prod.level >= 60;
                        bool canAfford = gameState.money >= cost && !isMax;
                        double progressRatio = (prod.level / 60.0).clamp(0.0, 1.0);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(
                              color: canAfford ? AppColors.gold : AppColors.border,
                              width: 2.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.zero,
                                      border: Border.all(
                                        color: canAfford ? AppColors.gold : AppColors.border, width: 2
                                      ),
                                    ),
                                    child: Center(
                                      child: ProductSvgIcon(
                                        name: prod.name,
                                        size: 24,
                                        color: canAfford ? AppColors.gold : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(prod.name, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              'Lvl ${prod.level}/60',
                                              style: TextStyle(
                                                color: isMax ? AppColors.profit : AppColors.gold,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'SpaceMono',
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.zero,
                                                border: Border.all(color: AppColors.profit, width: 1.5),
                                              ),
                                              child: Text(
                                                '+\$${widget.formatNum(prod.passiveIncome)}/s',
                                                style: const TextStyle(color: AppColors.profit, fontSize: 10, fontWeight: FontWeight.w900),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  HeavyTycoonButton(
                                    width: 80, height: 44,
                                    color: isMax ? AppColors.background : (canAfford ? AppColors.gold : AppColors.surface),
                                    shadowColor: isMax ? Colors.black : (canAfford ? const Color(0xFF8B6B32) : Colors.black),
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
                                        Text(
                                          isMax ? 'MAKS' : 'GELİŞTİR',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: isMax || !canAfford ? AppColors.textMuted : AppColors.darkBrown),
                                        ),
                                        if (!isMax) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '\$${widget.formatNum(cost)}',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              fontFamily: 'SpaceMono',
                                              color: canAfford ? AppColors.darkBrown : AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2), borderRadius: BorderRadius.zero),
                                child: LinearProgressIndicator(
                                  value: progressRatio,
                                  minHeight: 6,
                                  backgroundColor: Colors.black,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isMax ? AppColors.profit : (canAfford ? AppColors.gold : AppColors.border),
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
  final String Function(double) formatNum; 
  final VoidCallback onProduceComplete;
  
  const ProductionLineWidget({
    super.key, 
    required this.product, 
    required this.formatNum, 
    required this.onProduceComplete,
  });

  @override 
  State<ProductionLineWidget> createState() => _ProductionLineWidgetState();
}

class _ProductionLineWidgetState extends State<ProductionLineWidget> with TickerProviderStateMixin {
  final List<int> _activeItems = [];
  final List<FloatingIncomeData> _floatingIncomes = [];
  int _counter = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startProduction() {
    final int currentId = _counter++;
    final double randomOffsetX = (math.Random().nextDouble() * 30) - 15;
    
    setState(() {
      _activeItems.add(currentId);
      _floatingIncomes.add(FloatingIncomeData(
        id: currentId,
        text: '+\$${widget.formatNum(widget.product.manualIncome)}',
        offsetX: randomOffsetX,
      ));
    });

    Future.delayed(const Duration(milliseconds: 800), () { 
      AudioService.instance.playSfx('cash.mp3'); 
      widget.onProduceComplete(); 
      
      if (mounted) { 
        setState(() { 
          _activeItems.remove(currentId); 
        }); 
      } 
    });
  }

  void _removeFloatingIncome(int id) {
    if (mounted) {
      setState(() {
        _floatingIncomes.removeWhere((item) => item.id == id);
      });
    }
  }

  @override 
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: Text(
                  'Lvl ${widget.product.level}',
                  style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.product.name, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: AppColors.profit, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 14, height: 14, child: CustomPaint(painter: HeavyIconPainter(type: 'boost', color: AppColors.profit))),
                    const SizedBox(width: 4),
                    Text(
                      '+\$${widget.formatNum(widget.product.manualIncome)}', 
                      style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'SpaceMono'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final double btnWidth = constraints.maxWidth < 340 ? 80.0 : 94.0;
              final double outWidth = constraints.maxWidth < 340 ? 44.0 : 50.0;

              return SizedBox(
                height: 60,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: btnWidth),

                          Expanded(
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    8,
                                    (i) => Container(
                                      width: 4, height: 26,
                                      decoration: const BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.zero,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 14, left: 0, right: 0,
                                  child: Container(height: 2, color: AppColors.border),
                                ),
                                Positioned(
                                  bottom: 14, left: 0, right: 0,
                                  child: Container(height: 2, color: AppColors.border),
                                ),
                                ..._activeItems.map((id) => ProductTokenAnimator(
                                  key: ValueKey(id), 
                                  productName: widget.product.name,
                                )),
                              ],
                            ),
                          ),

                          Container(
                            width: outWidth, height: double.infinity,
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.zero,
                              border: Border(left: BorderSide(color: AppColors.border, width: 2)),
                            ),
                            child: Center(
                              child: ProductSvgIcon(
                                name: widget.product.name,
                                size: 20,
                                color: AppColors.gold.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      left: 0, top: 0, bottom: 6,
                      width: btnWidth,
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: HeavyTycoonButton(
                          height: 54, width: btnWidth,
                          color: AppColors.gold,
                          shadowColor: const Color(0xFF8B6B32),
                          onTap: _startProduction,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 18, height: 18, child: CustomPaint(painter: HeavyIconPainter(type: 'touch', color: AppColors.darkBrown))),
                              const SizedBox(width: 4),
                              const Flexible(
                                child: Text(
                                  'ÜRET',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.darkBrown,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    ..._floatingIncomes.map((item) => Positioned(
                      left: 20 + item.offsetX,
                      bottom: 24,
                      child: FloatingIncomeText(
                        key: ValueKey(item.id),
                        text: item.text,
                        onEnd: () => _removeFloatingIncome(item.id),
                      ),
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

class FloatingIncomeData {
  final int id;
  final String text;
  final double offsetX;
  FloatingIncomeData({required this.id, required this.text, this.offsetX = 0.0});
}

class HeavyTycoonButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color color;
  final Color shadowColor;
  final double height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onPressed; 

  const HeavyTycoonButton({
    super.key,
    this.onTap,
    this.onPressed,
    required this.child,
    required this.color,
    required this.shadowColor,
    this.height = 50,
    this.width,
    this.padding,
  });

  @override
  State<HeavyTycoonButton> createState() => _HeavyTycoonButtonState();
}

class _HeavyTycoonButtonState extends State<HeavyTycoonButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? action = widget.onTap ?? widget.onPressed;
    final bool isDisabled = action == null;
    
    return GestureDetector(
      onTapDown: isDisabled ? null : (_) {
        HapticFeedback.lightImpact(); 
        AudioService.instance.playSfx('click.mp3');
        setState(() => _isPressed = true);
      },
      onTapUp: isDisabled ? null : (_) {
        setState(() => _isPressed = false);
        action();
      },
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            Positioned(
              bottom: 0, left: 0, right: 0, top: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: isDisabled ? AppColors.border.withValues(alpha: 0.5) : widget.shadowColor,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: Colors.black87, width: 2.5),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              bottom: _isPressed || isDisabled ? 0 : 6,
              left: 0, right: 0, top: _isPressed || isDisabled ? 6 : 0,
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: isDisabled ? AppColors.surfaceElevated : widget.color,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: Colors.black87, width: 2.5),
                ),
                child: Center(child: widget.child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductTokenAnimator extends StatefulWidget { 
  final String productName;
  const ProductTokenAnimator({super.key, required this.productName}); 
  @override State<ProductTokenAnimator> createState() => _ProductTokenAnimatorState(); 
}

class _ProductTokenAnimatorState extends State<ProductTokenAnimator> {
  bool _started = false;
  
  @override 
  void initState() { 
    super.initState(); 
    WidgetsBinding.instance.addPostFrameCallback((_) { 
      if (mounted) {
        setState(() { _started = true; }); 
      }
    }); 
  }

  @override 
  Widget build(BuildContext context) { 
    return AnimatedAlign(
      duration: const Duration(milliseconds: 800), 
      alignment: _started ? Alignment.centerRight : Alignment.centerLeft, 
      curve: Curves.linear, 
      child: Container(
        width: 30, height: 30, 
        margin: const EdgeInsets.symmetric(horizontal: 4), 
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.gold, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ), 
        child: Center(
          child: ProductSvgIcon(
            name: widget.productName,
            size: 18,
            color: AppColors.gold,
          ),
        ),
      ),
    ); 
  }
}

class FloatingIncomeText extends StatefulWidget {
  final String text;
  final VoidCallback onEnd;
  const FloatingIncomeText({super.key, required this.text, required this.onEnd});

  @override 
  State<FloatingIncomeText> createState() => _FloatingIncomeTextState();
}

class _FloatingIncomeTextState extends State<FloatingIncomeText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );

    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0.2, -1.8)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward().then((_) => widget.onEnd());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Text(
          widget.text,
          style: const TextStyle(
            color: AppColors.profit,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            fontFamily: 'SpaceMono',
            shadows: [
              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
            ],
          ),
        ),
      ),
    );
  }
}

class SeagullFlockComponent extends PositionComponent {
  double _time = 0; final Vector2 velocity; final int birdCount = 3 + math.Random().nextInt(5); 
  final List<Vector2> offsets = []; final List<double> phaseShifts = [];

  SeagullFlockComponent({required Vector2 startPos, required this.velocity}) {
    position = startPos; size = Vector2(150, 150);
    for(int i=0; i<birdCount; i++) { 
      offsets.add(Vector2(math.Random().nextDouble() * 100, math.Random().nextDouble() * 100)); 
      phaseShifts.add(math.Random().nextDouble() * math.pi * 2); 
    }
  }

  @override void update(double dt) { 
    _time += dt; 
    position.add(velocity * dt); 
    if (position.x < -300 || position.x > 1500) {
      removeFromParent(); 
    }
  }

  @override void render(Canvas canvas) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    for (int i = 0; i < birdCount; i++) {
      double flap = math.sin(_time * 8 + phaseShifts[i]) * 8; 
      double bx = offsets[i].x, by = offsets[i].y;
      Path bird = Path()..moveTo(bx, by - flap)..quadraticBezierTo(bx + 8, by - 5, bx + 12, by)..quadraticBezierTo(bx + 16, by - 5, bx + 24, by - flap);
      canvas.drawPath(bird, paint);
    }
  }
}

class CrashingWavesComponent extends Component {
  final double mapWidth; final double mapHeight; final math.Random _random = math.Random(); final List<_Wave> _waves = [];
  CrashingWavesComponent({required this.mapWidth, required this.mapHeight});

  @override void update(double dt) {
    if (_random.nextDouble() < 0.03) {
      _waves.add(_Wave(x: -100 + _random.nextDouble() * (mapWidth + 200), y: -100 + _random.nextDouble() * (mapHeight + 200), maxLife: 3.0 + _random.nextDouble() * 2.0, size: 0.8 + _random.nextDouble() * 1.5));
    }
    for (int i = _waves.length - 1; i >= 0; i--) { 
      _waves[i].life += dt; 
      if (_waves[i].life > _waves[i].maxLife) {
        _waves.removeAt(i); 
      }
    }
  }

  @override void render(Canvas canvas) {
    Path safeWaterZone = Path.combine(PathOperation.difference, Path.combine(PathOperation.difference, Path.combine(PathOperation.difference, Path()..addRect(Rect.fromLTWH(-500, -500, mapWidth + 1000, mapHeight + 1000)), Path()..addOval(const Rect.fromLTRB(965, 1340, 1300, 1540))), Path()..addOval(const Rect.fromLTRB(-20, 2800, 120, 3100))), Path()..addOval(const Rect.fromLTRB(-20, 400, 140, 600)));
    canvas.save(); canvas.clipPath(safeWaterZone);
    for (var wave in _waves) {
      double progress = wave.life / wave.maxLife; double alpha = math.sin(progress * math.pi) * 0.6; 
      final paint = Paint()..color = Colors.white.withValues(alpha: alpha)..style = PaintingStyle.fill;
      double currentX = wave.x + (progress * 30 * wave.size), currentY = wave.y + (progress * 20 * wave.size);
      Path wavePath = Path()..moveTo(currentX, currentY)..quadraticBezierTo(currentX + (40 * wave.size), currentY - (15 * wave.size), currentX + (80 * wave.size), currentY + (10 * wave.size))..quadraticBezierTo(currentX + (40 * wave.size), currentY - (5 * wave.size), currentX, currentY);
      canvas.drawPath(wavePath, paint);
    }
    canvas.restore();
  }
}
class _Wave { double x, y, life = 0, maxLife, size; _Wave({required this.x, required this.y, required this.maxLife, required this.size}); }

class OpenSeaRipples extends Component {
  double _time = 0; final Paint _ripplePaint = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 3.5;
  @override void update(double dt) { _time += dt * 0.6; }
  @override void render(Canvas canvas) {
    for (double y = -200; y < 3400; y += 120) {
      for (double x = -100; x < 1200; x += 150) {
        double cycle = (_time + ((x + math.sin(y * 3.2) * 60) * 0.01) + ((y + math.cos(x * 2.1) * 40) * 0.015)) % (math.pi * 2);
        if (cycle < math.pi) {
          _ripplePaint.color = Colors.white.withValues(alpha: math.sin(cycle) * 0.35);
          double currentX = (x + math.sin(y * 3.2) * 60) - ((cycle / math.pi) * 45.0); 
          canvas.drawPath(Path()..moveTo(currentX, y + math.cos(x * 2.1) * 40)..quadraticBezierTo(currentX + 20, (y + math.cos(x * 2.1) * 40) + 5, currentX + 40, y + math.cos(x * 2.1) * 40), _ripplePaint);
        }
      }
    }
  }
}

class PerfectPngWaves extends Component {
  final Sprite mapSprite; final double mapWidth; final double mapHeight; double _time = 0;
  PerfectPngWaves({required this.mapSprite, required this.mapWidth, required this.mapHeight});
  @override void update(double dt) { _time += dt * 0.12; }
  @override void render(Canvas canvas) {
    Path safeWaterZone = Path.combine(PathOperation.difference, Path.combine(PathOperation.difference, Path.combine(PathOperation.difference, Path()..addRect(Rect.fromLTWH(-500, -500, mapWidth + 1000, mapHeight + 1000)), Path()..addOval(const Rect.fromLTRB(965, 1340, 1300, 1540))), Path()..addOval(const Rect.fromLTRB(-20, 2800, 120, 3100))), Path()..addOval(const Rect.fromLTRB(-20, 400, 140, 600)));
    for (int i = 0; i < 3; i++) {
      double progress = ((_time * 0.5) - (i * 0.333)) % 1.0; 
      if (progress < 0) {
        progress += 1.0;
      }
      double reversedProgress = 1.0 - progress; double alpha = math.sin(reversedProgress * math.pi) * 0.45;
      if (alpha <= 0) {
        continue;
      }
      canvas.save(); canvas.clipPath(safeWaterZone);
      canvas.translate((mapWidth / 2) + (reversedProgress * 70.0) * 0.75, mapHeight / 2); canvas.scale((mapWidth + ((reversedProgress * 70.0) * 2)) / mapWidth, (mapHeight + ((reversedProgress * 70.0) * 2)) / mapHeight); canvas.translate(-mapWidth / 2, -mapHeight / 2);
      mapSprite.render(canvas, size: Vector2(mapWidth, mapHeight), overridePaint: Paint()..colorFilter = ColorFilter.mode(Color.lerp(Colors.white, themeOceanBlue, 0.25)!.withValues(alpha: alpha), BlendMode.srcIn));
      canvas.restore();
    }
  }
}

class FlyingBagComponent extends PositionComponent with TapCallbacks {
  final double reward; final Function(double) onBagTap; double _time = 0; final Vector2 velocity;
  FlyingBagComponent({required this.reward, required this.onBagTap, required Vector2 startPos, required this.velocity}) { position = startPos; size = Vector2(80, 80); anchor = Anchor.center; }
  @override void update(double dt) { _time += dt; position.add(velocity * dt); position.y += math.sin(_time * 6) * 3; if (position.x < -200 || position.x > 1300) { removeFromParent(); } }
  @override void onTapUp(TapUpEvent event) { onBagTap(reward); removeFromParent(); }
  @override void render(Canvas canvas) {
    canvas.drawRect(Rect.fromCenter(center: Offset(size.x/2, size.y/2), width: 70, height: 70), Paint()..color=Colors.yellow.withValues(alpha: 0.3)..maskFilter=const MaskFilter.blur(BlurStyle.normal, 15));
    Path bag = Path()..moveTo(size.x/2 - 25, size.y/2 + 25)..lineTo(size.x/2 - 25, size.y/2)..lineTo(size.x/2 - 15, size.y/2 - 20)..lineTo(size.x/2 + 15, size.y/2 - 20)..lineTo(size.x/2 + 25, size.y/2)..lineTo(size.x/2 + 25, size.y/2 + 25)..close();
    canvas.drawPath(bag, Paint()..color = const Color(0xFF6D4C41)); canvas.drawPath(bag, Paint()..color = const Color(0xFF4E342E)..style = PaintingStyle.stroke..strokeWidth=2);
    canvas.drawRect(Rect.fromLTWH(size.x/2 - 12, size.y/2 - 32, 24, 12), Paint()..color = const Color(0xFF8D6E63)); canvas.drawLine(Offset(size.x/2 - 14, size.y/2 - 20), Offset(size.x/2 + 14, size.y/2 - 20), Paint()..color = const Color(0xFF3E2723)..strokeWidth=3);
    final textPainter = TextPainter(text: const TextSpan(text: '\$', style: TextStyle(color: Colors.yellow, fontSize: 32, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black54, offset: Offset(1,1), blurRadius: 2)])), textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, Offset(size.x/2 - textPainter.width/2, size.y/2 - 12));
  }
}

class HoldingTycoonGame extends FlameGame with PanDetector {
  final Function(String) onFactoryTap; final Function(double) onBagTapped; 
  late final CameraComponent cam; final World mapWorld = World(); double mapWidth = 1080.0; double mapHeight = 1920.0; final double topPadding = 250.0; final double bottomPadding = 350.0;
  GameState? _currentState;
  HoldingTycoonGame({required this.onFactoryTap, required this.onBagTapped}) { cam = CameraComponent(world: mapWorld); }
  
  void updateState(GameState state) { 
    _currentState = state; 
    for (var child in mapWorld.children) { 
      if (child is FactoryPlotComponent && _currentState != null) { 
        child.updateData(_currentState!.factories.firstWhere((f) => f.id == child.factoryId)); 
      } 
    } 
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
      
      mapWorld.add(OpenSeaRipples()); 
      mapWorld.add(CrashingWavesComponent(mapWidth: mapWidth, mapHeight: mapHeight)); 
      mapWorld.add(PerfectPngWaves(mapSprite: mapSprite, mapWidth: mapWidth, mapHeight: mapHeight)); 
      
      mapWorld.add(SpriteComponent(sprite: mapSprite, size: Vector2(mapWidth, mapHeight)));
      final List<Vector2> plotPositions = [Vector2(540, 420), Vector2(330, 520), Vector2(700, 560), Vector2(320, 720), Vector2(720, 750), Vector2(310, 930), Vector2(680, 950), Vector2(460, 1080), Vector2(650, 1180), Vector2(360, 1240), Vector2(530, 1280), Vector2(320, 1390), Vector2(500, 1440), Vector2(420, 1550), Vector2(580, 1680)];
      for (int i = 0; i < 15; i++) {
        mapWorld.add(FactoryPlotComponent(factoryId: (i + 1).toString(), position: plotPositions[i], onTap: onFactoryTap));
      }
    } catch (e) { 
      debugPrint("PNG HATASI: $e"); 
    }
    cam.viewfinder.anchor = Anchor.topLeft; 
    cam.viewfinder.position = Vector2(0, -topPadding); 
    add(cam);
  }

  @override void onGameResize(Vector2 size) { 
    super.onGameResize(size); 
    cam.viewfinder.zoom = size.x / mapWidth; 
  }
  
  @override void onPanUpdate(DragUpdateInfo info) { 
    final delta = info.delta.global; 
    double newY = cam.viewfinder.position.y - (delta.y / cam.viewfinder.zoom); 
    double maxScroll = mapHeight - (size.y / cam.viewfinder.zoom) + bottomPadding; 
    cam.viewfinder.position = Vector2(0, newY.clamp(-topPadding, maxScroll > -topPadding ? maxScroll : -topPadding)); 
  }
}

class FactoryPlotComponent extends PositionComponent with TapCallbacks {
  final String factoryId; 
  final Function(String) onTap; 
  FactoryData? _data;
  
  FactoryPlotComponent({required this.factoryId, required Vector2 position, required this.onTap}) : super(position: position, size: Vector2(170, 170), anchor: Anchor.center);
  
  void updateData(FactoryData data) { _data = data; } 
  
  @override void onTapUp(TapUpEvent event) { onTap(factoryId); }
  
  @override void render(Canvas canvas) {
    final currentData = _data; 
    
    if (currentData == null) {
      return; 
    }
    
    if (!currentData.isUnlocked) {
      canvas.drawRect(Rect.fromLTWH(10, 10, size.x-20, size.y-20), Paint()..color = const Color(0xFF1E2128).withValues(alpha: 0.8)..style=PaintingStyle.fill);
      canvas.drawRect(Rect.fromLTWH(10, 10, size.x-20, size.y-20), Paint()..color = Colors.black..style=PaintingStyle.stroke..strokeWidth=4);
      final iconPainter = TextPainter(textDirection: TextDirection.ltr)..text = TextSpan(text: String.fromCharCode(Icons.lock_rounded.codePoint), style: TextStyle(fontSize: 32, fontFamily: Icons.lock_rounded.fontFamily, color: const Color(0xFF94A3B8)))..layout(); 
      iconPainter.paint(canvas, Offset(size.x/2 - 16, size.y/2 - 16));
    } else {
      canvas.drawRect(Rect.fromLTWH(size.x/2 - 50, size.y/2 - 30, 100, 60), Paint()..color = const Color(0xFF2D3748));
      canvas.drawRect(Rect.fromLTWH(size.x/2 - 50, size.y/2 - 30, 100, 60), Paint()..color = Colors.black..style=PaintingStyle.stroke..strokeWidth=3);
      canvas.drawPath(Path()..moveTo(size.x/2 - 58, size.y/2 - 30)..lineTo(size.x/2, size.y/2 - 60)..lineTo(size.x/2 + 58, size.y/2 - 30)..close(), Paint()..color = const Color(0xFF4A5568));
      final textPainter = TextPainter(text: TextSpan(text: 'Lvl ${currentData.totalLevel}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, backgroundColor: Colors.black87)), textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, const Offset(12, 12));
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