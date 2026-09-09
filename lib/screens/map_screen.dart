// lib/screens/map_screen.dart
import 'dart:math' as math;
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
const Color themeAsphaltDark = Color(0xFF2D2D2D);
const Color themeLighthouseRed = Color(0xFFD64D4D);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override State<MapScreen> createState() => _MapScreenState();
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
    _game = HoldingTycoonGame(
      onFactoryTap: _handleFactoryTap,
      onBagTapped: _handleBagTapped,
    );
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
      _holdingName = prefs.getString('holding_name') ?? 'Köse Holding'; 
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
        backgroundColor: AppColors.background, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.profit, width: 3)),
        title: Text('Hoş Geldin Patron!', textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 22).copyWith(color: AppColors.profit)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.nightlight_round, size: 48, color: AppColors.profit), 
            const SizedBox(height: 16),
            const Text('Sen yokken fabrikalar çalışmaya devam etti.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 14)), 
            const SizedBox(height: 16),
            Text('Kazanılan: \$${_formatNum(state.offlineEarningsToClaim)}', style: const TextStyle(color: AppColors.profit, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { 
              state.claimOfflineEarnings(false); 
              Navigator.pop(context); 
            }, 
            child: const Text('Topla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkBrown),
            icon: const Icon(Icons.ondemand_video_rounded, size: 18),
            label: const Text('2X KATLA', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              AdMobService.showRewardedAd(
                context: context, 
                onRewardEarned: () {
                  state.incrementAdsWatched();
                  state.claimOfflineEarnings(true);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ],
      ),
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
        backgroundColor: AppColors.background, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.gold, width: 3)),
        title: Text('Para Çantası Yakalandı!', style: AppTheme.titleStyle(fontSize: 20).copyWith(color: AppColors.gold)),
        content: Text('İçinde \$${_formatNum(reward)} var. Reklam izleyerek bu parayı 3E KATLAYABİLİRSİN!', style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () { 
              state.claimBagReward(false, reward); 
              Navigator.pop(c); 
            }, 
            child: const Text('Normal Al', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkBrown), 
            icon: const Icon(Icons.ondemand_video_rounded, size: 18), 
            label: const Text('3X AL!'), 
            onPressed: () { 
              AdMobService.showRewardedAd(
                context: context, 
                onRewardEarned: () { 
                  state.incrementAdsWatched(); 
                  state.claimBagReward(true, reward); 
                  Navigator.pop(c); 
                },
              ); 
            },
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(FactoryData fac) {
    showDialog(
      context: context,
      builder: (context) {
        final state = context.read<GameState>();
        double finalPrice = fac.price;
        if (state.officeStaff.firstWhere((s) => s.id == 'staff_3').isHired) {
          finalPrice *= 0.90; 
        }

        return AlertDialog(
          backgroundColor: AppColors.background, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border, width: 3)),
          title: Text(fac.name, textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 22).copyWith(color: AppColors.gold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 48, color: AppColors.textMuted), 
              const SizedBox(height: 16),
              const Text('Bu arsayı satın alıp fabrikayı kurmak istiyor musun?', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 14)), 
              const SizedBox(height: 16),
              Text('Fiyat: \$${_formatNum(finalPrice)}', style: const TextStyle(color: AppColors.profit, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('İPTAL', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkBrown),
              onPressed: () {
                if (state.money >= finalPrice) { 
                  state.unlockFactory(fac.id); 
                  Navigator.pop(context); 
                } else { 
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yetersiz Bakiye!'), backgroundColor: AppColors.loss)); 
                  Navigator.pop(context); 
                }
              },
              child: const Text('SATIN AL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showFactoryInsideSheet(FactoryData fac) {
    showModalBottomSheet(
      context: context, 
      backgroundColor: AppColors.background, 
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => FactoryInsideModal(factoryId: fac.id, formatNum: _formatNum),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    _game.updateState(gameState);

    if (gameState.consumeUnhandledEvent() case var ev?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context, barrierDismissible: false,
          builder: (c) => AlertDialog(
            backgroundColor: AppColors.background, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: ev.preventCost > 0 ? AppColors.loss : AppColors.profit, width: 3)),
            title: Text(ev.title, style: AppTheme.titleStyle(fontSize: 20).copyWith(color: ev.preventCost > 0 ? AppColors.loss : AppColors.profit)),
            content: Text(ev.description, style: const TextStyle(color: Colors.white, fontSize: 14)),
            actions: [
              if (ev.preventCost > 0) 
                TextButton(
                  onPressed: () { 
                    gameState.resolveEvent(true, ev); 
                    Navigator.pop(c); 
                  }, 
                  child: Text('Önle (\$${_formatNum(ev.preventCost)})', style: const TextStyle(color: AppColors.gold)),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: ev.preventCost > 0 ? AppColors.loss : AppColors.profit, foregroundColor: Colors.white),
                onPressed: () { 
                  gameState.resolveEvent(false, ev); 
                  Navigator.pop(c); 
                }, 
                child: Text(ev.preventCost > 0 ? 'Kabul Et' : 'Harika!'),
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
      backgroundColor: themeOceanBlue,
      body: SafeArea(
        bottom: false, top: false, 
        child: Stack(
          children: [
            GameWidget(game: _game),
            Positioned(top: 0, left: 0, right: 0, child: _buildTopPanel(context, gameState)),
            Positioned(bottom: 0, left: 0, right: 0, child: _buildUnifiedBottomBar(context)),
            Positioned(right: 16, top: 140, child: _buildSideActionButtons(gameState)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPanel(BuildContext context, GameState gameState) {
    const Color classicBrown = Color(0xFF5D4037); 
    const Color lightBrown = Color(0xFF7A574A); 
    const Color darkBrown = Color(0xFF3D2821);
    IconData holdingIcon = _defaultLogos.isNotEmpty && _holdingLogoIndex >= 0 && _holdingLogoIndex < _defaultLogos.length ? _defaultLogos[_holdingLogoIndex] : Icons.domain_rounded;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59A45), themeSandYellow, Color(0xFFF2DC8F)], stops: [0.0, 0.4, 1.0]),
            boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6, left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42, height: 42, 
                            decoration: BoxDecoration(color: const Color(0xFF3D2821), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFB59A45), width: 2.5), boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 4, offset: Offset(1, 2))]), 
                            child: Center(
                              child: ShaderMask(
                                shaderCallback: (Rect bounds) => const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x99FFFFFF), themeSandYellow, Color(0x4DF3D78F)], stops: [0.0, 0.5, 1.0]).createShader(bounds), 
                                child: Icon(holdingIcon, size: 24, color: Colors.white, shadows: const [Shadow(color: Color(0x80000000), offset: Offset(1.5, 2), blurRadius: 3)]),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(_holdingName, style: const TextStyle(fontFamily: 'Times New Roman', color: classicBrown, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5, height: 1.0, shadows: [Shadow(color: Color(0xCCFFFFFF), offset: Offset(1, 1), blurRadius: 0)])),
                                  const SizedBox(width: 8),
                                  if (gameState.isBoostActive) 
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), 
                                      decoration: BoxDecoration(color: AppColors.profit, borderRadius: BorderRadius.circular(4)), 
                                      child: const Text('2X BOOST', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text('\$ ${_formatNum(gameState.money)}', style: const TextStyle(color: Color(0xFF1E3A1E), fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                                  const SizedBox(width: 8),
                                  Text(
                                    gameState.incomePerSecond > 0 ? '+\$${_formatNum(gameState.incomePerSecond)}/s' : '', 
                                    style: TextStyle(color: gameState.currentMultiplier > 1 ? const Color(0xFFEF6C00) : const Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (gameState.hasTaxDebt) 
                            InkWell(
                              onTap: () => showDialog(
                                context: context, 
                                builder: (c) => AlertDialog(
                                  backgroundColor: AppColors.background, 
                                  title: const Text('Vergi Borcu', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)), 
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min, 
                                    children: [
                                      Text('Borç: \$${_formatNum(gameState.currentTaxDebt)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), 
                                      const SizedBox(height: 10), 
                                      Text(gameState.isUnderPenalty ? 'HACİZ SÜRECİ BAŞLADI!' : 'Ödeme için son 12 saat.', style: TextStyle(color: gameState.isUnderPenalty ? Colors.red : Colors.grey, fontWeight: FontWeight.bold)),
                                    ],
                                  ), 
                                  actionsAlignment: MainAxisAlignment.center, 
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.profit, foregroundColor: Colors.white), 
                                      onPressed: gameState.money >= gameState.currentTaxDebt ? () { 
                                        gameState.payTax(); 
                                        Navigator.pop(c); 
                                      } : null, 
                                      child: const Text('ÖDE'),
                                    ), 
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkBrown), 
                                      icon: const Icon(Icons.ondemand_video_rounded, size: 18), 
                                      label: const Text('VERGİ AFFI'), 
                                      onPressed: () {
                                        AdMobService.showRewardedAd(
                                          context: context,
                                          onRewardEarned: () {
                                            gameState.incrementAdsWatched();
                                            gameState.applyTaxAmnesty();
                                            Navigator.pop(c);
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ), 
                              child: Icon(Icons.warning_rounded, color: gameState.isUnderPenalty ? Colors.red : Colors.orange, size: 28),
                            ),
                          const SizedBox(width: 8),
                          Theme(
                            data: Theme.of(context).copyWith(popupMenuTheme: PopupMenuThemeData(color: themeSandYellow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: classicBrown, width: 3)))), 
                            child: PopupMenuButton<String>(
                              icon: ShaderMask(
                                shaderCallback: (Rect bounds) => const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x99FFFFFF), classicBrown, Color(0x4D5D4037)], stops: [0.0, 0.5, 1.0]).createShader(bounds), 
                                child: const Icon(Icons.menu_rounded, size: 28, color: Colors.white, shadows: [Shadow(color: Color(0x80000000), offset: Offset(1.5, 2), blurRadius: 3)]),
                              ), 
                              offset: const Offset(0, 50), 
                              onSelected: (value) { 
                                if (value == 'settings') {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen())); 
                                } else if (value == 'main_menu') {
                                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainMenuScreen(isInitialLaunch: false))); 
                                }
                              }, 
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings_rounded, color: classicBrown), SizedBox(width: 10), Text('Ayarlar', style: TextStyle(color: classicBrown, fontWeight: FontWeight.bold))])), 
                                const PopupMenuDivider(height: 1), 
                                const PopupMenuItem(value: 'main_menu', child: Row(children: [Icon(Icons.exit_to_app_rounded, color: Color(0xFFD32F2F)), SizedBox(width: 10), Text('Ana Menü', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold))])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(height: 4, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0x40000000), Colors.transparent]))),
              Container(height: 6, decoration: const BoxDecoration(color: classicBrown, border: Border(top: BorderSide(color: lightBrown, width: 1.5), bottom: BorderSide(color: darkBrown, width: 2.5)))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedBottomBar(BuildContext context) {
    const Color classicBrown = Color(0xFF5D4037); 
    const Color lightBrown = Color(0xFF7A574A); 
    const Color darkBrown = Color(0xFF3D2821);  
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59A45), themeSandYellow, Color(0xFFF2DC8F)], stops: [0.0, 0.4, 1.0]), 
        boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 10, 
            decoration: const BoxDecoration(color: classicBrown, border: Border(top: BorderSide(color: lightBrown, width: 2.5), bottom: BorderSide(color: darkBrown, width: 3.5))),
          ),
          Container(
            height: 8, 
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x59000000), Colors.transparent])),
          ),
          SafeArea(
            top: false,
            child: SizedBox(
              height: 64, 
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _build3DTab("Araştırmalar", Icons.science_rounded, themeOceanBlue, classicBrown, () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ResearchScreen()))),
                  _buildDeepGrooveDivider(), 
                  _build3DTab("Borsa", Icons.assessment_rounded, themeIslandGreen, classicBrown, () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StockScreen()))),
                  _buildDeepGrooveDivider(),
                  _build3DTab("Yazıhane", Icons.location_city_rounded, Colors.orangeAccent, classicBrown, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const OfficeScreen()));
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DTab(String title, IconData icon, Color iconColor, Color textColor, VoidCallback onTap, {double glareOpacity = 0.9}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (Rect bounds) => LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight, 
                colors: [Colors.white.withValues(alpha: glareOpacity), iconColor, iconColor.withValues(alpha: 0.3)], 
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds), 
              child: Icon(icon, size: 34, color: Colors.white, shadows: const [Shadow(color: Color(0x99000000), offset: Offset(1.5, 2.5), blurRadius: 4)]),
            ), 
            const SizedBox(height: 4),
            Text(
              title, 
              textAlign: TextAlign.center, 
              maxLines: 1, 
              style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5, shadows: const [Shadow(color: Color(0x99FFFFFF), offset: Offset(1, 1), blurRadius: 0)]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeepGrooveDivider() {
    return Container(
      height: 44, width: 4, 
      decoration: const BoxDecoration(color: themeSandYellow, border: Border(left: BorderSide(color: Color(0x66000000), width: 2), right: BorderSide(color: Color(0xB3FFFFFF), width: 2))),
    );
  }

  Widget _buildSideActionButtons(GameState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSideButton(
          icon: Icons.electric_bolt_rounded, 
          iconColor: Colors.amberAccent, 
          hasNotification: !state.isBoostActive, 
          onTap: () {
            AdMobService.showRewardedAd(
              context: context, 
              onRewardEarned: () {
                state.incrementAdsWatched();
                state.activate2xBoost();
              },
            );
          },
        ),
        const SizedBox(height: 12),
        AnimatedSideButton(
          icon: Icons.casino_rounded, 
          iconColor: Colors.purpleAccent, 
          hasNotification: true, 
          onTap: () {
            WheelDialog.show(context);
          },
        ),
        const SizedBox(height: 12),
        AnimatedSideButton(icon: Icons.emoji_events_rounded, iconColor: themeSandYellow, hasNotification: false, onTap: () => AchievementsDialog.show(context)),
        const SizedBox(height: 12),
        AnimatedSideButton(icon: Icons.assignment_rounded, iconColor: themeOceanBlue, hasNotification: false, onTap: () => TasksDialog.show(context)),
        const SizedBox(height: 12),
        AnimatedSideButton(icon: Icons.stars_rounded, iconColor: themeLighthouseRed, hasNotification: false, onTap: () {
          PrestigeDialog.show(context, currentTurnover: state.money, onPrestigeConfirmed: () { state.executePrestige((state.money/1e20).floor()); });
        }),
      ],
    );
  }
}

