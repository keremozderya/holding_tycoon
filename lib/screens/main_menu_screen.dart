// lib/screens/main_menu_screen.dart
// ignore_for_file: discarded_futures, use_build_context_synchronously

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/game_state.dart';
import '../services/translation_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatefulWidget {
  final bool isInitialLaunch;

  const MainMenuScreen({
    super.key,
    this.isInitialLaunch = true,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _isAutoStarting = true;

  @override
  void initState() {
    super.initState();

    if (widget.isInitialLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final state = context.read<GameState>();

        if (!state.isFirstLaunch) {
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) {
              _goToMap();
            }
          });
        } else {
          setState(() {
            _isAutoStarting = false;
          });
        }
      });
    } else {
      _isAutoStarting = false;
    }
  }

  void _goToMap() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => const MapScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _confirmAndStartNewGame() {
    HapticFeedback.selectionClick();
    AudioService.instance.playSfx('click.mp3');

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.black, width: 4),
        ),
        title: const Text(
          'HOLDİNGİ TASFİYE ET',
          style: TextStyle(
            color: AppColors.loss,
            fontWeight: FontWeight.w900,
            fontFamily: 'SpaceMono',
          ),
        ),
        content: const Text(
          'Yeni bir oyun başlatmak mevcut holdinginizi, '
          'tüm şirketlerinizi, fabrikalarınızı ve kasanızı '
          'kalıcı olarak silecektir. Emin misiniz?',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.instance.playSfx('click.mp3');
              Navigator.pop(c);
            },
            child: const Text(
              'İPTAL',
              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          MenuHeavyButton(
            color: AppColors.loss,
            shadowColor: Colors.red.shade900,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () async {
              HapticFeedback.heavyImpact();
              AudioService.instance.playSfx('click.mp3');

              Navigator.pop(c);

              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('game_save_data');
              await prefs.remove('holding_name');
              await prefs.remove('holding_logo_index');

              if (mounted) {
                _showHoldingSetupDialog();
              }
            },
            child: const Text(
              'SİL VE BAŞLA',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showHoldingSetupDialog() {
    String compName = 'Köse Holding';
    int logoIndex = 0;

    final List<IconData> logos = [
      Icons.domain_rounded,
      Icons.account_balance_rounded,
      Icons.precision_manufacturing_rounded,
      Icons.rocket_launch_rounded,
      Icons.local_shipping_rounded,
      Icons.bolt_rounded,
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.black, width: 4.0),
                    boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 8))],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.neonCyan,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.black, width: 3),
                          ),
                          child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 20),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'HOLDİNG KURULUMU',
                            textAlign: TextAlign.center,
                            style: AppTheme.titleStyle(fontSize: 22).copyWith(color: Colors.black, shadows: []),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Kendi holdinginin adını belirle, logosunu seç ve ticari imparatorluğunu kurmaya başla.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold, height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black, width: 3),
                          ),
                          child: TextField(
                            maxLength: 24,
                            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n\r]'))],
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'SpaceMono'),
                            decoration: const InputDecoration(
                              labelText: 'Holding Adı',
                              labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
                              border: InputBorder.none,
                              counterText: '',
                            ),
                            onChanged: (val) {
                              compName = val;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('HOLDİNG LOGOSU', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: List.generate(
                            logos.length,
                            (i) {
                              final bool isSel = logoIndex == i;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  AudioService.instance.playSfx('click.mp3');
                                  setDialogState(() {
                                    logoIndex = i;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSel ? AppColors.gold : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.black, width: 3),
                                    boxShadow: isSel ? const [BoxShadow(color: Colors.black26, offset: Offset(0, 4))] : [],
                                  ),
                                  child: Icon(logos[i], color: isSel ? Colors.black : AppColors.textMuted, size: 32),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 36),
                        MenuHeavyButton(
                          width: double.infinity,
                          height: 60,
                          color: AppColors.profit,
                          shadowColor: Colors.green.shade800,
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            AudioService.instance.playSfx('cash.mp3');
                            final prefs = await SharedPreferences.getInstance();
                            final normalizedName = compName.trim();
                            await prefs.setString('holding_name', normalizedName.isEmpty ? 'Köse Holding' : normalizedName);
                            await prefs.setInt('holding_logo_index', logoIndex);

                            if (context.mounted) {
                              await context.read<GameState>().startNewGameSession();
                              if (context.mounted) {
                                Navigator.pop(context);
                                _goToMap();
                              }
                            }
                          },
                          child: const Text('HOLDİNGİ KUR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF061B37),
                  Color(0xFF0E3A66),
                  Color(0xFF0A6AA1),
                ],
                stops: [0.0, 0.48, 1.0],
              ),
            ),
          ),
          const CartoonStyleBackgroundAnimation(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 300,
                        child: OverflowBox(
                          alignment: Alignment.center,
                          minWidth: 575,
                          maxWidth: 575,
                          minHeight: 575,
                          maxHeight: 575,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.97, end: 1.0),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) {
                              return Transform.scale(scale: scale, child: child);
                            },
                            child: SizedBox(
                              width: 575,
                              height: 575,
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.account_balance_rounded,
                                    size: 280,
                                    color: AppColors.gold,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                        ),
                        child: const Text(
                          'Küresel Bir İmparatorluk Kur!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_isAutoStarting)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.black, width: 4),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, offset: Offset(0, 10), blurRadius: 18),
                            ],
                          ),
                          child: const Column(
                            children: [
                              SizedBox(
                                width: 38,
                                height: 38,
                                child: CircularProgressIndicator(
                                  color: AppColors.neonCyan,
                                  strokeWidth: 4,
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'HOLDİNG HAZIRLANIYOR...',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  fontFamily: 'SpaceMono',
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Şirketlerin seni bekliyor',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.black, width: 4),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, offset: Offset(0, 10), blurRadius: 20),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (state.isFirstLaunch) ...[
                                MenuHeavyButton(
                                  width: double.infinity,
                                  height: 65,
                                  color: AppColors.profit,
                                  shadowColor: Colors.green.shade800,
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    AudioService.instance.playSfx('click.mp3');
                                    _showHoldingSetupDialog();
                                  },
                                  child: const Text(
                                    'HOLDİNG KUR',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5),
                                  ),
                                ),
                              ] else ...[
                                MenuHeavyButton(
                                  width: double.infinity,
                                  height: 65,
                                  color: AppColors.gold,
                                  shadowColor: Colors.orange.shade700,
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    AudioService.instance.playSfx('click.mp3');
                                    _goToMap();
                                  },
                                  child: const Text(
                                    'HOLDİNGİ YÖNET',
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                MenuHeavyButton(
                                  width: double.infinity,
                                  height: 60,
                                  color: Colors.white,
                                  shadowColor: Colors.grey.shade400,
                                  onPressed: _confirmAndStartNewGame,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_business_rounded, size: 24, color: AppColors.neonCyan),
                                      SizedBox(width: 10),
                                      Text(
                                        'YENİ HOLDİNG KUR',
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              MenuHeavyButton(
                                width: double.infinity,
                                height: 60,
                                color: const Color(0xFFF1F5F9),
                                shadowColor: Colors.grey.shade400,
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  AudioService.instance.playSfx('click.mp3');
                                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.settings_suggest_rounded, size: 24, color: AppColors.textSecondary),
                                    SizedBox(width: 10),
                                    Text(
                                      'OYUN AYARLARI',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class CartoonStyleBackgroundAnimation extends StatefulWidget {
  const CartoonStyleBackgroundAnimation({super.key});

  @override
  State<CartoonStyleBackgroundAnimation> createState() => _CartoonStyleBackgroundAnimationState();
}

class _CartoonStyleBackgroundAnimationState extends State<CartoonStyleBackgroundAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: CartoonStyleBackgroundPainter(time: _animController.value),
        );
      },
    );
  }
}

