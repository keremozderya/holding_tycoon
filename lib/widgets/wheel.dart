// lib/widgets/wheel.dart
// ignore_for_file: discarded_futures

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
  bool _isAdPending = false;
  int _selectedSlice = 0;

  final List<Map<String, dynamic>> _slices = [
    {'line1': '10K',    'line2': 'NAKİT', 'color': const Color(0xFF38BDF8), 'value': 1e4}, 
    {'line1': '100K',   'line2': 'NAKİT', 'color': const Color(0xFFFBBF24), 'value': 1e5}, 
    {'line1': '1M',     'line2': 'NAKİT', 'color': const Color(0xFF4ADE80), 'value': 1e6}, 
    {'line1': '500M',   'line2': 'NAKİT', 'color': const Color(0xFFA855F7), 'value': 5e8}, 
    {'line1': '1B',     'line2': 'NAKİT', 'color': const Color(0xFFF472B6), 'value': 1e9}, 
    {'line1': '500B',   'line2': 'NAKİT', 'color': const Color(0xFF38BDF8), 'value': 5e11},
    {'line1': '1T',     'line2': 'NAKİT', 'color': const Color(0xFFFBBF24), 'value': 1e12},
    {'line1': '500Qa',  'line2': 'NAKİT', 'color': const Color(0xFF4ADE80), 'value': 5e17},
    {'line1': '500Sx',  'line2': 'NAKİT', 'color': const Color(0xFFA855F7), 'value': 5e23},
    {'line1': '1Sp',    'line2': 'NAKİT', 'color': const Color(0xFFF472B6), 'value': 1e24},
    {'line1': '1No',    'line2': 'İKRAMİYE','color': const Color(0xFFF87171),'value': 1e30},
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
    if (_isSpinning || _isAdPending) return;
    setState(() => _isAdPending = true);
    AdMobService.showRewardedAd(
      context: context,
      onRewardEarned: () {
        if (!mounted) return;
        setState(() { _isAdPending = false; _isSpinning = true; });
        final state = context.read<GameState>();
        state.incrementAdsWatched(); state.incrementWheelSpins();
        _selectedSlice = _getBalancedSlice(state.baseIncomePerSecond);
        if (state.researchLevel('node_075') > 0 &&
            math.Random().nextDouble() < state.researchLevel('node_075') * 0.20) {
          _selectedSlice = math.min(_selectedSlice + 1, _slices.length - 1);
        }
        final double sweep = (2 * math.pi) / _slices.length;
        final double targetRotation = (6 * 2 * math.pi) - (_selectedSlice * sweep) - (sweep / 2) - (math.pi / 2);
        _animation = Tween<double>(begin: _animation.value % (2 * math.pi), end: targetRotation)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
        _controller.forward(from: 0).then((_) {
          _grantReward();
          if (mounted) setState(() { _isSpinning = false; });
        });
      },
      onUnavailable: () {
        if (mounted) setState(() => _isAdPending = false);
      },
    );
  }

  void _grantReward() {
    final state = context.read<GameState>();
    final slice = _slices[_selectedSlice];
    final reward = (slice['value'] as double) * (1.0 + state.researchLevel('node_074') * 0.25);
    state.updateMoney(reward);
    final taxAmnesty = state.hasTaxDebt && state.researchLevel('node_060') > 0 &&
        math.Random().nextDouble() < state.researchLevel('node_060') * 0.25;
    if (taxAmnesty) state.applyTaxAmnesty();
    HapticFeedback.heavyImpact(); 
    AudioService.instance.playSfx('cash.mp3');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.black, width: 3)), content: Text('Tebrikler! +\$${reward.toStringAsFixed(0)} kazandınız!${taxAmnesty ? ' Vergi borcunuz affedildi.' : ''}', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32), 
          border: Border.all(color: Colors.black, width: 5.0), 
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text('MAKİNE ÇARKI', style: AppTheme.titleStyle(fontSize: 24).copyWith(color: Colors.black, shadows: [])))),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.black, size: 32), 
                    onPressed: _isSpinning || _isAdPending ? null : () {
                      AudioService.instance.playSfx('click.mp3');
                      Navigator.pop(context);
                    }
                  ),
                ],
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Column(
                  children: [
                    const Text('Yatırım fonu için çarkı çevirin.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 36),
                    
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double wheelSize = math.min(290.0, constraints.maxWidth);
                        return SizedBox(
                          width: wheelSize, height: wheelSize, 
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _animation.value, 
                                    child: CustomPaint(size: Size(wheelSize - 10, wheelSize - 10), painter: WheelPainter(slices: _slices))
                                  );
                                },
                              ),
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.black, width: 4), boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4))]),
                                child: const Center(child: Icon(Icons.attach_money_rounded, color: Colors.black, size: 32)),
                              ),
                              Positioned(
                                top: -12,
                                child: Transform.rotate(
                                  angle: math.pi,
                                  child: const Icon(Icons.arrow_drop_down_rounded, color: Colors.black, size: 56),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                    
                    const SizedBox(height: 48),
                    WheelHeavyButton(
                      width: double.infinity, height: 65,
                      color: _isSpinning ? const Color(0xFFF1F5F9) : AppColors.gold,
                      shadowColor: _isSpinning ? Colors.grey.shade400 : Colors.orange.shade700,
                      onPressed: _isSpinning ? null : () {
                        HapticFeedback.selectionClick();
                        AudioService.instance.playSfx('click.mp3');
                        _spinWheel();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isSpinning ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded, size: 28, color: _isSpinning ? AppColors.textMuted : Colors.black),
                          const SizedBox(width: 10),
                          FittedBox(fit: BoxFit.scaleDown, child: Text(_isSpinning ? 'BEKLENİYOR...' : 'REKLAMLA ÇEVİR', style: TextStyle(color: _isSpinning ? AppColors.textMuted : Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0))),
                        ]
                      )
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

      final linePaint = Paint()..color = Colors.black..strokeWidth = 4.0..style = PaintingStyle.stroke;
      canvas.drawArc(rect, i * sweep, sweep, true, linePaint);

      canvas.save();
      canvas.translate(radius, radius);
      canvas.rotate(i * sweep + sweep / 2);

      final textSpan = TextSpan(
        children: [
          TextSpan(text: '${slices[i]['line1']}\n', style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
        ],
      );

      final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();
      canvas.translate(radius * 0.65, 0); 
      canvas.rotate(math.pi / 2); 
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(Offset(radius, radius), radius - 2.0, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 5.0);
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
          Positioned(bottom: 0, left: 0, right: 0, top: 8, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade400 : widget.shadowColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 4)))),
          AnimatedPositioned(duration: const Duration(milliseconds: 60), bottom: _isPressed || isDisabled ? 0 : 8, left: 0, right: 0, top: _isPressed || isDisabled ? 8 : 0, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade300 : widget.color, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 4)), child: Center(child: widget.child))),
        ]),
      ),
    );
  }
}
