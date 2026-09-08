// lib/widgets/achievements.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int currentProgress;
  final int targetProgress;
  final int rewardRp;
  final double rewardMoney;
  bool isClaimed;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.currentProgress,
    required this.targetProgress,
    this.rewardRp = 0,
    this.rewardMoney = 0.0,
    this.isClaimed = false,
  });

  bool get isCompleted => currentProgress >= targetProgress;
}

class AchievementsDialog extends StatefulWidget {
  const AchievementsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AchievementsDialog(),
    );
  }

  @override
  State<AchievementsDialog> createState() => _AchievementsDialogState();
}

class _AchievementsDialogState extends State<AchievementsDialog> {
  late final List<Achievement> _achievements = [
    Achievement(
      id: 'ach_01',
      title: 'İlk Çekiç',
      description: 'Sanayi sahasında ilk fabrikanı kur.',
      icon: Icons.factory_rounded,
      currentProgress: 1,
      targetProgress: 1,
      rewardMoney: 10000.0,
    ),
    Achievement(
      id: 'ach_02',
      title: 'Seri Üretime Geçiş',
      description: 'Herhangi bir fabrikayı Seviye 30 yap ve 2. ürünü aç.',
      icon: Icons.chair_rounded,
      currentProgress: 30,
      targetProgress: 30,
      rewardRp: 5,
    ),
    Achievement(
      id: 'ach_03',
      title: 'Borsa Spekülatörü',
      description: 'Küresel Borsada işlem yap ve ilk hisseni al.',
      icon: Icons.candlestick_chart_rounded,
      currentProgress: 1,
      targetProgress: 1,
      rewardMoney: 50000.0,
    ),
    Achievement(
      id: 'ach_04',
      title: 'Sadık Mükellef',
      description: 'Vergi borcunu 12 saat dolmadan öde.',
      icon: Icons.receipt_long_rounded,
      currentProgress: 0,
      targetProgress: 1,
      rewardRp: 10,
    ),
    Achievement(
      id: 'ach_05',
      title: 'Sanayi Devrimi',
      description: 'Bir fabrikayı Seviye 100\'e ulaştır.',
      icon: Icons.precision_manufacturing_rounded,
      currentProgress: 45,
      targetProgress: 100,
      rewardRp: 25,
    ),
    Achievement(
      id: 'ach_06',
      title: 'Büyük Tasfiye',
      description: '100 Qi ciro eşiğini aşıp ilk prestijini tamamla.',
      icon: Icons.workspace_premium_rounded,
      currentProgress: 0,
      targetProgress: 1,
      rewardRp: 50,
    ),
    Achievement(
      id: 'ach_07',
      title: 'Dünyaların Sahibi',
      description: '10^33 servete ulaşarak nihai unvanı kazan.',
      icon: Icons.diamond_rounded,
      currentProgress: 0,
      targetProgress: 1,
      rewardRp: 1000,
      rewardMoney: 1.0e30,
    ),
  ];

  void _claimReward(Achievement achievement) {
    if (!achievement.isCompleted || achievement.isClaimed) return;

    final gameState = context.read<GameState>();
    setState(() {
      achievement.isClaimed = true;
      if (achievement.rewardMoney > 0) {
        gameState.updateMoney(achievement.rewardMoney);
      }
      if (achievement.rewardRp > 0) {
        gameState.updateResearchPoints(achievement.rewardRp);
      }
    });

    final rewardText = '${achievement.rewardMoney > 0 ? "+\$${achievement.rewardMoney.toStringAsFixed(0)} " : ""}${achievement.rewardRp > 0 ? "+${achievement.rewardRp} RP" : ""}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text(
          'achievements.reward_toast'.tr(params: {'reward': rewardText}),
          style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<GameState>();
    final completedCount = _achievements.where((a) => a.isCompleted).length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 620),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 25,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'achievements.title'.tr(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'achievements.completed_count'.tr(params: {
                            'completed': completedCount.toString(),
                            'total': _achievements.length.toString(),
                          }),
                          style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _achievements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ach = _achievements[index];
                  final progress = (ach.currentProgress / ach.targetProgress).clamp(0.0, 1.0);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ach.isCompleted
                            ? AppColors.gold.withValues(alpha: 0.5)
                            : AppColors.border.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: ach.isCompleted
                                ? AppColors.gold.withValues(alpha: 0.2)
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            ach.icon,
                            color: ach.isCompleted ? AppColors.gold : AppColors.textMuted,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ach.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                ach.description,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.2),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 5,
                                        backgroundColor: AppColors.surfaceElevated,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          ach.isCompleted ? AppColors.gold : AppColors.neonCyan,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${ach.currentProgress}/${ach.targetProgress}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                      fontFamily: 'SpaceMono',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (ach.rewardRp > 0)
                              Text(
                                '+${ach.rewardRp} RP',
                                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            if (ach.rewardMoney > 0)
                              Text(
                                '+\$${ach.rewardMoney >= 1e6 ? "${(ach.rewardMoney / 1e6).toStringAsFixed(1)}M" : "${(ach.rewardMoney / 1000).toStringAsFixed(0)}K"}',
                                style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ach.isClaimed
                                    ? AppColors.surfaceElevated
                                    : (ach.isCompleted ? AppColors.gold : AppColors.surfaceElevated),
                                foregroundColor: ach.isClaimed ? AppColors.textMuted : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(64, 28),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: ach.isCompleted && !ach.isClaimed ? 2 : 0,
                              ),
                              onPressed: (ach.isCompleted && !ach.isClaimed)
                                  ? () => _claimReward(ach)
                                  : null,
                              child: Text(
                                ach.isClaimed ? 'achievements.claimed'.tr() : (ach.isCompleted ? 'achievements.claim'.tr() : 'achievements.locked'.tr()),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                              ),
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