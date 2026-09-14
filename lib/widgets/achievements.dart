// lib/widgets/achievements.dart
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

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
    if (value > 0 && value < 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(0);
  }

  void _claimReward(int index) {
    HapticFeedback.heavyImpact();
    AudioService.instance.playSfx('cash.mp3');
    context.read<GameState>().claimAchievement(index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.white, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.black, width: 3)),
        content: const Text('KADEME ÖDÜLÜ ALINDI!', style: TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    
    if (!state.areAchievementsUnlocked) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.black, size: 32),
                    onPressed: () {
                      AudioService.instance.playSfx('click.mp3');
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 3)),
                child: const Icon(Icons.lock_rounded, color: AppColors.loss, size: 64),
              ),
              const SizedBox(height: 20),
              FittedBox(fit: BoxFit.scaleDown, child: Text('BAŞARIMLAR KİLİTLİ', style: AppTheme.titleStyle(fontSize: 24).copyWith(color: AppColors.loss, shadows: []))),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'HOLDİNG BAŞARIMLARINA ERİŞMEK İÇİN HERHANGİ BİR FABRİKANIZI EN AZ SEVİYE 30 YAPMALISINIZ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black, fontSize: 14, height: 1.5, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 32),
              AchieveHeavyButton(
                width: double.infinity,
                height: 55,
                color: const Color(0xFFF1F5F9),
                shadowColor: Colors.grey.shade400,
                onPressed: () {
                  AudioService.instance.playSfx('click.mp3');
                  Navigator.pop(context);
                },
                child: const Text('ANLAŞILDI', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> achDefs = [
      {'title': 'Tıklama Kralı', 'desc': 'Üretim hattında {T} kez üretim yap.', 'icon': 'touch', 'curr': state.getAchievementProgress(0)},
      {'title': 'Kasa Bekçisi', 'desc': 'Toplam \$ {T} ciro elde et.', 'icon': 'receipt', 'curr': state.getAchievementProgress(1)},
      {'title': 'Holding Genişlemesi', 'desc': '{T} yeni sanayi tesisini faaliyete geçir.', 'icon': 'factory', 'curr': state.getAchievementProgress(2)},
      {'title': 'Prestij Lordu', 'desc': '{T} kez holdingi tasfiye edip prestij yap.', 'icon': 'prestige', 'curr': state.getAchievementProgress(3)},
      {'title': 'Seviye Canavarı', 'desc': 'Tesis bantlarında toplam {T} ilave seviyeye ulaş.', 'icon': 'upgrade', 'curr': state.getAchievementProgress(4)},
      {'title': 'Hisse Avcısı', 'desc': 'Borsada {T} kez hisse senedi işlemi yap.', 'icon': 'stock', 'curr': state.getAchievementProgress(5)},
      {'title': 'Zirveye Tırmanış', 'desc': '\$ {T} net birikim nakit paraya ulaş.', 'icon': 'chart', 'curr': state.getAchievementProgress(6)},
    ];

    int completedCount = state.claimedAchievements.fold(0, (sum, val) => sum + val);
    int totalCount = achDefs.length * 10; 

    return Dialog(
      backgroundColor: Colors.transparent, 
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity, 
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(color: Colors.black, width: 4), 
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 10))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), 
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)), 
                border: Border(bottom: BorderSide(color: Colors.black, width: 4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10), 
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)), 
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.black, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('BAŞARIMLAR', style: AppTheme.titleStyle(fontSize: 22).copyWith(color: Colors.black, shadows: []))), 
                        const SizedBox(height: 4), 
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('TOPLAM İLERLEME: $completedCount / $totalCount', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono', letterSpacing: 0.5))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.black, size: 28), 
                    onPressed: () {
                      AudioService.instance.playSfx('click.mp3');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(12), 
                itemCount: achDefs.length, 
                separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(20), 
                      border: Border.all(color: isCompleted ? AppColors.gold : Colors.black, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48, height: 48, 
                          decoration: BoxDecoration(
                            color: isCompleted ? AppColors.gold : const Color(0xFFE2E8F0), 
                            borderRadius: BorderRadius.circular(16), 
                            border: Border.all(color: Colors.black, width: 3),
                          ), 
                          child: Center(
                            child: Icon(Icons.star_rounded, color: isCompleted ? Colors.white : AppColors.textMuted, size: 28),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMaxed) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)), child: Text('KADEME ${tier + 1}/10', style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
                                  if (isMaxed) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)), child: const Text('MAKSİMUM', style: TextStyle(color: AppColors.profit, fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
                                ],
                              ),
                              const SizedBox(height: 6),
                              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(def['title'].toString().toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14))), 
                              const SizedBox(height: 4), 
                              Text(isMaxed ? 'Tüm kademeler tamamlandı.' : desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3, fontWeight: FontWeight.bold)), 
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)), 
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(value: isMaxed ? 1.0 : progress, minHeight: 8, backgroundColor: const Color(0xFFF1F5F9), valueColor: AlwaysStoppedAnimation<Color>(isMaxed ? AppColors.profit : (isCompleted ? AppColors.gold : AppColors.neonCyan))),
                                      ),
                                    ),
                                  ), 
                                  const SizedBox(width: 8), 
                                  Flexible(
                                    flex: 2,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(isMaxed ? 'TAMAMLANDI' : '$formattedCurr/$formattedTarget', style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMaxed) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)), child: FittedBox(fit: BoxFit.scaleDown, child: Text('+${rpReward.toString()} RP', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'SpaceMono')))),
                            if (!isMaxed) const SizedBox(height: 4),
                            if (!isMaxed) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)), child: FittedBox(fit: BoxFit.scaleDown, child: Text('+\$${_formatNum(mReward)}', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'SpaceMono')))),
                            if (!isMaxed) const SizedBox(height: 10),
                            AchieveHeavyButton(
                              width: 72, height: 36,
                              color: isMaxed ? const Color(0xFFE2E8F0) : (isCompleted ? AppColors.gold : const Color(0xFFF1F5F9)),
                              shadowColor: isMaxed ? Colors.grey.shade400 : (isCompleted ? Colors.orange.shade700 : Colors.grey.shade400),
                              onPressed: isCompleted && !isMaxed ? () => _claimReward(i) : null,
                              child: Text(isMaxed ? 'ALINDI' : (isCompleted ? 'AL' : 'KİLİTLİ'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isCompleted ? Colors.black : Colors.grey.shade500)),
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
          Positioned(bottom: 0, left: 0, right: 0, top: 4, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade400 : widget.shadowColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 3)))),
          AnimatedPositioned(duration: const Duration(milliseconds: 60), bottom: _isPressed || isDisabled ? 0 : 4, left: 0, right: 0, top: _isPressed || isDisabled ? 4 : 0, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade300 : widget.color, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 3)), child: Center(child: widget.child))),
        ]),
      ),
    );
  }
}