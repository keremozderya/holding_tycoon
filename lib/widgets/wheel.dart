// lib/widgets/wheel.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/admob_service.dart';
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
    {'line1': '15 DK', 'line2': 'GELİR', 'color': AppColors.islandGreen, 'type': 'money', 'mult': 15 * 60},
    {'line1': '+20', 'line2': 'RP', 'color': AppColors.oceanBlue, 'type': 'rp', 'amount': 20},
    {'line1': '30 DK', 'line2': 'GELİR', 'color': const Color(0xFF689F38), 'type': 'money', 'mult': 30 * 60},
    {'line1': '1 SAAT', 'line2': 'GELİR', 'color': AppColors.gold, 'type': 'money', 'mult': 60 * 60},
    {'line1': '+40', 'line2': 'RP', 'color': const Color(0xFF00ACC1), 'type': 'rp', 'amount': 40},
    {'line1': '3 SAAT', 'line2': 'İKRAMİYE', 'color': AppColors.lighthouseRed, 'type': 'money', 'mult': 3 * 60 * 60},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800));
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning) return;

    AdMobService.showRewardedAd(
      context: context,
      onRewardEarned: () {
        setState(() { _isSpinning = true; });
        final state = context.read<GameState>();
        state.incrementAdsWatched();
        state.incrementWheelSpins();

        _selectedSlice = math.Random().nextInt(_slices.length);
        
        final double sweep = (2 * math.pi) / _slices.length;
        // Ok tepede (-pi/2). Dilimin merkezi ibreye denk gelecek açı
        final double targetRotation = (6 * 2 * math.pi) - (_selectedSlice * sweep) - (sweep / 2) - (math.pi / 2);

        _animation = Tween<double>(
          begin: _animation.value % (2 * math.pi),
          end: targetRotation,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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
    String rewardText = '';

    if (slice['type'] == 'money') {
      double rewardAmount = state.baseIncomePerSecond * slice['mult'];
      if (rewardAmount == 0) rewardAmount = 10000;
      state.updateMoney(rewardAmount);
      rewardText = '\$${rewardAmount >= 1e6 ? "${(rewardAmount / 1e6).toStringAsFixed(1)}M" : "${(rewardAmount / 1000).toStringAsFixed(0)}K"}';
    } else {
      int rpAmount = slice['amount'];
      state.updateResearchPoints(rpAmount);
      rewardText = '+$rpAmount RP';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text('Tebrikler! $rewardText kazandınız!', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 25,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32),
                Text(
                  'ŞANS ÇARKI',
                  style: AppTheme.titleStyle(fontSize: 22).copyWith(color: AppColors.gold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.gold),
                  onPressed: _isSpinning ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'Çarkı çevirin, kasanıza devasa servet akıtın!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // ÇARK
            SizedBox(
              width: 270,
              height: 270,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animation.value,
                        child: CustomPaint(
                          size: const Size(260, 260),
                          painter: WheelPainter(slices: _slices),
                        ),
                      );
                    },
                  ),
                  // Göbek
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.darkBrown,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 3.5),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                    ),
                    child: const Center(
                      child: Icon(Icons.star_rounded, color: AppColors.gold, size: 22),
                    ),
                  ),
                  // Tepe İbresi
                  Positioned(
                    top: 0,
                    child: Transform.rotate(
                      angle: math.pi,
                      child: const Icon(
                        Icons.navigation_rounded,
                        color: Colors.white,
                        size: 32,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSpinning ? AppColors.surface : AppColors.gold,
                  foregroundColor: AppColors.darkBrown,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.darkBrown, width: 2),
                  ),
                  elevation: 6,
                ),
                icon: Icon(
                  _isSpinning ? Icons.hourglass_top_rounded : Icons.ondemand_video_rounded,
                  size: 22,
                ),
                label: Text(
                  _isSpinning ? 'DÖNÜYOR...' : 'REKLAM İZLE & ÇEVİR',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.8),
                ),
                onPressed: _isSpinning ? null : _spinWheel,
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

      final linePaint = Paint()..color = AppColors.darkBrown..strokeWidth = 2.5..style = PaintingStyle.stroke;
      canvas.drawArc(rect, i * sweep, sweep, true, linePaint);

      // Metinler
      canvas.save();
      canvas.translate(radius, radius);
      canvas.rotate(i * sweep + sweep / 2);

      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: '${slices[i]['line1']}\n',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'SpaceMono',
              shadows: [Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(1, 1))],
            ),
          ),
          TextSpan(
            text: slices[i]['line2'],
            style: const TextStyle(
              color: AppColors.sandYellow,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(color: Colors.black87, blurRadius: 2, offset: Offset(1, 1))],
            ),
          ),
        ],
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      // Merkeze yakın ve taşmayan konum
      canvas.translate(radius * 0.58, -textPainter.height / 2);
      canvas.rotate(math.pi / 2); // Yazıyı dik okunur hale getirir
      textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
      canvas.restore();
    }

    // Dış Altın Halka
    canvas.drawCircle(
      Offset(radius, radius),
      radius - 1.5,
      Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = 5.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}