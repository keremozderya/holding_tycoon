// lib/screens/map_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
    if (state.offlineEarningsToClaim > 0) {
      _showOfflineEarningsDialog(state);
    }
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
            Text('Kazanılan: \$${_formatNum(state.offlineEarningsToClaim)}', style: const TextStyle(color: AppColors.profit, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () { 
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
    final gameState = context.read<GameState>();
    final fac = gameState.factories.firstWhere((f) => f.id == factoryId);
    if (!fac.isUnlocked) {
      _showPurchaseDialog(fac); 
    } else {
      _showFactoryInsideSheet(fac);
    }
  }

  void _handleBagTapped(double reward) {
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
              Text('\$${_formatNum(finalPrice)}', style: const TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('İPTAL', style: TextStyle(color: AppColors.textMuted))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkBrown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                if (state.money >= finalPrice) { 
                  state.unlockFactory(fac.id); 
                  Navigator.pop(context); 
                } else { 
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
      context: context, backgroundColor: AppColors.background, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => FactoryInsideModal(factoryId: fac.id, formatNum: _formatNum),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    _game.updateState(gameState);

    final ev = gameState.consumeUnhandledEvent();
    if (ev != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bool isCrisis = ev.preventCost > 0;
        bool canAffordPrevent = gameState.money >= ev.preventCost;
        
        showDialog(
          context: context, barrierDismissible: false,
          builder: (c) => AlertDialog(
            backgroundColor: AppColors.surface, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isCrisis ? AppColors.loss : AppColors.profit, width: 1.5)),
            title: Row(
              children: [
                Icon(isCrisis ? Icons.warning_rounded : Icons.info_outline_rounded, color: isCrisis ? AppColors.loss : AppColors.profit, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(ev.title, style: AppTheme.titleStyle(fontSize: 16).copyWith(color: isCrisis ? AppColors.loss : AppColors.profit))),
              ],
            ),
            content: Text(ev.description, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              if (isCrisis) 
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.background, foregroundColor: canAffordPrevent ? AppColors.textPrimary : AppColors.textMuted, side: BorderSide(color: canAffordPrevent ? AppColors.border : Colors.transparent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: canAffordPrevent ? () { 
                    gameState.resolveEvent(true, ev); 
                    Navigator.pop(c); 
                  } : null, 
                  child: Text('ÖNLE (\$${_formatNum(ev.preventCost)})', style: const TextStyle(fontSize: 11)),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: isCrisis ? AppColors.loss : AppColors.profit, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () { 
                  gameState.resolveEvent(false, ev); 
                  Navigator.pop(c); 
                }, 
                child: Text(isCrisis ? 'KATLAN' : 'KABUL ET', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        );
      });
    }

    final bagReward = gameState.consumeUnhandledBagReward();
    if (bagReward > 0) {
      _game.spawnFlyingBag(bagReward);
    }

    return Scaffold(
      // DÜZELTME: Mat okyanus rengi yerine, canlı okyanus mavisini geri yükledik!
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
                          Text('\$ ${_formatNum(gameState.money)}', style: const TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'SpaceMono')),
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
                        InkWell(
                          onTap: () => showDialog(
                            context: context, 
                            builder: (c) => AlertDialog(
                              backgroundColor: AppColors.surface, 
                              title: const Text('VERGİ TAHAKKUKU', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)), 
                              content: Column(
                                mainAxisSize: MainAxisSize.min, 
                                children: [
                                  Text('Borç: \$${_formatNum(gameState.currentTaxDebt)}', style: const TextStyle(color: AppColors.loss, fontSize: 18, fontWeight: FontWeight.bold)), 
                                  const SizedBox(height: 10), 
                                  Text(gameState.isUnderPenalty ? 'HACİZ SÜRECİ BAŞLADI!' : 'Ödeme için son 12 saat.', style: TextStyle(color: gameState.isUnderPenalty ? AppColors.loss : AppColors.textSecondary, fontSize: 12)),
                                ],
                              ), 
                              actionsAlignment: MainAxisAlignment.center, 
                              actions: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.background, foregroundColor: AppColors.textPrimary), 
                                  onPressed: gameState.money >= gameState.currentTaxDebt ? () { 
                                    gameState.payTax(); 
                                    Navigator.pop(c); 
                                  } : null, 
                                  child: const Text('ÖDE')
                                ), 
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkBrown), 
                                  onPressed: () { 
                                    AdMobService.showRewardedAd(
                                      context: context, 
                                      onRewardEarned: () { 
                                        gameState.incrementAdsWatched(); 
                                        gameState.applyTaxAmnesty(); 
                                        Navigator.pop(c); 
                                      }
                                    ); 
                                  }, 
                                  child: const Text('VERGİ AFFI')
                                ),
                              ],
                            ),
                          ), 
                          child: Icon(Icons.warning_amber_rounded, color: gameState.isUnderPenalty ? AppColors.loss : AppColors.gold, size: 24),
                        ),
                      const SizedBox(width: 8),
                      Theme(
                        data: Theme.of(context).copyWith(popupMenuTheme: PopupMenuThemeData(color: AppColors.surfaceElevated, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.border)))), 
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.menu_rounded, size: 24, color: AppColors.textPrimary), offset: const Offset(0, 40), 
                          onSelected: (value) { 
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
              if (gameState.isBoostActive || gameState.isEventActive) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (gameState.isBoostActive)
                      Container(
                        margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.gold.withValues(alpha: 0.5))),
                        child: Row(children: [const Icon(Icons.electric_bolt_rounded, color: AppColors.gold, size: 12), const SizedBox(width: 4), Text('2X (${gameState.boostTimeLeft})', style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold))]),
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
            _buildPremiumTab("Ar-Ge", Icons.science_rounded, () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ResearchScreen()))),
            Container(width: 1, height: 24, color: AppColors.border),
            _buildPremiumTab("Borsa", Icons.candlestick_chart_rounded, () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StockScreen()))),
            Container(width: 1, height: 24, color: AppColors.border),
            _buildPremiumTab("Yazıhane", Icons.business_rounded, () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OfficeScreen()))),
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
            AdMobService.showRewardedAd(
              context: context, 
              onRewardEarned: () { 
                state.incrementAdsWatched(); 
                state.activate2xBoost(); 
              }
            ); 
          }
        ),
        const SizedBox(height: 12),
        AnimatedSideButton(icon: Icons.pie_chart_rounded, onTap: () { WheelDialog.show(context); }),
        const SizedBox(height: 12),
        AnimatedSideButton(icon: Icons.emoji_events_rounded, onTap: () => AchievementsDialog.show(context)),
        const SizedBox(height: 12),
        AnimatedSideButton(icon: Icons.checklist_rounded, onTap: () => TasksDialog.show(context)),
        const SizedBox(height: 12),
        AnimatedSideButton(
          icon: Icons.diamond_rounded, 
          onTap: () { 
            PrestigeDialog.show(context, currentTurnover: state.money, onPrestigeConfirmed: () { 
              state.executePrestige((state.money/1e20).floor()); 
            }); 
          }
        ),
      ],
    );
  }
}