class AnimatedSideButton extends StatefulWidget {
  final IconData icon; final Color iconColor; final VoidCallback onTap; final bool hasNotification;
  const AnimatedSideButton({super.key, required this.icon, required this.iconColor, required this.onTap, this.hasNotification = false});
  @override State<AnimatedSideButton> createState() => _AnimatedSideButtonState();
}

class _AnimatedSideButtonState extends State<AnimatedSideButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _scaleAnimation;
  @override void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    const Color classicBrown = Color(0xFF5D4037);
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation, 
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40, height: 40, 
              decoration: BoxDecoration(color: classicBrown, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF7A574A), width: 1.5), boxShadow: [BoxShadow(color: widget.iconColor.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 0)), const BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(2, 3))]), 
              child: Center(
                child: ShaderMask(shaderCallback: (Rect bounds) => LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: 0.6), widget.iconColor, widget.iconColor.withValues(alpha: 0.3)], stops: const [0.0, 0.5, 1.0]).createShader(bounds), child: Icon(widget.icon, size: 22, color: Colors.white, shadows: const [Shadow(color: Color(0x80000000), offset: Offset(1, 1.5), blurRadius: 2)])),
              ),
            ),
            if (widget.hasNotification) 
              Positioned(
                top: -2, right: -2, 
                child: Container(width: 12, height: 12, decoration: BoxDecoration(color: themeLighthouseRed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5), boxShadow: const [BoxShadow(color: Color(0xCCD64D4D), blurRadius: 6, spreadRadius: 2)])),
              ),
          ],
        ),
      ),
    );
  }
}

