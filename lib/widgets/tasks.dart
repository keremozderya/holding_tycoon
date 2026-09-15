// lib/widgets/tasks.dart
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart' hide AnimatedContainer, Container, Icon, Text;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/game_state.dart';
import '../services/audio_service.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import 'adaptive_widgets.dart';

class TasksDialog extends StatefulWidget {
  const TasksDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const TasksDialog(),
    );
  }

  @override
  State<TasksDialog> createState() => _TasksDialogState();
}

class _TasksDialogState extends State<TasksDialog> {
  String _formatNum(double value) {
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
    if (!state.claimTask(index)) return;

    HapticFeedback.heavyImpact();
    AudioService.instance.playSfx('cash.mp3');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        content: Text(
          'tasks.claimed_message'.tr(),
          style: const TextStyle(
            color: AppColors.profit,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  IconData _iconFor(int index) {
    return <IconData>[
      Icons.precision_manufacturing_rounded,
      Icons.upgrade_rounded,
      Icons.candlestick_chart_rounded,
      Icons.settings_rounded,
    ][index];
  }

  String _titleFor(int index) => 'tasks.items.$index.title'.tr();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 4),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'tasks.title'.tr().toUpperCase(),
                            style: AppTheme.titleStyle(fontSize: 22).copyWith(
                              color: AppColors.textPrimary,
                              shadows: const <Shadow>[],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'tasks.daily_info'.tr().toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () {
                      AudioService.instance.playSfx('click.mp3');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: state.allDailyTasksClaimed
                    ? const Color(0xFFDCFCE7)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.science_rounded,
                    color: AppColors.neonCyan,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'tasks.all_clear_bonus'.tr(
                        params: <String, String>{
                          'rp': state.dailyTaskCompletionBonusRp.toString(),
                        },
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(
                    state.isDailyTaskCompletionBonusClaimed
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    color: state.isDailyTaskCompletionBonusClaimed
                        ? AppColors.profit
                        : AppColors.textMuted,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final current = state.getTaskProgress(i);
                  final target = state.getTaskTarget(i);
                  final claimed = state.claimedTasks[i];
                  final completed = current >= target;
                  final progress = target <= 0
                      ? 0.0
                      : (current / target).clamp(0.0, 1.0);
                  final money = state.getTaskMoneyReward(i);
                  final rp = state.getTaskRpReward(i);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: completed ? AppColors.profit : Colors.black,
                        width: 3,
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: completed
                                ? AppColors.profit
                                : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            _iconFor(i),
                            color: completed
                                ? Colors.white
                                : AppColors.textMuted,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _titleFor(i).toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'tasks.progress'.tr(
                                  params: <String, String>{
                                    'current': current.toString(),
                                    'target': target.toString(),
                                  },
                                ),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 9,
                                    backgroundColor: AppColors.surfaceSoft,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      completed
                                          ? AppColors.profit
                                          : AppColors.neonCyan,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '+\$${_formatNum(money)}',
                                style: const TextStyle(
                                  color: AppColors.profit,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  fontFamily: 'SpaceMono',
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '+$rp RP',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  fontFamily: 'SpaceMono',
                                ),
                              ),
                            ),
                            const SizedBox(height: 9),
                            TaskHeavyButton(
                              width: 76,
                              height: 36,
                              color: claimed
                                  ? AppColors.surfaceMuted
                                  : completed
                                      ? AppColors.profit
                                      : AppColors.surfaceSoft,
                              shadowColor: claimed
                                  ? Colors.grey.shade600
                                  : completed
                                      ? Colors.green.shade800
                                      : Colors.grey.shade500,
                              onPressed: completed && !claimed
                                  ? () => _claimTask(i)
                                  : null,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  claimed
                                    ? 'common.claimed'.tr()
                                    : completed
                                        ? 'common.claim'.tr()
                                        : 'common.waiting'.tr(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                    color: completed && !claimed
                                        ? Colors.white
                                        : AppColors.textMuted,
                                  ),
                                ),
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

class TaskHeavyButton extends StatefulWidget {
  const TaskHeavyButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.color,
    required this.shadowColor,
    this.height = 50,
    this.width,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color shadowColor;
  final double height;
  final double? width;

  @override
  State<TaskHeavyButton> createState() => _TaskHeavyButtonState();
}

class _TaskHeavyButtonState extends State<TaskHeavyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: disabled
          ? null
          : (_) {
              HapticFeedback.lightImpact();
              AudioService.instance.playSfx('click.mp3');
              setState(() => _isPressed = true);
            },
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed!();
            },
      onTapCancel: disabled
          ? null
          : () => setState(() => _isPressed = false),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: <Widget>[
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              top: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: disabled
                      ? Colors.grey.shade600
                      : widget.shadowColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 3),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              bottom: _isPressed || disabled ? 0 : 4,
              left: 0,
              right: 0,
              top: _isPressed || disabled ? 4 : 0,
              child: Container(
                decoration: BoxDecoration(
                  color:
                      disabled ? AppColors.surfaceMuted : widget.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Center(child: widget.child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
