// lib/widgets/prestige_dialog.dart
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart' hide AnimatedContainer, Container, Icon, Text;
import 'adaptive_widgets.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/translation_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class PrestigeDialog extends StatelessWidget {
  final VoidCallback onPrestigeConfirmed;

  const PrestigeDialog({
    super.key,
    required this.onPrestigeConfirmed,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onPrestigeConfirmed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PrestigeDialog(
        onPrestigeConfirmed: onPrestigeConfirmed,
      ),
    );
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
    final state = context.watch<GameState>();
    final liveTurnover = state.statTotalEarned;
    final bool canPrestige = state.canPrestige;
    final int earnableRP = state.calculateEarnableRP(liveTurnover);
    final double progress = (liveTurnover / GameState.prestigeThreshold).clamp(0.0, 1.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 360,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.black, width: 5),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), 
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                border: Border(bottom: BorderSide(color: Colors.black, width: 4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_rounded, color: Colors.black, size: 24),
                        const SizedBox(width: 10),
                        Text('prestige.badge'.tr().toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () { AudioService.instance.playSfx('click.mp3'); Navigator.pop(context); },
                    child: const Icon(Icons.close_rounded, color: Colors.black, size: 32),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    FittedBox(fit: BoxFit.scaleDown, child: Text('prestige.title'.tr().toUpperCase(), style: AppTheme.titleStyle(fontSize: 28).copyWith(color: Colors.black, shadows: []))),
                    const SizedBox(height: 16),
                    Text('prestige.description'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 28),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black, width: 4),
                        boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('prestige.current_turnover'.tr().toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900)))),
                              const SizedBox(width: 8),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)), child: Text('\$${_formatTurnover(liveTurnover)} / 100 Qi', style: TextStyle(color: canPrestige ? AppColors.profit : Colors.black, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 3)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress, minHeight: 16,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation<Color>(canPrestige ? AppColors.profit : AppColors.gold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: Colors.black, height: 1, thickness: 3),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('prestige.earnable_rp'.tr().toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE), 
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black, width: 3),
                                ),
                                child: Text('+$earnableRP RP', style: const TextStyle(color: AppColors.neonCyan, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 3)),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded, color: AppColors.loss, size: 28),
                          const SizedBox(width: 12),
                          Expanded(child: Text('prestige.warning'.tr().toUpperCase(), style: const TextStyle(color: AppColors.loss, fontSize: 12, fontWeight: FontWeight.w900))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    PrestigeHeavyButton(
                      width: double.infinity, height: 60,
                      color: canPrestige ? AppColors.gold : const Color(0xFFF1F5F9),
                      shadowColor: canPrestige ? Colors.orange.shade700 : Colors.grey.shade400,
                      onPressed: canPrestige ? () { 
                        HapticFeedback.heavyImpact();
                        AudioService.instance.playSfx('cash.mp3');
                        Navigator.pop(context); 
                        onPrestigeConfirmed(); 
                      } : null,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          canPrestige ? 'prestige.btn_action'.tr(params: {'rp': earnableRP.toString()}) : 'prestige.btn_progress'.tr(params: {'percent': (progress * 100).toInt().toString()}),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
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
          Positioned(bottom: 0, left: 0, right: 0, top: 6, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade400 : widget.shadowColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)))),
          AnimatedPositioned(duration: const Duration(milliseconds: 60), bottom: _isPressed || isDisabled ? 0 : 6, left: 0, right: 0, top: _isPressed || isDisabled ? 6 : 0, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade300 : widget.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)), child: Center(child: widget.child))),
        ]),
      ),
    );
  }
}