class FactoryInsideModal extends StatefulWidget {
  final String factoryId;
  final String Function(double) formatNum;
  const FactoryInsideModal({super.key, required this.factoryId, required this.formatNum});

  @override State<FactoryInsideModal> createState() => _FactoryInsideModalState();
}

class _FactoryInsideModalState extends State<FactoryInsideModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); }
  @override void dispose() { _tabController.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final currentFac = gameState.factories.firstWhere((f) => f.id == widget.factoryId);
        return Container(
          height: MediaQuery.of(context).size.height * 0.8, padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Text(currentFac.name, style: AppTheme.titleStyle(fontSize: 24).copyWith(color: AppColors.gold)),
              Text('Aşama: ${currentFac.currentStage} | Toplam Seviye: ${currentFac.totalLevel}/300', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TabBar(controller: _tabController, indicatorColor: AppColors.gold, labelColor: AppColors.gold, unselectedLabelColor: AppColors.textMuted, tabs: const [Tab(text: "ÜRETİM BANDI"), Tab(text: "GELİŞTİRMELER")]),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ListView.separated(
                      itemCount: currentFac.products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final prod = currentFac.products[index];
                        if (prod.level == 0) {
                          return const SizedBox.shrink(); 
                        }
                        return ProductionLineWidget(product: prod, formatNum: widget.formatNum, onProduceComplete: () => gameState.completeManualProduction(currentFac.id, index));
                      },
                    ),
                    ListView.separated(
                      itemCount: currentFac.products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final prod = currentFac.products[index];
                        bool canUnlock = index == 0 || currentFac.products[index - 1].level >= 10;
                        if (!canUnlock) {
                          return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)), child: Row(children: const [Icon(Icons.lock, color: Colors.white30), SizedBox(width: 12), Text('Önceki ürünü Lvl 10 yapın', style: TextStyle(color: Colors.white54))]));
                        }

                        double cost = prod.upgradeCost;
                        bool isMax = prod.level >= 60;
                        return Container(
                          padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gold)),
                          child: Row(
                            children: [
                              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.inventory_2_rounded, color: AppColors.gold)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(prod.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('Seviye: ${prod.level}/60', style: const TextStyle(color: AppColors.gold, fontSize: 11)),
                                    Text('Pasif: +\$${widget.formatNum(prod.passiveIncome)}/s', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: isMax ? AppColors.border : AppColors.gold, foregroundColor: AppColors.darkBrown),
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
  final FactoryProduct product;
  final String Function(double) formatNum;
  final VoidCallback onProduceComplete;

  const ProductionLineWidget({super.key, required this.product, required this.formatNum, required this.onProduceComplete});
  @override State<ProductionLineWidget> createState() => _ProductionLineWidgetState();
}

class _ProductionLineWidgetState extends State<ProductionLineWidget> {
  final List<int> _activeItems = [];
  int _counter = 0;

  void _startProduction() {
    int currentId = _counter++;
    setState(() => _activeItems.add(currentId));

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onProduceComplete();
        setState(() => _activeItems.remove(currentId));
      }
    });
  }

  @override Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text('Kazan: +\$${widget.formatNum(widget.product.manualIncome)}', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 60, decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 2)),
          child: Row(
            children: [
              InkWell(
                onTap: _startProduction,
                child: Container(
                  width: 70, height: double.infinity, 
                  decoration: const BoxDecoration(color: AppColors.profit, borderRadius: BorderRadius.horizontal(left: Radius.circular(10))), 
                  child: const Center(child: Text('ÜRET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(height: 4, width: double.infinity, color: AppColors.border),
                    ..._activeItems.map((id) => BoxAnimator(key: ValueKey(id))),
                  ],
                ),
              ),
              Container(width: 50, height: double.infinity, decoration: const BoxDecoration(color: AppColors.darkBrown, borderRadius: BorderRadius.horizontal(right: Radius.circular(10))), child: const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 28)),
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
  
  @override 
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _started = true);
    });
  }

  @override 
  Widget build(BuildContext context) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 1500), 
      alignment: _started ? Alignment.centerRight : Alignment.centerLeft, 
      curve: Curves.linear,
      child: Container(
        width: 40, height: 40, margin: const EdgeInsets.symmetric(horizontal: 10), 
        decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.darkBrown)), 
        child: const Icon(Icons.inventory_2_rounded, color: AppColors.darkBrown, size: 24),
      ),
    );
  }
}