class CartoonStyleBackgroundPainter extends CustomPainter {
  final double time;

  CartoonStyleBackgroundPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final double t = time * math.pi * 2;

    _drawSky(canvas, size, t);
    _drawDistantMountains(canvas, size, t);
    _drawDistantIndustrialSkyline(canvas, size, t);
    _drawCampusGround(canvas, size, t);
    _drawIndustrialCampus(canvas, size, t);
    _drawFrontTransportLayer(canvas, size, t);
    _drawAtmosphere(canvas, size, t);
  }

  void _drawSky(Canvas canvas, Size size, double t) {
    final double w = size.width;
    final double h = size.height;

    final Paint skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, h),
        const [
          Color(0xFFA9ECFF),
          Color(0xFF73D7FB),
          Color(0xFF3DAFEC),
          Color(0xFF2897DA),
        ],
        const [0.0, 0.26, 0.64, 1.0],
      );
    canvas.drawRect(Offset.zero & size, skyPaint);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.15),
      Paint()..color = Colors.white.withValues(alpha: 0.04),
    );

    final Offset sunCenter = Offset(w * 0.86, h * 0.14);
    final double sunPulse = 1.0 + math.sin(t) * 0.035;
    canvas.drawCircle(
      sunCenter,
      105 * sunPulse,
      Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      sunCenter,
      74 * sunPulse,
      Paint()..color = const Color(0xFFFFF3B0).withValues(alpha: 0.14),
    );
    canvas.drawCircle(sunCenter, 46 * sunPulse, Paint()..color = const Color(0xFFFFE082));
    canvas.drawCircle(
      sunCenter,
      46 * sunPulse,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    for (int i = 0; i < 10; i++) {
      final double ang = (math.pi * 2 / 10) * i + t;
      final Offset inner = sunCenter + Offset(math.cos(ang) * 58, math.sin(ang) * 58);
      final Offset outer = sunCenter + Offset(math.cos(ang) * 79, math.sin(ang) * 79);
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = const Color(0xFFFFF59D).withValues(alpha: 0.72)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    _drawCloud(canvas, Offset(_loopX(w + 330, start: -140, cycles: 1.0), h * 0.13), 1.08, 0.96);
    _drawCloud(canvas, Offset(_loopXReverse(w + 340, start: w + 120, cycles: 1.0), h * 0.18), 1.20, 0.92);
    _drawCloud(canvas, Offset(_loopX(w + 280, start: -120, cycles: 2.0), h * 0.28), 0.82, 0.86);
    _drawCloud(canvas, Offset(_loopXReverse(w + 260, start: w + 100, cycles: 2.0), h * 0.10), 0.66, 0.84);
    _drawCloud(canvas, Offset(_loopX(w + 250, start: -100, cycles: 1.0), h * 0.22), 0.56, 0.80);

    final double planeX = _loopX(w + 260, start: -130, cycles: 1.0);
    _drawPlane(canvas, Offset(planeX, h * 0.24 + math.sin(t) * 6), 0.78);
  }

  void _drawDistantMountains(Canvas canvas, Size size, double t) {
    final double w = size.width;
    final double h = size.height;
    final double sway = math.sin(t) * 4;

    final Path ridge1 = Path()
      ..moveTo(0, h * 0.54)
      ..quadraticBezierTo(w * 0.16, h * 0.45 + sway, w * 0.32, h * 0.55)
      ..quadraticBezierTo(w * 0.50, h * 0.65 - sway, w * 0.70, h * 0.54)
      ..quadraticBezierTo(w * 0.86, h * 0.47 + sway, w, h * 0.53)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ridge1, Paint()..color = const Color(0xFFADE57A));

    final Path ridge2 = Path()
      ..moveTo(0, h * 0.63)
      ..quadraticBezierTo(w * 0.14, h * 0.57 - sway, w * 0.34, h * 0.65)
      ..quadraticBezierTo(w * 0.54, h * 0.74 + sway, w * 0.72, h * 0.66)
      ..quadraticBezierTo(w * 0.90, h * 0.57 - sway, w, h * 0.63)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ridge2, Paint()..color = const Color(0xFF84D365));

    final Path grassyBand = Path()
      ..moveTo(0, h * 0.75)
      ..quadraticBezierTo(w * 0.24, h * 0.70, w * 0.46, h * 0.76)
      ..quadraticBezierTo(w * 0.73, h * 0.82, w, h * 0.75)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(grassyBand, Paint()..color = const Color(0xFF67C35D));
  }

  void _drawDistantIndustrialSkyline(Canvas canvas, Size size, double t) {
    final double w = size.width;
    final double h = size.height;
    final double baseY = h * 0.64;

    final Paint silhouettePaint = Paint()..color = const Color(0xFF7EA3B7).withValues(alpha: 0.18);
    final Path silhouette = Path()..moveTo(0, baseY);

    double x = -20;
    final List<double> heights = [60, 82, 48, 72, 58, 100, 52, 74, 44, 88];
    int index = 0;
    while (x < w + 60) {
      final double width = 34 + (index % 4) * 12;
      final double height = heights[index % heights.length];
      silhouette.lineTo(x, baseY - height);
      silhouette.lineTo(x + width, baseY - height);
      silhouette.lineTo(x + width, baseY);
      if (index % 3 == 0) {
        final double stackX = x + width * 0.72;
        silhouette.lineTo(stackX, baseY);
        silhouette.lineTo(stackX, baseY - height - 34);
        silhouette.lineTo(stackX + 8, baseY - height - 34);
        silhouette.lineTo(stackX + 8, baseY);
      }
      x += width + 10;
      index++;
    }
    silhouette.lineTo(w, baseY);
    silhouette.lineTo(w, h);
    silhouette.lineTo(0, h);
    silhouette.close();
    canvas.drawPath(silhouette, silhouettePaint);

    for (int i = 0; i < 8; i++) {
      final double lx = w * (0.08 + i * 0.11);
      final double blink = 0.20 + 0.18 * math.sin((time + i * 0.12) * math.pi * 2);
      canvas.drawCircle(
        Offset(lx, baseY - 30 - (i % 3) * 16),
        2.2,
        Paint()..color = const Color(0xFFFFF59D).withValues(alpha: blink),
      );
    }
  }

  void _drawCampusGround(Canvas canvas, Size size, double t) {
    final double w = size.width;
    final double h = size.height;

    final Rect yardRect = Rect.fromLTWH(w * 0.03, h * 0.62, w * 0.94, h * 0.21);
    final RRect yard = RRect.fromRectAndRadius(yardRect, const Radius.circular(18));
    canvas.drawRRect(yard, Paint()..color = const Color(0xFFDDE6EF));
    canvas.drawRRect(
      yard,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Texture stripes on the concrete.
    for (int i = 0; i < 12; i++) {
      final double y = yardRect.top + 10 + i * ((yardRect.height - 20) / 11);
      canvas.drawLine(
        Offset(yardRect.left + 8, y),
        Offset(yardRect.right - 8, y),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..strokeWidth = 1,
      );
    }
    for (int i = 0; i < 9; i++) {
      final double x = yardRect.left + 16 + i * ((yardRect.width - 32) / 8);
      canvas.drawLine(
        Offset(x, yardRect.top + 8),
        Offset(x, yardRect.bottom - 8),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.03)
          ..strokeWidth = 1,
      );
    }

    for (int i = 0; i < 10; i++) {
      final double mx = yardRect.left + 18 + i * (yardRect.width / 10.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(mx, yardRect.bottom - 28, yardRect.width * 0.055, 5),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.62),
      );
    }
  }

  void _drawIndustrialCampus(Canvas canvas, Size size, double t) {
    final double w = size.width;
    final double h = size.height;

    // Rebuilt from scratch with bigger, closer structures and cleaner hierarchy.
    // The large middle plant is the focal point; side factories stay readable but lighter.

    // Far-left supporting structures.
    _drawCoolingTower(
      canvas,
      Rect.fromLTWH(w * 0.015, h * 0.425, w * 0.115, h * 0.19),
      const Color(0xFFC9D6E2),
      opacity: 0.50,
    );
    _drawCoolingTower(
      canvas,
      Rect.fromLTWH(w * 0.090, h * 0.455, w * 0.085, h * 0.145),
      const Color(0xFFD5E0EA),
      opacity: 0.40,
    );

    _drawBackgroundFactory(
      canvas,
      Rect.fromLTWH(w * 0.045, h * 0.485, w * 0.27, h * 0.18),
      bodyColor: const Color(0xFFB6C5D2),
      roofColor: const Color(0xFF8096AD),
      accentColor: const Color(0xFF1ECBF3),
      chimneyCount: 2,
      smokeOffset: time,
      opacity: 0.72,
    );

    _drawStorageTank(
      canvas,
      Rect.fromLTWH(w * 0.180, h * 0.575, w * 0.060, h * 0.078),
      const Color(0xFFE7EDF4),
      opacity: 0.66,
    );
    _drawStorageTank(
      canvas,
      Rect.fromLTWH(w * 0.248, h * 0.588, w * 0.044, h * 0.060),
      const Color(0xFFD5DDE7),
      opacity: 0.60,
    );
    _drawPipeBridge(
      canvas,
      Offset(w * 0.165, h * 0.620),
      Offset(w * 0.320, h * 0.620),
      4.6,
      const Color(0xFF88A2B8),
    );

    // Main factory complex.
    _drawMegaFactory(
      canvas,
      Rect.fromLTWH(w * 0.255, h * 0.360, w * 0.48, h * 0.325),
      bodyColor: const Color(0xFFC8D5E2),
      roofColor: const Color(0xFF8FA3B8),
      accentColor: const Color(0xFFFBBF24),
      chimneyCount: 3,
      smokeOffset: time + 0.18,
      windowBlink: 0.42,
      hasOfficeTower: true,
      hasRooftopUnits: true,
      doorCount: 2,
      opacity: 1.0,
    );

    // Right side background complex.
    _drawBackgroundFactory(
      canvas,
      Rect.fromLTWH(w * 0.710, h * 0.490, w * 0.235, h * 0.175),
      bodyColor: const Color(0xFFB7C8D8),
      roofColor: const Color(0xFF8095AC),
      accentColor: const Color(0xFF22D3EE),
      chimneyCount: 1,
      smokeOffset: time + 0.52,
      opacity: 0.72,
      addConveyor: true,
      mirror: true,
    );

    _drawStorageTank(
      canvas,
      Rect.fromLTWH(w * 0.818, h * 0.576, w * 0.058, h * 0.076),
      const Color(0xFFE7EEF4),
      opacity: 0.66,
    );
    _drawPipeBridge(
      canvas,
      Offset(w * 0.702, h * 0.620),
      Offset(w * 0.896, h * 0.620),
      4.6,
      const Color(0xFF879FB6),
    );
    _drawWaterTower(
      canvas,
      Offset(w * 0.944, h * 0.465),
      0.98,
      const Color(0xFFA5B7C8),
      opacity: 0.60,
    );

    // Cranes sit behind the yard and in front of the sky.
    _drawCrane(canvas, Offset(w * 0.034, h * 0.378), 1.08, const Color(0xFFF59E0B), t);
    _drawCrane(canvas, Offset(w * 0.850, h * 0.388), 0.98, const Color(0xFFF97316), t + 0.5);

    // Mid-yard activity.
    _drawYardConveyor(canvas, Rect.fromLTWH(w * 0.535, h * 0.687, w * 0.245, h * 0.038));
    _drawForklift(canvas, Offset(w * 0.748 + math.sin(t) * 10, h * 0.736), 0.92, const Color(0xFFF59E0B));

    _drawPallet(canvas, Rect.fromLTWH(w * 0.248, h * 0.704, w * 0.068, h * 0.031), const Color(0xFF60A5FA));
    _drawPallet(canvas, Rect.fromLTWH(w * 0.321, h * 0.708, w * 0.052, h * 0.026), const Color(0xFFF59E0B));
    _drawPallet(canvas, Rect.fromLTWH(w * 0.587, h * 0.708, w * 0.086, h * 0.032), const Color(0xFFFBBF24));
    _drawPallet(canvas, Rect.fromLTWH(w * 0.678, h * 0.703, w * 0.057, h * 0.028), const Color(0xFF22D3EE));

    _drawWarningSign(canvas, Offset(w * 0.505, h * 0.735), 0.88);
    _drawSmallUtilityShed(canvas, Rect.fromLTWH(w * 0.862, h * 0.661, w * 0.084, h * 0.060));

    // Fence remains the foremost layer of the industrial yard.
    _drawFence(canvas, Rect.fromLTWH(w * 0.03, h * 0.740, w * 0.94, h * 0.045));
  }

  void _drawFrontTransportLayer(Canvas canvas, Size size, double t) {
    final double w = size.width;
    final double h = size.height;

    final Rect roadRect = Rect.fromLTWH(0, h * 0.80, w, h * 0.115);
    canvas.drawRect(roadRect, Paint()..color = const Color(0xFF48515F));
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.80, w, 6),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.908, w, h * 0.012),
      Paint()..color = const Color(0xFF2E343D),
    );

    for (int i = 0; i < 9; i++) {
      final double startX = w * 0.025 + i * (w * 0.115);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX, h * 0.848, w * 0.050, 6),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFFFF176),
      );
    }

    final double truck1X = _loopX(w + 220, start: -120, cycles: 1.0);
    final double truck2X = _loopXReverse(w + 260, start: w + 130, cycles: 1.0);
    final double truck3X = _loopX(w + 320, start: -180, cycles: 2.0);

    _drawTruck(canvas, Offset(truck1X, h * 0.820), 1.00, const Color(0xFF22D3EE), cargoColor: const Color(0xFFCBD5E1));
    _drawTruck(canvas, Offset(truck2X, h * 0.858), 0.86, const Color(0xFFF59E0B), cargoColor: const Color(0xFF9FB3C7), facingLeft: true);
    _drawTruck(canvas, Offset(truck3X, h * 0.888), 0.72, const Color(0xFF60A5FA), cargoColor: const Color(0xFFE2E8F0));

    final Rect railBed = Rect.fromLTWH(0, h * 0.915, w, h * 0.040);
    canvas.drawRect(railBed, Paint()..color = const Color(0xFF7C5A3A));
    for (int i = 0; i < 20; i++) {
      final double x = i * (w / 19);
      canvas.drawRect(Rect.fromLTWH(x - 2, railBed.top + 2, 4, railBed.height - 4), Paint()..color = const Color(0xFF5C3D23));
    }
    canvas.drawLine(Offset(0, railBed.top + 10), Offset(w, railBed.top + 10), Paint()..color = const Color(0xFFD1D5DB)..strokeWidth = 2.4);
    canvas.drawLine(Offset(0, railBed.bottom - 10), Offset(w, railBed.bottom - 10), Paint()..color = const Color(0xFFD1D5DB)..strokeWidth = 2.4);

    final double trainX = _loopXReverse(w + 500, start: w + 200, cycles: 1.0);
    _drawCargoTrain(canvas, Offset(trainX, h * 0.944), 0.78, const Color(0xFFF59E0B));

    _drawShrub(canvas, Offset(w * 0.07, h * 0.912), 1.00);
    _drawShrub(canvas, Offset(w * 0.17, h * 0.918), 0.82);
    _drawShrub(canvas, Offset(w * 0.87, h * 0.915), 0.92);
    _drawShrub(canvas, Offset(w * 0.95, h * 0.908), 0.78);
  }

  void _drawAtmosphere(Canvas canvas, Size size, double t) {
    final double w = size.width;
    final double h = size.height;

    final Paint sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.64);
    for (int i = 0; i < 14; i++) {
      final double sx = (((i * 0.071) + time) % 1.0) * w;
      final double sy = h * (0.08 + (i % 5) * 0.09) + math.sin(t + i) * 2;
      canvas.drawCircle(Offset(sx, sy), 1.6 + (i % 2) * 0.7, sparklePaint);
    }

    final Paint hazePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.50),
        Offset(0, h),
        [
          Colors.white.withValues(alpha: 0.04),
          Colors.transparent,
        ],
      );
    canvas.drawRect(Offset.zero & size, hazePaint);
  }

  double _loopX(double travelDistance, {required double start, double cycles = 1.0}) {
    return start + (((time * cycles) % 1.0) * travelDistance);
  }

  double _loopXReverse(double travelDistance, {required double start, double cycles = 1.0}) {
    return start - (((time * cycles) % 1.0) * travelDistance);
  }

  void _drawCloud(Canvas canvas, Offset center, double scale, double alpha) {
    final Paint shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.08 * alpha);
    final Paint fillPaint = Paint()..color = Colors.white.withValues(alpha: alpha);
    final Paint outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    final List<Offset> bubbles = [
      Offset(-58 * scale, 8 * scale),
      Offset(-22 * scale, -12 * scale),
      Offset(16 * scale, -4 * scale),
      Offset(56 * scale, 9 * scale),
      Offset(0, 17 * scale),
    ];
    final List<double> radii = [26 * scale, 34 * scale, 31 * scale, 22 * scale, 25 * scale];

    for (int i = 0; i < bubbles.length; i++) {
      canvas.drawCircle(center + bubbles[i] + Offset(0, 6 * scale), radii[i], shadowPaint);
    }
    for (int i = 0; i < bubbles.length; i++) {
      canvas.drawCircle(center + bubbles[i], radii[i], fillPaint);
      canvas.drawCircle(center + bubbles[i], radii[i], outlinePaint);
    }
  }

  void _drawPlane(Canvas canvas, Offset nose, double scale) {
    final Path plane = Path()
      ..moveTo(nose.dx, nose.dy)
      ..lineTo(nose.dx - 26 * scale, nose.dy + 5 * scale)
      ..lineTo(nose.dx - 62 * scale, nose.dy + 1 * scale)
      ..lineTo(nose.dx - 76 * scale, nose.dy + 15 * scale)
      ..lineTo(nose.dx - 84 * scale, nose.dy + 13 * scale)
      ..lineTo(nose.dx - 70 * scale, nose.dy)
      ..lineTo(nose.dx - 84 * scale, nose.dy - 13 * scale)
      ..lineTo(nose.dx - 76 * scale, nose.dy - 15 * scale)
      ..lineTo(nose.dx - 62 * scale, nose.dy - 1 * scale)
      ..lineTo(nose.dx - 26 * scale, nose.dy - 5 * scale)
      ..close();

    canvas.drawPath(plane, Paint()..color = Colors.white);
    canvas.drawPath(
      plane,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final Paint trailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(nose.dx - 95 * scale, nose.dy - 6 * scale), Offset(nose.dx - 140 * scale, nose.dy - 10 * scale), trailPaint);
    canvas.drawLine(Offset(nose.dx - 95 * scale, nose.dy + 6 * scale), Offset(nose.dx - 140 * scale, nose.dy + 10 * scale), trailPaint);
  }

  void _drawBackgroundFactory(
    Canvas canvas,
    Rect rect, {
    required Color bodyColor,
    required Color roofColor,
    required Color accentColor,
    required int chimneyCount,
    required double smokeOffset,
    double opacity = 1.0,
    bool addConveyor = false,
    bool mirror = false,
  }) {
    final Paint outlinePaint = Paint()
      ..color = _withOpacity(Colors.black, 0.16 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final double roofTopY = rect.top + rect.height * 0.16;
    final double parapetBottomY = rect.top + rect.height * 0.34;
    final double roofInset = rect.width * 0.05;
    final Rect roofDeck = Rect.fromLTWH(
      rect.left + roofInset,
      roofTopY + rect.height * 0.03,
      rect.width - roofInset * 2,
      parapetBottomY - roofTopY - rect.height * 0.05,
    );

    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, parapetBottomY, rect.width, rect.bottom - parapetBottomY),
      const Radius.circular(8),
    );
    canvas.drawRRect(body, Paint()..color = _withOpacity(bodyColor, opacity));
    canvas.drawRRect(body, outlinePaint);

    final RRect parapet = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, roofTopY, rect.width, parapetBottomY - roofTopY + rect.height * 0.02),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      parapet,
      Paint()..color = _withOpacity(Color.lerp(roofColor, Colors.white, 0.08)!, opacity),
    );
    canvas.drawRRect(parapet, outlinePaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(roofDeck, const Radius.circular(5)),
      Paint()..color = _withOpacity(Color.lerp(roofColor, Colors.black, 0.04)!, opacity),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(roofDeck, const Radius.circular(5)),
      Paint()
        ..color = _withOpacity(Colors.black, 0.08 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final Rect accentBand = Rect.fromLTWH(
      rect.left + rect.width * 0.06,
      parapetBottomY + rect.height * 0.08,
      rect.width * 0.88,
      rect.height * 0.035,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(accentBand, const Radius.circular(4)),
      Paint()..color = _withOpacity(Color.lerp(accentColor, Colors.white, 0.45)!, opacity),
    );

    for (int i = 0; i < 3; i++) {
      final Rect rooftopUnit = Rect.fromLTWH(
        rect.left + rect.width * (0.10 + i * 0.27),
        roofDeck.top + rect.height * 0.01,
        rect.width * 0.16,
        roofDeck.height * 0.58,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rooftopUnit, const Radius.circular(4)),
        Paint()..color = _withOpacity(Color.lerp(roofColor, Colors.white, 0.14)!, opacity),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rooftopUnit, const Radius.circular(4)),
        Paint()
          ..color = _withOpacity(Colors.black, 0.08 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    final double annexWidth = rect.width * 0.15;
    final Rect annex = Rect.fromLTWH(
      mirror ? rect.right - annexWidth : rect.left,
      parapetBottomY + rect.height * 0.10,
      annexWidth,
      rect.height * 0.56,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(annex, const Radius.circular(6)),
      Paint()..color = _withOpacity(Color.lerp(bodyColor, Colors.white, 0.06)!, opacity),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(annex, const Radius.circular(6)), outlinePaint);

    for (int i = 0; i < 4; i++) {
      final Rect win = Rect.fromLTWH(
        rect.left + rect.width * (0.12 + i * 0.18),
        rect.top + rect.height * 0.52,
        rect.width * 0.10,
        rect.height * 0.10,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(win, const Radius.circular(3)),
        Paint()..color = _withOpacity(const Color(0xFFDFF6FF), opacity),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(win, const Radius.circular(3)),
        Paint()
          ..color = _withOpacity(Colors.black, 0.10 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    final Rect door = Rect.fromLTWH(
      rect.left + rect.width * 0.43,
      rect.top + rect.height * 0.66,
      rect.width * 0.12,
      rect.height * 0.34,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(door, const Radius.circular(4)),
      Paint()..color = _withOpacity(accentColor, opacity),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(door, const Radius.circular(4)),
      Paint()
        ..color = _withOpacity(Colors.black, 0.14 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final List<double> chimneyXs = chimneyCount == 1
        ? [rect.left + rect.width * 0.74]
        : chimneyCount == 2
            ? [rect.left + rect.width * 0.22, rect.left + rect.width * 0.76]
            : [rect.left + rect.width * 0.20, rect.left + rect.width * 0.50, rect.left + rect.width * 0.80];

    for (int i = 0; i < chimneyCount; i++) {
      final double stackX = chimneyXs[i];
      final Rect stackBase = Rect.fromCenter(
        center: Offset(stackX, roofDeck.center.dy),
        width: rect.width * 0.12,
        height: rect.height * 0.048,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(stackBase, const Radius.circular(3)),
        Paint()..color = _withOpacity(Color.lerp(roofColor, bodyColor, 0.40)!, opacity),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(stackBase, const Radius.circular(3)),
        Paint()
          ..color = _withOpacity(Colors.black, 0.12 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      final double stackHeight = rect.height * (0.20 + (i.isOdd ? 0.04 : 0.0));
      final double stackWidth = rect.width * 0.055;
      final Rect chimney = Rect.fromLTWH(
        stackBase.center.dx - stackWidth / 2,
        stackBase.top - stackHeight + 1.5,
        stackWidth,
        stackHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(chimney, const Radius.circular(4)),
        Paint()..color = _withOpacity(const Color(0xFF97AABD), opacity),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(chimney, const Radius.circular(4)),
        Paint()
          ..color = _withOpacity(Colors.black, 0.16 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(
        Offset(chimney.center.dx, chimney.top + 3),
        2.8 + math.sin((time + i * 0.22) * math.pi * 2) * 0.35,
        Paint()..color = _withOpacity(const Color(0xFFFF8A65), opacity),
      );
      _drawSmokePuffs(
        canvas,
        Offset(chimney.center.dx, chimney.top - 8),
        0.80 + i * 0.12,
        smokeOffset + i * 0.18,
        opacity: opacity,
      );
    }

    if (addConveyor) {
      final Rect conveyor = Rect.fromLTWH(
        mirror ? rect.left - rect.width * 0.18 : rect.right - rect.width * 0.03,
        rect.top + rect.height * 0.43,
        rect.width * 0.22,
        rect.height * 0.09,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(conveyor, const Radius.circular(5)),
        Paint()..color = _withOpacity(const Color(0xFF8EA2B8), opacity),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(conveyor, const Radius.circular(5)),
        Paint()
          ..color = _withOpacity(Colors.black, 0.14 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
      for (int i = 0; i < 3; i++) {
        final double p = ((time + i * 0.26) % 1.0);
        final Rect box = Rect.fromLTWH(conveyor.left + 6 + p * (conveyor.width - 18), conveyor.top - 6, 13, 10);
        canvas.drawRRect(
          RRect.fromRectAndRadius(box, const Radius.circular(3)),
          Paint()..color = _withOpacity(i.isEven ? const Color(0xFFFBBF24) : const Color(0xFF22D3EE), opacity),
        );
      }
    }
  }

  void _drawMegaFactory(
    Canvas canvas,
    Rect rect, {
    required Color bodyColor,
    required Color roofColor,
    required Color accentColor,
    required int chimneyCount,
    required double smokeOffset,
    required double windowBlink,
    bool hasOfficeTower = false,
    bool hasRooftopUnits = false,
    int doorCount = 1,
    double opacity = 1.0,
  }) {
    final Paint outlinePaint = Paint()
      ..color = _withOpacity(Colors.black, 0.22 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;

    final double roofTopY = rect.top + rect.height * 0.14;
    final double parapetBottomY = rect.top + rect.height * 0.38;
    final Rect roofDeck = Rect.fromLTWH(
      rect.left + rect.width * 0.04,
      roofTopY + rect.height * 0.035,
      rect.width * 0.92,
      parapetBottomY - roofTopY - rect.height * 0.055,
    );

    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, parapetBottomY, rect.width, rect.bottom - parapetBottomY),
      const Radius.circular(12),
    );
    canvas.drawRRect(body, Paint()..color = _withOpacity(bodyColor, opacity));
    canvas.drawRRect(body, outlinePaint);

    final RRect parapet = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, roofTopY, rect.width, parapetBottomY - roofTopY + rect.height * 0.025),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      parapet,
      Paint()..color = _withOpacity(Color.lerp(roofColor, Colors.white, 0.10)!, opacity),
    );
    canvas.drawRRect(parapet, outlinePaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(roofDeck, const Radius.circular(6)),
      Paint()..color = _withOpacity(Color.lerp(roofColor, Colors.black, 0.04)!, opacity),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(roofDeck, const Radius.circular(6)),
      Paint()
        ..color = _withOpacity(Colors.black, 0.09 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    final Rect upperBand = Rect.fromLTWH(
      rect.left + rect.width * 0.04,
      parapetBottomY + rect.height * 0.04,
      rect.width * 0.92,
      rect.height * 0.05,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(upperBand, const Radius.circular(5)),
      Paint()..color = _withOpacity(Color.lerp(accentColor, Colors.white, 0.55)!, opacity),
    );

    for (int i = 0; i < 4; i++) {
      final Rect rooftopBlock = Rect.fromLTWH(
        rect.left + rect.width * (0.05 + i * 0.23),
        roofDeck.top + rect.height * (i.isEven ? 0.01 : 0.025),
        rect.width * 0.15,
        roofDeck.height * (i.isEven ? 0.55 : 0.42),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rooftopBlock, const Radius.circular(5)),
        Paint()..color = _withOpacity(Color.lerp(roofColor, Colors.white, i.isEven ? 0.16 : 0.08)!, opacity),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rooftopBlock, const Radius.circular(5)),
        Paint()
          ..color = _withOpacity(Colors.black, 0.08 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }

    final double blink = 0.50 + 0.50 * math.sin((time + windowBlink) * math.pi * 2);
    final Color litWindow = _withOpacity(Color.lerp(const Color(0xFFCDEFFF), const Color(0xFFF3FCFF), blink)!, opacity);
    for (int row = 0; row < 2; row++) {
      for (int i = 0; i < 6; i++) {
        final Rect win = Rect.fromLTWH(
          rect.left + rect.width * (0.06 + i * 0.12),
          rect.top + rect.height * (0.54 + row * 0.14),
          rect.width * 0.08,
          rect.height * 0.085,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(win, const Radius.circular(4)), Paint()..color = litWindow);
        canvas.drawRRect(
          RRect.fromRectAndRadius(win, const Radius.circular(4)),
          Paint()
            ..color = _withOpacity(Colors.black, 0.14 * opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }

    final Rect sign = Rect.fromLTWH(
      rect.left + rect.width * 0.31,
      rect.top + rect.height * 0.45,
      rect.width * 0.22,
      rect.height * 0.07,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sign, const Radius.circular(4)),
      Paint()..color = _withOpacity(const Color(0xFFFEF3C7), opacity),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sign, const Radius.circular(4)),
      Paint()
        ..color = _withOpacity(Colors.black, 0.16 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    for (int i = 0; i < doorCount; i++) {
      final Rect door = Rect.fromLTWH(
        rect.left + rect.width * (0.28 + i * 0.17),
        rect.top + rect.height * 0.70,
        rect.width * 0.11,
        rect.height * 0.30,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(door, const Radius.circular(5)),
        Paint()..color = _withOpacity(accentColor, opacity),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(door, const Radius.circular(5)),
        Paint()
          ..color = _withOpacity(Colors.black, 0.18 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    if (hasRooftopUnits) {
      for (int i = 0; i < 3; i++) {
        final Rect unit = Rect.fromLTWH(
          rect.left + rect.width * (0.08 + i * 0.11),
          rect.top + rect.height * 0.42,
          rect.width * 0.07,
          rect.height * 0.05,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(unit, const Radius.circular(4)),
          Paint()..color = _withOpacity(const Color(0xFF7C8DA3), opacity),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(unit, const Radius.circular(4)),
          Paint()
            ..color = _withOpacity(Colors.black, 0.14 * opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );
      }
    }

    if (hasOfficeTower) {
      final Rect towerRect = Rect.fromLTWH(
        rect.right - rect.width * 0.12,
        rect.top - rect.height * 0.16,
        rect.width * 0.12,
        rect.height * 0.58,
      );
      final RRect tower = RRect.fromRectAndRadius(towerRect, const Radius.circular(12));
      canvas.drawRRect(tower, Paint()..color = _withOpacity(const Color(0xFFBED2E5), opacity));
      canvas.drawRRect(tower, outlinePaint);
      for (int i = 0; i < 5; i++) {
        final Rect win = Rect.fromLTWH(
          towerRect.left + towerRect.width * 0.22,
          towerRect.top + towerRect.height * (0.10 + i * 0.15),
          towerRect.width * 0.56,
          towerRect.height * 0.08,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(win, const Radius.circular(3)), Paint()..color = _withOpacity(const Color(0xFFE7F8FF), opacity));
      }
      final Offset beacon = Offset(towerRect.center.dx, towerRect.top - 8);
      canvas.drawLine(
        Offset(towerRect.center.dx, towerRect.top),
        beacon,
        Paint()..color = _withOpacity(const Color(0xFF7B8DA4), opacity)..strokeWidth = 2,
      );
      canvas.drawCircle(
        beacon,
        4.5 + math.sin(time * math.pi * 2) * 0.8,
        Paint()..color = _withOpacity(const Color(0xFFFF6B6B), opacity),
      );
    }

    final List<double> chimneyXs = chimneyCount == 1
        ? [rect.left + rect.width * 0.84]
        : chimneyCount == 2
            ? [rect.left + rect.width * 0.36, rect.left + rect.width * 0.84]
            : [rect.left + rect.width * 0.18, rect.left + rect.width * 0.58, rect.left + rect.width * 0.84];

    for (int i = 0; i < chimneyCount; i++) {
      final double stackX = chimneyXs[i];
      final Rect stackBase = Rect.fromCenter(
        center: Offset(stackX, roofDeck.center.dy),
        width: rect.width * 0.11,
        height: rect.height * 0.055,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(stackBase, const Radius.circular(4)),
        Paint()..color = _withOpacity(Color.lerp(roofColor, bodyColor, 0.42)!, opacity),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(stackBase, const Radius.circular(4)),
        Paint()
          ..color = _withOpacity(Colors.black, 0.14 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      final double stackWidth = rect.width * 0.045;
      final double stackHeight = rect.height * (0.25 + (i.isOdd ? 0.05 : 0.0));
      final Rect chimney = Rect.fromLTWH(
        stackBase.center.dx - stackWidth / 2,
        stackBase.top - stackHeight + 2,
        stackWidth,
        stackHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(chimney, const Radius.circular(4)),
        Paint()..color = _withOpacity(const Color(0xFF94A3B8), opacity),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(chimney, const Radius.circular(4)),
        Paint()
          ..color = _withOpacity(Colors.black, 0.18 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      canvas.drawCircle(
        Offset(chimney.center.dx, chimney.top + 3),
        3.2 + math.sin((time + i * 0.21) * math.pi * 2) * 0.45,
        Paint()..color = _withOpacity(const Color(0xFFFF8A65), opacity),
      );
      _drawSmokePuffs(
        canvas,
        Offset(chimney.center.dx, chimney.top - 9),
        0.94 + i * 0.15,
        smokeOffset + i * 0.17,
        opacity: opacity,
      );
    }
  }

  void _drawConveyorFactory(
    Canvas canvas,
    Rect rect,
    Color bodyColor,
    Color roofColor,
    Color accentColor, {
    double opacity = 1.0,
  }) {
    _drawMegaFactory(
      canvas,
      rect,
      bodyColor: bodyColor,
      roofColor: roofColor,
      accentColor: accentColor,
      chimneyCount: 1,
      smokeOffset: time + 0.52,
      windowBlink: 0.70,
      hasRooftopUnits: true,
      opacity: opacity,
    );

    final Rect conveyor = Rect.fromLTWH(
      rect.left - rect.width * 0.24,
      rect.top + rect.height * 0.38,
      rect.width * 0.32,
      rect.height * 0.10,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(conveyor, const Radius.circular(5)),
      Paint()..color = _withOpacity(const Color(0xFF8EA2B8), opacity),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(conveyor, const Radius.circular(5)),
      Paint()
        ..color = _withOpacity(Colors.black, 0.16 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    for (int i = 0; i < 4; i++) {
      final double p = ((time + i * 0.24) % 1.0);
      final Rect box = Rect.fromLTWH(conveyor.left + 8 + p * (conveyor.width - 20), conveyor.top - 7, 16, 12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(3)),
        Paint()..color = _withOpacity(i.isEven ? const Color(0xFFFBBF24) : const Color(0xFF22D3EE), opacity),
      );
    }
  }

  void _drawCoolingTower(Canvas canvas, Rect rect, Color color, {double opacity = 1.0}) {
    final Path tower = Path()
      ..moveTo(rect.left + rect.width * 0.18, rect.bottom)
      ..quadraticBezierTo(rect.left, rect.top + rect.height * 0.55, rect.left + rect.width * 0.24, rect.top)
      ..lineTo(rect.right - rect.width * 0.24, rect.top)
      ..quadraticBezierTo(rect.right, rect.top + rect.height * 0.55, rect.right - rect.width * 0.18, rect.bottom)
      ..close();
    canvas.drawPath(tower, Paint()..color = _withOpacity(color, opacity));
    canvas.drawPath(
      tower,
      Paint()
        ..color = _withOpacity(Colors.black, 0.18 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    _drawSmokePuffs(canvas, Offset(rect.center.dx, rect.top - 8), 1.04, time, opacity: opacity);
  }

  void _drawWaterTower(Canvas canvas, Offset top, double scale, Color color, {double opacity = 1.0}) {
    final Rect tank = Rect.fromCenter(center: Offset(top.dx, top.dy + 20 * scale), width: 58 * scale, height: 34 * scale);
    canvas.drawRRect(RRect.fromRectAndRadius(tank, Radius.circular(14 * scale)), Paint()..color = _withOpacity(color, opacity));
    canvas.drawRRect(
      RRect.fromRectAndRadius(tank, Radius.circular(14 * scale)),
      Paint()
        ..color = _withOpacity(Colors.black, 0.18 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final dx in [-16.0, -5.0, 6.0, 17.0]) {
      canvas.drawLine(
        Offset(top.dx + dx * scale, top.dy + 36 * scale),
        Offset(top.dx + (dx * 0.7) * scale, top.dy + 82 * scale),
        Paint()..color = _withOpacity(const Color(0xFF7F94AD), opacity)..strokeWidth = 3,
      );
    }
  }

  void _drawStorageTank(Canvas canvas, Rect rect, Color color, {double opacity = 1.0}) {
    final RRect tankBody = RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.46));
    canvas.drawRRect(tankBody, Paint()..color = _withOpacity(color, opacity));
    canvas.drawRRect(
      tankBody,
      Paint()
        ..color = _withOpacity(Colors.black, 0.18 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rect.center.dx, rect.top + 4), width: rect.width, height: rect.width * 0.22),
      Paint()..color = Colors.white.withValues(alpha: 0.15 * opacity),
    );
  }

  void _drawPipeBridge(Canvas canvas, Offset start, Offset end, double thickness, Color color) {
    final Paint pipePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, pipePaint);
    canvas.drawLine(Offset(start.dx, start.dy - 9), Offset(end.dx, end.dy - 9), pipePaint..strokeWidth = thickness * 0.70);
    for (int i = 0; i < 5; i++) {
      final double x = start.dx + (end.dx - start.dx) * (i / 4);
      canvas.drawLine(Offset(x, start.dy - 11), Offset(x, start.dy + 4), Paint()..color = const Color(0xFF6D8194)..strokeWidth = 2);
    }
  }

  void _drawCrane(Canvas canvas, Offset base, double scale, Color color, double phase) {
    final Paint linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * scale
      ..strokeCap = StrokeCap.round;
    final Paint detailPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scale;

    final double mastH = 118 * scale;
    final double boomLen = 132 * scale;
    canvas.drawLine(base, Offset(base.dx, base.dy + mastH), linePaint);
    canvas.drawLine(base, Offset(base.dx + boomLen, base.dy + 8 * scale), linePaint);
    canvas.drawLine(base, Offset(base.dx + boomLen * 0.72, base.dy + mastH * 0.35), linePaint);
    canvas.drawLine(Offset(base.dx + boomLen * 0.46, base.dy + 6 * scale), Offset(base.dx + boomLen * 0.72, base.dy + mastH * 0.35), linePaint);
    for (int i = 0; i < 5; i++) {
      final double y = base.dy + i * mastH / 5;
      canvas.drawLine(Offset(base.dx - 10 * scale, y), Offset(base.dx + 10 * scale, y), detailPaint);
    }
    final double swing = math.sin(phase) * 12 * scale;
    final Offset hookStart = Offset(base.dx + boomLen * 0.80, base.dy + 8 * scale);
    final Offset hookEnd = Offset(hookStart.dx + swing, hookStart.dy + 48 * scale);
    canvas.drawLine(hookStart, hookEnd, Paint()..color = Colors.black54..strokeWidth = 2.5 * scale);
    canvas.drawCircle(hookEnd, 4.5 * scale, Paint()..color = const Color(0xFF374151));
  }

  void _drawFence(Canvas canvas, Rect rect) {
    final Paint postPaint = Paint()..color = const Color(0xFF64748B);
    final Paint railPaint = Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 4..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(rect.left, rect.top + rect.height * 0.30), Offset(rect.right, rect.top + rect.height * 0.30), railPaint);
    canvas.drawLine(Offset(rect.left, rect.top + rect.height * 0.76), Offset(rect.right, rect.top + rect.height * 0.76), railPaint);
    for (int i = 0; i < 21; i++) {
      final double x = rect.left + i * (rect.width / 20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 2.8, rect.top, 5.6, rect.height), const Radius.circular(3)),
        postPaint,
      );
    }
  }

  void _drawYardConveyor(Canvas canvas, Rect rect) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = const Color(0xFF8FA3B6));
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (int i = 0; i < 6; i++) {
      final double x = rect.left + 8 + i * (rect.width - 16) / 5;
      canvas.drawCircle(Offset(x, rect.center.dy), 3, Paint()..color = const Color(0xFF6D8194));
    }
    for (int i = 0; i < 5; i++) {
      final double p = (((time * 2.0) + i * 0.22) % 1.0);
      final Rect box = Rect.fromLTWH(rect.left + 8 + p * (rect.width - 26), rect.top - 10, 18, 12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(3)),
        Paint()..color = i.isEven ? const Color(0xFFFBBF24) : const Color(0xFF60A5FA),
      );
    }
  }

  void _drawForklift(Canvas canvas, Offset pos, double scale, Color color) {
    final Rect body = Rect.fromLTWH(pos.dx, pos.dy - 16 * scale, 30 * scale, 16 * scale);
    final Rect cab = Rect.fromLTWH(pos.dx + 8 * scale, pos.dy - 28 * scale, 12 * scale, 12 * scale);
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(5)), Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(cab, const Radius.circular(4)), Paint()..color = const Color(0xFFE0F2FE));
    canvas.drawRect(Rect.fromLTWH(pos.dx + 27 * scale, pos.dy - 34 * scale, 3 * scale, 34 * scale), Paint()..color = const Color(0xFF475569));
    canvas.drawRect(Rect.fromLTWH(pos.dx + 30 * scale, pos.dy - 6 * scale, 8 * scale, 2 * scale), Paint()..color = const Color(0xFF475569));
    for (final dx in [6.0, 24.0]) {
      canvas.drawCircle(Offset(pos.dx + dx * scale, pos.dy + 1), 5 * scale, Paint()..color = const Color(0xFF1F2937));
      canvas.drawCircle(Offset(pos.dx + dx * scale, pos.dy + 1), 2.2 * scale, Paint()..color = const Color(0xFFE5E7EB));
    }
  }

  void _drawTruck(Canvas canvas, Offset pos, double scale, Color cabColor, {required Color cargoColor, bool facingLeft = false}) {
    canvas.save();
    if (facingLeft) {
      canvas.translate(pos.dx, 0);
      canvas.scale(-1, 1);
      canvas.translate(-pos.dx, 0);
    }

    final Rect cargo = Rect.fromLTWH(pos.dx - 10 * scale, pos.dy - 24 * scale, 66 * scale, 24 * scale);
    final Rect cab = Rect.fromLTWH(pos.dx + 46 * scale, pos.dy - 21 * scale, 32 * scale, 21 * scale);
    final Rect bumper = Rect.fromLTWH(pos.dx + 74 * scale, pos.dy - 8 * scale, 6 * scale, 6 * scale);

    // Soft shadow under the vehicle.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx + 30 * scale, pos.dy + 5 * scale), width: 88 * scale, height: 10 * scale),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    // Cargo container.
    canvas.drawRRect(RRect.fromRectAndRadius(cargo, const Radius.circular(6)), Paint()..color = cargoColor);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cargo, const Radius.circular(6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Cargo ribs for more detail.
    for (int i = 0; i < 4; i++) {
      final double x = cargo.left + cargo.width * (0.16 + i * 0.18);
      canvas.drawLine(
        Offset(x, cargo.top + 3 * scale),
        Offset(x, cargo.bottom - 3 * scale),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.10)
          ..strokeWidth = 1.4,
      );
    }
    canvas.drawLine(
      Offset(cargo.left + 4 * scale, cargo.top + 5 * scale),
      Offset(cargo.right - 4 * scale, cargo.top + 5 * scale),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..strokeWidth = 1.3,
    );

    // Cab and bumper.
    canvas.drawRRect(RRect.fromRectAndRadius(cab, const Radius.circular(6)), Paint()..color = cabColor);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cab, const Radius.circular(6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(bumper, const Radius.circular(2)), Paint()..color = const Color(0xFFCBD5E1));

    // Windshield and side window.
    final Rect frontWindow = Rect.fromLTWH(pos.dx + 54 * scale, pos.dy - 18 * scale, 12 * scale, 8 * scale);
    final Rect sideWindow = Rect.fromLTWH(pos.dx + 67 * scale, pos.dy - 18 * scale, 6 * scale, 8 * scale);
    canvas.drawRRect(RRect.fromRectAndRadius(frontWindow, const Radius.circular(3)), Paint()..color = const Color(0xFFDFF4FF));
    canvas.drawRRect(RRect.fromRectAndRadius(sideWindow, const Radius.circular(2)), Paint()..color = const Color(0xFFCBEAFF));

    // Door line and mirror.
    canvas.drawLine(
      Offset(pos.dx + 65 * scale, pos.dy - 20 * scale),
      Offset(pos.dx + 65 * scale, pos.dy),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(Offset(pos.dx + 75 * scale, pos.dy - 15 * scale), 1.4 * scale, Paint()..color = const Color(0xFF475569));
    canvas.drawLine(
      Offset(pos.dx + 74 * scale, pos.dy - 14 * scale),
      Offset(pos.dx + 77 * scale, pos.dy - 12 * scale),
      Paint()
        ..color = const Color(0xFF475569)
        ..strokeWidth = 1.0,
    );

    // Lights.
    canvas.drawCircle(Offset(pos.dx + 78 * scale, pos.dy - 7 * scale), 2.8 * scale, Paint()..color = const Color(0xFFFFF176));
    canvas.drawCircle(Offset(pos.dx - 8 * scale, pos.dy - 8 * scale), 2.2 * scale, Paint()..color = const Color(0xFFFF8A65));
    canvas.drawCircle(Offset(pos.dx - 8 * scale, pos.dy - 15 * scale), 1.6 * scale, Paint()..color = const Color(0xFFEF4444));

    // Chassis.
    canvas.drawRect(
      Rect.fromLTWH(pos.dx + 2 * scale, pos.dy - 1.5 * scale, 62 * scale, 3 * scale),
      Paint()..color = const Color(0xFF475569),
    );

    // Wheel arches.
    canvas.drawArc(
      Rect.fromLTWH(pos.dx - 1 * scale, pos.dy - 8 * scale, 16 * scale, 16 * scale),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawArc(
      Rect.fromLTWH(pos.dx + 45 * scale, pos.dy - 8 * scale, 16 * scale, 16 * scale),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Wheels.
    for (final dx in [6 * scale, 52 * scale]) {
      final Offset wheel = Offset(pos.dx + dx, pos.dy + 1.5 * scale);
      canvas.drawCircle(wheel, 7 * scale, Paint()..color = const Color(0xFF1F2937));
      canvas.drawCircle(wheel, 4.2 * scale, Paint()..color = const Color(0xFF374151));
      canvas.drawCircle(wheel, 2.2 * scale, Paint()..color = const Color(0xFFE5E7EB));
      canvas.drawLine(
        Offset(wheel.dx - 2.4 * scale, wheel.dy),
        Offset(wheel.dx + 2.4 * scale, wheel.dy),
        Paint()..color = const Color(0xFFE5E7EB)..strokeWidth = 0.8,
      );
      canvas.drawLine(
        Offset(wheel.dx, wheel.dy - 2.4 * scale),
        Offset(wheel.dx, wheel.dy + 2.4 * scale),
        Paint()..color = const Color(0xFFE5E7EB)..strokeWidth = 0.8,
      );
    }

    canvas.restore();
  }

  void _drawCargoTrain(Canvas canvas, Offset pos, double scale, Color color) {
    canvas.save();
    final Rect engine = Rect.fromLTWH(pos.dx, pos.dy - 22 * scale, 56 * scale, 20 * scale);
    canvas.drawRRect(RRect.fromRectAndRadius(engine, const Radius.circular(6)), Paint()..color = color);
    canvas.drawRRect(RRect.fromRectAndRadius(engine, const Radius.circular(6)), Paint()..color = Colors.black.withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx + 6 * scale, pos.dy - 34 * scale, 22 * scale, 14 * scale), const Radius.circular(4)), Paint()..color = color);
    for (int i = 0; i < 3; i++) {
      final double carX = pos.dx + (68 + i * 48) * scale;
      final Rect car = Rect.fromLTWH(carX, pos.dy - 20 * scale, 40 * scale, 18 * scale);
      canvas.drawRRect(RRect.fromRectAndRadius(car, const Radius.circular(5)), Paint()..color = i.isEven ? const Color(0xFF60A5FA) : const Color(0xFFCBD5E1));
      canvas.drawRRect(RRect.fromRectAndRadius(car, const Radius.circular(5)), Paint()..color = Colors.black.withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 1.8);
      for (int j = 0; j < 2; j++) {
        canvas.drawCircle(Offset(carX + (10 + j * 20) * scale, pos.dy + 1 * scale), 4.5 * scale, Paint()..color = const Color(0xFF1F2937));
      }
    }
    for (int j = 0; j < 2; j++) {
      canvas.drawCircle(Offset(pos.dx + (14 + j * 20) * scale, pos.dy + 1 * scale), 5.0 * scale, Paint()..color = const Color(0xFF1F2937));
    }
    canvas.restore();
  }

  void _drawPallet(Canvas canvas, Rect rect, Color color) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), Paint()..color = color);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), Paint()..color = Colors.black.withValues(alpha: 0.16)..style = PaintingStyle.stroke..strokeWidth = 1.8);
    final Rect base = Rect.fromLTWH(rect.left, rect.bottom, rect.width, rect.height * 0.25);
    canvas.drawRect(base, Paint()..color = const Color(0xFF8B5A2B));
  }

  void _drawWarningSign(Canvas canvas, Offset center, double scale) {
    final Rect pole = Rect.fromCenter(center: Offset(center.dx, center.dy + 10 * scale), width: 4 * scale, height: 24 * scale);
    canvas.drawRect(pole, Paint()..color = const Color(0xFF7C8DA3));
    final Path diamond = Path()
      ..moveTo(center.dx, center.dy - 14 * scale)
      ..lineTo(center.dx + 12 * scale, center.dy)
      ..lineTo(center.dx, center.dy + 14 * scale)
      ..lineTo(center.dx - 12 * scale, center.dy)
      ..close();
    canvas.drawPath(diamond, Paint()..color = const Color(0xFFFCD34D));
    canvas.drawPath(diamond, Paint()..color = Colors.black.withValues(alpha: 0.20)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  void _drawSmallUtilityShed(Canvas canvas, Rect rect) {
    final Path shed = Path()
      ..moveTo(rect.left, rect.top + rect.height * 0.28)
      ..lineTo(rect.left + rect.width * 0.18, rect.top)
      ..lineTo(rect.right - rect.width * 0.18, rect.top)
      ..lineTo(rect.right, rect.top + rect.height * 0.28)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    canvas.drawPath(shed, Paint()..color = const Color(0xFFB7C8D8));
    canvas.drawPath(shed, Paint()..color = Colors.black.withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  void _drawShrub(Canvas canvas, Offset center, double scale) {
    final Paint bushPaint = Paint()..color = const Color(0xFF43A047);
    for (final bubble in [
      Offset(-10 * scale, 4 * scale),
      Offset(0, -3 * scale),
      Offset(11 * scale, 5 * scale),
    ]) {
      canvas.drawCircle(center + bubble, 10 * scale, bushPaint);
    }
  }

  void _drawSmokePuffs(Canvas canvas, Offset origin, double scale, double phase, {double opacity = 1.0}) {
    final Paint smokePaint = Paint()..color = Colors.white.withValues(alpha: 0.74 * opacity);
    final double drift = math.sin(phase * math.pi * 2) * 10;
    final List<Offset> puffs = [
      Offset(drift, -6),
      Offset(12 + drift, -22),
      Offset(-8 + drift, -34),
      Offset(18 + drift, -42),
      Offset(-3 + drift, -52),
    ];
    final List<double> radii = [10 * scale, 13 * scale, 9 * scale, 7 * scale, 5.5 * scale];
    for (int i = 0; i < puffs.length; i++) {
      canvas.drawCircle(origin + puffs[i], radii[i], smokePaint);
    }
  }

  Color _withOpacity(Color color, double opacity) {
    final double alpha = opacity.clamp(0.0, 1.0).toDouble();
    return Color.fromRGBO(color.red, color.green, color.blue, alpha);
  }

  @override
  bool shouldRepaint(covariant CartoonStyleBackgroundPainter oldDelegate) => oldDelegate.time != time;
}

class MenuHeavyButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color shadowColor;
  final double height;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const MenuHeavyButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.color,
    required this.shadowColor,
    this.height = 50,
    this.width,
    this.padding,
  });

  @override
  State<MenuHeavyButton> createState() => _MenuHeavyButtonState();
}

class _MenuHeavyButtonState extends State<MenuHeavyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: isDisabled
          ? null
          : (_) {
              setState(() {
                _isPressed = true;
              });
            },
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed!();
            },
      onTapCancel: isDisabled
          ? null
          : () {
              setState(() {
                _isPressed = false;
              });
            },
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              top: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: isDisabled ? Colors.grey : widget.shadowColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 4),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              bottom: _isPressed || isDisabled ? 0 : 8,
              left: 0,
              right: 0,
              top: _isPressed || isDisabled ? 8 : 0,
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: isDisabled ? Colors.grey.shade300 : widget.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 4),
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
