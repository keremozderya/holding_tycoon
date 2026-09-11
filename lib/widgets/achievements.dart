// lib/widgets/achievements.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/translation_service.dart';
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

  void _claimReward(int index, double money, int rp) {
    final state = context.read<GameState>();
    if (state.claimedAchievements[index]) return;
    state.claimedAchievements[index] = true;
    if (money > 0) state.updateMoney(money);
    if (rp > 0) state.updateResearchPoints(rp);
    HapticFeedback.heavyImpact();
    AudioService.instance.playSfx('cash.mp3');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppColors.surface, content: Text('Başarım Ödülü Alındı!', style: TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900))));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    
    int unlockedFacs = state.factories.where((f) => f.isUnlocked).length;
    int maxProductLvl = 0;
    for (var f in state.factories) {
      for (var p in f.products) { if (p.level > maxProductLvl) maxProductLvl = p.level; }
    }

    final List<Map<String, dynamic>> achs = [
      {'title': 'Endüstri Devi', 'desc': '5 farklı fabrikanın kilidini aç.', 'icon': Icons.factory_rounded, 'curr': unlockedFacs, 'targ': 5, 'm': 500000.0, 'rp': 10, 'c': state.claimedAchievements[0]},
      {'title': 'Trilyoner Kulübü', 'desc': 'Toplam 1 Trilyon (1T) nakite ulaş.', 'icon': Icons.account_balance_rounded, 'curr': state.money >= 1e12 ? 1 : 0, 'targ': 1, 'm': 0.0, 'rp': 50, 'c': state.claimedAchievements[1]},
      {'title': 'Adım Adım Zirveye', 'desc': '100 kez manuel üretim yap.', 'icon': Icons.touch_app_rounded, 'curr': state.statClicks, 'targ': 100, 'm': 250000.0, 'rp': 0, 'c': state.claimedAchievements[2]},
      {'title': 'Vergi Kaçakçısı Değil', 'desc': '10 kez zamanında vergi öde.', 'icon': Icons.receipt_long_rounded, 'curr': state.statTaxes, 'targ': 10, 'm': 0.0, 'rp': 25, 'c': state.claimedAchievements[3]},
      {'title': 'Borsa Kurdu', 'desc': 'Borsada 50 kez işlem yap.', 'icon': Icons.candlestick_chart_rounded, 'curr': state.statStocks, 'targ': 50, 'm': 1000000.0, 'rp': 0, 'c': state.claimedAchievements[4]},
      {'title': 'Zamanın Ötesinde', 'desc': 'Bir ürünü maksimum seviyeye (60) ulaştır.', 'icon': Icons.rocket_launch_rounded, 'curr': maxProductLvl, 'targ': 60, 'm': 0.0, 'rp': 100, 'c': state.claimedAchievements[5]},
      {'title': 'Dünyaların Sahibi', 'desc': '10^33 servete ulaş.', 'icon': Icons.diamond_rounded, 'curr': state.money >= 1e33 ? 1 : 0, 'targ': 1, 'm': 0.0, 'rp': 1000, 'c': state.claimedAchievements[6]},
    ];

    int completedCount = achs.where((a) => (a['curr'] as num) >= (a['targ'] as num)).length;

    return Dialog(
      backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity, constraints: const BoxConstraints(maxHeight: 620),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border, width: 3), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
              decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16)), border: Border(bottom: BorderSide(color: AppColors.border, width: 3))),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('achievements.title'.tr(), style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.gold)), Text('$completedCount / ${achs.length} Tamamlandı', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))])),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.gold), 
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
                padding: const EdgeInsets.all(16), itemCount: achs.length, separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final ach = achs[i];
                  bool isCompleted = (ach['curr'] as num) >= (ach['targ'] as num);
                  double progress = ((ach['curr'] as num) / (ach['targ'] as num)).clamp(0.0, 1.0);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isCompleted ? AppColors.gold : AppColors.border, width: 2)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: isCompleted ? AppColors.gold.withValues(alpha: 0.2) : AppColors.border, borderRadius: BorderRadius.circular(12)), child: Icon(ach['icon'], color: isCompleted ? AppColors.gold : AppColors.textMuted, size: 24)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(ach['title'], style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text(ach['desc'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.2)), const SizedBox(height: 8),
                          Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? AppColors.gold : AppColors.neonCyan)))), const SizedBox(width: 8), Text('${ach['curr']}/${ach['targ']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))]),
                        ])),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (ach['rp'] > 0) Text('+${ach['rp']} RP', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 12)),
                            if (ach['m'] > 0) Text('+\$${ach['m'] >= 1e6 ? "${(ach['m'] / 1e6).toStringAsFixed(1)}M" : "${(ach['m'] / 1000).toStringAsFixed(0)}K"}', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900, fontSize: 12)),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: ach['c'] ? AppColors.border : (isCompleted ? AppColors.gold : AppColors.surfaceElevated), foregroundColor: ach['c'] ? AppColors.textMuted : AppColors.darkBrown, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: const Size(64, 28), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: ach['c'] ? Colors.transparent : AppColors.border, width: 2)), elevation: isCompleted && !ach['c'] ? 4 : 0),
                              onPressed: (isCompleted && !ach['c']) ? () => _claimReward(i, ach['m'], ach['rp']) : null,
                              child: Text(ach['c'] ? 'ALINDI' : (isCompleted ? 'AL' : 'KİLİTLİ'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isCompleted && !ach['c'] ? AppColors.darkBrown : Colors.white54)),
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