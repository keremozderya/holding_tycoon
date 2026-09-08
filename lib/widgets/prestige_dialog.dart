// lib/widgets/prestige_dialog.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';

class PrestigeDialog extends StatelessWidget {
  final double currentTurnover;
  final VoidCallback onPrestigeConfirmed;

  static const double prestigeThreshold = 1.0e20;

  const PrestigeDialog({
    super.key,
    required this.currentTurnover,
    required this.onPrestigeConfirmed,
  });

  static Future<void> show(
    BuildContext context, {
    required double currentTurnover,
    required VoidCallback onPrestigeConfirmed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PrestigeDialog(
        currentTurnover: currentTurnover,
        onPrestigeConfirmed: onPrestigeConfirmed,
      ),
    );
  }

  int _calculateEarnableRP() {
    if (currentTurnover < prestigeThreshold) return 0;
    final ratio = currentTurnover / prestigeThreshold;
    return (10 * math.sqrt(ratio)).floor();
  }

  String _formatTurnover(double value) {
    if (value >= 1e24) return '${(value / 1e24).toStringAsFixed(2)} Sp';
    if (value >= 1e21) return '${(value / 1e21).toStringAsFixed(2)} Sx';
    if (value >= 1e18) return '${(value / 1e18).toStringAsFixed(2)} Qi';
    if (value >= 1e15) return '${(value / 1e15).toStringAsFixed(2)} Qa';
    if (value >= 1e12) return '${(value / 1e12).toStringAsFixed(2)} T';
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(2)} B';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrestige = currentTurnover >= prestigeThreshold;
    final int earnableRP = _calculateEarnableRP();
    final double progress = (currentTurnover / prestigeThreshold).clamp(0.0, 1.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 330,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: canPrestige ? AppColors.gold : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 25,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'prestige.badge'.tr(),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'prestige.title'.tr(),
              style: AppTheme.titleStyle(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'prestige.description'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'prestige.current_turnover'.tr(),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      Text(
                        '\$${_formatTurnover(currentTurnover)} / 100 Qi',
                        style: TextStyle(
                          color: canPrestige ? AppColors.profit : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceMono',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.border.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        canPrestige ? AppColors.profit : AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'prestige.earnable_rp'.tr(),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      Text(
                        '+$earnableRP RP',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'SpaceMono',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.loss.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.loss, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'prestige.warning'.tr(),
                      style: const TextStyle(color: AppColors.loss, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canPrestige ? AppColors.gold : AppColors.surfaceElevated,
                  foregroundColor: canPrestige ? Colors.white : AppColors.textMuted,
                  elevation: canPrestige ? 4 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: canPrestige
                    ? () {
                        Navigator.pop(context);
                        onPrestigeConfirmed();
                      }
                    : null,
                child: Text(
                  canPrestige 
                      ? 'prestige.btn_action'.tr(params: {'rp': earnableRP.toString()})
                      : 'prestige.btn_progress'.tr(params: {'percent': (progress * 100).toInt().toString()}),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontSize: 12,
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