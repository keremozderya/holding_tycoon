// lib/widgets/prestige_dialog.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/translation_service.dart';
import '../services/audio_service.dart';
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
    if (currentTurnover < prestigeThreshold) {
      return 0;
    }
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
        decoration: BoxDecoration(
          color: AppColors.background, 
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: canPrestige ? AppColors.gold : AppColors.border, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 25, spreadRadius: 2)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface, 
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: AppColors.border, width: 3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 16),
                        const SizedBox(width: 6),
                        Text('prestige.badge'.tr(), style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: AppColors.gold, size: 24),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('prestige.title'.tr(), style: AppTheme.titleStyle(fontSize: 22).copyWith(color: AppColors.gold)),
                  const SizedBox(height: 8),
                  Text('prestige.description'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 20),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface, 
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('prestige.current_turnover'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('\$${_formatTurnover(currentTurnover)} / 100 Qi', style: TextStyle(color: canPrestige ? AppColors.profit : AppColors.gold, fontSize: 13, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress, minHeight: 8,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(canPrestige ? AppColors.profit : AppColors.gold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.border, height: 1, thickness: 2),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('prestige.earnable_rp'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('+$earnableRP RP', style: const TextStyle(color: AppColors.neonCyan, fontSize: 18, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.loss.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.loss)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.loss, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('prestige.warning'.tr(), style: const TextStyle(color: AppColors.loss, fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canPrestige ? AppColors.gold : AppColors.surface,
                        foregroundColor: canPrestige ? AppColors.darkBrown : AppColors.textMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14), 
                          side: const BorderSide(color: AppColors.border, width: 2)
                        ),
                        elevation: canPrestige ? 6 : 0,
                      ),
                      onPressed: canPrestige ? () { 
                        HapticFeedback.heavyImpact();
                        AudioService.instance.playSfx('cash.mp3');
                        Navigator.pop(context); 
                        onPrestigeConfirmed(); 
                      } : null,
                      child: Text(
                        canPrestige ? 'prestige.btn_action'.tr(params: {'rp': earnableRP.toString()}) : 'prestige.btn_progress'.tr(params: {'percent': (progress * 100).toInt().toString()}),
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}