// YENİ EKLENDİ: MARTI SÜRÜSÜ ANİMASYONU
class SeagullFlockComponent extends PositionComponent {
  double _time = 0;
  final Vector2 velocity;
  final int birdCount = 3 + math.Random().nextInt(5); // 3 ile 7 arası kuş
  final List<Vector2> offsets = [];
  final List<double> phaseShifts = [];

  SeagullFlockComponent({required Vector2 startPos, required this.velocity}) {
    position = startPos;
    size = Vector2(150, 150);
    for(int i=0; i<birdCount; i++) {
       offsets.add(Vector2(math.Random().nextDouble() * 100, math.Random().nextDouble() * 100));
       phaseShifts.add(math.Random().nextDouble() * math.pi * 2);
    }
  }

  @override
  void update(double dt) {
    _time += dt;
    position.add(velocity * dt);
    
    // Ekran dışına çıkarsa sil
    if (position.x < -300 || position.x > 1500) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < birdCount; i++) {
      double flap = math.sin(_time * 8 + phaseShifts[i]) * 8; // Kanat çırpma
      Path bird = Path();
      double bx = offsets[i].x;
      double by = offsets[i].y;
      
      // Basit 'V' veya Martı Şekli Çizimi
      bird.moveTo(bx, by - flap);
      bird.quadraticBezierTo(bx + 8, by - 5, bx + 12, by); // Gövde (orta)
      bird.quadraticBezierTo(bx + 16, by - 5, bx + 24, by - flap);
      
      canvas.drawPath(bird, paint);
    }
  }
}