class AnimatedSideButton extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const AnimatedSideButton({super.key, required this.icon, required this.onTap});

  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40, 
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border, width: 1.5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]), 
        child: Center(child: Icon(icon, size: 20, color: AppColors.gold)),
      ),
    );
  }
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
          height: MediaQuery.of(context).size.height * 0.8, padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Text(currentFac.name.toUpperCase(), style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.textPrimary)),
              Text('Aşama: ${currentFac.currentStage} | Tesis Seviyesi: ${currentFac.totalLevel}/300', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController, indicatorColor: AppColors.gold, labelColor: AppColors.gold, unselectedLabelColor: AppColors.textMuted, dividerColor: AppColors.border, labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5), 
                tabs: const [Tab(text: "ÜRETİM BANDI"), Tab(text: "TESİS GELİŞTİRME")]
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ListView.separated(
                      itemCount: currentFac.products.length, separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final prod = currentFac.products[index];
                        if (prod.level == 0) {
                          return const SizedBox.shrink(); 
                        }
                        return ProductionLineWidget(product: prod, formatNum: widget.formatNum, onProduceComplete: () => gameState.completeManualProduction(currentFac.id, index));
                      },
                    ),
                    ListView.separated(
                      itemCount: currentFac.products.length, separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final prod = currentFac.products[index];
                        bool canUnlock = index == 0 || currentFac.products[index - 1].level >= 10;
                        if (!canUnlock) {
                          return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Row(children: const [Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 18), SizedBox(width: 12), Text('Önceki bandı Lvl 10 yapın', style: TextStyle(color: AppColors.textMuted, fontSize: 12))]));
                        }

                        double cost = prod.upgradeCost; bool isMax = prod.level >= 60;
                        return Container(
                          padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                          child: Row(
                            children: [
                              Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.precision_manufacturing_rounded, color: AppColors.textSecondary, size: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(prod.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Seviye: ${prod.level}/60', style: const TextStyle(color: AppColors.gold, fontSize: 10)),
                                    Text('Kapasite: +\$${widget.formatNum(prod.passiveIncome)}/s', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: isMax ? AppColors.background : AppColors.gold, foregroundColor: isMax ? AppColors.textMuted : AppColors.darkBrown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                                onPressed: isMax || gameState.money < cost ? null : () => gameState.upgradeProduct(currentFac.id, index),
                                child: Text(isMax ? 'MAKS' : 'GELİŞTİR\n\$${widget.formatNum(cost)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
  final FactoryProduct product; final String Function(double) formatNum; final VoidCallback onProduceComplete;
  const ProductionLineWidget({super.key, required this.product, required this.formatNum, required this.onProduceComplete});
  @override State<ProductionLineWidget> createState() => _ProductionLineWidgetState();
}
class _ProductionLineWidgetState extends State<ProductionLineWidget> {
  final List<int> _activeItems = []; int _counter = 0;
  void _startProduction() {
    int currentId = _counter++; 
    setState(() { _activeItems.add(currentId); });
    Future.delayed(const Duration(milliseconds: 1500), () { 
      if (mounted) { 
        widget.onProduceComplete(); 
        setState(() { _activeItems.remove(currentId); }); 
      } 
    });
  }
  @override Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(widget.product.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)), Text('Kâr: +\$${widget.formatNum(widget.product.manualIncome)}', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.bold, fontSize: 11))]),
        const SizedBox(height: 6),
        Container(
          height: 48, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              InkWell(onTap: _startProduction, child: Container(width: 70, height: double.infinity, decoration: const BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.horizontal(left: Radius.circular(7)), border: Border(right: BorderSide(color: AppColors.border))), child: const Center(child: Text('ÜRET', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12))))),
              Expanded(child: Stack(alignment: Alignment.centerLeft, children: [Container(height: 2, width: double.infinity, color: AppColors.border), ..._activeItems.map((id) => BoxAnimator(key: ValueKey(id)))] )),
              Container(width: 48, height: double.infinity, decoration: const BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.horizontal(right: Radius.circular(7)), border: Border(left: BorderSide(color: AppColors.border))), child: const Icon(Icons.outbox_rounded, color: AppColors.textSecondary, size: 20)),
            ],
          ),
        ),
      ],
    );
  }
}

