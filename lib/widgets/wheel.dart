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

  // YENİ: Mat ve Kurumsal (Corporate) Renk Paleti
  final List<Map<String, dynamic>> _slices = [
    {'line1': '100K',   'line2': 'NAKİT', 'color': const Color(0xFF2C3E50), 'value': 1e5}, // Mat Çelik Mavisi
    {'line1': '1M',     'line2': 'NAKİT', 'color': const Color(0xFF1F3A3D), 'value': 1e6}, // Mat Petrol
    {'line1': '500M',   'line2': 'NAKİT', 'color': const Color(0xFF3E4E3A), 'value': 5e8}, // Zeytin Yeşili
    {'line1': '1B',     'line2': 'NAKİT', 'color': const Color(0xFF4A3B32), 'value': 1e9}, // Mat Kahve
    {'line1': '500B',   'line2': 'NAKİT', 'color': const Color(0xFF503D33), 'value': 5e11},// Mat Bakır
    {'line1': '1T',     'line2': 'NAKİT', 'color': const Color(0xFF4D2C2C), 'value': 1e12},// Bordo
    {'line1': '500Qa',  'line2': 'NAKİT', 'color': const Color(0xFF2C2F40), 'value': 5e17},// Gece Mavisi
    {'line1': '500Sx',  'line2': 'NAKİT', 'color': const Color(0xFF1D2833), 'value': 5e23},// Antrasit
    {'line1': '1Sp',    'line2': 'NAKİT', 'color': const Color(0xFF8C7343), 'value': 1e24},// Oksit Altın
    {'line1': '1No',    'line2': 'İKRAMİYE','color': const Color(0xFF7A2020),'value': 1e30},// Koyu Kan Kırmızı
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

  int _getBalancedSlice(double income) {
    double r = math.Random().nextDouble() * 100;
    if (income < 1e5) { 
      if (r < 60) return 0; if (r < 90) return 1; if (r < 98) return 2; return 3;             
    } else if (income < 1e8) { 
      if (r < 30) return 1; if (r < 65) return 2; if (r < 90) return 3; if (r < 98) return 4; return 5;             
    } else if (income < 1e11) { 
      if (r < 25) return 2; if (r < 55) return 3; if (r < 80) return 4; if (r < 95) return 5; return 6;             
    } else if (income < 1e16) { 
      if (r < 25) return 4; if (r < 55) return 5; if (r < 85) return 6; if (r < 98) return 7; return 8;             
    } else if (income < 1e22) { 
      if (r < 30) return 5; if (r < 60) return 6; if (r < 85) return 7; if (r < 98) return 8; return 9;             
    } else { 
      if (r < 20) return 6; if (r < 50) return 7; if (r < 80) return 8; return 9;             
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.surface, content: Text('Tebrikler! +\$${slice['line1']} kazandınız!', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.bold))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16), // Köşeler daha sert (Premium)
          border: Border.all(color: AppColors.border, width: 1.5), // İnce metalik gri çizgi
          boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 30, offset: Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32),
                Text('ŞANS ÇARKI', style: AppTheme.titleStyle(fontSize: 20).copyWith(color: AppColors.textPrimary)),
                IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: _isSpinning ? null : () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Yatırım fonu için çarkı çevirin.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 24),
            
            SizedBox(
              width: 270, height: 270, 
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.rotate(angle: _animation.value, child: CustomPaint(size: const Size(260, 260), painter: WheelPainter(slices: _slices)));
                    },
                  ),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle, border: Border.all(color: AppColors.gold, width: 2), boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 8)]),
                    child: const Center(child: Icon(Icons.attach_money_rounded, color: AppColors.gold, size: 20)),
                  ),
                  Positioned(
                    top: -5,
                    child: Transform.rotate(
                      angle: math.pi,
                      child: const Icon(Icons.arrow_drop_down_circle_rounded, color: AppColors.textPrimary, size: 28, shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))]),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSpinning ? AppColors.surfaceElevated : AppColors.gold,
                  foregroundColor: _isSpinning ? AppColors.textSecondary : AppColors.darkBrown,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Daha mat ve sert kenarlar
                  elevation: 0,
                ),
                icon: Icon(_isSpinning ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded, size: 20),
                label: Text(_isSpinning ? 'BEKLENİYOR...' : 'REKLAMLA ÇEVİR', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.0)),
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

      final linePaint = Paint()..color = AppColors.background..strokeWidth = 1.5..style = PaintingStyle.stroke;
      canvas.drawArc(rect, i * sweep, sweep, true, linePaint);

      canvas.save();
      canvas.translate(radius, radius);
      canvas.rotate(i * sweep + sweep / 2);

      final textSpan = TextSpan(
        children: [
          TextSpan(text: '${slices[i]['line1']}\n', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'SpaceMono')),
        ],
      );

      final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();
      canvas.translate(radius * 0.65, 0); 
      canvas.rotate(math.pi / 2); 
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
    // Dış Halka Mat Altın
    canvas.drawCircle(Offset(radius, radius), radius - 1.0, Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = 3.0);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}