// YENİ EKLENDİ: KIYIYA VURAN KÖPÜKLÜ BEYAZ DALGALAR
class CrashingWavesComponent extends Component {
  final double mapWidth;
  final double mapHeight;
  double _time = 0;
  final math.Random _random = math.Random();
  final List<_Wave> _waves = [];

  CrashingWavesComponent({required this.mapWidth, required this.mapHeight});

  @override
  void update(double dt) {
    _time += dt;
    // Saniyede %3 ihtimalle yeni bir dalga oluştur
    if (_random.nextDouble() < 0.03) {
      _waves.add(_Wave(
        x: -100 + _random.nextDouble() * (mapWidth + 200),
        y: -100 + _random.nextDouble() * (mapHeight + 200),
        maxLife: 3.0 + _random.nextDouble() * 2.0,
        size: 0.8 + _random.nextDouble() * 1.5,
      ));
    }
    
    for (int i = _waves.length - 1; i >= 0; i--) {
      _waves[i].life += dt;
      if (_waves[i].life > _waves[i].maxLife) {
        _waves.removeAt(i);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Deniz sınırlarını maskele (Kıyıya ve adaya dalga girmesin)
    Path safeWaterZone = Path.combine(
      PathOperation.difference, 
      Path.combine(PathOperation.difference, Path.combine(PathOperation.difference, Path()..addRect(Rect.fromLTWH(-500, -500, mapWidth + 1000, mapHeight + 1000)), Path()..addOval(const Rect.fromLTRB(965, 1340, 1300, 1540))), Path()..addOval(const Rect.fromLTRB(-20, 2800, 120, 3100))), 
      Path()..addOval(const Rect.fromLTRB(-20, 400, 140, 600))
    );

    canvas.save();
    canvas.clipPath(safeWaterZone);

    for (var wave in _waves) {
      double progress = wave.life / wave.maxLife;
      // Opaklık artar ve azalır (Fade in & Fade out)
      double alpha = math.sin(progress * math.pi) * 0.6; 
      
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      // Dalganın kıyıya doğru hafif kayması (Y ve X ekseninde)
      double currentX = wave.x + (progress * 30 * wave.size);
      double currentY = wave.y + (progress * 20 * wave.size);

      Path wavePath = Path();
      wavePath.moveTo(currentX, currentY);
      wavePath.quadraticBezierTo(currentX + (40 * wave.size), currentY - (15 * wave.size), currentX + (80 * wave.size), currentY + (10 * wave.size));
      wavePath.quadraticBezierTo(currentX + (40 * wave.size), currentY - (5 * wave.size), currentX, currentY);
      
      canvas.drawPath(wavePath, paint);
    }
    
    canvas.restore();
  }
}

class _Wave {
  double x, y, life = 0, maxLife, size;
  _Wave({required this.x, required this.y, required this.maxLife, required this.size});
}

class OpenSeaRipples extends Component {
  double _time = 0;
  final Paint _ripplePaint = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 3.5;

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
  final Sprite mapSprite;
  final double mapWidth;
  final double mapHeight;
  double _time = 0;

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
  final double reward;
  final Function(double) onBagTap;
  double _time = 0;
  final Vector2 velocity;

  FlyingBagComponent({required this.reward, required this.onBagTap, required Vector2 startPos, required this.velocity}) {
    position = startPos;
    size = Vector2(80, 80);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    _time += dt;
    position.add(velocity * dt);
    position.y += math.sin(_time * 6) * 3; 
    if (position.x < -200 || position.x > 1300) {
      removeFromParent();
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    onBagTap(reward);
    removeFromParent(); 
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x/2, size.y/2), 35, Paint()..color=Colors.yellow.withValues(alpha: 0.3)..maskFilter=const MaskFilter.blur(BlurStyle.normal, 15));
    
    Path bag = Path();
    bag.moveTo(size.x/2 - 15, size.y/2 + 25);
    bag.quadraticBezierTo(size.x/2 - 35, size.y/2 + 25, size.x/2 - 30, size.y/2);
    bag.quadraticBezierTo(size.x/2 - 25, size.y/2 - 20, size.x/2 - 10, size.y/2 - 20);
    bag.lineTo(size.x/2 + 10, size.y/2 - 20);
    bag.quadraticBezierTo(size.x/2 + 25, size.y/2 - 20, size.x/2 + 30, size.y/2);
    bag.quadraticBezierTo(size.x/2 + 35, size.y/2 + 25, size.x/2 + 15, size.y/2 + 25);
    bag.close();
    
    canvas.drawPath(bag, Paint()..color = const Color(0xFF6D4C41));
    canvas.drawPath(bag, Paint()..color = const Color(0xFF4E342E)..style = PaintingStyle.stroke..strokeWidth=2);

    canvas.drawRect(Rect.fromLTWH(size.x/2 - 12, size.y/2 - 32, 24, 12), Paint()..color = const Color(0xFF8D6E63));
    canvas.drawLine(Offset(size.x/2 - 14, size.y/2 - 20), Offset(size.x/2 + 14, size.y/2 - 20), Paint()..color = const Color(0xFF3E2723)..strokeWidth=3);
    
    final textPainter = TextPainter(text: const TextSpan(text: '\$', style: TextStyle(color: Colors.yellow, fontSize: 32, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black54, offset: Offset(1,1), blurRadius: 2)])), textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, Offset(size.x/2 - textPainter.width/2, size.y/2 - 12));
  }
}

