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
                            onChanged: (val) { compName = val; },
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('HOLDİNG LOGOSU', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
                          children: List.generate(
                            logos.length,
                            (i) {
                              final bool isSel = logoIndex == i;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  AudioService.instance.playSfx('click.mp3');
                                  setDialogState(() { logoIndex = i; });
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
                          width: double.infinity, height: 60,
                          color: AppColors.profit, shadowColor: Colors.green.shade800,
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
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
              ),
            ),
          ),
          const CartoonBackgroundAnimation(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 160, height: 160,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.black, width: 5),
                        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 10))],
                      ),
                      child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.account_balance_rounded,
                            size: 80,
                            color: AppColors.gold,
                          );
                        },
                      ),
                    ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        border: Border.all(color: Colors.black, width: 4),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 6))],
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'app_title'.tr().toUpperCase(),
                          style: AppTheme.titleStyle(fontSize: 28).copyWith(
                            color: Colors.black, letterSpacing: 2.0,
                            shadows: const [],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    if (_isAutoStarting)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.black, width: 4),
                        ),
                        child: const Column(
                          children: [
                            SizedBox(width: 36, height: 36, child: CircularProgressIndicator(color: AppColors.neonCyan, strokeWidth: 4)),
                            SizedBox(height: 20),
                            Text('HOLDİNG HAZIRLANIYOR...', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2.0, fontFamily: 'SpaceMono')),
                            SizedBox(height: 8),
                            Text('Şirketlerin seni bekliyor', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          if (state.isFirstLaunch) ...[
                            MenuHeavyButton(
                              width: 280, height: 65,
                              color: AppColors.profit, shadowColor: Colors.green.shade800,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                AudioService.instance.playSfx('click.mp3');
                                _showHoldingSetupDialog();
                              },
                              child: const Text('HOLDİNG KUR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
                            ),
                          ] else ...[
                            MenuHeavyButton(
                              width: 280, height: 65,
                              color: AppColors.gold, shadowColor: Colors.orange.shade700,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                AudioService.instance.playSfx('click.mp3');
                                _goToMap();
                              },
                              child: const Text('HOLDİNGİ YÖNET', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
                            ),
                            const SizedBox(height: 20),
                            MenuHeavyButton(
                              width: 280, height: 60,
                              color: Colors.white, shadowColor: Colors.grey.shade400,
                              onPressed: _confirmAndStartNewGame,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_business_rounded, size: 24, color: AppColors.neonCyan),
                                  SizedBox(width: 10),
                                  Text('YENİ HOLDİNG KUR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0, color: Colors.black)),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          MenuHeavyButton(
                            width: 280, height: 60,
                            color: const Color(0xFFF1F5F9), shadowColor: Colors.grey.shade400,
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
                                Text('OYUN AYARLARI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartoonLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint outlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeJoin = StrokeJoin.round;

    final Paint buildingFill = Paint()..color = AppColors.neonCyan;
    final Paint goldFill = Paint()..color = AppColors.gold;
    final Paint shadowFill = Paint()..color = Colors.black12;

    Path factoryPath = Path()
      ..moveTo(w * 0.1, h * 0.9)
      ..lineTo(w * 0.1, h * 0.4)
      ..lineTo(w * 0.3, h * 0.2)
      ..lineTo(w * 0.3, h * 0.4)
      ..lineTo(w * 0.5, h * 0.2)
      ..lineTo(w * 0.5, h * 0.4)
      ..lineTo(w * 0.7, h * 0.2)
      ..lineTo(w * 0.9, h * 0.4)
      ..lineTo(w * 0.9, h * 0.9)
      ..close();

    canvas.drawPath(factoryPath, buildingFill);
    canvas.drawPath(factoryPath, outlinePaint);

    for (int i = 0; i < 3; i++) {
      Rect window = Rect.fromLTWH(w * 0.2 + (i * w * 0.22), h * 0.55, w * 0.12, h * 0.12);
      canvas.drawRect(window, Paint()..color = Colors.white);
      canvas.drawRect(window, outlinePaint);
    }

    canvas.drawCircle(Offset(w * 0.75, h * 0.75), w * 0.3, shadowFill);
    canvas.drawCircle(Offset(w * 0.75, h * 0.75), w * 0.3, goldFill);
    canvas.drawCircle(Offset(w * 0.75, h * 0.75), w * 0.3, outlinePaint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.75), w * 0.22, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '\$',
        style: TextStyle(color: Colors.black, fontSize: 56, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(w * 0.75 - textPainter.width / 2, h * 0.75 - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CartoonBackgroundAnimation extends StatefulWidget {
  const CartoonBackgroundAnimation({super.key});
  @override State<CartoonBackgroundAnimation> createState() => _CartoonBackgroundAnimationState();
}

class _CartoonBackgroundAnimationState extends State<CartoonBackgroundAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  @override void initState() { super.initState(); _animController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat(); }
  @override void dispose() { _animController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _animController, builder: (context, child) {
      return CustomPaint(size: Size.infinite, painter: CartoonGridPainter(time: _animController.value));
    });
  }
}

class CartoonGridPainter extends CustomPainter {
  final double time;
  CartoonGridPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    final Path cloud = Path()
      ..addOval(Rect.fromCircle(center: Offset((time * 80) % (w + 200) - 100, h * 0.15), radius: 45))
      ..addOval(Rect.fromCircle(center: Offset((time * 80) % (w + 200) - 50, h * 0.15 - 25), radius: 60))
      ..addOval(Rect.fromCircle(center: Offset((time * 80) % (w + 200) + 10, h * 0.15), radius: 45));
    canvas.drawPath(cloud, cloudPaint);
    
    final Path cloud2 = Path()
      ..addOval(Rect.fromCircle(center: Offset(w - ((time * 60) % (w + 200)) + 100, h * 0.85), radius: 35))
      ..addOval(Rect.fromCircle(center: Offset(w - ((time * 60) % (w + 200)) + 50, h * 0.85 - 20), radius: 45))
      ..addOval(Rect.fromCircle(center: Offset(w - ((time * 60) % (w + 200)) - 10, h * 0.85), radius: 35));
    canvas.drawPath(cloud2, cloudPaint);

    final Paint starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for(int i=0; i<8; i++) {
      double sx = (i * w / 8 + time * 30) % w;
      double sy = (math.sin(time * 4 + i) * 30) + (h * 0.5);
      canvas.drawCircle(Offset(sx, sy), 5 + math.sin(time * 6 + i) * 3, starPaint);
    }
  }

  @override bool shouldRepaint(covariant CartoonGridPainter oldDelegate) => oldDelegate.time != time;
}

class MenuHeavyButton extends StatefulWidget {
  final VoidCallback? onPressed; final Widget child; final Color color; final Color shadowColor; final double height; final double? width; final EdgeInsetsGeometry? padding;
  const MenuHeavyButton({super.key, required this.onPressed, required this.child, required this.color, required this.shadowColor, this.height = 50, this.width, this.padding});
  @override State<MenuHeavyButton> createState() => _MenuHeavyButtonState();
}

class _MenuHeavyButtonState extends State<MenuHeavyButton> {
  bool _isPressed = false;
  @override Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: isDisabled ? null : (_) { setState(() { _isPressed = true; }); },
      onTapUp: isDisabled ? null : (_) { setState(() => _isPressed = false); widget.onPressed!(); },
      onTapCancel: isDisabled ? null : () { setState(() { _isPressed = false; }); },
      child: SizedBox(
        width: widget.width, height: widget.height,
        child: Stack(
          children: [
            Positioned(
              bottom: 0, left: 0, right: 0, top: 8,
              child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey : widget.shadowColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 4))),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              bottom: _isPressed || isDisabled ? 0 : 8, left: 0, right: 0, top: _isPressed || isDisabled ? 8 : 0,
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade300 : widget.color, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 4)),
                child: Center(child: widget.child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
