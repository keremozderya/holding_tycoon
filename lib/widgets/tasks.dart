// lib/widgets/tasks.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/translation_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class TasksDialog extends StatefulWidget {
  const TasksDialog({super.key});
  static Future<void> show(BuildContext context) {
    return showDialog(context: context, builder: (context) => const TasksDialog());
  }
  @override State<TasksDialog> createState() => _TasksDialogState();
}

class _TasksDialogState extends State<TasksDialog> {
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

  void _claimTask(int index) {
    final state = context.read<GameState>();
    if (state.claimedTasks[index]) return;
    
    bool claimed = state.claimTask(index);
    if (claimed) {
      HapticFeedback.heavyImpact();
      AudioService.instance.playSfx('cash.mp3');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surface, 
          content: Text('Görev Tamamlandı!', style: TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    
    final List<Map<String, dynamic>> tasks = [
      {'title': 'Sermaye Enjeksiyonu (3 Reklam İzle)', 'icon': Icons.settings_input_antenna_rounded, 'curr': state.statAdsWatched, 'targ': 3, 'money': state.getTaskMoneyReward(0), 'claimed': state.claimedTasks[0]},
      {'title': 'Makine Çarkı (1 Kez Çark Çevir)', 'icon': Icons.settings_rounded, 'curr': state.statWheelSpins, 'targ': 1, 'money': state.getTaskMoneyReward(1), 'claimed': state.claimedTasks[1]},
      {'title': 'Aktif Mesai (20 Kez Manuel Üret)', 'icon': Icons.precision_manufacturing_rounded, 'curr': state.statClicks, 'targ': 20, 'money': state.getTaskMoneyReward(2), 'claimed': state.claimedTasks[2]},
      {'title': 'Piyasayı Yokla (Borsada 3 İşlem)', 'icon': Icons.candlestick_chart_rounded, 'curr': state.statStocks, 'targ': 3, 'money': state.getTaskMoneyReward(3), 'claimed': state.claimedTasks[3]},
    ];

    return Dialog(
      backgroundColor: Colors.transparent, 
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 560),
        decoration: BoxDecoration(
          color: AppColors.background, 
          borderRadius: BorderRadius.zero, 
          border: Border.all(color: AppColors.border, width: 4), 
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 25, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
              decoration: const BoxDecoration(
                color: AppColors.surface, 
                borderRadius: BorderRadius.zero, 
                border: Border(bottom: BorderSide(color: AppColors.border, width: 4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10), 
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.neonCyan, width: 2)), 
                    child: const Icon(Icons.assignment_turned_in_rounded, color: AppColors.neonCyan, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Text('tasks.title'.tr().toUpperCase(), style: AppTheme.titleStyle(fontSize: 20).copyWith(color: AppColors.neonCyan)), 
                        const SizedBox(height: 4), 
                        Text('tasks.refresh_info'.tr().toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 28), 
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
                padding: const EdgeInsets.all(16), 
                itemCount: tasks.length, 
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  var t = tasks[i];
                  bool isCompleted = (t['curr'] as int) >= (t['targ'] as int);
                  double progress = ((t['curr'] as int) / (t['targ'] as int)).clamp(0.0, 1.0);
                  double moneyVal = t['money'] as double;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface, 
                      borderRadius: BorderRadius.zero, 
                      border: Border.all(color: isCompleted ? AppColors.profit : AppColors.border, width: 3),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44, 
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.zero, border: Border.all(color: isCompleted ? AppColors.profit : AppColors.border, width: 2)), 
                          child: Icon(t['icon'], color: isCompleted ? AppColors.profit : AppColors.textSecondary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            children: [
                              Text(t['title'].toString().toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)), 
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5)), 
                                      child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.black, valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? AppColors.profit : AppColors.neonCyan)),
                                    ),
                                  ), 
                                  const SizedBox(width: 10), 
                                  Text('${t['curr']}/${t['targ']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                              color: Colors.black, 
                              child: Text('+\$${_formatNum(moneyVal)}', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'SpaceMono')),
                            ),
                            const SizedBox(height: 10),
                            TaskHeavyButton(
                              width: 70, height: 35,
                              color: t['claimed'] ? AppColors.border : (isCompleted ? AppColors.profit : AppColors.surfaceElevated),
                              shadowColor: t['claimed'] ? Colors.black : (isCompleted ? const Color(0xFF1B5E20) : Colors.black),
                              onPressed: (isCompleted && !t['claimed']) ? () => _claimTask(i) : null,
                              child: Text(t['claimed'] ? 'ALINDI' : (isCompleted ? 'AL' : 'BEKLİYOR'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isCompleted && !t['claimed'] ? AppColors.darkBrown : Colors.white54)),
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

class TaskHeavyButton extends StatefulWidget {
  final VoidCallback? onPressed; final Widget child; final Color color; final Color shadowColor; final double height; final double? width;
  const TaskHeavyButton({super.key, required this.onPressed, required this.child, required this.color, required this.shadowColor, this.height = 50, this.width});
  @override State<TaskHeavyButton> createState() => _TaskHeavyButtonState();
}
class _TaskHeavyButtonState extends State<TaskHeavyButton> {
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