class HoldingTycoonGame extends FlameGame with PanDetector {
  final Function(String) onFactoryTap; 
  final Function(double) onBagTapped; 

  late final CameraComponent cam;
  final World mapWorld = World();
  double mapWidth = 1080.0; double mapHeight = 1920.0; 
  final double topPadding = 250.0; final double bottomPadding = 350.0;
  
  GameState? _currentState;
  double _seagullTimer = 0; // YENİ: Martı Sayacı

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
    
    Vector2 startPos = Vector2(fromLeft ? -100 : mapWidth + 100, spawnY);
    Vector2 velocity = Vector2(fromLeft ? 200 : -200, 0); 

    mapWorld.add(FlyingBagComponent(
      reward: reward,
      startPos: startPos,
      velocity: velocity,
      onBagTap: onBagTapped,
    ));
  }

  // YENİ EKLENDİ: Martı Doğurucu
  void _spawnSeagulls() {
    bool fromLeft = math.Random().nextBool();
    double viewTop = -cam.viewfinder.position.y;
    double viewHeight = size.y / cam.viewfinder.zoom;
    
    // Kameranın baktığı herhangi bir yükseklikten gelebilir
    double spawnY = viewTop + (math.Random().nextDouble() * viewHeight);
    
    Vector2 startPos = Vector2(fromLeft ? -200 : mapWidth + 200, spawnY);
    
    // Hafif yukarı eğimli uçuş rotası
    Vector2 velocity = Vector2(fromLeft ? 120 : -120, -30 + math.Random().nextDouble() * 60); 

    mapWorld.add(SeagullFlockComponent(startPos: startPos, velocity: velocity));
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // YENİ EKLENDİ: Martı Döngüsü
    _seagullTimer += dt;
    if (_seagullTimer > 12.0) { // Her 12 saniyede bir ihtimal
      _seagullTimer = 0;
      if (math.Random().nextDouble() < 0.6) { // %60 ihtimalle martı sürüsü çağır
        _spawnSeagulls();
      }
    }
  }

  @override Color backgroundColor() => themeOceanBlue; 

  @override
  Future<void> onLoad() async {
    add(mapWorld);
    try {
      final mapSprite = await Sprite.load('map.png');
      mapHeight = mapWidth * (mapSprite.srcSize.y / mapSprite.srcSize.x);
      
      mapWorld.add(OpenSeaRipples());
      mapWorld.add(CrashingWavesComponent(mapWidth: mapWidth, mapHeight: mapHeight)); // YENİ: Yüksek Köpüklü Dalgalar Eklendi
      mapWorld.add(PerfectPngWaves(mapSprite: mapSprite, mapWidth: mapWidth, mapHeight: mapHeight));
      mapWorld.add(SpriteComponent(sprite: mapSprite, size: Vector2(mapWidth, mapHeight)));
      
      final List<Vector2> plotPositions = [
        Vector2(540, 420),  Vector2(330, 520),  Vector2(700, 560),  Vector2(320, 720),
        Vector2(720, 750),  Vector2(310, 930),  Vector2(680, 950),  Vector2(460, 1080),
        Vector2(650, 1180), Vector2(360, 1240), Vector2(530, 1280), Vector2(320, 1390),
        Vector2(500, 1440), Vector2(420, 1550), 
      ];

      for (int i = 0; i < 14; i++) {
        mapWorld.add(FactoryPlotComponent(
          factoryId: (i + 1).toString(),
          position: plotPositions[i],
          onTap: onFactoryTap,
        ));
      }
    } catch (e) { debugPrint("PNG YÜKLEME HATASI: $e"); }

    cam.viewfinder.anchor = Anchor.topLeft;
    cam.viewfinder.position = Vector2(0, -topPadding);
    add(cam);
  }

  @override void onGameResize(Vector2 size) { super.onGameResize(size); cam.viewfinder.zoom = size.x / mapWidth; }
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

  FactoryPlotComponent({
    required this.factoryId,
    required Vector2 position,
    required this.onTap,
  }) : super(position: position, size: Vector2(170, 170), anchor: Anchor.center);

  void updateData(FactoryData data) { _data = data; }
  @override void onTapUp(TapUpEvent event) { onTap(factoryId); }

  @override
  void render(Canvas canvas) {
    if (_data == null) {
      return;
    }

    if (!_data!.isUnlocked) {
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, size.x-20, size.y-20), const Radius.circular(20));
      canvas.drawRRect(rrect, Paint()..color = Colors.black.withValues(alpha: 0.60)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      
      final iconPainter = TextPainter(textDirection: TextDirection.ltr);
      iconPainter.text = TextSpan(text: String.fromCharCode(Icons.lock_rounded.codePoint), style: TextStyle(fontSize: 40, fontFamily: Icons.lock_rounded.fontFamily, color: Colors.white.withValues(alpha: 0.75)));
      iconPainter.layout();
      iconPainter.paint(canvas, Offset(size.x/2 - 20, size.y/2 - 20));
    } else {
      canvas.drawOval(Rect.fromCenter(center: Offset(size.x/2, size.y/2 + 20), width: 130, height: 44), Paint()..color = Colors.black.withValues(alpha: 0.25));
      Paint wallPaint = Paint()..color = AppColors.classicBrown;
      Paint roofPaint = Paint()..color = AppColors.lightBrown;
      
      canvas.drawRect(Rect.fromLTWH(size.x/2 - 50, size.y/2 - 30, 100, 60), wallPaint);
      Path roof = Path()..moveTo(size.x/2 - 58, size.y/2 - 30)..lineTo(size.x/2, size.y/2 - 68)..lineTo(size.x/2 + 58, size.y/2 - 30)..close();
      canvas.drawPath(roof, roofPaint);
      canvas.drawRect(Rect.fromLTWH(size.x/2 + 22, size.y/2 - 76, 16, 50), Paint()..color = Colors.grey.shade800);

      final textPainter = TextPainter(
        text: TextSpan(text: 'Lvl ${_data!.totalLevel}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, backgroundColor: Colors.black54)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, const Offset(12, 12));
    }
  }
}