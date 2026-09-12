// lib/widgets/achievements.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../screens/map_screen.dart'; 

class AchievementsDialog extends StatefulWidget {
  const AchievementsDialog({super.key});
  static Future<void> show(BuildContext context) {
    return showDialog(context: context, barrierDismissible: true, builder: (context) => const AchievementsDialog());
  }
  @override State<AchievementsDialog> createState() => _AchievementsDialogState();
}

class _AchievementsDialogState extends State<AchievementsDialog> {

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

  void _claimReward(int index) {
    HapticFeedback.heavyImpact();
    AudioService.instance.playSfx('cash.mp3');
    context.read<GameState>().claimAchievement(index);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppColors.surface, content: Text('KADEME ÖDÜLÜ ALINDI!', style: TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900))));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    
    int unlockedFacs = state.factories.where((f) => f.isUnlocked).length;
    int totalProductLevels = 0;
    for (var f in state.factories) {
      for (var p in f.products) { totalProductLevels += p.level; }
    }

    final List<Map<String, dynamic>> achDefs = [
      {'title': 'Tıklama Kralı', 'desc': 'Manuel üretim hattında {T} kez üretim yap.', 'icon': 'touch', 'curr': state.statClicks.toDouble()},
      {'title': 'Kasa Bekçisi', 'desc': 'Holding tarihinde toplam \$ {T} ciro elde et.', 'icon': 'receipt', 'curr': state.statTotalEarned},
      {'title': 'Holding Genişlemesi', 'desc': '{T} farklı sanayi tesisini faaliyete geçir.', 'icon': 'factory', 'curr': unlockedFacs.toDouble()},
      {'title': 'Prestij Lordu', 'desc': '{T} kez holdingi tasfiye edip prestij yap.', 'icon': 'prestige', 'curr': state.statPrestige.toDouble()},
      {'title': 'Seviye Canavarı', 'desc': 'Tesis bantlarında toplam {T} seviyeye ulaş.', 'icon': 'upgrade', 'curr': totalProductLevels.toDouble()},
      {'title': 'Hisse Avcısı', 'desc': 'Borsada {T} kez hisse senedi alım satımı yap.', 'icon': 'stock', 'curr': state.statStocks.toDouble()},
      {'title': 'Zirveye Tırmanış', 'desc': 'Tek seferde \$ {T} net nakit paraya ulaş.', 'icon': 'chart', 'curr': state.money},
    ];

    int completedCount = state.claimedAchievements.fold(0, (sum, val) => sum + val);
    int totalCount = achDefs.length * 10; 

    return Dialog(
      backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity, constraints: const BoxConstraints(maxHeight: 680),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.border, width: 4), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 24, offset: const Offset(0, 10))]),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
              decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.zero, border: Border(bottom: BorderSide(color: AppColors.border, width: 4))),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.gold, width: 2)), child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: HeavyIconPainter(type: 'achievements', color: AppColors.gold)))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('BAŞARIMLAR', style: AppTheme.titleStyle(fontSize: 20).copyWith(color: AppColors.gold)), const SizedBox(height: 4), Text('TOPLAM İLERLEME: $completedCount / $totalCount', style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono', letterSpacing: 0.5))])),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 28), 
                    onPressed: () {
                      AudioService.instance.playSfx('click.mp3');
                      Navigator.pop(context);
                    }
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(14), itemCount: achDefs.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final def = achDefs[i];
                  final tier = state.claimedAchievements[i];
                  final isMaxed = tier >= GameState.achievementTargets[i].length;
                  final target = isMaxed ? GameState.achievementTargets[i].last : GameState.achievementTargets[i][tier];
                  final curr = def['curr'] as double;
                  
                  bool isCompleted = curr >= target && !isMaxed;
                  double progress = (curr / target).clamp(0.0, 1.0);

                  String formattedTarget = (i == 1 || i == 6) ? _formatNum(target) : target.toInt().toString();
                  String formattedCurr = (i == 1 || i == 6) ? _formatNum(curr) : curr.toInt().toString();
                  String desc = def['desc'].toString().replaceAll('{T}', formattedTarget);

                  double mReward = isMaxed ? 0 : state.getAchievementMoneyReward(tier);
                  int rpReward = isMaxed ? 0 : state.getAchievementRpReward(tier);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.zero, border: Border.all(color: isCompleted ? AppColors.gold : AppColors.border, width: 3)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44, height: 44, 
                          decoration: BoxDecoration(color: isCompleted ? AppColors.gold.withValues(alpha: 0.2) : Colors.black, borderRadius: BorderRadius.zero, border: Border.all(color: isCompleted ? AppColors.gold : AppColors.border, width: 2)), 
                          child: Center(child: SizedBox(width: 24, height: 24, child: CustomPaint(painter: HeavyIconPainter(type: def['icon'], color: isCompleted ? AppColors.gold : AppColors.textMuted))))
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMaxed) Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.black, border: Border.all(color: AppColors.border)), child: Text('KADEME ${tier + 1}/10', style: const TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
                                  if (isMaxed) Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.black, border: Border.all(color: AppColors.profit)), child: const Text('MAKSİMUM', style: TextStyle(color: AppColors.profit, fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
                                ]
                              ),
                              const SizedBox(height: 4),
                              Text(def['title'].toString().toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 13)), 
                              const SizedBox(height: 4), 
                              Text(isMaxed ? 'Tüm kademeler tamamlandı.' : desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3, fontWeight: FontWeight.bold)), 
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5)), child: LinearProgressIndicator(value: isMaxed ? 1.0 : progress, minHeight: 6, backgroundColor: Colors.black, valueColor: AlwaysStoppedAnimation<Color>(isMaxed ? AppColors.profit : (isCompleted ? AppColors.gold : AppColors.neonCyan))))), 
                                  const SizedBox(width: 8), 
                                  Text(isMaxed ? 'TAMAMLANDI' : '$formattedCurr/$formattedTarget', style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))
                                ]
                              ),
                            ]
                          )
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMaxed) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: Colors.black, child: Text('+${rpReward.toString()} RP', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'SpaceMono'))),
                            if (!isMaxed) const SizedBox(height: 4),
                            if (!isMaxed) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: Colors.black, child: Text('+\$${mReward >= 1e6 ? "${(mReward / 1e6).toStringAsFixed(1)}M" : "${(mReward / 1000).toStringAsFixed(0)}K"}', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'SpaceMono'))),
                            if (!isMaxed) const SizedBox(height: 8),
                            AchieveHeavyButton(
                              width: 64, height: 32,
                              color: isMaxed ? AppColors.border : (isCompleted ? AppColors.gold : AppColors.surfaceElevated),
                              shadowColor: isMaxed ? Colors.black : (isCompleted ? const Color(0xFF8B6B32) : Colors.black),
                              onPressed: isCompleted && !isMaxed ? () => _claimReward(i) : null,
                              child: Text(isMaxed ? 'ALINDI' : (isCompleted ? 'AL' : 'KİLİTLİ'), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isCompleted ? AppColors.darkBrown : Colors.white54)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AchieveHeavyButton extends StatefulWidget {
  final VoidCallback? onPressed; final Widget child; final Color color; final Color shadowColor; final double height; final double? width;
  const AchieveHeavyButton({super.key, required this.onPressed, required this.child, required this.color, required this.shadowColor, this.height = 50, this.width});
  @override State<AchieveHeavyButton> createState() => _AchieveHeavyButtonState();
}
class _AchieveHeavyButtonState extends State<AchieveHeavyButton> {
  bool _isPressed = false;
  @override Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: isDisabled ? null : (_) { HapticFeedback.lightImpact(); AudioService.instance.playSfx('click.mp3'); setState(() => _isPressed = true); },
      onTapUp: isDisabled ? null : (_) { setState(() => _isPressed = false); widget.onPressed!(); },
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      child: SizedBox(
        width: widget.width, height: widget.height,
        child: Stack(children: [
          Positioned(bottom: 0, left: 0, right: 0, top: 4, child: Container(decoration: BoxDecoration(color: isDisabled ? AppColors.border.withValues(alpha: 0.5) : widget.shadowColor, border: Border.all(color: Colors.black87, width: 2.0)))),
          AnimatedPositioned(duration: const Duration(milliseconds: 60), bottom: _isPressed || isDisabled ? 0 : 4, left: 0, right: 0, top: _isPressed || isDisabled ? 4 : 0, child: Container(decoration: BoxDecoration(color: isDisabled ? AppColors.surfaceElevated : widget.color, border: Border.all(color: Colors.black87, width: 2.0)), child: Center(child: widget.child))),
        ]),
      ),
    );
  }
}