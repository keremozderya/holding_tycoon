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

  // SENİN BELİRLEDİĞİN 10 SABİT DİLİM
  final List<Map<String, dynamic>> _slices = [
    {'line1': '100K',   'line2': 'NAKİT', 'color': const Color(0xFF455A64), 'value': 1e5},
    {'line1': '1M',     'line2': 'NAKİT', 'color': const Color(0xFF00ACC1), 'value': 1e6},
    {'line1': '500M',   'line2': 'NAKİT', 'color': const Color(0xFF43A047), 'value': 5e8},
    {'line1': '1B',     'line2': 'NAKİT', 'color': const Color(0xFF689F38), 'value': 1e9},
    {'line1': '500B',   'line2': 'NAKİT', 'color': const Color(0xFFF57C00), 'value': 5e11},
    {'line1': '1T',     'line2': 'NAKİT', 'color': const Color(0xFFE64A19), 'value': 1e12},
    {'line1': '500Qa',  'line2': 'NAKİT', 'color': const Color(0xFF8E24AA), 'value': 5e17},
    {'line1': '500Sx',  'line2': 'NAKİT', 'color': const Color(0xFF1E88E5), 'value': 5e23},
    {'line1': '1Sp',    'line2': 'NAKİT', 'color': AppColors.gold,          'value': 1e24},
    {'line1': '1No',    'line2': 'İKRAMİYE','color': AppColors.lighthouseRed, 'value': 1e30},
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

  // OYUNCUNUN CİROSUNA (GELİRİNE) GÖRE DENGELİ ŞANS SİSTEMİ
  int _getBalancedSlice(double income) {
    double r = math.Random().nextDouble() * 100;
    
    if (income < 1e5) { 
      // Erken Aşama (0 - 100K/s)
      if (r < 60) return 0; // %60: 100K
      if (r < 90) return 1; // %30: 1M
      if (r < 98) return 2; // %8: 500M
      return 3;             // %2: 1B (Büyük İkramiye Şansı)
    } 
    else if (income < 1e8) { 
      // (100K/s - 100M/s)
      if (r < 30) return 1; // 1M
      if (r < 65) return 2; // 500M
      if (r < 90) return 3; // 1B
      if (r < 98) return 4; // 500B
      return 5;             // 1T
    } 
    else if (income < 1e11) { 
      // (100M/s - 100B/s)
      if (r < 25) return 2; // 500M
      if (r < 55) return 3; // 1B
      if (r < 80) return 4; // 500B
      if (r < 95) return 5; // 1T
      return 6;             // 500Qa
    } 
    else if (income < 1e16) { 
      // (100B/s - 10Qa/s)
      if (r < 25) return 4; // 500B
      if (r < 55) return 5; // 1T
      if (r < 85) return 6; // 500Qa
      if (r < 98) return 7; // 500Sx
      return 8;             // 1Sp
    } 
    else if (income < 1e22) { 
      // (10Qa/s - 10Sx/s)
      if (r < 30) return 5; // 1T
      if (r < 60) return 6; // 500Qa
      if (r < 85) return 7; // 500Sx
      if (r < 98) return 8; // 1Sp
      return 9;             // 1No
    } 
    else { 
      // Zengin ve Oyun Sonu (10Sx/s ve üzeri)
      if (r < 20) return 6; // 500Qa
      if (r < 50) return 7; // 500Sx
      if (r < 80) return 8; // 1Sp
      return 9;             // 1No
    }
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

        // Şansı oyuncunun o anki saniyelik cirosuna göre hesapla
        _selectedSlice = _getBalancedSlice(state.baseIncomePerSecond);
        
        final double sweep = (2 * math.pi) / _slices.length;
        // Ok tepede (-pi/2). Seçilen dilimi merkeze hizalayan fizik rotasyonu (6 tur atar)
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
    double rewardAmount = slice['value'];

    state.updateMoney(rewardAmount);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text('Tebrikler! +\$${slice['line1']} kazandınız!', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900)),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 25)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32),
                Text('ŞANS ÇARKI', style: AppTheme.titleStyle(fontSize: 22).copyWith(color: AppColors.gold)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.gold),
                  onPressed: _isSpinning ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'Çarkı çevirin, kasanıza devasa nakit akıtın!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: 280, height: 280, // Çark biraz daha büyütüldü
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animation.value,
                        child: CustomPaint(size: const Size(270, 270), painter: WheelPainter(slices: _slices)),
                      );
                    },
                  ),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.darkBrown, shape: BoxShape.circle, border: Border.all(color: AppColors.gold, width: 3.5), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)]),
                    child: const Center(child: Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 22)),
                  ),
                  Positioned(
                    top: 0,
                    child: Transform.rotate(
                      angle: math.pi,
                      child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 32, shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))]),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSpinning ? AppColors.surface : AppColors.gold,
                  foregroundColor: AppColors.darkBrown,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.darkBrown, width: 2)),
                  elevation: 6,
                ),
                icon: Icon(_isSpinning ? Icons.hourglass_top_rounded : Icons.ondemand_video_rounded, size: 22),
                label: Text(_isSpinning ? 'DÖNÜYOR...' : 'REKLAM İZLE & ÇEVİR', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.8)),
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
    final double sweep = (2 * math.pi) / slices.length; // 10 dilim için 36 derece
    final double radius = size.width / 2;

    for (int i = 0; i < slices.length; i++) {
      final fillPaint = Paint()..color = slices[i]['color']..style = PaintingStyle.fill;
      canvas.drawArc(rect, i * sweep, sweep, true, fillPaint);

      final linePaint = Paint()..color = AppColors.darkBrown..strokeWidth = 2.0..style = PaintingStyle.stroke;
      canvas.drawArc(rect, i * sweep, sweep, true, linePaint);

      canvas.save();
      // Tam ortaya git
      canvas.translate(radius, radius);
      // Dilimin orta açısına dön
      canvas.rotate(i * sweep + sweep / 2);

      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: '${slices[i]['line1']}\n',
            // 10 dilim olduğu için font boyutunu sıkışmaması için 12'ye indirdik
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono', shadows: [Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(1, 1))]),
          ),
          TextSpan(
            text: slices[i]['line2'],
            style: const TextStyle(color: AppColors.sandYellow, fontSize: 8, fontWeight: FontWeight.w800, shadows: [Shadow(color: Colors.black87, blurRadius: 2, offset: Offset(1, 1))]),
          ),
        ],
      );

      final textPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();

      // Metni dış çizgiye yakın hizala ve yönünü düzelt
      canvas.translate(radius * 0.65, 0); 
      canvas.rotate(math.pi / 2); 
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      
      canvas.restore();
    }

    // Dış Altın Halka
    canvas.drawCircle(Offset(radius, radius), radius - 1.5, Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = 5.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}