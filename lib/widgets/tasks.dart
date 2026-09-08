// lib/widgets/tasks.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';

class DailyTask {
  final String id;
  final String title;
  final IconData icon;
  final int currentProgress;
  final int targetProgress;
  final double rewardMoney;
  final int rewardRp;
  bool isClaimed;

  DailyTask({
    required this.id,
    required this.title,
    required this.icon,
    required this.currentProgress,
    required this.targetProgress,
    this.rewardMoney = 0.0,
    this.rewardRp = 0,
    this.isClaimed = false,
  });

  bool get isCompleted => currentProgress >= targetProgress;
}

class TasksDialog extends StatefulWidget {
  final int highestFactoryLevel;

  const TasksDialog({super.key, required this.highestFactoryLevel});

  static Future<void> show(BuildContext context, {int highestFactoryLevel = 30}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TasksDialog(highestFactoryLevel: highestFactoryLevel),
    );
  }

  @override
  State<TasksDialog> createState() => _TasksDialogState();
}

class _TasksDialogState extends State<TasksDialog> {
  static const int requiredUnlockLevel = 30;

  late final List<DailyTask> _tasks = [
    DailyTask(
      id: 'task_01',
      title: '15 Kez Fabrika Üretimi Yap',
      icon: Icons.touch_app_rounded,
      currentProgress: 15,
      targetProgress: 15,
      rewardMoney: 25000.0,
    ),
    DailyTask(
      id: 'task_02',
      title: 'Borsadan En Az 1 Lot Hisse Satın Al',
      icon: Icons.show_chart_rounded,
      currentProgress: 1,
      targetProgress: 1,
      rewardMoney: 15000.0,
    ),
    DailyTask(
      id: 'task_03',
      title: 'Herhangi Bir Fabrikayı 5 Seviye Yükselt',
      icon: Icons.trending_up_rounded,
      currentProgress: 3,
      targetProgress: 5,
      rewardRp: 2,
    ),
    DailyTask(
      id: 'task_04',
      title: 'Vergi Tahakkukunu Vaktinde Sıfırla',
      icon: Icons.security_rounded,
      currentProgress: 0,
      targetProgress: 1,
      rewardMoney: 30000.0,
      rewardRp: 1,
    ),
  ];

  void _claimTask(DailyTask task) {
    if (!task.isCompleted || task.isClaimed) return;

    final gameState = context.read<GameState>();
    setState(() {
      task.isClaimed = true;
      if (task.rewardMoney > 0) gameState.updateMoney(task.rewardMoney);
      if (task.rewardRp > 0) gameState.updateResearchPoints(task.rewardRp);
    });

    final rewardText = '${task.rewardMoney > 0 ? "+\$${task.rewardMoney.toStringAsFixed(0)} " : ""}${task.rewardRp > 0 ? "+${task.rewardRp} RP" : ""}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text(
          'tasks.reward_toast'.tr(params: {'reward': rewardText}),
          style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<GameState>();
    final bool isUnlocked = widget.highestFactoryLevel >= requiredUnlockLevel;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 560),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUnlocked ? AppColors.neonCyan.withValues(alpha: 0.4) : AppColors.border,
            width: 1.5,
          ),
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
                      color: isUnlocked
                          ? AppColors.neonCyan.withValues(alpha: 0.15)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.task_alt_rounded,
                      color: isUnlocked ? AppColors.neonCyan : AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'tasks.title'.tr(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'tasks.refresh_info'.tr(),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
              child: isUnlocked
                  ? ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        final progress = (task.currentProgress / task.targetProgress).clamp(0.0, 1.0);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: task.isCompleted
                                  ? AppColors.profit.withValues(alpha: 0.4)
                                  : AppColors.border.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: task.isCompleted
                                      ? AppColors.profit.withValues(alpha: 0.15)
                                      : AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  task.icon,
                                  color: task.isCompleted ? AppColors.profit : AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
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
                                                task.isCompleted ? AppColors.profit : AppColors.neonCyan,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${task.currentProgress}/${task.targetProgress}',
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
                                  if (task.rewardMoney > 0)
                                    Text(
                                      '+\$${(task.rewardMoney / 1000).toStringAsFixed(0)}K',
                                      style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  if (task.rewardRp > 0)
                                    Text(
                                      '+${task.rewardRp} RP',
                                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  const SizedBox(height: 4),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: task.isClaimed
                                          ? AppColors.surfaceElevated
                                          : (task.isCompleted ? AppColors.profit : AppColors.surfaceElevated),
                                      foregroundColor: task.isClaimed ? AppColors.textMuted : Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: const Size(60, 26),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: task.isCompleted && !task.isClaimed ? 2 : 0,
                                    ),
                                    onPressed: (task.isCompleted && !task.isClaimed)
                                        ? () => _claimTask(task)
                                        : null,
                                    child: Text(
                                      task.isClaimed ? 'tasks.claimed'.tr() : (task.isCompleted ? 'tasks.claim'.tr() : 'tasks.in_progress'.tr()),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.loss.withValues(alpha: 0.1),
                                border: Border.all(color: AppColors.loss.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.lock_clock_rounded, color: AppColors.loss, size: 48),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'tasks.locked_title'.tr(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'tasks.locked_desc'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (widget.highestFactoryLevel / requiredUnlockLevel).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: AppColors.surfaceElevated,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'tasks.current_progress'.tr(params: {'level': widget.highestFactoryLevel.toString()}),
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'SpaceMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}