// lib/screens/map_screen.dart
// ignore_for_file: unused_import

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.rocket_launch_rounded, color: AppColors.gold, size: 36),
                      const SizedBox(height: 12),
                      Text('SEKTÖR SEÇİMİ', textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.textPrimary, letterSpacing: 2.0)),
                      const SizedBox(height: 8),
                      const Text('Holdinginizin faaliyetlerine başlayacağı ilk sanayi kolunu seçin. Seçtiğiniz ilk tesis size bedelsiz olarak tahsis edilecektir.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _buildFactoryChoiceCard('1', 'Tekstil', Icons.checkroom_rounded, selectedId, (val) { 
                            HapticFeedback.selectionClick(); 
                            AudioService.instance.playSfx('click.mp3'); 
                            setDialogState(() => selectedId = val); 
                          }),
                          _buildFactoryChoiceCard('2', 'Mobilya', Icons.chair_rounded, selectedId, (val) { 
                            HapticFeedback.selectionClick(); 
                            AudioService.instance.playSfx('click.mp3'); 
                            setDialogState(() => selectedId = val); 
                          }),
                          _buildFactoryChoiceCard('3', 'Tarım', Icons.agriculture_rounded, selectedId, (val) { 
                            HapticFeedback.selectionClick(); 
                            AudioService.instance.playSfx('click.mp3'); 
                            setDialogState(() => selectedId = val); 
                          }),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold, 
                            foregroundColor: AppColors.darkBrown,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            AudioService.instance.playSfx('click.mp3');
                            context.read<GameState>().applyStarterSector(selectedId);
                            Navigator.pop(context);
                          },
                          child: const Text('SEKTÖRE GİRİŞ YAP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
                        ),
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

  Widget _buildFactoryChoiceCard(String id, String name, IconData icon, String selectedId, Function(String) onSelect) {
    bool isSel = selectedId == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSel ? AppColors.gold.withValues(alpha: 0.15) : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSel ? AppColors.gold : AppColors.border, width: isSel ? 2.0 : 1.0),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSel ? AppColors.gold : AppColors.textMuted, size: 28),
              const SizedBox(height: 8),
              Text(name, style: TextStyle(color: isSel ? AppColors.gold : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
        title: Text('GECE MESAİSİ', textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assessment_rounded, size: 40, color: AppColors.gold), 
            const SizedBox(height: 16),
            const Text('Tesisleriniz siz yokken üretime devam etti.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)), 
            const SizedBox(height: 16),
            AnimatedMoneyText(money: state.offlineEarningsToClaim, formatNum: _formatNum, style: const TextStyle(color: AppColors.profit, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () { 
              AudioService.instance.playSfx('cash.mp3');
              state.claimOfflineEarnings(false); 
              Navigator.pop(context); 
            }, 
            child: const Text('Normal Tahsil Et', style: TextStyle(color: AppColors.textMuted))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkBrown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
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
            child: const Text('REKLAMLA 2X AL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.gold)),
        title: Text('FİNANSMAN', style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.gold)),
        content: Text('Sahada \$${_formatNum(reward)} değerinde harici finansman bulundu.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () { 
              AudioService.instance.playSfx('cash.mp3');
              state.claimBagReward(false, reward); 
              Navigator.pop(c); 
            }, 
            child: const Text('Tahsil Et', style: TextStyle(color: AppColors.textMuted))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkBrown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
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
            child: const Text('3X KATLA', style: TextStyle(fontWeight: FontWeight.bold)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
          title: Text('ARSA SATIN ALIMI', textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 16).copyWith(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.landscape_rounded, size: 40, color: AppColors.textMuted), 
              const SizedBox(height: 16),
              Text('${fac.name} inşası için arsa bedeli:', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)), 
              const SizedBox(height: 8),
              Text(finalPrice == 0 ? 'BEDELSİZ' : '\$${_formatNum(finalPrice)}', style: const TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () {
                AudioService.instance.playSfx('click.mp3');
                Navigator.pop(context);
              }, 
              child: const Text('İPTAL', style: TextStyle(color: AppColors.textMuted))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkBrown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                if (state.money >= finalPrice) { 
                  HapticFeedback.mediumImpact();
                  AudioService.instance.playSfx('cash.mp3');
                  state.unlockFactory(fac.id); 
                  Navigator.pop(context); 
                } else { 
                  HapticFeedback.heavyImpact();
                  AudioService.instance.playSfx('click.mp3');
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yetersiz Bakiye'), backgroundColor: AppColors.surfaceElevated)); 
                  Navigator.pop(context); 
                }
              },
              child: const Text('ONAYLA', style: TextStyle(fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: AppColors.loss, size: 22),
            SizedBox(width: 8),
            Text('VERGİ TAHAKKUKU', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedMoneyText(money: gameState.currentTaxDebt, formatNum: _formatNum, style: const TextStyle(color: AppColors.loss, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.loss.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.loss, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    gameState.isUnderPenalty
                        ? 'SÜRE DOLDU (HACİZ SÜRECİ)'
                        : 'Kalan Süre: ${gameState.taxTimeLeftFormatted}',
                    style: const TextStyle(color: AppColors.loss, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.gold, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verginizi 12 saat dolmadan zamanında öderseniz 30 dakika boyunca %20 ek gelir takviyesi kazanırsınız!',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: gameState.money >= gameState.currentTaxDebt
                ? () {
                    HapticFeedback.lightImpact();
                    AudioService.instance.playSfx('cash.mp3');
                    gameState.payTax();
                    Navigator.pop(c);
                  }
                : null,
            child: const Text('NAKİT ÖDE', style: TextStyle(fontSize: 11)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.darkBrown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
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
            label: const Text('REKLAMLA ÖDE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    _game.updateState(gameState);

    // YENİ: Kriz ve fırsatlar için 10 saniye limitli dialog
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
          Positioned(right: 16, top: 160, child: _buildSideActionButtons(gameState)),
        ],
      ),
    );
  }

  Widget _buildPremiumTopPanel(BuildContext context, GameState gameState) {
    IconData holdingIcon = _defaultLogos.isNotEmpty && _holdingLogoIndex >= 0 && _holdingLogoIndex < _defaultLogos.length ? _defaultLogos[_holdingLogoIndex] : Icons.domain_rounded;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95), 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
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
                        width: 42, height: 42, 
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.gold.withValues(alpha: 0.5))), 
                        child: Center(child: Icon(holdingIcon, size: 22, color: AppColors.gold)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_holdingName.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          const SizedBox(height: 2),
                          AnimatedMoneyText(money: gameState.money, formatNum: _formatNum, style: const TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'SpaceMono')),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                        child: Text(gameState.incomePerSecond > 0 ? '+\$${_formatNum(gameState.incomePerSecond)}/s' : 'Beklemede', style: TextStyle(color: gameState.currentMultiplier > 1 ? AppColors.gold : AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      if (gameState.hasTaxDebt) 
                        PulsingTaxIcon(
                          onTap: () { 
                            HapticFeedback.selectionClick(); 
                            AudioService.instance.playSfx('click.mp3');
                            _showTaxDialog(context, gameState); 
                          },
                        ),
                      const SizedBox(width: 8),
                      Theme(
                        data: Theme.of(context).copyWith(popupMenuTheme: PopupMenuThemeData(color: AppColors.surfaceElevated, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.border)))), 
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.menu_rounded, size: 24, color: AppColors.textPrimary), offset: const Offset(0, 40), 
                          onSelected: (value) { 
                            AudioService.instance.playSfx('click.mp3');
                            if (value == 'settings') {
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen())); 
                            } else if (value == 'main_menu') {
                              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainMenuScreen(isInitialLaunch: false))); 
                            }
                          }, 
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings_rounded, color: AppColors.textSecondary, size: 18), SizedBox(width: 10), Text('Ayarlar', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))])), 
                            const PopupMenuDivider(height: 1), 
                            const PopupMenuItem(value: 'main_menu', child: Row(children: [Icon(Icons.exit_to_app_rounded, color: AppColors.loss, size: 18), SizedBox(width: 10), Text('Oturumu Kapat', style: TextStyle(color: AppColors.loss, fontSize: 13))])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (gameState.isBoostActive || gameState.isTaxBonusActive || gameState.isEventActive) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (gameState.isBoostActive)
                      Container(
                        margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.gold.withValues(alpha: 0.5))),
                        child: Row(children: [const Icon(Icons.electric_bolt_rounded, color: AppColors.gold, size: 12), const SizedBox(width: 4), Text('2X (${gameState.boostTimeLeft})', style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold))]),
                      ),
                    if (gameState.isTaxBonusActive)
                      Container(
                        margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.profit.withValues(alpha: 0.5))),
                        child: Row(children: [const Icon(Icons.speed_rounded, color: AppColors.profit, size: 12), const SizedBox(width: 4), Text('+%20 (${gameState.taxBonusTimeLeft})', style: const TextStyle(color: AppColors.profit, fontSize: 10, fontWeight: FontWeight.bold))]),
                      ),
                    if (gameState.isEventActive)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: gameState.activeEvent!.multiplier > 1 ? AppColors.profit : AppColors.loss)),
                          child: Row(children: [Icon(gameState.activeEvent!.multiplier > 1 ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: gameState.activeEvent!.multiplier > 1 ? AppColors.profit : AppColors.loss, size: 12), const SizedBox(width: 4), Expanded(child: Text('${gameState.activeEvent!.title} (${gameState.activeEventTimeLeft})', overflow: TextOverflow.ellipsis, style: TextStyle(color: gameState.activeEvent!.multiplier > 1 ? AppColors.profit : AppColors.loss, fontSize: 10, fontWeight: FontWeight.bold)))]),
                        ),
                      ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95), 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPremiumTab("Ar-Ge", Icons.science_rounded, () { 
              HapticFeedback.selectionClick(); 
              AudioService.instance.playSfx('click.mp3');
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ResearchScreen())); 
            }),
            Container(width: 1, height: 24, color: AppColors.border),
            _buildPremiumTab("Borsa", Icons.candlestick_chart_rounded, () { 
              HapticFeedback.selectionClick(); 
              AudioService.instance.playSfx('click.mp3');
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StockScreen())); 
            }),
            Container(width: 1, height: 24, color: AppColors.border),
            _buildPremiumTab("Yazıhane", Icons.business_rounded, () { 
              HapticFeedback.selectionClick(); 
              AudioService.instance.playSfx('click.mp3');
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OfficeScreen())); 
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTab(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(title.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
          icon: Icons.electric_bolt_rounded, 
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
        const SizedBox(height: 12),
        AnimatedSideButton(
          icon: Icons.pie_chart_rounded, 
          onTap: () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            WheelDialog.show(context); 
          }
        ),
        const SizedBox(height: 12),
        AnimatedSideButton(
          icon: Icons.emoji_events_rounded, 
          badgeCount: state.unclaimedAchievementsCount,
          onTap: () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            AchievementsDialog.show(context); 
          }
        ),
        const SizedBox(height: 12),
        AnimatedSideButton(
          icon: Icons.checklist_rounded, 
          badgeCount: state.unclaimedTasksCount,
          onTap: () { 
            HapticFeedback.selectionClick(); 
            AudioService.instance.playSfx('click.mp3');
            TasksDialog.show(context); 
          }
        ),
        const SizedBox(height: 12),
        AnimatedSideButton(
          icon: Icons.diamond_rounded, 
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

// YENİ: Etkinlikler için 10 saniye limitli ve animasyonlu dialog widget'ı
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isCrisis ? AppColors.loss : AppColors.profit, width: 1.5)),
      title: Row(
        children: [
          Icon(isCrisis ? Icons.warning_rounded : Icons.info_outline_rounded, color: isCrisis ? AppColors.loss : AppColors.profit, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.ev.title, style: AppTheme.titleStyle(fontSize: 16).copyWith(color: isCrisis ? AppColors.loss : AppColors.profit))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.ev.description, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _controller.value,
                      minHeight: 6,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(isCrisis ? AppColors.loss : AppColors.profit),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kalan Süre: ${(_controller.value * 10).ceil()}s',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.background, foregroundColor: canAffordPrevent ? AppColors.textPrimary : AppColors.textMuted, side: BorderSide(color: canAffordPrevent ? AppColors.border : Colors.transparent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: canAffordPrevent ? () { 
              _resolved = true;
              AudioService.instance.playSfx('cash.mp3');
              widget.gameState.resolveEvent(true, widget.ev); 
              Navigator.pop(context); 
            } : null, 
            child: Text('ÖNLE (\$${widget.formatNum(widget.ev.preventCost)})', style: const TextStyle(fontSize: 11)),
          )
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.background, foregroundColor: AppColors.textMuted, side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () { 
              _resolved = true;
              AudioService.instance.playSfx('click.mp3');
              Navigator.pop(context); 
            }, 
            child: const Text('REDDET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: isCrisis ? AppColors.loss : AppColors.profit, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () { 
            _resolved = true;
            AudioService.instance.playSfx('click.mp3');
            widget.gameState.resolveEvent(false, widget.ev); 
            Navigator.pop(context); 
          }, 
          child: Text(isCrisis ? 'KATLAN' : 'KABUL ET', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
        child: const Icon(
          Icons.warning_rounded,
          color: AppColors.loss,
          size: 26,
        ),
      ),
    );
  }
}

