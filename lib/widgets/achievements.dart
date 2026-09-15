// lib/widgets/achievements.dart
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart' hide AnimatedContainer, Container, Icon, Text;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/game_state.dart';
import '../services/audio_service.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import 'adaptive_widgets.dart';

class AchievementsDialog extends StatefulWidget {
  const AchievementsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AchievementsDialog(),
    );
  }

  @override
  State<AchievementsDialog> createState() => _AchievementsDialogState();
}

class _AchievementsDialogState extends State<AchievementsDialog> {
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

  void _claimReward(int index) {
    HapticFeedback.heavyImpact();
    AudioService.instance.playSfx('cash.mp3');
    context.read<GameState>().claimAchievement(index);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        content: Text(
          'achievements.reward_claimed'.tr(),
          style: const TextStyle(
            color: AppColors.profit,
            fontWeight: FontWeight.w900,
          ),
        ),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Colors.black26, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.black,
                      size: 32,
                    ),
                    onPressed: () {
                      AudioService.instance.playSfx('click.mp3');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.loss,
                  size: 64,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'achievements.locked_title'.tr(),
                style: AppTheme.titleStyle(fontSize: 24).copyWith(
                  color: AppColors.loss,
                  shadows: const <Shadow>[],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'achievements.locked_description'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AchieveHeavyButton(
                width: double.infinity,
                height: 55,
                color: AppColors.surfaceSoft,
                shadowColor: Colors.grey.shade600,
                onPressed: () {
                  AudioService.instance.playSfx('click.mp3');
                  Navigator.pop(context);
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'common.understood'.tr(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final definitions = List<Map<String, dynamic>>.generate(
      7,
      (index) => <String, dynamic>{
        'title': 'achievements.items.$index.title'.tr(),
        'description': 'achievements.items.$index.description'.tr(),
        'current': state.getAchievementProgress(index),
      },
    );

    final completedCount =
        state.claimedAchievements.fold<int>(0, (sum, value) => sum + value);
    final totalCount = definitions.length * 10;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
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
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'achievements.title'.tr().toUpperCase(),
                          style: AppTheme.titleStyle(fontSize: 22).copyWith(
                            color: AppColors.textPrimary,
                            shadows: const <Shadow>[],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'achievements.total_progress'.tr(
                            params: <String, String>{
                              'current': completedCount.toString(),
                              'total': totalCount.toString(),
                            },
                          ),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'SpaceMono',
                            letterSpacing: 0.5,
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
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: definitions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final definition = definitions[i];
                  final tier = state.claimedAchievements[i];
                  final maxed =
                      tier >= GameState.achievementTargets[i].length;
                  final target = maxed
                      ? GameState.achievementTargets[i].last
                      : GameState.achievementTargets[i][tier];
                  final current = definition['current'] as double;
                  final completed = current >= target && !maxed;
                  final progress = target <= 0
                      ? 0.0
                      : (current / target).clamp(0.0, 1.0);

                  final formattedTarget = i == 1 || i == 6
                      ? _formatNum(target)
                      : target.toInt().toString();
                  final formattedCurrent = i == 1 || i == 6
                      ? _formatNum(current)
                      : current.toInt().toString();

                  final description =
                      (definition['description'] as String).replaceAll(
                    '{target}',
                    formattedTarget,
                  );

                  final moneyReward =
                      maxed ? 0.0 : state.getAchievementMoneyReward(tier);
                  final rpReward =
                      maxed ? 0 : state.getAchievementRpReward(tier);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: completed ? AppColors.gold : Colors.black,
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: completed
                                ? AppColors.gold
                                : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: completed
                                ? Colors.white
                                : AppColors.textMuted,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: maxed
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  maxed
                                      ? 'common.maximum'.tr()
                                      : 'achievements.tier'.tr(
                                          params: <String, String>{
                                            'current': (tier + 1).toString(),
                                            'total': '10',
                                          },
                                        ),
                                  style: TextStyle(
                                    color: maxed
                                        ? AppColors.profit
                                        : Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'SpaceMono',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (definition['title'] as String).toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                maxed
                                    ? 'achievements.all_tiers_complete'.tr()
                                    : description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  height: 1.3,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: maxed ? 1.0 : progress,
                                          minHeight: 8,
                                          backgroundColor:
                                              AppColors.surfaceSoft,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            maxed
                                                ? AppColors.profit
                                                : completed
                                                    ? AppColors.gold
                                                    : AppColors.neonCyan,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    flex: 2,
                                    child: Text(
                                      maxed
                                          ? 'common.completed'.tr()
                                          : '$formattedCurrent/$formattedTarget',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'SpaceMono',
                                      ),
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
                          children: <Widget>[
                            if (!maxed) ...<Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
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
                                  '+$rpReward RP',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    fontFamily: 'SpaceMono',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
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
                                  '+\$${_formatNum(moneyReward)}',
                                  style: const TextStyle(
                                    color: AppColors.profit,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    fontFamily: 'SpaceMono',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            AchieveHeavyButton(
                              width: 72,
                              height: 36,
                              color: maxed
                                  ? AppColors.surfaceMuted
                                  : completed
                                      ? AppColors.gold
                                      : AppColors.surfaceSoft,
                              shadowColor: maxed
                                  ? Colors.grey.shade600
                                  : completed
                                      ? Colors.orange.shade700
                                      : Colors.grey.shade500,
                              onPressed: completed && !maxed
                                  ? () => _claimReward(i)
                                  : null,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  maxed
                                      ? 'common.claimed'.tr()
                                      : completed
                                          ? 'common.claim'.tr()
                                          : 'common.locked'.tr(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: completed
                                        ? Colors.black
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

class AchieveHeavyButton extends StatefulWidget {
  const AchieveHeavyButton({
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
  State<AchieveHeavyButton> createState() => _AchieveHeavyButtonState();
}

class _AchieveHeavyButtonState extends State<AchieveHeavyButton> {
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
