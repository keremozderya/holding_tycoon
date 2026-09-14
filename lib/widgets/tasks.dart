// lib/widgets/tasks.dart
// ignore_for_file: discarded_futures

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
        SnackBar(
          backgroundColor: Colors.white, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.black, width: 3)),
          content: const Text('Görev Tamamlandı!', style: TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    
    final List<Map<String, dynamic>> tasks = [
      {'title': 'Sermaye Enjeksiyonu (3 Reklam İzle)', 'icon': Icons.settings_input_antenna_rounded, 'curr': state.statAdsWatched, 'targ': 3, 'reward': '+\$${_formatNum(state.getTaskMoneyReward(0))}', 'claimed': state.claimedTasks[0]},
      {'title': 'Makine Çarkı (1 Kez Çark Çevir)', 'icon': Icons.settings_rounded, 'curr': state.statWheelSpins, 'targ': 1, 'reward': '+5 RP', 'claimed': state.claimedTasks[1]},
      {'title': 'Aktif Mesai (20 Kez Manuel Üret)', 'icon': Icons.precision_manufacturing_rounded, 'curr': state.statClicks, 'targ': 20, 'reward': '+\$${_formatNum(state.getTaskMoneyReward(2))}', 'claimed': state.claimedTasks[2]},
      {'title': 'Piyasayı Yokla (Borsada 3 İşlem)', 'icon': Icons.candlestick_chart_rounded, 'curr': state.statStocks, 'targ': 3, 'reward': '+2 RP', 'claimed': state.claimedTasks[3]},
    ];

    return Dialog(
      backgroundColor: Colors.transparent, 
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
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
                    decoration: BoxDecoration(color: AppColors.neonCyan, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)), 
                    child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('tasks.title'.tr().toUpperCase(), style: AppTheme.titleStyle(fontSize: 22).copyWith(color: Colors.black, shadows: []))), 
                        const SizedBox(height: 4), 
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('tasks.refresh_info'.tr().toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w900))),
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
                itemCount: tasks.length, 
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  var t = tasks[i];
                  bool isCompleted = (t['curr'] as int) >= (t['targ'] as int);
                  double progress = ((t['curr'] as int) / (t['targ'] as int)).clamp(0.0, 1.0);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(20), 
                      border: Border.all(color: isCompleted ? AppColors.profit : Colors.black, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48, 
                          decoration: BoxDecoration(color: isCompleted ? AppColors.profit : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)), 
                          child: Icon(t['icon'], color: isCompleted ? Colors.white : AppColors.textMuted, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            children: [
                              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(t['title'].toString().toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5))), 
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)), 
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: const Color(0xFFF1F5F9), valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? AppColors.profit : AppColors.neonCyan)),
                                      ),
                                    ),
                                  ), 
                                  const SizedBox(width: 8), 
                                  Flexible(
                                    flex: 2,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text('${t['curr']}/${t['targ']}', style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                                    )
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)), 
                              child: FittedBox(fit: BoxFit.scaleDown, child: Text(t['reward'] as String, style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'SpaceMono'))),
                            ),
                            const SizedBox(height: 10),
                            TaskHeavyButton(
                              width: 72, height: 36,
                              color: t['claimed'] ? const Color(0xFFE2E8F0) : (isCompleted ? AppColors.profit : const Color(0xFFF1F5F9)),
                              shadowColor: t['claimed'] ? Colors.grey.shade400 : (isCompleted ? Colors.green.shade800 : Colors.grey.shade400),
                              onPressed: (isCompleted && !t['claimed']) ? () => _claimTask(i) : null,
                              child: Text(t['claimed'] ? 'ALINDI' : (isCompleted ? 'AL' : 'BEKLİYOR'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isCompleted && !t['claimed'] ? Colors.white : Colors.grey.shade500)),
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
          Positioned(bottom: 0, left: 0, right: 0, top: 4, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade400 : widget.shadowColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 3)))),
          AnimatedPositioned(duration: const Duration(milliseconds: 60), bottom: _isPressed || isDisabled ? 0 : 4, left: 0, right: 0, top: _isPressed || isDisabled ? 4 : 0, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade300 : widget.color, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 3)), child: Center(child: widget.child))),
        ]),
      ),
    );
  }
}
