// lib/screens/main_menu_screen.dart
// ignore_for_file: use_build_context_synchronously

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
  const MainMenuScreen({super.key, this.isInitialLaunch = true});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _isAutoStarting = true; 

  @override
  void initState() {
    super.initState();
    
    if (widget.isInitialLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<GameState>().loadData();
        if (!mounted) return;
        
        final state = context.read<GameState>();
        
        if (!state.isFirstLaunch) {
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) _goToMap();
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
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.loss, width: 3)),
        title: const Text('ŞİRKETİ TASFİYE ET', style: TextStyle(color: AppColors.loss, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
        content: const Text('Yeni bir oyun başlatmak mevcut holdinginizi, tüm fabrikalarınızı ve kasanızı kalıcı olarak silecektir. Emin misiniz?', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () { 
              AudioService.instance.playSfx('click.mp3');
              Navigator.pop(c); 
            }, 
            child: const Text('İPTAL', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold))
          ),
          MenuHeavyButton(
            color: AppColors.loss,
            shadowColor: const Color(0xFF7A1010),
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () async {
              HapticFeedback.heavyImpact();
              AudioService.instance.playSfx('click.mp3');
              Navigator.pop(c);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                await context.read<GameState>().loadData();
                _showHoldingSetupDialog();
              }
            }, 
            child: const Text('SİL VE YENİDEN BAŞLA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      )
    );
  }

  void _showHoldingSetupDialog() {
    String compName = 'MyHolding';
    int logoIndex = 0;
    
    final List<IconData> logos = [
      Icons.domain_rounded, Icons.account_balance_rounded, Icons.precision_manufacturing_rounded,
      Icons.rocket_launch_rounded, Icons.local_shipping_rounded, Icons.bolt_rounded,
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
                    color: AppColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppColors.border, width: 4.0),
                    boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 16)],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: const Icon(Icons.assignment_rounded, color: AppColors.gold, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text('KURUMSAL KAYIT', textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 20).copyWith(color: AppColors.textPrimary, letterSpacing: 2.0)),
                        const SizedBox(height: 8),
                        const Text('Lütfen ticari serüvene atılacak olan holdinginizin resmi adını ve logosunu belirleyin.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 24),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: TextField(
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'SpaceMono'),
                            decoration: const InputDecoration(
                              labelText: 'Holding Adı',
                              labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                              border: InputBorder.none,
                            ),
                            onChanged: (val) => compName = val,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        const Align(alignment: Alignment.centerLeft, child: Text('Tescilli Logo Seçimi', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900))),
                        const SizedBox(height: 12),
                        
                        Wrap(
                          spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
                          children: List.generate(logos.length, (i) {
                            bool isSel = logoIndex == i;
                            return GestureDetector(
                              onTap: () { 
                                HapticFeedback.selectionClick();
                                AudioService.instance.playSfx('click.mp3');
                                setDialogState(() => logoIndex = i); 
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.gold : AppColors.background,
                                  borderRadius: BorderRadius.zero,
                                  border: Border.all(color: isSel ? AppColors.darkBrown : AppColors.border, width: 2),
                                  boxShadow: isSel ? const [BoxShadow(color: Colors.black54, offset: Offset(0, 4))] : [],
                                ),
                                child: Icon(logos[i], color: isSel ? AppColors.darkBrown : AppColors.textMuted, size: 28),
                              ),
                            );
                          }),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        MenuHeavyButton(
                          width: double.infinity,
                          height: 55,
                          color: AppColors.gold,
                          shadowColor: const Color(0xFF8B6B32),
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            AudioService.instance.playSfx('cash.mp3');
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('holding_name', compName.isEmpty ? 'Köse Holding' : compName);
                            await prefs.setInt('holding_logo_index', logoIndex);
                            
                            await context.read<GameState>().startNewGameSession();
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                              _goToMap(); 
                            }
                          },
                          child: const Text('TİCARİ FAALİYETE BAŞLA', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
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
                colors: [Color(0xFF14141C), Color(0xFF0A0A10)], 
              ),
            ),
          ),
          
          const CorporateBackgroundAnimation(),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140, height: 140,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.9),
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: AppColors.border, width: 4),
                        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 8), blurRadius: 10)],
                      ),
                      child: ClipRect(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_rounded, size: 60, color: AppColors.gold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        border: Border.all(color: AppColors.border, width: 2),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        'app_title'.tr().toUpperCase(),
                        style: AppTheme.titleStyle(fontSize: 32).copyWith(
                          color: AppColors.textPrimary,
                          letterSpacing: 4.0,
                          shadows: const [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4)],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 80),

                    if (_isAutoStarting)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: const Column(
                          children: [
                            SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 3),
                            ),
                            SizedBox(height: 16),
                            Text('SİSTEME BAĞLANILIYOR...', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.0, fontFamily: 'SpaceMono')),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          if (state.isFirstLaunch) ...[
                            MenuHeavyButton(
                              width: 260, height: 60,
                              color: AppColors.gold,
                              shadowColor: const Color(0xFF8B6B32),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                AudioService.instance.playSfx('click.mp3');
                                _showHoldingSetupDialog();
                              },
                              child: const Text(
                                'YENİ ŞİRKET KUR',
                                style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5),
                              ),
                            ),
                          ] else ...[
                            MenuHeavyButton(
                              width: 260, height: 60,
                              color: AppColors.gold,
                              shadowColor: const Color(0xFF8B6B32),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                AudioService.instance.playSfx('click.mp3');
                                _goToMap();
                              },
                              child: const Text(
                                'YÖNETİME DÖN',
                                style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            MenuHeavyButton(
                              width: 260, height: 55,
                              color: AppColors.surfaceElevated,
                              shadowColor: const Color(0xFF14161C),
                              onPressed: _confirmAndStartNewGame,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_business_rounded, size: 18, color: AppColors.gold),
                                  SizedBox(width: 8),
                                  Text('YENİ ŞİRKET KUR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0, color: AppColors.gold)),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          MenuHeavyButton(
                            width: 260, height: 55,
                            color: AppColors.background,
                            shadowColor: Colors.black,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              AudioService.instance.playSfx('click.mp3');
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.settings_suggest_rounded, size: 18, color: AppColors.textSecondary),
                                SizedBox(width: 8),
                                Text('SİSTEM AYARLARI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0, color: AppColors.textSecondary)),
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
          
          Positioned(
            bottom: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black87, border: Border.all(color: AppColors.border, width: 2), borderRadius: BorderRadius.zero),
              child: const Text('Terminal v1.2.0.4', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontFamily: 'SpaceMono', fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

class CorporateBackgroundAnimation extends StatefulWidget {
  const CorporateBackgroundAnimation({super.key});
  @override State<CorporateBackgroundAnimation> createState() => _CorporateBackgroundAnimationState();
}

class _CorporateBackgroundAnimationState extends State<CorporateBackgroundAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  @override void initState() { super.initState(); _animController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat(); }
  @override void dispose() { _animController.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) => CustomPaint(size: Size.infinite, painter: CorporateGridPainter(time: _animController.value)),
    );
  }
}

class CorporateGridPainter extends CustomPainter {
  final double time; 
  CorporateGridPainter({required this.time});

  @override void paint(Canvas canvas, Size size) {
    final double w = size.width; final double h = size.height;
    final Paint gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.03)..strokeWidth = 2.0;
    double gridSize = 50.0;
    double offsetX = (time * gridSize) % gridSize; double offsetY = (time * gridSize * 0.5) % gridSize;
    for (double x = -gridSize + offsetX; x < w; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = -gridSize + offsetY; y < h; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final Paint chartPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.08)..style = PaintingStyle.stroke..strokeWidth = 3.0;
    final Path chartPath = Path(); double startY = h * 0.7;
    chartPath.moveTo(0, startY);
    for (double x = 0; x <= w; x += 20) {
      double y = startY + math.sin((x / 50) + (time * math.pi * 4)) * 30 + math.cos((x / 100) - (time * math.pi * 2)) * 50;
      chartPath.lineTo(x, y);
    }
    canvas.drawPath(chartPath, chartPaint);

    final Paint nodePaint = Paint()..color = AppColors.gold.withValues(alpha: 0.3);
    math.Random rnd = math.Random(42); 
    for (int i = 0; i < 15; i++) {
      double nx = rnd.nextDouble() * w; double ny = rnd.nextDouble() * h;
      double pulse = (math.sin(time * math.pi * 2 * (1 + rnd.nextDouble())) + 1) / 2;
      if (pulse > 0.5) {
        canvas.drawRect(Rect.fromCenter(center: Offset(nx, ny), width: 6, height: 6), nodePaint);
        if (i % 3 == 0) canvas.drawLine(Offset(nx, ny), Offset(nx + 40, ny - 20), Paint()..color = AppColors.gold.withValues(alpha: 0.15 * pulse)..strokeWidth = 2);
      }
    }
  }
  @override bool shouldRepaint(covariant CorporateGridPainter oldDelegate) => oldDelegate.time != time;
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
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) { setState(() => _isPressed = false); widget.onPressed!(); },
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      child: SizedBox(
        width: widget.width, height: widget.height,
        child: Stack(children: [
          Positioned(bottom: 0, left: 0, right: 0, top: 6, child: Container(decoration: BoxDecoration(color: isDisabled ? AppColors.border.withValues(alpha: 0.5) : widget.shadowColor, borderRadius: BorderRadius.zero, border: Border.all(color: Colors.black87, width: 2.5)))),
          AnimatedPositioned(duration: const Duration(milliseconds: 60), bottom: _isPressed || isDisabled ? 0 : 6, left: 0, right: 0, top: _isPressed || isDisabled ? 6 : 0, child: Container(padding: widget.padding, decoration: BoxDecoration(color: isDisabled ? AppColors.surfaceElevated : widget.color, borderRadius: BorderRadius.zero, border: Border.all(color: Colors.black87, width: 2.5)), child: Center(child: widget.child))),
        ]),
      ),
    );
  }
}