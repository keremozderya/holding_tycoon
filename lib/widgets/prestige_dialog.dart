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
        width: 340,
        decoration: BoxDecoration(
          color: AppColors.background, 
          borderRadius: BorderRadius.zero,
          border: Border.all(color: canPrestige ? AppColors.gold : AppColors.border, width: 4),
          boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 25, offset: Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface, 
                borderRadius: BorderRadius.zero,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_rounded, color: AppColors.gold, size: 20),
                        const SizedBox(width: 8),
                        Text('prestige.badge'.tr().toUpperCase(), style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () { AudioService.instance.playSfx('click.mp3'); Navigator.pop(context); },
                    child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 28),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('prestige.title'.tr().toUpperCase(), style: AppTheme.titleStyle(fontSize: 24).copyWith(color: AppColors.gold)),
                  const SizedBox(height: 12),
                  Text('prestige.description'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface, 
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: AppColors.border, width: 3),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('prestige.current_turnover'.tr().toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900)),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: Colors.black, child: Text('\$${_formatTurnover(currentTurnover)} / 100 Qi', style: TextStyle(color: canPrestige ? AppColors.profit : AppColors.gold, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
                          child: LinearProgressIndicator(
                            value: progress, minHeight: 12,
                            backgroundColor: Colors.black,
                            valueColor: AlwaysStoppedAnimation<Color>(canPrestige ? AppColors.profit : AppColors.gold),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.border, height: 1, thickness: 3),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('prestige.earnable_rp'.tr().toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                              decoration: BoxDecoration(
                                color: Colors.black, 
                                border: Border.all(color: AppColors.neonCyan, width: 2),
                              ),
                              child: Text('+$earnableRP RP', style: const TextStyle(color: AppColors.neonCyan, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.loss, width: 2)),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_rounded, color: AppColors.loss, size: 24),
                        const SizedBox(width: 12),
                        Expanded(child: Text('prestige.warning'.tr().toUpperCase(), style: const TextStyle(color: AppColors.loss, fontSize: 12, fontWeight: FontWeight.w900))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrestigeHeavyButton(
                    width: double.infinity, height: 55,
                    color: canPrestige ? AppColors.gold : AppColors.surfaceElevated,
                    shadowColor: canPrestige ? const Color(0xFF8B6B32) : Colors.black,
                    onPressed: canPrestige ? () { 
                      HapticFeedback.heavyImpact();
                      AudioService.instance.playSfx('cash.mp3');
                      Navigator.pop(context); 
                      onPrestigeConfirmed(); 
                    } : null,
                    child: Text(
                      canPrestige ? 'prestige.btn_action'.tr(params: {'rp': earnableRP.toString()}) : 'prestige.btn_progress'.tr(params: {'percent': (progress * 100).toInt().toString()}),
                      style: TextStyle(color: canPrestige ? AppColors.darkBrown : AppColors.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 14),
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

class PrestigeHeavyButton extends StatefulWidget {
  final VoidCallback? onPressed; final Widget child; final Color color; final Color shadowColor; final double height; final double? width;
  const PrestigeHeavyButton({super.key, required this.onPressed, required this.child, required this.color, required this.shadowColor, this.height = 50, this.width});
  @override State<PrestigeHeavyButton> createState() => _PrestigeHeavyButtonState();
}
class _PrestigeHeavyButtonState extends State<PrestigeHeavyButton> {
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
          Positioned(bottom: 0, left: 0, right: 0, top: 6, child: Container(decoration: BoxDecoration(color: isDisabled ? AppColors.border.withValues(alpha: 0.5) : widget.shadowColor, border: Border.all(color: Colors.black87, width: 2.5)))),
          AnimatedPositioned(duration: const Duration(milliseconds: 60), bottom: _isPressed || isDisabled ? 0 : 6, left: 0, right: 0, top: _isPressed || isDisabled ? 6 : 0, child: Container(decoration: BoxDecoration(color: isDisabled ? AppColors.surfaceElevated : widget.color, border: Border.all(color: Colors.black87, width: 2.5)), child: Center(child: widget.child))),
        ]),
      ),
    );
  }
}