class BoxAnimator extends StatefulWidget { 
  const BoxAnimator({super.key}); 
  @override State<BoxAnimator> createState() => _BoxAnimatorState(); 
}
class _BoxAnimatorState extends State<BoxAnimator> {
  bool _started = false;
  @override void initState() { 
    super.initState(); 
    WidgetsBinding.instance.addPostFrameCallback((_) { 
      if (mounted) {
        setState(() { _started = true; }); 
      }
    }); 
  }
  @override Widget build(BuildContext context) { 
    return AnimatedAlign(duration: const Duration(milliseconds: 1500), alignment: _started ? Alignment.centerRight : Alignment.centerLeft, curve: Curves.linear, child: Container(width: 24, height: 24, margin: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.inventory_2_rounded, color: AppColors.darkBrown, size: 14))); 
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
  
  // DÜZELTME: Okyanusun canlı mavi rengi geri yüklendi!
  @override Color backgroundColor() => themeOceanBlue; 
  
  @override Future<void> onLoad() async {
    add(mapWorld);
    try {
      final mapSprite = await Sprite.load('map.png'); 
      mapHeight = mapWidth * (mapSprite.srcSize.y / mapSprite.srcSize.x);
      
      // Okyanus animasyonları eklendi
      mapWorld.add(OpenSeaRipples()); 
      mapWorld.add(CrashingWavesComponent(mapWidth: mapWidth, mapHeight: mapHeight)); 
      mapWorld.add(PerfectPngWaves(mapSprite: mapSprite, mapWidth: mapWidth, mapHeight: mapHeight)); 
      
      mapWorld.add(SpriteComponent(sprite: mapSprite, size: Vector2(mapWidth, mapHeight)));
      final List<Vector2> plotPositions = [Vector2(540, 420), Vector2(330, 520), Vector2(700, 560), Vector2(320, 720), Vector2(720, 750), Vector2(310, 930), Vector2(680, 950), Vector2(460, 1080), Vector2(650, 1180), Vector2(360, 1240), Vector2(530, 1280), Vector2(320, 1390), Vector2(500, 1440), Vector2(420, 1550)];
      for (int i = 0; i < 14; i++) {
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