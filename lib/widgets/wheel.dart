// lib/widgets/wheel.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/admob_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class WheelDialog extends StatefulWidget {
  const WheelDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const WheelDialog(),
    );
  }

  @override
  State<WheelDialog> createState() => _WheelDialogState();
}

class _WheelDialogState extends State<WheelDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSpinning = false;
  int _selectedSlice = 0;

  final List<Map<String, dynamic>> _slices = [
    {'line1': '10K',    'line2': 'NAKİT', 'color': const Color(0xFF3B4D61), 'value': 1e4}, 
    {'line1': '100K',   'line2': 'NAKİT', 'color': const Color(0xFF2C3E50), 'value': 1e5}, 
    {'line1': '1M',     'line2': 'NAKİT', 'color': const Color(0xFF1F3A3D), 'value': 1e6}, 
    {'line1': '500M',   'line2': 'NAKİT', 'color': const Color(0xFF3E4E3A), 'value': 5e8}, 
    {'line1': '1B',     'line2': 'NAKİT', 'color': const Color(0xFF4A3B32), 'value': 1e9}, 
    {'line1': '500B',   'line2': 'NAKİT', 'color': const Color(0xFF503D33), 'value': 5e11},
    {'line1': '1T',     'line2': 'NAKİT', 'color': const Color(0xFF4D2C2C), 'value': 1e12},
    {'line1': '500Qa',  'line2': 'NAKİT', 'color': const Color(0xFF2C2F40), 'value': 5e17},
    {'line1': '500Sx',  'line2': 'NAKİT', 'color': const Color(0xFF1D2833), 'value': 5e23},
    {'line1': '1Sp',    'line2': 'NAKİT', 'color': const Color(0xFF8C7343), 'value': 1e24},
    {'line1': '1No',    'line2': 'İKRAMİYE','color': const Color(0xFF7A2020),'value': 1e30},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800));
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
    
    double lastVibrationAngle = 0.0;
    _controller.addListener(() {
      if ((_animation.value - lastVibrationAngle).abs() > 0.15) {
        HapticFeedback.selectionClick();
        AudioService.instance.playSfx('click.mp3');
        lastVibrationAngle = _animation.value;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getBalancedSlice(double income) {
    double r = math.Random().nextDouble() * 100;
    if (income < 1e5) { 
      if (r < 50) return 0; if (r < 85) return 1; if (r < 97) return 2; if (r < 99.5) return 3; return 4;             
    } else if (income < 1e8) { 
      if (r < 40) return 1; if (r < 75) return 2; if (r < 93) return 3; if (r < 99) return 4; return 5;             
    } else if (income < 1e11) { 
      if (r < 35) return 2; if (r < 70) return 3; if (r < 90) return 4; if (r < 98) return 5; return 6;             
    } else if (income < 1e16) { 
      if (r < 35) return 4; if (r < 70) return 5; if (r < 92) return 6; if (r < 99) return 7; return 8;             
    } else if (income < 1e22) { 
      if (r < 40) return 5; if (r < 75) return 6; if (r < 93) return 7; if (r < 99) return 8; return 9;             
    } else { 
      if (r < 35) return 6; if (r < 70) return 7; if (r < 92) return 8; if (r < 99) return 9; return 10;             
    }
  }

  void _spinWheel() {
    if (_isSpinning) return;
    AdMobService.showRewardedAd(
      context: context,
      onRewardEarned: () {
        setState(() { _isSpinning = true; });
        final state = context.read<GameState>();
        state.incrementAdsWatched(); state.incrementWheelSpins();
        _selectedSlice = _getBalancedSlice(state.baseIncomePerSecond);
        final double sweep = (2 * math.pi) / _slices.length;
        final double targetRotation = (6 * 2 * math.pi) - (_selectedSlice * sweep) - (sweep / 2) - (math.pi / 2);
        _animation = Tween<double>(begin: _animation.value % (2 * math.pi), end: targetRotation)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
        _controller.forward(from: 0).then((_) {
          _grantReward();
          if (mounted) setState(() { _isSpinning = false; });
        });
      },
    );
  }

  void _grantReward() {
    final state = context.read<GameState>();
    final slice = _slices[_selectedSlice];
    state.updateMoney(slice['value']);
    HapticFeedback.heavyImpact(); 
    AudioService.instance.playSfx('cash.mp3');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.surface, content: Text('Tebrikler! +\$${slice['line1']} kazandınız!', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.zero, 
          border: Border.all(color: AppColors.border, width: 4.0), 
          boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 30, offset: Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32),
                Text('MAKİNE ÇARKI', style: AppTheme.titleStyle(fontSize: 22).copyWith(color: AppColors.textPrimary)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 28), 
                  onPressed: _isSpinning ? null : () {
                    AudioService.instance.playSfx('click.mp3');
                    Navigator.pop(context);
                  }
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Yatırım fonu için çarkı çevirin.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            
            SizedBox(
              width: 280, height: 280, 
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.rotate(angle: _animation.value, child: CustomPaint(size: const Size(270, 270), painter: WheelPainter(slices: _slices)));
                    },
                  ),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: Colors.black, border: Border.all(color: AppColors.gold, width: 3), boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 10)]),
                    child: const Center(child: Icon(Icons.attach_money_rounded, color: AppColors.gold, size: 24)),
                  ),
                  Positioned(
                    top: -8,
                    child: Transform.rotate(
                      angle: math.pi,
                      child: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textPrimary, size: 40, shadows: [Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 3))]),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            WheelHeavyButton(
              width: double.infinity, height: 55,
              color: _isSpinning ? AppColors.surfaceElevated : AppColors.gold,
              shadowColor: _isSpinning ? Colors.black : const Color(0xFF8B6B32),
              onPressed: _isSpinning ? null : () {
                HapticFeedback.selectionClick();
                AudioService.instance.playSfx('click.mp3');
                _spinWheel();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isSpinning ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded, size: 24, color: _isSpinning ? AppColors.textMuted : AppColors.darkBrown),
                  const SizedBox(width: 8),
                  Text(_isSpinning ? 'BEKLENİYOR...' : 'REKLAMLA ÇEVİR', style: TextStyle(color: _isSpinning ? AppColors.textMuted : AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0)),
                ]
              )
            ),
          ],
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> slices;
  WheelPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final double sweep = (2 * math.pi) / slices.length; 
    final double radius = size.width / 2;

    for (int i = 0; i < slices.length; i++) {
      final fillPaint = Paint()..color = slices[i]['color']..style = PaintingStyle.fill;
      canvas.drawArc(rect, i * sweep, sweep, true, fillPaint);

      final linePaint = Paint()..color = Colors.black..strokeWidth = 3.0..style = PaintingStyle.stroke;
      canvas.drawArc(rect, i * sweep, sweep, true, linePaint);

      canvas.save();
      canvas.translate(radius, radius);
      canvas.rotate(i * sweep + sweep / 2);

      final textSpan = TextSpan(
        children: [
          TextSpan(text: '${slices[i]['line1']}\n', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
        ],
      );

      final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();
      canvas.translate(radius * 0.65, 0); 
      canvas.rotate(math.pi / 2); 
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(Offset(radius, radius), radius - 1.5, Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = 4.0);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WheelHeavyButton extends StatefulWidget {
  final VoidCallback? onPressed; final Widget child; final Color color; final Color shadowColor; final double height; final double? width;
  const WheelHeavyButton({super.key, required this.onPressed, required this.child, required this.color, required this.shadowColor, this.height = 50, this.width});
  @override State<WheelHeavyButton> createState() => _WheelHeavyButtonState();
}
class _WheelHeavyButtonState extends State<WheelHeavyButton> {
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