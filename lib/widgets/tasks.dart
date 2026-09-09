// lib/widgets/tasks.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';

class TasksDialog extends StatefulWidget {
  const TasksDialog({super.key});
  static Future<void> show(BuildContext context) {
    return showDialog(context: context, builder: (context) => const TasksDialog());
  }
  @override State<TasksDialog> createState() => _TasksDialogState();
}

class _TasksDialogState extends State<TasksDialog> {

  void _claimTask(int index, double money, int rp) {
    final state = context.read<GameState>();
    if (state.claimedTasks[index]) return;
    state.claimedTasks[index] = true;
    if (money > 0) state.updateMoney(money);
    if (rp > 0) state.updateResearchPoints(rp);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppColors.surface, content: Text('Görev Tamamlandı!', style: TextStyle(color: AppColors.profit, fontWeight: FontWeight.bold))));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    
    // REKLAM VE AKTİFLİK ODAKLI GÜNLÜK GÖREVLER
    final List<Map<String, dynamic>> tasks = [
      {'title': 'Sermaye Enjeksiyonu (3 Reklam İzle)', 'icon': Icons.ondemand_video_rounded, 'curr': state.statAdsWatched, 'targ': 3, 'money': 50000.0, 'rp': 0, 'claimed': state.claimedTasks[0]},
      {'title': 'Çarkıfelek (1 Kez Çark Çevir)', 'icon': Icons.casino_rounded, 'curr': state.statWheelSpins, 'targ': 1, 'money': 0.0, 'rp': 5, 'claimed': state.claimedTasks[1]},
      {'title': 'Aktif Mesai (20 Kez Manuel Üret)', 'icon': Icons.touch_app_rounded, 'curr': state.statClicks, 'targ': 20, 'money': 15000.0, 'rp': 0, 'claimed': state.claimedTasks[2]},
      {'title': 'Piyasayı Yokla (Borsada 3 İşlem)', 'icon': Icons.show_chart_rounded, 'curr': state.statStocks, 'targ': 3, 'money': 0.0, 'rp': 2, 'claimed': state.claimedTasks[3]},
    ];

    bool isUnlocked = state.factories[0].totalLevel >= 30;

    return Dialog(
      backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 560),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border, width: 3), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 25, offset: const Offset(0, 10))]),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
              decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16)), border: Border(bottom: BorderSide(color: AppColors.border, width: 3))),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.task_alt_rounded, color: AppColors.neonCyan, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('tasks.title'.tr(), style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.neonCyan)), Text('tasks.refresh_info'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 11))])),
                  IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.gold), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: isUnlocked ? ListView.separated(
                padding: const EdgeInsets.all(16), itemCount: tasks.length, separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  var t = tasks[i];
                  bool isCompleted = (t['curr'] as int) >= (t['targ'] as int);
                  double progress = ((t['curr'] as int) / (t['targ'] as int)).clamp(0.0, 1.0);
                  
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isCompleted ? AppColors.profit : AppColors.border, width: 2)),
                    child: Row(
                      children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)), child: Icon(t['icon'], color: isCompleted ? AppColors.profit : AppColors.textSecondary, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t['title'], style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 13)), const SizedBox(height: 6),
                          Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? AppColors.profit : AppColors.neonCyan)))), const SizedBox(width: 8), Text('${t['curr']}/${t['targ']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold))]),
                        ])),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (t['money'] > 0) Text('+\$${(t['money'] / 1000).toStringAsFixed(0)}K', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900, fontSize: 12)),
                            if (t['rp'] > 0) Text('+${t['rp']} RP', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 12)),
                            const SizedBox(height: 4),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: t['claimed'] ? AppColors.border : (isCompleted ? AppColors.profit : AppColors.surfaceElevated), foregroundColor: t['claimed'] ? Colors.white30 : AppColors.darkBrown, minimumSize: const Size(60, 30), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: t['claimed'] ? Colors.transparent : AppColors.border, width: 2))),
                              onPressed: (isCompleted && !t['claimed']) ? () => _claimTask(i, t['money'], t['rp']) : null,
                              child: Text(t['claimed'] ? 'ALINDI' : (isCompleted ? 'AL' : 'SÜRÜYOR'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isCompleted && !t['claimed'] ? AppColors.darkBrown : Colors.white54)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ) : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.lock_rounded, color: AppColors.loss, size: 64), const SizedBox(height: 16), Text('tasks.locked_title'.tr(), style: AppTheme.titleStyle(fontSize: 20).copyWith(color: AppColors.loss)), const SizedBox(height: 12), const Padding(padding: EdgeInsets.symmetric(horizontal: 32), child: Text('Günlük görevlerin açılması için en az 1 fabrikayı Seviye 30 yapmalısın.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4)))]))
            ),
          ],
        ),
      ),
    );
  }
}