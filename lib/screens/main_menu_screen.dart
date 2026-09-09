// lib/screens/main_menu_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/game_state.dart';
import '../services/translation_service.dart';
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

  // YENİ EKLENDİ: Tüm kayıtları silip sıfırdan oyun başlatma mekanizması
  void _confirmAndStartNewGame() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.loss)),
        title: const Text('ŞİRKETİ TASFİYE ET', style: TextStyle(color: AppColors.loss, fontWeight: FontWeight.bold)),
        content: const Text('Yeni bir oyun başlatmak mevcut holdinginizi, tüm fabrikalarınızı ve kasanızı kalıcı olarak silecektir. Emin misiniz?', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c), 
            child: const Text('İPTAL', style: TextStyle(color: AppColors.textMuted))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.loss, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.pop(c);
              // Tüm kayıtları sil ve yeni oyun kurulum ekranını aç
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                await context.read<GameState>().loadData();
                _showHoldingSetupDialog();
              }
            }, 
            child: const Text('SİL VE YENİDEN BAŞLA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      )
    );
  }

  void _showHoldingSetupDialog() {
    String compName = 'Köse Holding';
    int logoIndex = 0;
    final List<IconData> logos = [
      Icons.domain_rounded, Icons.account_balance_rounded, Icons.factory_rounded,
      Icons.rocket_launch_rounded, Icons.local_shipping_rounded, Icons.bolt_rounded,
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment_rounded, color: AppColors.gold, size: 36),
                      const SizedBox(height: 12),
                      Text('KURUMSAL KAYIT', textAlign: TextAlign.center, style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.textPrimary, letterSpacing: 2.0)),
                      const SizedBox(height: 8),
                      const Text('Lütfen holdinginizin resmi adını ve tescilli amblemini belirleyin.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 24),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: 'Holding Adı',
                            labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            border: InputBorder.none,
                          ),
                          onChanged: (val) => compName = val,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      const Align(alignment: Alignment.centerLeft, child: Text('Tescilli Logo Seçimi', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 12),
                      
                      Wrap(
                        spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
                        children: List.generate(logos.length, (i) {
                          bool isSel = logoIndex == i;
                          return GestureDetector(
                            onTap: () => setDialogState(() => logoIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.gold.withValues(alpha: 0.1) : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isSel ? AppColors.gold : AppColors.border, width: isSel ? 2 : 1),
                              ),
                              child: Icon(logos[i], color: isSel ? AppColors.gold : AppColors.textMuted, size: 28),
                            ),
                          );
                        }),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold, 
                            foregroundColor: AppColors.darkBrown,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('holding_name', compName.isEmpty ? 'Köse Holding' : compName);
                            await prefs.setInt('holding_logo_index', logoIndex);
                            
                            if (context.mounted) {
                              context.read<GameState>().completeFirstLaunch();
                              Navigator.pop(context);
                              _goToMap(); 
                            }
                          },
                          child: const Text('TİCARİ FAALİYETE BAŞLA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
                        ),
                      ),
                    ],
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // DÜZELTME: İkon silindi, Kendi özel logon (assets/images/logo.png) eklendi
                  Container(
                    width: 130, height: 130,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        // Logo bulunamazsa oyun çökmesin diye geçici ikon yedeği
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_rounded, size: 60, color: AppColors.gold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'app_title'.tr().toUpperCase(),
                    style: AppTheme.titleStyle(fontSize: 36).copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 4.0,
                    ),
                  ),
                  
                  // EXECUTIVE EDITION yazısı tamamen kaldırıldı!
                  const SizedBox(height: 80),

                  if (_isAutoStarting)
                    Column(
                      children: [
                        const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
                        ),
                        const SizedBox(height: 16),
                        const Text('SİSTEME BAĞLANILIYOR...', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        if (state.isFirstLaunch) ...[
                          // HİÇ OYUN YOKSA SADECE YENİ OYUN BUTONU
                          SizedBox(
                            width: 260, height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.darkBrown,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _showHoldingSetupDialog,
                              child: const Text(
                                'YENİ ŞİRKET KUR',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5),
                              ),
                            ),
                          ),
                        ] else ...[
                          // KAYITLI OYUN VARSA DEVAM ET BUTONU
                          SizedBox(
                            width: 260, height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.darkBrown,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _goToMap,
                              child: const Text(
                                'YÖNETİME DÖN',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // KAYITLI OYUN VARSA YENİ OYUN BUTONU
                          SizedBox(
                            width: 260, height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.textPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.border, width: 1.5)),
                              ),
                              icon: const Icon(Icons.add_business_rounded, size: 18, color: AppColors.gold),
                              label: const Text('YENİ ŞİRKET KUR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0, color: AppColors.gold)),
                              onPressed: _confirmAndStartNewGame,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        // AYARLAR BUTONU
                        SizedBox(
                          width: 260, height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.background,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.border, width: 1.5)),
                            ),
                            icon: const Icon(Icons.settings_rounded, size: 18, color: AppColors.textSecondary),
                            label: const Text('SİSTEM AYARLARI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0, color: AppColors.textSecondary)),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          Positioned(
            bottom: 16, right: 16,
            child: Text('Build v1.2.0.4', style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5), fontSize: 10, fontFamily: 'SpaceMono')),
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
    final Paint gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.03)..strokeWidth = 1.0;
    double gridSize = 40.0;
    double offsetX = (time * gridSize) % gridSize; double offsetY = (time * gridSize * 0.5) % gridSize;
    for (double x = -gridSize + offsetX; x < w; x += gridSize) canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    for (double y = -gridSize + offsetY; y < h; y += gridSize) canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);

    final Paint chartPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.05)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final Path chartPath = Path(); double startY = h * 0.7;
    chartPath.moveTo(0, startY);
    for (double x = 0; x <= w; x += 20) {
      double y = startY + math.sin((x / 50) + (time * math.pi * 4)) * 30 + math.cos((x / 100) - (time * math.pi * 2)) * 50;
      chartPath.lineTo(x, y);
    }
    canvas.drawPath(chartPath, chartPaint);

    final Paint chartPaint2 = Paint()..color = AppColors.textSecondary.withValues(alpha: 0.05)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final Path chartPath2 = Path(); double startY2 = h * 0.8;
    chartPath2.moveTo(0, startY2);
    for (double x = 0; x <= w; x += 20) {
      double y = startY2 + math.cos((x / 60) + (time * math.pi * 3)) * 40;
      chartPath2.lineTo(x, y);
    }
    canvas.drawPath(chartPath2, chartPaint2);

    final Paint nodePaint = Paint()..color = AppColors.gold.withValues(alpha: 0.2);
    math.Random rnd = math.Random(42); 
    for (int i = 0; i < 15; i++) {
      double nx = rnd.nextDouble() * w; double ny = rnd.nextDouble() * h;
      double pulse = (math.sin(time * math.pi * 2 * (1 + rnd.nextDouble())) + 1) / 2;
      if (pulse > 0.5) {
        canvas.drawCircle(Offset(nx, ny), 2.0, nodePaint);
        if (i % 3 == 0) canvas.drawLine(Offset(nx, ny), Offset(nx + 40, ny - 20), Paint()..color = AppColors.gold.withValues(alpha: 0.1 * pulse)..strokeWidth = 1);
      }
    }
  }
  @override bool shouldRepaint(covariant CorporateGridPainter oldDelegate) => oldDelegate.time != time;
}