class AnimatedSideButton extends StatelessWidget {
  final IconData icon; 
  final VoidCallback onTap; 
  final int badgeCount;
  
  const AnimatedSideButton({
    super.key, 
    required this.icon, 
    required this.onTap, 
    this.badgeCount = 0
  });

  @override Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40, 
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border, width: 1.5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]), 
        child: Center(child: Icon(icon, size: 20, color: AppColors.gold)),
      ),
    );

    if (badgeCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: -4, top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.loss, shape: BoxShape.circle),
              child: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }
    return button;
  }
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
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (name) {
      // 1. TEKSTİL ATÖLYESİ
      case 'T-shirt':
        Path tshirt = Path()..moveTo(8, 4)..lineTo(11, 6)..lineTo(13, 6)..lineTo(16, 4)..lineTo(21, 8)..lineTo(18, 11)..lineTo(16, 10)..lineTo(16, 20)..lineTo(8, 20)..lineTo(8, 10)..lineTo(6, 11)..lineTo(3, 8)..close();
        canvas.drawPath(tshirt, stroke);
        break;
      case 'Pantolon':
        Path pants = Path()..moveTo(7, 4)..lineTo(17, 4)..lineTo(18, 20)..lineTo(13, 20)..lineTo(12, 10)..lineTo(11, 20)..lineTo(6, 20)..close();
        canvas.drawPath(pants, stroke);
        break;
      case 'Ayakkabı':
        Path shoe = Path()..moveTo(6, 14)..quadraticBezierTo(10, 14, 12, 12)..lineTo(18, 14)..quadraticBezierTo(21, 16, 20, 20)..lineTo(5, 20)..close();
        canvas.drawPath(shoe, stroke);
        break;
      case 'Çanta':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 9, 14, 11), const Radius.circular(2)), stroke);
        canvas.drawPath(Path()..moveTo(9, 9)..quadraticBezierTo(12, 3, 15, 9), stroke);
        canvas.drawCircle(const Offset(12, 12), 1.5, fill);
        break;
      case 'Takım Elbise':
        Path suit = Path()..moveTo(6, 4)..lineTo(18, 4)..lineTo(20, 9)..lineTo(17, 11)..lineTo(17, 21)..lineTo(7, 21)..lineTo(7, 11)..lineTo(4, 9)..close();
        canvas.drawPath(suit, stroke);
        canvas.drawLine(const Offset(12, 4), const Offset(12, 21), stroke);
        canvas.drawLine(const Offset(7, 4), const Offset(10, 10), stroke);
        canvas.drawLine(const Offset(17, 4), const Offset(14, 10), stroke);
        break;

      // 2. MOBİLYA FABRİKASI
      case 'Sandalye':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 3, 12, 8), const Radius.circular(2)), stroke);
        canvas.drawLine(const Offset(4, 13), const Offset(20, 13), stroke);
        canvas.drawLine(const Offset(6, 13), const Offset(5, 21), stroke);
        canvas.drawLine(const Offset(18, 13), const Offset(19, 21), stroke);
        break;
      case 'Masa':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 7, 18, 4), const Radius.circular(1.5)), fill);
        canvas.drawLine(const Offset(6, 11), const Offset(5, 20), stroke);
        canvas.drawLine(const Offset(18, 11), const Offset(19, 20), stroke);
        canvas.drawLine(const Offset(6, 15), const Offset(18, 15), stroke);
        break;
      case 'Koltuk':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 6, 14, 8), const Radius.circular(3)), stroke);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, 10, 4, 8), const Radius.circular(2)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, 10, 4, 8), const Radius.circular(2)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 13, 12, 5), const Radius.circular(2)), fill);
        canvas.drawLine(const Offset(5, 18), const Offset(4, 21), stroke);
        canvas.drawLine(const Offset(19, 18), const Offset(20, 21), stroke);
        break;
      case 'Yatak':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 6, 18, 6), const Radius.circular(3)), stroke);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, 12, 20, 6), const Radius.circular(2)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 8, 7, 4), const Radius.circular(1.5)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(13, 8, 7, 4), const Radius.circular(1.5)), fill);
        canvas.drawLine(const Offset(4, 18), const Offset(4, 21), stroke);
        canvas.drawLine(const Offset(20, 18), const Offset(20, 21), stroke);
        break;
      case 'Dolap':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 3, 16, 17), const Radius.circular(2)), stroke);
        canvas.drawLine(const Offset(12, 3), const Offset(12, 20), stroke);
        canvas.drawCircle(const Offset(10, 12), 1, fill);
        canvas.drawCircle(const Offset(14, 12), 1, fill);
        canvas.drawLine(const Offset(6, 20), const Offset(6, 22), stroke);
        canvas.drawLine(const Offset(18, 20), const Offset(18, 22), stroke);
        break;

      // 3. TARIM TESİSLERİ
      case 'Buğday':
        canvas.drawLine(const Offset(12, 21), const Offset(12, 4), stroke);
        canvas.drawOval(const Rect.fromLTWH(7, 5, 4, 3), fill);
        canvas.drawOval(const Rect.fromLTWH(13, 5, 4, 3), fill);
        canvas.drawOval(const Rect.fromLTWH(6, 9, 5, 3), fill);
        canvas.drawOval(const Rect.fromLTWH(13, 9, 5, 3), fill);
        canvas.drawOval(const Rect.fromLTWH(7, 13, 4, 3), fill);
        canvas.drawOval(const Rect.fromLTWH(13, 13, 4, 3), fill);
        break;
      case 'Mısır':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, 4, 6, 15), const Radius.circular(3)), stroke);
        canvas.drawLine(const Offset(9, 9), const Offset(15, 9), stroke);
        canvas.drawLine(const Offset(9, 14), const Offset(15, 14), stroke);
        canvas.drawArc(const Rect.fromLTWH(6, 12, 6, 8), 0, math.pi / 2, false, stroke);
        canvas.drawArc(const Rect.fromLTWH(12, 12, 6, 8), math.pi / 2, math.pi / 2, false, stroke);
        break;
      case 'Pamuk':
        canvas.drawCircle(const Offset(9, 10), 3.5, stroke);
        canvas.drawCircle(const Offset(15, 10), 3.5, stroke);
        canvas.drawCircle(const Offset(12, 7), 3.5, stroke);
        canvas.drawCircle(const Offset(12, 13), 3.5, stroke);
        Path calyx = Path()..moveTo(9, 15)..lineTo(12, 19)..lineTo(15, 15)..close();
        canvas.drawPath(calyx, fill);
        canvas.drawLine(const Offset(12, 19), const Offset(12, 22), stroke);
        break;
      case 'Safran':
        canvas.drawOval(const Rect.fromLTWH(8, 12, 8, 8), stroke);
        canvas.drawLine(const Offset(10, 12), const Offset(8, 4), stroke);
        canvas.drawLine(const Offset(12, 12), const Offset(12, 3), stroke);
        canvas.drawLine(const Offset(14, 12), const Offset(16, 4), stroke);
        canvas.drawCircle(const Offset(8, 4), 1.5, fill);
        canvas.drawCircle(const Offset(12, 3), 1.5, fill);
        canvas.drawCircle(const Offset(16, 4), 1.5, fill);
        break;
      case 'Hibrit Tohum':
        Path seed = Path()..moveTo(12, 18)..quadraticBezierTo(6, 18, 8, 11)..quadraticBezierTo(12, 6, 12, 6)..quadraticBezierTo(12, 6, 16, 11)..quadraticBezierTo(18, 18, 12, 18)..close();
        canvas.drawPath(seed, stroke);
        canvas.drawCircle(const Offset(12, 14), 2.5, fill);
        canvas.drawLine(const Offset(12, 6), const Offset(12, 3), stroke);
        break;

      // 4. SÜT ÜRÜNLERİ FABRİKASI
      case 'Süt':
        Path carton = Path()..moveTo(8, 21)..lineTo(16, 21)..lineTo(16, 9)..lineTo(12, 4)..lineTo(8, 9)..close();
        canvas.drawPath(carton, stroke);
        canvas.drawLine(const Offset(8, 9), const Offset(16, 9), stroke);
        canvas.drawCircle(const Offset(12, 15), 1.8, fill);
        break;
      case 'Yoğurt':
        Path bowl = Path()..moveTo(4, 8)..lineTo(20, 8)..lineTo(17, 19)..lineTo(7, 19)..close();
        canvas.drawPath(bowl, stroke);
        canvas.drawLine(const Offset(3, 8), const Offset(21, 8), stroke);
        canvas.drawLine(const Offset(12, 4), const Offset(15, 12), stroke);
        break;
      case 'Tereyağ':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, 17, 20, 3), const Radius.circular(1.5)), stroke);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 9, 14, 8), const Radius.circular(2)), fill);
        canvas.drawLine(const Offset(8, 11), const Offset(16, 11), stroke);
        break;
      case 'Arı Sütü':
        Path hex = Path()..moveTo(12, 4)..lineTo(18, 8)..lineTo(18, 16)..lineTo(12, 20)..lineTo(6, 16)..lineTo(6, 8)..close();
        canvas.drawPath(hex, stroke);
        Path drop = Path()..moveTo(12, 8)..quadraticBezierTo(9, 14, 12, 16)..quadraticBezierTo(15, 14, 12, 8)..close();
        canvas.drawPath(drop, fill);
        break;
      case 'Pule Peyniri':
        Path cheese = Path()..moveTo(3, 17)..lineTo(20, 17)..lineTo(15, 7)..lineTo(5, 7)..close();
        canvas.drawPath(cheese, stroke);
        canvas.drawCircle(const Offset(9, 13), 1.5, fill);
        canvas.drawCircle(const Offset(14, 14), 1.2, fill);
        canvas.drawCircle(const Offset(12, 10), 1.0, fill);
        canvas.drawLine(const Offset(15, 7), const Offset(20, 17), stroke);
        break;

      // 5. MEZBAHA TESİSİ
      case 'Sosis':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 8, 7, 12), const Radius.circular(3.5)), stroke);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(13, 8, 7, 12), const Radius.circular(3.5)), stroke);
        canvas.drawLine(const Offset(11, 14), const Offset(13, 14), stroke);
        canvas.drawLine(const Offset(7.5, 5), const Offset(7.5, 8), stroke);
        break;
      case 'Tavuk':
        Path leg = Path()..moveTo(16, 6)..lineTo(12, 10)..quadraticBezierTo(4, 12, 6, 18)..quadraticBezierTo(12, 20, 14, 12)..lineTo(18, 8)..close();
        canvas.drawPath(leg, stroke);
        canvas.drawCircle(const Offset(17, 5), 1.5, fill);
        canvas.drawCircle(const Offset(19, 7), 1.5, fill);
        break;
      case 'Kebap':
        canvas.drawLine(const Offset(12, 2), const Offset(12, 22), stroke);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 6, 8, 4), const Radius.circular(1)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 11, 8, 4), const Radius.circular(1)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 16, 8, 4), const Radius.circular(1)), fill);
        break;
      case 'Timsah Derisi':
        Path skin = Path()..moveTo(4, 4)..quadraticBezierTo(12, 10, 20, 4)..lineTo(18, 20)..quadraticBezierTo(12, 14, 6, 20)..close();
        canvas.drawPath(skin, stroke);
        canvas.drawCircle(const Offset(12, 8), 1, fill);
        canvas.drawCircle(const Offset(10, 12), 1, fill);
        canvas.drawCircle(const Offset(14, 12), 1, fill);
        canvas.drawCircle(const Offset(12, 16), 1, fill);
        break;
      case 'Wagyu Eti':
        Path meat = Path()..moveTo(5, 8)..quadraticBezierTo(12, 2, 19, 8)..quadraticBezierTo(22, 15, 17, 19)..quadraticBezierTo(12, 22, 7, 19)..quadraticBezierTo(2, 15, 5, 8)..close();
        canvas.drawPath(meat, stroke);
        canvas.drawLine(const Offset(8, 8), const Offset(14, 18), stroke);
        canvas.drawLine(const Offset(14, 8), const Offset(9, 15), stroke);
        canvas.drawLine(const Offset(16, 12), const Offset(12, 15), stroke);
        break;

      // 6. GIDA İŞLEME
      case 'Un':
        Path bag = Path()..moveTo(6, 20)..lineTo(18, 20)..lineTo(16, 8)..lineTo(14, 5)..lineTo(10, 5)..lineTo(8, 8)..close();
        canvas.drawPath(bag, stroke);
        canvas.drawLine(const Offset(8, 8), const Offset(16, 8), stroke);
        canvas.drawCircle(const Offset(12, 14), 2.5, fill);
        break;
      case 'Şeker':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 10, 8, 8), const Radius.circular(2)), stroke);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, 10, 8, 8), const Radius.circular(2)), stroke);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 4, 8, 8), const Radius.circular(2)), stroke);
        break;
      case 'Konserve':
        canvas.drawOval(const Rect.fromLTWH(5, 3, 14, 5), stroke);
        Path can = Path()..moveTo(5, 5)..lineTo(5, 18)..quadraticBezierTo(12, 22, 19, 18)..lineTo(19, 5)..close();
        canvas.drawPath(can, stroke);
        canvas.drawLine(const Offset(5, 10), const Offset(19, 10), stroke);
        canvas.drawLine(const Offset(5, 15), const Offset(19, 15), stroke);
        break;
      case 'Havyar':
        canvas.drawOval(const Rect.fromLTWH(4, 12, 16, 8), stroke);
        canvas.drawPath(Path()..moveTo(4, 16)..lineTo(4, 8)..quadraticBezierTo(12, 4, 20, 8)..lineTo(20, 16), stroke);
        canvas.drawCircle(const Offset(9, 10), 1.2, fill);
        canvas.drawCircle(const Offset(12, 12), 1.2, fill);
        canvas.drawCircle(const Offset(15, 10), 1.2, fill);
        break;
      case 'Gurme Çikolata':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 4, 14, 16), const Radius.circular(2)), stroke);
        canvas.drawLine(const Offset(12, 4), const Offset(12, 20), stroke);
        canvas.drawLine(const Offset(5, 9), const Offset(19, 9), stroke);
        canvas.drawLine(const Offset(5, 15), const Offset(19, 15), stroke);
        break;

      // 7. MADEN ÇIKARMA
      case 'Kömür':
        Path coal = Path()..moveTo(6, 18)..lineTo(4, 12)..lineTo(8, 7)..lineTo(15, 6)..lineTo(20, 11)..lineTo(18, 18)..close();
        canvas.drawPath(coal, fill);
        canvas.drawLine(const Offset(8, 7), const Offset(12, 13), stroke);
        break;
      case 'Demir':
        Path anvil = Path()..moveTo(4, 7)..lineTo(20, 7)..lineTo(18, 12)..lineTo(14, 12)..lineTo(15, 18)..lineTo(9, 18)..lineTo(10, 12)..lineTo(7, 12)..close();
        canvas.drawPath(anvil, fill);
        break;
      case 'Gümüş':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 10, 14, 8), const Radius.circular(2)), stroke);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7, 6, 14, 8), const Radius.circular(2)), stroke);
        break;
      case 'Altın':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 13, 16, 6), const Radius.circular(2)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7, 6, 10, 6), const Radius.circular(2)), stroke);
        break;
      case 'Elmas':
        Path diamond = Path()..moveTo(7, 6)..lineTo(17, 6)..lineTo(21, 11)..lineTo(12, 20)..lineTo(3, 11)..close();
        canvas.drawPath(diamond, stroke);
        canvas.drawLine(const Offset(7, 6), const Offset(12, 20), stroke);
        canvas.drawLine(const Offset(17, 6), const Offset(12, 20), stroke);
        canvas.drawLine(const Offset(3, 11), const Offset(21, 11), stroke);
        break;

      // 8. KİMYA TESİSLERİ
      case 'Gübre':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 5, 14, 15), const Radius.circular(3)), stroke);
        canvas.drawCircle(const Offset(12, 12), 3, fill);
        canvas.drawCircle(const Offset(10, 15), 1, fill);
        canvas.drawCircle(const Offset(14, 15), 1, fill);
        break;
      case 'Plastik':
        canvas.drawCircle(const Offset(12, 7), 2.5, stroke);
        canvas.drawCircle(const Offset(7, 16), 2.5, stroke);
        canvas.drawCircle(const Offset(17, 16), 2.5, stroke);
        canvas.drawLine(const Offset(11, 9), const Offset(8, 14), stroke);
        canvas.drawLine(const Offset(13, 9), const Offset(16, 14), stroke);
        canvas.drawLine(const Offset(9, 16), const Offset(15, 16), stroke);
        break;
      case 'Boya':
        Path bucket = Path()..moveTo(5, 7)..lineTo(19, 7)..lineTo(16, 20)..lineTo(8, 20)..close();
        canvas.drawPath(bucket, stroke);
        canvas.drawArc(const Rect.fromLTWH(4, 3, 16, 8), math.pi, math.pi, false, stroke);
        Path drip = Path()..moveTo(12, 7)..lineTo(12, 13)..quadraticBezierTo(13, 14, 14, 13)..lineTo(14, 7);
        canvas.drawPath(drip, fill);
        break;
      case 'Lüks Parfüm':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 10, 12, 10), const Radius.circular(2)), stroke);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, 4, 6, 6), const Radius.circular(1)), fill);
        canvas.drawLine(const Offset(12, 10), const Offset(12, 18), stroke);
        break;
      case 'Karbonfiber':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 4, 16, 16), const Radius.circular(2)), stroke);
        for(int i = 8; i < 20; i+=4) {
          canvas.drawLine(Offset(4, i.toDouble()), Offset(20, i.toDouble()), stroke);
          canvas.drawLine(Offset(i.toDouble(), 4), Offset(i.toDouble(), 20), stroke);
        }
        break;

      // 9. OTOMOBİL FABRİKASI
      case 'Lastik':
        canvas.drawCircle(const Offset(12, 12), 9, stroke);
        canvas.drawCircle(const Offset(12, 12), 4.5, stroke);
        canvas.drawCircle(const Offset(12, 12), 1.5, fill);
        break;
      case 'Motorsiklet':
        canvas.drawCircle(const Offset(6, 16), 4, stroke);
        canvas.drawCircle(const Offset(18, 16), 4, stroke);
        canvas.drawLine(const Offset(6, 16), const Offset(10, 10), stroke);
        canvas.drawLine(const Offset(18, 16), const Offset(14, 10), stroke);
        canvas.drawLine(const Offset(10, 10), const Offset(14, 10), stroke);
        canvas.drawLine(const Offset(14, 10), const Offset(12, 6), stroke);
        break;
      case 'Otomobil':
        Path car = Path()..moveTo(3, 14)..lineTo(5, 11)..lineTo(8, 8)..lineTo(15, 8)..lineTo(18, 11)..lineTo(21, 12)..lineTo(21, 16)..lineTo(3, 16)..close();
        canvas.drawPath(car, stroke);
        canvas.drawCircle(const Offset(7, 16), 2.2, fill);
        canvas.drawCircle(const Offset(17, 16), 2.2, fill);
        break;
      case 'Vip Limuzin':
        Path limo = Path()..moveTo(2, 14)..lineTo(4, 11)..lineTo(7, 8)..lineTo(18, 8)..lineTo(20, 11)..lineTo(22, 12)..lineTo(22, 16)..lineTo(2, 16)..close();
        canvas.drawPath(limo, stroke);
        canvas.drawCircle(const Offset(6, 16), 2.2, fill);
        canvas.drawCircle(const Offset(18, 16), 2.2, fill);
        canvas.drawLine(const Offset(10, 8), const Offset(10, 16), stroke);
        canvas.drawLine(const Offset(14, 8), const Offset(14, 16), stroke);
        break;
      case 'Süper Spor Araç':
        Path sport = Path()..moveTo(2, 15)..lineTo(5, 11)..lineTo(10, 8)..lineTo(17, 8)..lineTo(21, 11)..lineTo(22, 15)..lineTo(2, 15)..close();
        canvas.drawPath(sport, stroke);
        canvas.drawLine(const Offset(20, 10), const Offset(22, 8), stroke);
        canvas.drawCircle(const Offset(6, 15), 2.2, fill);
        canvas.drawCircle(const Offset(17, 15), 2.2, fill);
        break;

      // 10. İLAÇ FABRİKASI
      case 'Vitamin Hapı':
        canvas.drawOval(const Rect.fromLTWH(6, 4, 12, 16), stroke);
        canvas.drawLine(const Offset(6, 12), const Offset(18, 12), stroke);
        break;
      case 'Ağrı Kesici':
        canvas.drawCircle(const Offset(12, 12), 7, stroke);
        canvas.drawLine(const Offset(8, 12), const Offset(16, 12), stroke);
        break;
      case 'Antibiyotik':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 8, 14, 8), const Radius.circular(4)), stroke);
        canvas.drawLine(const Offset(12, 8), const Offset(12, 16), stroke);
        canvas.drawCircle(const Offset(9, 12), 1.5, fill);
        break;
      case 'Covi-19 Aşısı':
        canvas.drawLine(const Offset(7, 17), const Offset(16, 8), stroke);
        canvas.drawRect(const Rect.fromLTWH(10, 9, 5, 5), fill);
        canvas.drawLine(const Offset(16, 8), const Offset(19, 5), stroke);
        canvas.drawLine(const Offset(7, 17), const Offset(4, 20), stroke);
        break;
      case 'Kanser İlacı':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 4, 12, 14), const Radius.circular(3)), stroke);
        canvas.drawLine(const Offset(12, 18), const Offset(12, 22), stroke);
        canvas.drawLine(const Offset(10, 4), const Offset(14, 4), stroke);
        canvas.drawRect(const Rect.fromLTWH(8, 9, 8, 6), fill);
        break;

      // 11. ELEKTRONİK EŞYA
      case 'Hesap Makinesi':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 3, 14, 18), const Radius.circular(2)), stroke);
        canvas.drawRect(const Rect.fromLTWH(7, 5, 10, 4), fill);
        for(int x=7; x<=15; x+=4) {
          for(int y=11; y<=19; y+=4) {
            canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 2, 2), fill);
          }
        }
        break;
      case 'Telefon':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 3, 12, 18), const Radius.circular(3)), stroke);
        canvas.drawCircle(const Offset(12, 5.5), 0.8, fill);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 7, 8, 11), const Radius.circular(1)), fill);
        canvas.drawLine(const Offset(11, 19), const Offset(13, 19), stroke);
        break;
      case 'Televizyon':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 5, 18, 11), const Radius.circular(1)), stroke);
        canvas.drawLine(const Offset(12, 16), const Offset(12, 19), stroke);
        canvas.drawLine(const Offset(8, 19), const Offset(16, 19), stroke);
        canvas.drawRect(const Rect.fromLTWH(5, 7, 14, 7), fill);
        break;
      case 'İnsansız Hava Aracı':
        canvas.drawLine(const Offset(6, 6), const Offset(18, 18), stroke);
        canvas.drawLine(const Offset(6, 18), const Offset(18, 6), stroke);
        canvas.drawCircle(const Offset(6, 6), 2, stroke);
        canvas.drawCircle(const Offset(18, 18), 2, stroke);
        canvas.drawCircle(const Offset(6, 18), 2, stroke);
        canvas.drawCircle(const Offset(18, 6), 2, stroke);
        canvas.drawCircle(const Offset(12, 12), 2.5, fill);
        break;
      case 'Kuantum PC':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 4, 16, 16), const Radius.circular(3)), stroke);
        canvas.drawCircle(const Offset(12, 12), 4, fill);
        canvas.drawLine(const Offset(12, 4), const Offset(12, 8), stroke);
        canvas.drawLine(const Offset(12, 16), const Offset(12, 20), stroke);
        canvas.drawLine(const Offset(4, 12), const Offset(8, 12), stroke);
        canvas.drawLine(const Offset(16, 12), const Offset(20, 12), stroke);
        break;

      // 12. YAPAY ZEKA AR-GE
      case 'Sohbet Botu':
        Path bubble = Path()..moveTo(4, 12)..quadraticBezierTo(4, 4, 12, 4)..quadraticBezierTo(20, 4, 20, 12)..quadraticBezierTo(20, 20, 12, 20)..lineTo(6, 20)..lineTo(8, 16)..quadraticBezierTo(4, 15, 4, 12)..close();
        canvas.drawPath(bubble, stroke);
        canvas.drawCircle(const Offset(10, 10), 1.5, fill);
        canvas.drawCircle(const Offset(14, 10), 1.5, fill);
        break;
      case 'Satranç Botu':
        Path pawn = Path()..moveTo(12, 5)..arcTo(const Rect.fromLTWH(9, 2, 6, 6), 0, math.pi*2, false)..moveTo(10, 8)..lineTo(14, 8)..lineTo(15, 18)..lineTo(9, 18)..close();
        canvas.drawPath(pawn, stroke);
        canvas.drawLine(const Offset(7, 18), const Offset(17, 18), stroke);
        canvas.drawLine(const Offset(6, 20), const Offset(18, 20), stroke);
        break;
      case 'Görsel Oluşturma Botu':
        canvas.drawRect(const Rect.fromLTWH(4, 5, 16, 14), stroke);
        canvas.drawCircle(const Offset(9, 9), 2, fill);
        Path mountain = Path()..moveTo(4, 19)..lineTo(10, 12)..lineTo(14, 16)..lineTo(17, 13)..lineTo(20, 19)..close();
        canvas.drawPath(mountain, stroke);
        break;
      case 'Kodlama Botu':
        canvas.drawLine(const Offset(10, 6), const Offset(5, 12), stroke);
        canvas.drawLine(const Offset(5, 12), const Offset(10, 18), stroke);
        canvas.drawLine(const Offset(14, 6), const Offset(19, 12), stroke);
        canvas.drawLine(const Offset(19, 12), const Offset(14, 18), stroke);
        canvas.drawLine(const Offset(13, 5), const Offset(11, 19), stroke);
        break;
      case 'Humanoid Robot':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7, 8, 10, 9), const Radius.circular(2)), stroke);
        canvas.drawLine(const Offset(12, 8), const Offset(12, 3), stroke);
        canvas.drawCircle(const Offset(12, 3), 1.2, fill);
        canvas.drawCircle(const Offset(9.5, 11), 1.5, fill);
        canvas.drawCircle(const Offset(14.5, 11), 1.5, fill);
        canvas.drawLine(const Offset(9, 15), const Offset(15, 15), stroke);
        break;

      // 13. ENERJİ SANTRALİ
      case 'Güneş Paneli':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 3, 14, 18), const Radius.circular(2)), stroke);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7, 5, 10, 6), const Radius.circular(1)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7, 13, 10, 6), const Radius.circular(1)), fill);
        break;
      case 'Rüzgar Tribünü':
        canvas.drawLine(const Offset(12, 12), const Offset(12, 22), stroke);
        canvas.drawLine(const Offset(12, 12), const Offset(12, 4), stroke);
        canvas.drawLine(const Offset(12, 12), const Offset(6, 17), stroke);
        canvas.drawLine(const Offset(12, 12), const Offset(18, 17), stroke);
        canvas.drawCircle(const Offset(12, 12), 2, fill);
        break;
      case 'Nükleer Santral':
        canvas.drawCircle(const Offset(12, 12), 9, stroke);
        canvas.drawCircle(const Offset(12, 12), 5, stroke);
        canvas.drawCircle(const Offset(12, 12), 2, fill);
        canvas.drawLine(const Offset(12, 3), const Offset(12, 7), stroke);
        canvas.drawLine(const Offset(12, 17), const Offset(12, 21), stroke);
        canvas.drawLine(const Offset(3, 12), const Offset(7, 12), stroke);
        canvas.drawLine(const Offset(17, 12), const Offset(21, 12), stroke);
        break;
      case 'Parçacık Hızlandırıcı':
        canvas.drawCircle(const Offset(12, 12), 9, stroke);
        canvas.drawCircle(const Offset(12, 12), 6, stroke);
        canvas.drawLine(const Offset(12, 12), const Offset(16, 8), stroke);
        canvas.drawLine(const Offset(12, 12), const Offset(8, 16), stroke);
        canvas.drawCircle(const Offset(12, 12), 1.5, fill);
        canvas.drawCircle(const Offset(16, 8), 1.5, fill);
        canvas.drawCircle(const Offset(8, 16), 1.5, fill);
        break;
      case 'Füzyon Çekirdeği':
        canvas.drawCircle(const Offset(12, 12), 3, fill);
        canvas.drawCircle(const Offset(8, 10), 2.5, fill);
        canvas.drawCircle(const Offset(15, 10), 2.5, fill);
        canvas.drawCircle(const Offset(12, 16), 2.5, fill);
        break;

      // 14. BİYOTEKNOLOJİ
      case 'Kök Hücre':
        canvas.drawCircle(const Offset(12, 12), 9, stroke);
        canvas.drawCircle(const Offset(12, 12), 4, fill);
        canvas.drawCircle(const Offset(8, 9), 1, fill);
        canvas.drawCircle(const Offset(15, 15), 1, fill);
        break;
      case '3D Biyo-Yazıcı':
        canvas.drawRect(const Rect.fromLTWH(4, 4, 16, 16), stroke);
        canvas.drawRect(const Rect.fromLTWH(6, 6, 12, 12), stroke);
        canvas.drawLine(const Offset(12, 6), const Offset(12, 12), stroke);
        canvas.drawCircle(const Offset(12, 13), 1.5, fill);
        break;
      case 'Biyonik Organ':
        Path heart = Path()..moveTo(12, 8)..cubicTo(12, 4, 6, 4, 6, 9)..cubicTo(6, 14, 12, 19, 12, 20)..cubicTo(12, 19, 18, 14, 18, 9)..cubicTo(18, 4, 12, 4, 12, 8)..close();
        canvas.drawPath(heart, stroke);
        canvas.drawLine(const Offset(6, 12), const Offset(18, 12), stroke);
        canvas.drawLine(const Offset(9, 7), const Offset(9, 17), stroke);
        canvas.drawLine(const Offset(15, 7), const Offset(15, 17), stroke);
        break;
      case 'Biyoçip':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 6, 12, 12), const Radius.circular(2)), stroke);
        canvas.drawCircle(const Offset(12, 12), 3, fill);
        canvas.drawLine(const Offset(12, 3), const Offset(12, 6), stroke);
        canvas.drawLine(const Offset(12, 18), const Offset(12, 21), stroke);
        canvas.drawLine(const Offset(3, 12), const Offset(6, 12), stroke);
        canvas.drawLine(const Offset(18, 12), const Offset(21, 12), stroke);
        break;
      case 'Klon Canlı':
        for (int i = 0; i < 4; i++) {
          double y = 5.0 + (i * 4.2);
          canvas.drawLine(Offset(6, y), Offset(18, y), stroke);
          canvas.drawCircle(Offset(6, y), 1.5, fill);
          canvas.drawCircle(Offset(18, y), 1.5, fill);
        }
        break;

      // 15. UZAY SANAYİİ
      case 'Roket Motoru':
        Path engine = Path()..moveTo(8, 4)..lineTo(16, 4)..lineTo(14, 10)..lineTo(18, 16)..lineTo(6, 16)..lineTo(10, 10)..close();
        canvas.drawPath(engine, stroke);
        Path fire = Path()..moveTo(8, 16)..lineTo(12, 22)..lineTo(16, 16)..close();
        canvas.drawPath(fire, fill);
        break;
      case 'Uydu':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, 9, 6, 6), const Radius.circular(1)), fill);
        canvas.drawRect(const Rect.fromLTWH(2, 10, 6, 4), stroke);
        canvas.drawRect(const Rect.fromLTWH(16, 10, 6, 4), stroke);
        canvas.drawLine(const Offset(12, 9), const Offset(12, 4), stroke);
        canvas.drawCircle(const Offset(12, 4), 1.5, stroke);
        break;
      case 'Uzay Mekiği':
        Path shuttle = Path()..moveTo(12, 2)..quadraticBezierTo(16, 8, 16, 16)..lineTo(8, 16)..quadraticBezierTo(8, 8, 12, 2)..close();
        canvas.drawPath(shuttle, stroke);
        canvas.drawCircle(const Offset(12, 9), 1.8, fill);
        Path finL = Path()..moveTo(8, 14)..lineTo(4, 18)..lineTo(8, 18)..close();
        Path finR = Path()..moveTo(16, 14)..lineTo(20, 18)..lineTo(16, 18)..close();
        canvas.drawPath(finL, fill);
        canvas.drawPath(finR, fill);
        Path flame = Path()..moveTo(10, 16)..lineTo(12, 21)..lineTo(14, 16)..close();
        canvas.drawPath(flame, fill);
        break;
      case 'Ay İniş Aracı':
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 8, 12, 6), const Radius.circular(2)), fill);
        canvas.drawLine(const Offset(8, 8), const Offset(8, 3), stroke);
        canvas.drawCircle(const Offset(8, 3), 1.5, fill);
        canvas.drawCircle(const Offset(6, 17), 2, stroke);
        canvas.drawCircle(const Offset(12, 17), 2, stroke);
        canvas.drawCircle(const Offset(18, 17), 2, stroke);
        break;
      case 'Yıldız Gemisi':
        canvas.drawCircle(const Offset(12, 12), 9, stroke);
        canvas.drawCircle(const Offset(12, 12), 5, stroke);
        canvas.drawCircle(const Offset(12, 12), 2, fill);
        Path hyper = Path()..moveTo(12, 3)..lineTo(12, 21);
        canvas.drawPath(hyper, stroke);
        break;

      default:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 4, 16, 16), const Radius.circular(3)), stroke);
        canvas.drawCircle(const Offset(12, 12), 3, fill);
        break;
    }

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
          height: MediaQuery.of(context).size.height * 0.84, 
          decoration: BoxDecoration(
            color: AppColors.surface, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -6)),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.factory_rounded, color: AppColors.gold, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentFac.name.toUpperCase(), 
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: AppTheme.titleStyle(fontSize: 15).copyWith(color: AppColors.textPrimary, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Aşama ${currentFac.currentStage + 1}  •  Tesis: ${currentFac.totalLevel}/300', 
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, color: AppColors.gold, size: 13),
                            const SizedBox(width: 5),
                            Flexible(
                              child: AnimatedMoneyText(money: gameState.money, formatNum: widget.formatNum, style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.darkBrown,
                    unselectedLabelColor: AppColors.textMuted,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bolt_rounded, size: 15), SizedBox(width: 4), Flexible(child: Text("ÜRETİM BANDI", overflow: TextOverflow.ellipsis))])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.upgrade_rounded, size: 15), SizedBox(width: 4), Flexible(child: Text("TESİS GELİŞTİRME", overflow: TextOverflow.ellipsis))])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: currentFac.products.length, 
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final prod = currentFac.products[index];
                        bool canUnlock = index == 0 || currentFac.products[index - 1].level >= 10;

                        if (!canUnlock) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(prod.name, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      const Text('Önceki bandı Seviye 10 yapın', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: canAfford ? AppColors.gold.withValues(alpha: 0.5) : AppColors.border,
                              width: canAfford ? 1.4 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 38, height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: canAfford ? AppColors.gold.withValues(alpha: 0.6) : AppColors.border,
                                      ),
                                    ),
                                    child: Center(
                                      child: ProductSvgIcon(
                                        name: prod.name,
                                        size: 20,
                                        color: canAfford ? AppColors.gold : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(prod.name, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6,
                                          runSpacing: 2,
                                          children: [
                                            Text(
                                              'Lvl ${prod.level}/60',
                                              style: TextStyle(
                                                color: isMax ? AppColors.profit : AppColors.gold,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'SpaceMono',
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.border),
                                              ),
                                              child: Text(
                                                '+\$${widget.formatNum(prod.passiveIncome)}/s',
                                                style: const TextStyle(color: AppColors.profit, fontSize: 9.5, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(minWidth: 70),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isMax
                                            ? AppColors.background
                                            : (canAfford ? AppColors.gold : AppColors.background),
                                        foregroundColor: isMax || !canAfford ? AppColors.textMuted : AppColors.darkBrown,
                                        side: BorderSide(color: isMax ? AppColors.border : (canAfford ? Colors.transparent : AppColors.border)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        elevation: 0,
                                      ),
                                      onPressed: isMax || !canAfford 
                                          ? null 
                                          : () {
                                              HapticFeedback.lightImpact();
                                              AudioService.instance.playSfx('cash.mp3');
                                              gameState.upgradeProduct(currentFac.id, index);
                                            },
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isMax ? 'MAKS' : 'GELİŞTİR',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                          ),
                                          if (!isMax) ...[
                                            const SizedBox(height: 1),
                                            Text(
                                              '\$${widget.formatNum(cost)}',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'SpaceMono',
                                                color: canAfford ? AppColors.darkBrown : AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: progressRatio,
                                  minHeight: 3.5,
                                  backgroundColor: AppColors.background,
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
    
    setState(() {
      _activeItems.add(currentId);
      _floatingIncomes.add(FloatingIncomeData(
        id: currentId,
        text: '+\$${widget.formatNum(widget.product.manualIncome)}',
      ));
    });

    Future.delayed(const Duration(milliseconds: 800), () { 
      if (mounted) { 
        AudioService.instance.playSfx('cash.mp3'); 
        widget.onProduceComplete(); 
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Lvl ${widget.product.level}',
                  style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.product.name, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.profit.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded, color: AppColors.profit, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '+\$${widget.formatNum(widget.product.manualIncome)}', 
                      style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'SpaceMono'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          LayoutBuilder(
            builder: (context, constraints) {
              final double btnWidth = constraints.maxWidth < 340 ? 76.0 : 86.0;
              final double outWidth = constraints.maxWidth < 340 ? 40.0 : 46.0;

              return SizedBox(
                height: 56,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 1.2),
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
                                      width: 2.5, height: 22,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 12, left: 0, right: 0,
                                  child: Container(height: 1.5, color: AppColors.border),
                                ),
                                Positioned(
                                  bottom: 12, left: 0, right: 0,
                                  child: Container(height: 1.5, color: AppColors.border),
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
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(9)),
                              border: Border(left: BorderSide(color: AppColors.border, width: 1.2)),
                            ),
                            child: Center(
                              child: ProductSvgIcon(
                                name: widget.product.name,
                                size: 18,
                                color: AppColors.gold.withValues(alpha: 0.7),
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
                        child: GoldProduceButton(
                          onTap: _startProduction,
                        ),
                      ),
                    ),

                    ..._floatingIncomes.map((item) => Positioned(
                      left: 18,
                      bottom: 22,
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

class GoldProduceButton extends StatefulWidget {
  final VoidCallback onTap;
  const GoldProduceButton({super.key, required this.onTap});

  @override 
  State<GoldProduceButton> createState() => _GoldProduceButtonState();
}

class _GoldProduceButtonState extends State<GoldProduceButton> {
  bool _isPressed = false;

  @override 
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact(); 
        AudioService.instance.playSfx('click.mp3');
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        margin: EdgeInsets.only(top: _isPressed ? 3.0 : 0.0, bottom: _isPressed ? 0.0 : 3.0),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, color: AppColors.darkBrown, size: 16),
              SizedBox(width: 3),
              Flexible(
                child: Text(
                  'ÜRET',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.darkBrown,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
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
        width: 26, height: 26, 
        margin: const EdgeInsets.symmetric(horizontal: 4), 
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.gold, width: 1.3),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ), 
        child: Center(
          child: ProductSvgIcon(
            name: widget.productName,
            size: 15,
            color: AppColors.gold,
          ),
        ),
      ),
    ); 
  }
}

class FloatingIncomeData {
  final int id;
  final String text;
  FloatingIncomeData({required this.id, required this.text});
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

    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0.2, -1.6)).animate(
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'SpaceMono',
            shadows: [
              Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1)),
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
    canvas.drawCircle(Offset(size.x/2, size.y/2), 35, Paint()..color=Colors.yellow.withValues(alpha: 0.3)..maskFilter=const MaskFilter.blur(BlurStyle.normal, 15));
    Path bag = Path()..moveTo(size.x/2 - 15, size.y/2 + 25)..quadraticBezierTo(size.x/2 - 35, size.y/2 + 25, size.x/2 - 30, size.y/2)..quadraticBezierTo(size.x/2 - 25, size.y/2 - 20, size.x/2 - 10, size.y/2 - 20)..lineTo(size.x/2 + 10, size.y/2 - 20)..quadraticBezierTo(size.x/2 + 25, size.y/2 - 20, size.x/2 + 30, size.y/2)..quadraticBezierTo(size.x/2 + 35, size.y/2 + 25, size.x/2 + 15, size.y/2 + 25)..close();
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
  final String factoryId; final Function(String) onTap; FactoryData? _data;
  FactoryPlotComponent({required this.factoryId, required Vector2 position, required this.onTap}) : super(position: position, size: Vector2(170, 170), anchor: Anchor.center);
  
  void updateData(FactoryData data) { _data = data; } 
  
  @override void onTapUp(TapUpEvent event) { onTap(factoryId); }
  
  @override void render(Canvas canvas) {
    if (_data == null) {
      return; 
    }
    if (!_data!.isUnlocked) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, size.x-20, size.y-20), const Radius.circular(10)), Paint()..color = const Color(0xFF1E2128).withValues(alpha: 0.8)..style=PaintingStyle.fill);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, size.x-20, size.y-20), const Radius.circular(10)), Paint()..color = const Color(0xFF383E4C)..style=PaintingStyle.stroke..strokeWidth=2);
      final iconPainter = TextPainter(textDirection: TextDirection.ltr)..text = TextSpan(text: String.fromCharCode(Icons.lock_rounded.codePoint), style: TextStyle(fontSize: 32, fontFamily: Icons.lock_rounded.fontFamily, color: const Color(0xFF94A3B8)))..layout(); 
      iconPainter.paint(canvas, Offset(size.x/2 - 16, size.y/2 - 16));
    } else {
      canvas.drawRect(Rect.fromLTWH(size.x/2 - 50, size.y/2 - 30, 100, 60), Paint()..color = const Color(0xFF2D3748));
      canvas.drawPath(Path()..moveTo(size.x/2 - 58, size.y/2 - 30)..lineTo(size.x/2, size.y/2 - 60)..lineTo(size.x/2 + 58, size.y/2 - 30)..close(), Paint()..color = const Color(0xFF4A5568));
      final textPainter = TextPainter(text: TextSpan(text: 'Lvl ${_data!.totalLevel}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, backgroundColor: Colors.black87)), textDirection: TextDirection.ltr)..layout();
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
    Duration duration = const Duration(milliseconds: 500),
  }) : super(duration: duration);

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