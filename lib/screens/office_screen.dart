// lib/screens/office_screen.dart
// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class OfficeScreen extends StatelessWidget {
  const OfficeScreen({super.key});

  String _formatNum(double value) {
    if (value >= 1e33) return '${(value / 1e33).toStringAsFixed(2)} Dc';
    if (value >= 1e30) return '${(value / 1e30).toStringAsFixed(2)} No';
    if (value >= 1e27) return '${(value / 1e27).toStringAsFixed(2)} Oc';
    if (value >= 1e24) return '${(value / 1e24).toStringAsFixed(2)} Sp';
    if (value >= 1e21) return '${(value / 1e21).toStringAsFixed(2)} Sx';
    if (value >= 1e18) return '${(value / 1e18).toStringAsFixed(2)} Qi';
    if (value >= 1e15) return '${(value / 1e15).toStringAsFixed(2)} Qa';
    if (value >= 1e12) return '${(value / 1e12).toStringAsFixed(2)} T';
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(2)} B';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(2)} M';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(1)} K';
    return value.toStringAsFixed(0);
  }

  void _showHireSheet(BuildContext context, OfficeStaff staff, GameState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 3)),
      builder: (c) {
        return Consumer<GameState>(
          builder: (context, gameState, child) {
            final currentStaff = gameState.officeStaff.firstWhere((s) => s.id == staff.id);
            final bool isMax = currentStaff.isMaxed;
            final bool canAfford = gameState.money >= currentStaff.currentCost && !isMax;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 50, height: 6, decoration: const BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.zero)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.border, width: 2)),
                          child: Icon(isMax ? Icons.workspace_premium_rounded : Icons.badge_rounded, color: AppColors.gold, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(fit: BoxFit.scaleDown, child: Text(currentStaff.title.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.0))),
                              const SizedBox(height: 4),
                              Text('Mevcut Kadro: ${currentStaff.level}/${currentStaff.maxLevel}', style: TextStyle(color: isMax ? AppColors.profit : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(currentStaff.baseDescription, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.border, width: 2)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Mevcut Etki:', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900)),
                              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(currentStaff.currentEffectText, style: TextStyle(color: currentStaff.level > 0 ? AppColors.profit : AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')))),
                            ],
                          ),
                          if (!isMax) ...[
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.border, height: 1, thickness: 2)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Terfi Sonrası:', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900)),
                                Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(currentStaff.nextEffectText, style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    OfficeHeavyButton(
                      width: double.infinity, height: 55,
                      color: isMax ? AppColors.background : (canAfford ? AppColors.gold : AppColors.surfaceElevated),
                      shadowColor: isMax ? Colors.black : (canAfford ? const Color(0xFF8B6B32) : Colors.black),
                      onPressed: canAfford ? () {
                        HapticFeedback.lightImpact(); 
                        AudioService.instance.playSfx('cash.mp3');
                        gameState.hireStaff(currentStaff.id);
                      } : null,
                      child: Text(
                        isMax ? 'MAKSİMUM KAPASİTE' : 'TERFİ VER (\$${_formatNum(currentStaff.currentCost)})',
                        style: TextStyle(color: isMax || !canAfford ? AppColors.textMuted : AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final staffList = gameState.officeStaff;
    final double incomePerSecond = gameState.incomePerSecond;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text('YAZIHANE', style: AppTheme.titleStyle(fontSize: 20).copyWith(color: AppColors.textPrimary)),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 24),
          onPressed: () {
            AudioService.instance.playSfx('click.mp3');
            Navigator.pop(context);
          }
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF14141C), Color(0xFF0A0A10)], 
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(left: 16, right: 16, top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, bottom: 16),
              sliver: SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppColors.border, width: 3.0),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      const Text('HOLDİNG YÖNETİM MERKEZİ', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      const Text(
                        'Departmanları genişletmek ve personeli terfi ettirmek için ilgili odaya dokunun.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.border, width: 2)),
                        child: Text('KASA: \$${_formatNum(gameState.money)}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 15, fontFamily: 'SpaceMono')),
                      )
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75, 
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final staff = staffList[index];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        AudioService.instance.playSfx('click.mp3');
                        _showHireSheet(context, staff, gameState);
                      },
                      child: VisualRoomWidget(staff: staff, incomePerSecond: incomePerSecond), 
                    );
                  },
                  childCount: staffList.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VisualRoomWidget extends StatefulWidget {
  final OfficeStaff staff;
  final double incomePerSecond; 

  const VisualRoomWidget({super.key, required this.staff, required this.incomePerSecond});
  @override 
  State<VisualRoomWidget> createState() => _VisualRoomWidgetState();
}

class _VisualRoomWidgetState extends State<VisualRoomWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override 
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))..repeat();
  }

  @override 
  void dispose() { 
    _animController.dispose(); 
    super.dispose(); 
  }

  Color _getDepartmentColor() {
    switch (widget.staff.id) {
      case 'staff_1': return const Color(0xFF38BDF8); 
      case 'staff_2': return const Color(0xFFF59E0B); 
      case 'staff_3': return const Color(0xFF10B981); 
      case 'staff_4': return const Color(0xFFA855F7); 
      case 'staff_5': return const Color(0xFFEC4899); 
      case 'staff_6': return const Color(0xFF0EA5E9); 
      case 'staff_7': return const Color(0xFFEAB308); 
      default: return Colors.white54;
    }
  }

  IconData _getDepartmentIcon() {
    switch (widget.staff.id) {
      case 'staff_1': return Icons.calculate_rounded;
      case 'staff_2': return Icons.precision_manufacturing_rounded;
      case 'staff_3': return Icons.engineering_rounded;
      case 'staff_4': return Icons.candlestick_chart_rounded;
      case 'staff_5': return Icons.settings_input_antenna_rounded;
      case 'staff_6': return Icons.local_shipping_rounded;
      case 'staff_7': return Icons.battery_charging_full_rounded;
      default: return Icons.domain_rounded;
    }
  }

  @override 
  Widget build(BuildContext context) {
    final bool isActive = widget.staff.level > 0;
    final Color deptColor = _getDepartmentColor();
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: isActive ? deptColor.withValues(alpha: 0.8) : AppColors.border, 
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive ? deptColor.withValues(alpha: 0.2) : Colors.black54, 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      child: ClipRect(
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) => CustomPaint(
                size: Size.infinite, 
                painter: MatteOfficePainter(
                  time: _animController.value, 
                  isActive: isActive, 
                  staffLevel: widget.staff.level, 
                  deptColor: deptColor,
                  deptId: widget.staff.id,
                  incomePerSecond: widget.incomePerSecond, 
                )
              ),
            ),
            
            Positioned(top: 10, left: 10, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: isActive ? AppColors.profit : AppColors.loss, border: Border.all(color: Colors.black, width: 1.5)))),
            Positioned(
              top: 8, right: 8, 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.border, width: 1.5)), 
                child: Text('Lvl ${widget.staff.level}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono'))
              )
            ),
            
            Positioned(
              bottom: 0, left: 0, right: 0, 
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4), 
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.96),
                  border: const Border(top: BorderSide(color: AppColors.border, width: 2))
                ), 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getDepartmentIcon(), color: isActive ? deptColor : AppColors.textMuted, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.staff.title
                              .replaceAll(' Departmanı', '')
                              .replaceAll(' Müdürlüğü', '')
                              .replaceAll(' Operasyonu', '')
                              .toUpperCase(), 
                          style: TextStyle(color: isActive ? AppColors.textPrimary : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                        ),
                      ),
                    ),
                  ],
                )
              )
            ),
          ],
        ),
      ),
    );
  }
}

class MatteOfficePainter extends CustomPainter {
  final double time; 
  final bool isActive;
  final int staffLevel;
  final Color deptColor;
  final String deptId;
  final double incomePerSecond;

  MatteOfficePainter({
    required this.time, 
    required this.isActive, 
    required this.staffLevel, 
    required this.deptColor, 
    required this.deptId,
    required this.incomePerSecond,
  });

  @override 
  void paint(Canvas canvas, Size size) {
    final double w = size.width; 
    final double h = size.height;
    final double tPI = time * math.pi * 2; 

    Color leftWallColor = isActive 
        ? Color.lerp(deptColor, const Color(0xFF333B4D), 0.82)! 
        : const Color(0xFF1E222B);

    Color backWallColor = isActive 
        ? Color.lerp(deptColor, const Color(0xFF40495C), 0.86)! 
        : const Color(0xFF262C38);

    Color floorColor = isActive 
        ? const Color(0xFF4A5568) 
        : const Color(0xFF1E293B);

    Path leftWall = Path()..moveTo(0, 0)..lineTo(w * 0.15, h * 0.1)..lineTo(w * 0.15, h * 0.65)..lineTo(0, h)..close();
    canvas.drawPath(leftWall, Paint()..color = leftWallColor); 
    
    canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.1, w * 0.85, h * 0.55), Paint()..color = backWallColor);

    Path floor = Path()..moveTo(0, h)..lineTo(w * 0.15, h * 0.65)..lineTo(w, h * 0.65)..lineTo(w, h)..close();
    canvas.drawPath(floor, Paint()..color = floorColor);

    if (isActive) {
      final Paint plankPaint = Paint()..color = Colors.black45..strokeWidth = 2.0;
      canvas.drawLine(Offset(0, h * 0.77), Offset(w, h * 0.77), plankPaint);
      canvas.drawLine(Offset(0, h * 0.89), Offset(w, h * 0.89), plankPaint);
      canvas.drawLine(Offset(w * 0.35, h * 0.65), Offset(w * 0.25, h * 0.77), plankPaint);
      canvas.drawLine(Offset(w * 0.70, h * 0.65), Offset(w * 0.60, h * 0.77), plankPaint);
      canvas.drawLine(Offset(w * 0.50, h * 0.77), Offset(w * 0.40, h * 0.89), plankPaint);

      canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.635, w * 0.85, h * 0.015), Paint()..color = const Color(0xFF1E293B));

      final Path lightCone = Path()
        ..moveTo(w * 0.42, 0)
        ..lineTo(w * 0.68, 0)
        ..lineTo(w * 0.95, h * 0.85)
        ..lineTo(w * 0.15, h * 0.85)
        ..close();
      canvas.drawPath(
        lightCone, 
        Paint()..shader = ui.Gradient.linear(
          Offset(w * 0.55, 0),
          Offset(w * 0.55, h * 0.85),
          [Colors.white.withValues(alpha: 0.12), Colors.white.withValues(alpha: 0.0)],
        )
      );

      canvas.drawLine(Offset(w * 0.15, h * 0.1), Offset(w * 0.15, h * 0.65), Paint()..color = Colors.white12..strokeWidth = 2.0);
    }

    if (isActive) {
      if (deptId == 'staff_1') {
        _drawSafe(canvas, w, h);
        _drawWallClock(canvas, w, h, tPI);
      } 
      else if (deptId == 'staff_2') {
        _drawBlueprintWall(canvas, w, h, tPI);
      } 
      else if (deptId == 'staff_3') {
        _drawHRPosters(canvas, w, h);
      } 
      else if (deptId == 'staff_4') {
        _drawStockTickerWall(canvas, w, h, tPI);
      }
      else if (deptId == 'staff_5') {
        _drawMarketingWall(canvas, w, h, tPI);
      }
      else if (deptId == 'staff_6') {
        _drawLogisticsWall(canvas, w, h, tPI);
      }
      else if (deptId == 'staff_7') {
        _drawShiftWall(canvas, w, h, tPI);
      }

      int assistants = math.min(4, staffLevel ~/ 10);
      for (int i = 0; i < assistants; i++) {
        double phase = i * 1.7;
        double ax = w * 0.25 + (i * w * 0.15);
        double ay = h * 0.68;
        
        _drawMatteDesk(canvas, ax, ay);
        _drawMatteWorker(canvas, ax + 10, ay - 8, tPI + phase, 0.45, isMain: false, deptId: deptId);
        _drawBgMonitorBack(canvas, ax + 10, ay);
      }

      final double deskY = h * 0.80;
      final double workerX = w * 0.55;
      _drawOfficeChairBack(canvas, workerX, deskY - 14, tPI);
      _drawMatteWorker(canvas, workerX, deskY - 14, tPI, 0.82, isMain: true, deptId: deptId);
      _drawMatteDesk(canvas, w * 0.55, deskY, width: w * 0.62, dark: false);
      _drawMainAccessories(canvas, w, deskY, tPI, deptId, workerX);

      if (deptId == 'staff_3') {
        _drawPottedPlant(canvas, w, h, tPI);
      }
      if (deptId == 'staff_2') {
        _drawWarningLines(canvas, w, h);
      }
      if (deptId == 'staff_6') {
        _drawLogisticsFloorCargo(canvas, w, h);
      }

    } else {
      _drawMatteDesk(canvas, w * 0.55, h * 0.80, width: w * 0.6, dark: true);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black.withValues(alpha: 0.55)); 
    }
  }

  void _drawOfficeChairBack(Canvas canvas, double cx, double cy, double tPI) {
    final double chairSway = math.sin(tPI * 1.5) * 0.6;
    final Rect chairRect = Rect.fromCenter(center: Offset(cx + chairSway, cy - 10), width: 28, height: 32);
    canvas.drawRect(chairRect, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRect(chairRect.deflate(2.0), Paint()..color = const Color(0xFF334155));
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx + chairSway, cy - 23), width: 18, height: 8),
      Paint()..color = const Color(0xFF475569),
    );
  }

  void _drawSafe(Canvas canvas, double w, double h) {
    final Rect safeRect = Rect.fromLTWH(w * 0.18, h * 0.35, w * 0.25, h * 0.30);
    canvas.drawRect(safeRect, Paint()..color = const Color(0xFF475569));
    canvas.drawRect(Rect.fromLTWH(w * 0.20, h * 0.38, w * 0.21, h * 0.24), Paint()..color = const Color(0xFF334155));
    canvas.drawCircle(Offset(w * 0.38, h * 0.50), 6, Paint()..color = const Color(0xFFCBD5E1));
    canvas.drawRect(Rect.fromLTWH(w * 0.37, h * 0.50, 2, 10), Paint()..color = Colors.white);
  }

  void _drawBlueprintWall(Canvas canvas, double w, double h, double tPI) {
    final Rect board = Rect.fromLTWH(w * 0.25, h * 0.20, w * 0.5, h * 0.25);
    canvas.drawRect(board, Paint()..color = const Color(0xFF1D4ED8)); 
    canvas.drawRect(board, Paint()..color = const Color(0xFF93C5FD)..style=PaintingStyle.stroke..strokeWidth=2);
    
    canvas.save();
    canvas.translate(w * 0.6, h * 0.3);
    canvas.rotate(tPI * 0.5); 
    final Paint gearPaint = Paint()..color = Colors.white70..style=PaintingStyle.stroke..strokeWidth=2.0;
    canvas.drawCircle(Offset.zero, 8, gearPaint);
    for (int i = 0; i < 4; i++) {
      canvas.rotate(math.pi / 4);
      canvas.drawLine(const Offset(-10, 0), const Offset(10, 0), gearPaint);
    }
    canvas.restore();

    final Paint line = Paint()..color = Colors.white70..style=PaintingStyle.stroke..strokeWidth=2.0;
    canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.25, w * 0.15, h * 0.1), line);
    canvas.drawLine(Offset(w * 0.32, h * 0.35), Offset(w * 0.48, h * 0.35), line);
  }

  void _drawHRPosters(Canvas canvas, double w, double h) {
    canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.2, w * 0.15, h * 0.18), Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawRect(Rect.fromLTWH(w * 0.32, h * 0.22, w * 0.11, h * 0.14), Paint()..color = const Color(0xFF64748B)..style=PaintingStyle.stroke..strokeWidth=2);
    canvas.drawRect(Rect.fromLTWH(w * 0.55, h * 0.25, w * 0.2, h * 0.12), Paint()..color = const Color(0xFFF1F5F9));
    canvas.drawRect(Rect.fromLTWH(w * 0.62, h * 0.28, 6, 6), Paint()..color = const Color(0xFFEAB308)); 
  }

  void _drawStockTickerWall(Canvas canvas, double w, double h, double tPI) {
    final Rect screen = Rect.fromLTWH(w * 0.2, h * 0.15, w * 0.6, h * 0.28);
    canvas.drawRect(screen, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRect(screen, Paint()..color = const Color(0xFF475569)..style=PaintingStyle.stroke..strokeWidth=3);

    final Path trend = Path();
    final Paint trendPaint = Paint()..color = AppColors.profit..style = PaintingStyle.stroke..strokeWidth = 2.5;
    double startX = screen.left + 5;
    double step = (screen.width - 10) / 15;
    
    trend.moveTo(startX, screen.bottom - 10);
    for (int i = 0; i <= 15; i++) {
      double py = screen.bottom - 10 - (i * 2) + math.sin(tPI * 2 + i) * 12;
      py = py.clamp(screen.top + 5, screen.bottom - 5);
      if (i == 0) {
        trend.moveTo(startX + (i * step), py);
      } else {
        trend.lineTo(startX + (i * step), py);
      }
    }
    canvas.drawPath(trend, trendPaint);

    double endX = startX + 15 * step;
    double endY = (screen.bottom - 10 - 30 + math.sin(tPI * 2 + 15) * 12).clamp(screen.top + 5, screen.bottom - 5);
    canvas.drawRect(Rect.fromCenter(center: Offset(endX, endY), width: 5, height: 5), Paint()..color = Colors.white);
  }

  void _drawWallClock(Canvas canvas, double w, double h, double tPI) {
    final Offset center = Offset(w * 0.8, h * 0.25);
    canvas.drawRect(Rect.fromCenter(center: center, width: 24, height: 24), Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawRect(Rect.fromCenter(center: center, width: 24, height: 24), Paint()..color = const Color(0xFF475569)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawLine(center, Offset(center.dx + math.cos(tPI * 0.1) * 4, center.dy + math.sin(tPI * 0.1) * 4), Paint()..color = const Color(0xFF0F172A)..strokeWidth = 2.5); 
    canvas.drawLine(center, Offset(center.dx + math.cos(tPI * 2) * 6, center.dy + math.sin(tPI * 2) * 6), Paint()..color = const Color(0xFFEF4444)..strokeWidth = 1.5); 
  }

  void _drawMarketingWall(Canvas canvas, double w, double h, double tPI) {
    final Rect board = Rect.fromLTWH(w * 0.25, h * 0.16, w * 0.52, h * 0.28);
    canvas.drawRect(board, Paint()..color = const Color(0xFF2E1065));
    canvas.drawRect(board, Paint()..color = const Color(0xFFE879F9)..style=PaintingStyle.stroke..strokeWidth=2.5);
    
    final Path viralPath = Path()
      ..moveTo(board.left + 5, board.bottom - 6)
      ..lineTo(board.left + 15, board.bottom - 16)
      ..lineTo(board.right - 10, board.top + 10);
    canvas.drawPath(viralPath, Paint()..color = const Color(0xFFFB7185)..style=PaintingStyle.stroke..strokeWidth=2.5);

    double heartScale = 1.0 + (math.sin(tPI * 4) * 0.20) + (math.sin(tPI * 8) * 0.08);
    canvas.drawRect(Rect.fromCenter(center: Offset(board.right - 14, board.top + 12), width: 6 * heartScale, height: 6 * heartScale), Paint()..color = const Color(0xFFF43F5E));
  }

  void _drawLogisticsWall(Canvas canvas, double w, double h, double tPI) {
    final Rect mapBoard = Rect.fromLTWH(w * 0.22, h * 0.18, w * 0.56, h * 0.26);
    canvas.drawRect(mapBoard, Paint()..color = const Color(0xFF0369A1));
    canvas.drawRect(mapBoard, Paint()..color = const Color(0xFF7DD3FC)..style=PaintingStyle.stroke..strokeWidth=2.5);

    final Paint routePaint = Paint()..color = Colors.white70..style=PaintingStyle.stroke..strokeWidth=2.0;
    canvas.drawRect(Rect.fromCenter(center: Offset(mapBoard.left + 12, mapBoard.center.dy), width: 6, height: 6), Paint()..color = const Color(0xFFBAE6FD));
    canvas.drawRect(Rect.fromCenter(center: Offset(mapBoard.center.dx, mapBoard.center.dy - 6), width: 6, height: 6), Paint()..color = const Color(0xFFBAE6FD));
    canvas.drawRect(Rect.fromCenter(center: Offset(mapBoard.right - 12, mapBoard.center.dy + 4), width: 6, height: 6), Paint()..color = const Color(0xFFBAE6FD));
    
    double radarRadius = (time * 16) % 12;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(mapBoard.center.dx, mapBoard.center.dy - 6), width: radarRadius * 2, height: radarRadius * 2), 
      Paint()..color = const Color(0xFFFDE047).withValues(alpha: (1.0 - (radarRadius / 12)).clamp(0.0, 1.0))..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );

    Path r1 = Path()..moveTo(mapBoard.left + 12, mapBoard.center.dy)..lineTo(mapBoard.left + 25, mapBoard.top + 8)..lineTo(mapBoard.center.dx, mapBoard.center.dy - 6);
    Path r2 = Path()..moveTo(mapBoard.center.dx, mapBoard.center.dy - 6)..lineTo(mapBoard.right - 25, mapBoard.bottom - 8)..lineTo(mapBoard.right - 12, mapBoard.center.dy + 4);
    canvas.drawPath(r1, routePaint);
    canvas.drawPath(r2, routePaint);

    double progress = (tPI / (math.pi * 2));
    double markerX = mapBoard.left + 12 + (progress * (mapBoard.width - 24));
    canvas.drawRect(Rect.fromCenter(center: Offset(markerX, mapBoard.center.dy - math.sin(progress * math.pi) * 8), width: 5, height: 5), Paint()..color = const Color(0xFFFACC15));
  }

  void _drawShiftWall(Canvas canvas, double w, double h, double tPI) {
    final Rect shiftBoard = Rect.fromLTWH(w * 0.26, h * 0.18, w * 0.48, h * 0.25);
    canvas.drawRect(shiftBoard, Paint()..color = const Color(0xFF27272A));
    canvas.drawRect(shiftBoard, Paint()..color = const Color(0xFFA1A1AA)..style=PaintingStyle.stroke..strokeWidth=2.5);

    for (int i = 0; i < 3; i++) {
      double lineY = shiftBoard.top + 8.0 + (i * 12.0);
      canvas.drawLine(Offset(shiftBoard.left + 6, lineY), Offset(shiftBoard.right - 6, lineY), Paint()..color = const Color(0xFF52525B)..strokeWidth = 2.0);
      canvas.drawRect(Rect.fromLTWH(shiftBoard.left + 8 + (i * 14), lineY - 3, 10, 6), Paint()..color = const Color(0xFFFBBF24));
    }

    final Offset beaconCenter = Offset(w * 0.82, h * 0.25);
    canvas.drawRect(Rect.fromLTWH(beaconCenter.dx - 5, beaconCenter.dy + 2, 10, 4), Paint()..color = const Color(0xFF52525B));
    canvas.drawRect(Rect.fromCenter(center: beaconCenter, width: 12, height: 12), Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.35 + (math.sin(tPI * 4) * 0.35)));
    canvas.drawRect(Rect.fromCenter(center: beaconCenter, width: 6, height: 6), Paint()..color = const Color(0xFFFDE047));
  }

  void _drawWarningLines(Canvas canvas, double w, double h) {
    double stripY = h * 0.88;
    for(int i = 0; i < 12; i++) {
      canvas.drawRect(Rect.fromLTWH(w * 0.05 + (i*15), stripY, 15, 6), Paint()..color = (i%2==0) ? const Color(0xFFF59E0B) : const Color(0xFF1E293B));
    }
  }

  void _drawLogisticsFloorCargo(Canvas canvas, double w, double h) {
    final Rect box1 = Rect.fromLTWH(w * 0.80, h * 0.74, 16, 14);
    canvas.drawRect(box1, Paint()..color = const Color(0xFF92400E));
    canvas.drawRect(Rect.fromLTWH(box1.left, box1.center.dy - 1, 16, 2), Paint()..color = const Color(0xFFD97706));
  }

  void _drawPottedPlant(Canvas canvas, double w, double h, double tPI) {
    final Offset base = Offset(w * 0.86, h * 0.77);
    canvas.drawRect(Rect.fromCenter(center: Offset(base.dx, base.dy + 12), width: 14, height: 4), Paint()..color = Colors.black38);

    final Path potPath = Path()
      ..moveTo(base.dx - 6, base.dy)
      ..lineTo(base.dx + 6, base.dy)
      ..lineTo(base.dx + 4.5, base.dy + 11)
      ..lineTo(base.dx - 4.5, base.dy + 11)
      ..close();
    canvas.drawPath(potPath, Paint()..color = const Color(0xFFEA580C));
    
    final Rect rim = Rect.fromCenter(center: Offset(base.dx, base.dy), width: 14, height: 3.5);
    canvas.drawRect(rim, Paint()..color = const Color(0xFFFB923C));
    canvas.drawRect(Rect.fromCenter(center: Offset(base.dx, base.dy - 0.5), width: 10, height: 2), Paint()..color = const Color(0xFF451A03));

    final double sway = (math.sin(tPI * 1.5) * 1.2) + (math.sin(tPI * 3.0) * 0.4);
    final Paint leafFill = Paint()..color = const Color(0xFF22C55E);
    final Paint leafLight = Paint()..color = const Color(0xFF86EFAC);

    final Path leftLeaf = Path()
      ..moveTo(base.dx, base.dy - 1)
      ..lineTo(base.dx - 12 + sway, base.dy - 14)
      ..lineTo(base.dx - 4 + sway, base.dy - 9)..close();
    canvas.drawPath(leftLeaf, leafFill);

    final Path rightLeaf = Path()
      ..moveTo(base.dx, base.dy - 1)
      ..lineTo(base.dx + 11 + sway, base.dy - 12)
      ..lineTo(base.dx + 4 + sway, base.dy - 8)..close();
    canvas.drawPath(rightLeaf, leafLight);

    final Path centerLeaf = Path()
      ..moveTo(base.dx, base.dy - 1)
      ..lineTo(base.dx + (sway * 0.5), base.dy - 17)
      ..lineTo(base.dx + 3 + (sway * 0.5), base.dy - 10)..close();
    canvas.drawPath(centerLeaf, leafFill);
  }

  void _drawMatteDesk(Canvas canvas, double cx, double cy, {double width = 30, bool dark = false}) {
    final Paint woodTop = Paint()..color = dark ? const Color(0xFF2B2118) : const Color(0xFF9CA3AF); 
    final Paint woodEdge = Paint()..color = dark ? const Color(0xFF1E1510) : const Color(0xFF475569);
    final Paint metalLegs = Paint()..color = dark ? const Color(0xFF171A21) : const Color(0xFF1E293B);

    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: width, height: 4.5), woodTop);
    canvas.drawRect(Rect.fromLTWH(cx - width / 2, cy + 1, width, 1.5), woodEdge);
    
    canvas.drawRect(Rect.fromLTWH(cx - width / 2 + 3, cy + 2.5, 3.5, 20), metalLegs); 
    canvas.drawRect(Rect.fromLTWH(cx + width / 2 - 6.5, cy + 2.5, 3.5, 20), metalLegs); 
  }

  void _drawBgMonitorBack(Canvas canvas, double cx, double cy) {
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 1), width: 7, height: 2.2), Paint()..color = const Color(0xFF1E293B));
    canvas.drawRect(Rect.fromLTWH(cx - 1, cy - 6, 2, 5), Paint()..color = const Color(0xFF475569));

    final Rect monRect = Rect.fromCenter(center: Offset(cx, cy - 9), width: 15, height: 9.5);
    canvas.drawRect(monRect, Paint()..color = const Color(0xFF334155));
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 9), width: 3, height: 3), Paint()..color = const Color(0xFF64748B));
  }

  void _drawStylizedKeyboard(Canvas canvas, double cx, double cy, {double width = 32, double height = 7.5, bool isRgb = false, double tPI = 0.0}) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + 0.8), width: width + 2, height: height + 0.8),
      Paint()..color = Colors.black26,
    );

    final Rect kbRect = Rect.fromCenter(center: Offset(cx, cy), width: width, height: height);
    canvas.drawRect(kbRect, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy - 0.4), width: width - 1.4, height: height - 1.2),
      Paint()..color = const Color(0xFF334155),
    );

    final double keyTopY = cy - (height / 2) + 1.0;
    final double keyWidth = width - 4;
    
    Color keyBaseColor = isRgb 
        ? Color.lerp(const Color(0xFF06B6D4), const Color(0xFFA855F7), (math.sin(tPI * 3) + 1) / 2)!
        : const Color(0xFF64748B);

    for (int i = 0; i < 5; i++) {
      double kx = (cx - keyWidth / 2) + (i * (keyWidth / 5)) + 0.3;
      canvas.drawRect(
        Rect.fromLTWH(kx, keyTopY, (keyWidth / 5) - 0.8, 1.5),
        Paint()..color = keyBaseColor,
      );
    }

    for (int i = 0; i < 4; i++) {
      double kx = (cx - keyWidth / 2) + (i * (keyWidth / 4)) + 0.4;
      canvas.drawRect(
        Rect.fromLTWH(kx, keyTopY + 2.0, (keyWidth / 4) - 1.0, 1.5),
        Paint()..color = keyBaseColor,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(cx - (keyWidth * 0.28), keyTopY + 4.0, keyWidth * 0.56, 1.5),
      Paint()..color = isRgb ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
    );

    final double mouseX = cx + (width / 2) + 5.5;
    final double mouseY = cy + 0.5;
    canvas.drawRect(Rect.fromCenter(center: Offset(mouseX, mouseY + 0.8), width: 5, height: 6.8), Paint()..color = Colors.black26);
    canvas.drawRect(Rect.fromCenter(center: Offset(mouseX, mouseY), width: 5, height: 6.8), Paint()..color = const Color(0xFF1E293B));
    canvas.drawRect(Rect.fromCenter(center: Offset(mouseX, mouseY - 0.4), width: 4, height: 5.8), Paint()..color = const Color(0xFF475569));
  }

  void _drawMonitorBackChassis(Canvas canvas, {
    required double cx,
    required double deskY,
    required double width,
    required double height,
    required String deptId,
    double tPI = 0.0,
    double angle = 0.0,
  }) {
    canvas.save();
    canvas.translate(cx, deskY);
    if (angle != 0.0) {
      canvas.rotate(angle);
    }

    const double screenCenterY = -16.0;

    Color glowColor;
    if (deptId == 'staff_1') {
      glowColor = const Color(0xFF38BDF8);
    } else if (deptId == 'staff_2') glowColor = const Color(0xFFF59E0B);
    else if (deptId == 'staff_3') glowColor = const Color(0xFF10B981);
    else if (deptId == 'staff_5') glowColor = const Color(0xFFEC4899);
    else if (deptId == 'staff_6') glowColor = const Color(0xFF0EA5E9);
    else if (deptId == 'staff_7') glowColor = const Color(0xFFEAB308);
    else glowColor = Color.lerp(const Color(0xFF10B981), const Color(0xFFEF4444), (math.sin(tPI * 2) + 1) / 2)!;

    final double pulseSpread = 6.0 + (math.sin(tPI * 2.5) * 2.0);
    final Rect glowRect = Rect.fromCenter(center: const Offset(0, screenCenterY), width: width + pulseSpread, height: height + pulseSpread);
    canvas.drawRect(
      glowRect,
      Paint()
        ..color = glowColor.withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final Rect basePlate = Rect.fromCenter(center: const Offset(0, -1), width: 16, height: 3.5);
    canvas.drawRect(basePlate.translate(0, 0.8), Paint()..color = Colors.black38);
    canvas.drawRect(basePlate, Paint()..color = const Color(0xFF334155));
    canvas.drawRect(basePlate.deflate(0.5), Paint()..color = const Color(0xFF64748B));

    final Rect standArm = Rect.fromCenter(center: const Offset(0, screenCenterY / 2), width: 4.2, height: -screenCenterY + 2);
    canvas.drawRect(standArm, Paint()..color = const Color(0xFF334155));
    canvas.drawRect(const Rect.fromLTWH(-1.4, screenCenterY, 2.8, -screenCenterY), Paint()..color = const Color(0xFF64748B));

    final Rect monRect = Rect.fromCenter(center: const Offset(0, screenCenterY), width: width, height: height);
    
    canvas.drawRect(monRect.inflate(1.0), Paint()..color = const Color(0xFF0F172A));
    canvas.drawRect(monRect, Paint()..color = const Color(0xFF273244));
    canvas.drawRect(
      Rect.fromLTWH(-width / 2 + 1, screenCenterY - (height / 2) + 1, width - 2, 2),
      Paint()..color = const Color(0xFF475569),
    );

    for (int i = 0; i < 4; i++) {
      double vy = screenCenterY - (height / 2) + 4.0 + (i * 1.6);
      canvas.drawLine(Offset(-width * 0.35, vy), Offset(width * 0.35, vy), Paint()..color = const Color(0xFF1E293B)..strokeWidth = 1.0);
    }

    final Rect vesaPlate = Rect.fromCenter(center: const Offset(0, screenCenterY + 1), width: 8.5, height: 8.5);
    canvas.drawRect(vesaPlate, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, screenCenterY + 1), width: 4, height: 4), Paint()..color = const Color(0xFF475569));
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, screenCenterY - 3.5), width: 2, height: 2), Paint()..color = const Color(0xFF94A3B8));

    if (deptId == 'staff_4' || deptId == 'staff_5') {
      Color ledColor = deptId == 'staff_5' 
          ? const Color(0xFFEC4899) 
          : Color.lerp(const Color(0xFF06B6D4), const Color(0xFFA855F7), (math.sin(tPI * 3) + 1) / 2)!;
      canvas.drawRect(
        Rect.fromCenter(center: const Offset(0, screenCenterY + 5), width: width * 0.65, height: 1.4),
        Paint()..color = ledColor,
      );
    }

    final Path cablePath = Path()
      ..moveTo(2.5, screenCenterY + 3)
      ..lineTo(4.5, screenCenterY / 2)..lineTo(2.0, -1);
    canvas.drawPath(cablePath, Paint()..color = const Color(0xFF1E293B)..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.square);

    canvas.restore();
  }

  void _drawMainAccessories(Canvas canvas, double w, double deskY, double tPI, String deptId, double workerX) {
    final Rect deskMat = Rect.fromCenter(center: Offset(w * 0.55, deskY - 1.5), width: w * 0.52, height: 11);
    canvas.drawRect(deskMat, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRect(deskMat.deflate(0.5), Paint()..color = const Color(0xFF334155));

    bool isRgb = deptId == 'staff_4' || deptId == 'staff_5';
    final double kbX = workerX;
    final double kbY = deskY - 2.5;
    _drawStylizedKeyboard(canvas, kbX, kbY, width: isRgb ? 34 : 30, height: 7.5, isRgb: isRgb, tPI: tPI);

    _drawAccurateTypingArms(canvas, workerX, deskY - 14, kbX, kbY, tPI, isMain: true, deptId: deptId);

    if (deptId != 'staff_4') {
      _drawMonitorBackChassis(
        canvas,
        cx: workerX,
        deskY: deskY,
        width: 38,
        height: 19,
        deptId: deptId,
        tPI: tPI,
      );

      if (deptId == 'staff_1') {
        canvas.drawRect(Rect.fromLTWH(w * 0.28, deskY - 10, 8, 7), Paint()..color = const Color(0xFFF1F5F9));
        canvas.drawRect(Rect.fromLTWH(w * 0.28, deskY - 10, 2, 7), Paint()..color = const Color(0xFF38BDF8));
      } else if (deptId == 'staff_2') {
        canvas.drawRect(Rect.fromLTWH(w * 0.28, deskY - 5, 7, 3), Paint()..color = const Color(0xFFFDE68A));
      } else if (deptId == 'staff_3') {
        canvas.drawRect(Rect.fromLTWH(w * 0.28, deskY - 7, 4.5, 5.5), Paint()..color = const Color(0xFFF8FAFC));
        double steamY = math.sin(tPI * 3) * 1.5;
        final Paint steamPaint = Paint()..color = Colors.white54..style = PaintingStyle.stroke..strokeWidth = 1.0..strokeCap = StrokeCap.square;
        canvas.drawLine(Offset(w * 0.29, deskY - 8 + steamY), Offset(w * 0.295, deskY - 11 + steamY), steamPaint);
        canvas.drawLine(Offset(w * 0.31, deskY - 8 - steamY), Offset(w * 0.305, deskY - 11 - steamY), steamPaint);
      } else if (deptId == 'staff_5') {
        final Offset micBase = Offset(w * 0.29, deskY - 2);
        canvas.drawLine(micBase, Offset(micBase.dx, micBase.dy - 8), Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 2.0);
        canvas.drawRect(Rect.fromCenter(center: Offset(micBase.dx, micBase.dy - 10), width: 4.5, height: 6.5), Paint()..color = const Color(0xFFEC4899));
        double waveR = (time * 12) % 6;
        canvas.drawRect(Rect.fromCenter(center: Offset(micBase.dx, micBase.dy - 10), width: waveR * 2, height: waveR * 2), Paint()..color = const Color(0xFFEC4899).withValues(alpha: (1.0 - (waveR / 6)).clamp(0.0, 1.0))..style = PaintingStyle.stroke..strokeWidth = 1.0);
      } else if (deptId == 'staff_6') {
        final Rect miniBox = Rect.fromLTWH(w * 0.27, deskY - 8, 9, 8);
        canvas.drawRect(miniBox, Paint()..color = const Color(0xFFD97706));
        canvas.drawRect(Rect.fromLTWH(miniBox.left, miniBox.center.dy - 0.5, 9, 1.2), Paint()..color = const Color(0xFFFEF08A));
      } else if (deptId == 'staff_7') {
        final Rect walkie = Rect.fromLTWH(w * 0.28, deskY - 9, 5, 8);
        canvas.drawRect(walkie, Paint()..color = const Color(0xFF27272A));
        canvas.drawLine(Offset(walkie.left + 1.5, walkie.top), Offset(walkie.left + 1.5, walkie.top - 4), Paint()..color = const Color(0xFF71717A)..strokeWidth = 1.5);
        double blinkAlpha = (math.sin(tPI * 6) > 0) ? 1.0 : 0.2;
        canvas.drawRect(Rect.fromCenter(center: Offset(walkie.right - 1.5, walkie.top + 2), width: 1.6, height: 1.6), Paint()..color = const Color(0xFFEF4444).withValues(alpha: blinkAlpha));
      }
    } 
    else {
      _drawMonitorBackChassis(canvas, cx: workerX - 16, deskY: deskY, width: 28, height: 18, deptId: deptId, tPI: tPI, angle: -0.12);
      _drawMonitorBackChassis(canvas, cx: workerX + 16, deskY: deskY, width: 28, height: 18, deptId: deptId, tPI: tPI, angle: 0.12);
    }
  }

  void _drawAccurateTypingArms(Canvas canvas, double workerX, double workerY, double kbX, double kbY, double tPI, {required bool isMain, required String deptId}) {
    final double dynamicSpeed = 8.0 + (incomePerSecond / 50000).clamp(0.0, 12.0);
    final double speedMult = (deptId == 'staff_4' || deptId == 'staff_5') ? dynamicSpeed + 4.0 : dynamicSpeed;
    
    final double leftTap = math.sin(tPI * speedMult) * 1.8;
    final double rightTap = -math.sin((tPI * speedMult) + 1.2) * 1.8;
    final double thumbSpace = (math.sin(tPI * speedMult * 0.25) > 0.6) ? 1.4 : 0.0;
    final double bodyBob = math.sin(tPI) * 1.2;
    const double scale = 0.82;

    final double shoulderY = workerY + bodyBob + (-6.0 * scale);
    final double leftShoulderX = workerX + (-9.5 * scale);
    final double rightShoulderX = workerX + (9.5 * scale);

    Color armColor = isMain ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8);
    if (deptId == 'staff_6') armColor = const Color(0xFF0284C7);
    if (deptId == 'staff_7') armColor = const Color(0xFFD97706);

    final Paint shirtArm = Paint()
      ..color = armColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final Paint skin = Paint()..color = const Color(0xFFFDBA74);

    final double leftElbowX = workerX - 12.0;
    final double leftElbowY = kbY - 5.5;
    final double leftWristX = kbX - 6.5;
    final double leftWristY = kbY - 1.0 + leftTap;

    Path leftArmPath = Path()
      ..moveTo(leftShoulderX, shoulderY)
      ..lineTo(leftElbowX, leftElbowY)
      ..lineTo(leftWristX, leftWristY);
    canvas.drawPath(leftArmPath, shirtArm);
    canvas.drawRect(Rect.fromCenter(center: Offset(leftWristX, leftWristY), width: 4.4, height: 4.4), skin);
    canvas.drawRect(Rect.fromCenter(center: Offset(leftWristX + 1.0, leftWristY + 1.0), width: 2.2, height: 2.2), skin);

    final double rightElbowX = workerX + 12.0;
    final double rightElbowY = kbY - 5.5;
    final double rightWristX = kbX + 6.5;
    final double rightWristY = kbY - 1.0 + rightTap;

    Path rightArmPath = Path()
      ..moveTo(rightShoulderX, shoulderY)
      ..lineTo(rightElbowX, rightElbowY)
      ..lineTo(rightWristX, rightWristY);
    canvas.drawPath(rightArmPath, shirtArm);
    canvas.drawRect(Rect.fromCenter(center: Offset(rightWristX, rightWristY), width: 4.4, height: 4.4), skin);
    canvas.drawRect(Rect.fromCenter(center: Offset(rightWristX - 1.0, rightWristY + 1.0 + thumbSpace), width: 2.2, height: 2.2), skin);
  }

  void _drawMatteWorker(Canvas canvas, double cx, double cy, double tPI, double scale, {required bool isMain, required String deptId}) {
    canvas.save(); 
    canvas.translate(cx, cy); 
    canvas.scale(scale);

    final Paint skin = Paint()..color = const Color(0xFFFDBA74);
    Paint shirt = Paint()..color = isMain ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8); 

    if (deptId == 'staff_6') shirt = Paint()..color = const Color(0xFF0284C7); 
    if (deptId == 'staff_7') shirt = Paint()..color = const Color(0xFFD97706); 

    final double breathBob = math.sin(tPI) * 1.2;
    final double headTilt = math.sin(tPI * 1.5) * 0.04;
    canvas.translate(0, breathBob);
    
    canvas.drawRect(const Rect.fromLTWH(-12, -8, 24, 26), shirt);
    
    if (deptId == 'staff_7') {
      canvas.drawRect(const Rect.fromLTWH(-12, -2, 24, 4), Paint()..color = const Color(0xFFFEF08A));
    }
    
    canvas.drawPath(Path()..moveTo(-4, -8)..lineTo(0, -2)..lineTo(4, -8), Paint()..color = const Color(0xFF0F172A)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    
    canvas.save();
    canvas.rotate(headTilt);
    canvas.drawRect(const Rect.fromLTWH(-8, -26, 16, 16), skin);
    
    double blinkCycle = (tPI * 1.8 + cx) % (math.pi * 2);
    bool isBlinking = blinkCycle > (math.pi * 2 - 0.25);

    if (isBlinking) {
      final Paint eyelidPaint = Paint()..color = const Color(0xFF0F172A)..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeCap = StrokeCap.square;
      canvas.drawLine(const Offset(-4.5, -18.5), const Offset(-1.5, -18.5), eyelidPaint);
      canvas.drawLine(const Offset(1.5, -18.5), const Offset(4.5, -18.5), eyelidPaint);
    } else {
      final Paint eyeWhite = Paint()..color = Colors.white;
      final Paint pupil = Paint()..color = const Color(0xFF0F172A);
      
      canvas.drawRect(const Rect.fromLTWH(-4.5, -20, 3, 4), eyeWhite);
      canvas.drawRect(const Rect.fromLTWH(1.5, -20, 3, 4), eyeWhite);
      canvas.drawRect(const Rect.fromLTWH(-3.7, -19.2, 1.4, 2.4), pupil);
      canvas.drawRect(const Rect.fromLTWH(2.3, -19.2, 1.4, 2.4), pupil);
    }
    
    if (deptId == 'staff_2') {
      canvas.drawRect(const Rect.fromLTWH(-9, -29, 18, 5), Paint()..color = const Color(0xFFF59E0B));
      canvas.drawRect(const Rect.fromLTWH(-10, -24, 20, 2), Paint()..color = const Color(0xFFD97706));
    } else if (deptId == 'staff_5') {
      canvas.drawPath(Path()..moveTo(-9, -18)..lineTo(0, -30)..lineTo(9, -18)..close(), Paint()..color = const Color(0xFF332014));
      canvas.drawRect(const Rect.fromLTWH(-10, -30, 20, 18), Paint()..color = const Color(0xFFEC4899)..style=PaintingStyle.stroke..strokeWidth=2.5);
    } else if (deptId == 'staff_6') {
      canvas.drawRect(const Rect.fromLTWH(-9, -28, 18, 5), Paint()..color = const Color(0xFF0284C7));
      canvas.drawRect(const Rect.fromLTWH(-4, -23, 15, 3.5), Paint()..color = const Color(0xFF0369A1));
    } else {
      canvas.drawPath(Path()..moveTo(-9, -18)..lineTo(0, -30)..lineTo(9, -18)..close(), Paint()..color = const Color(0xFF332014));
    }
    canvas.restore();

    if (!isMain) {
      final Paint bgArm = Paint()..color = shirt.color..style = PaintingStyle.stroke..strokeWidth = 4.0..strokeCap = StrokeCap.square;
      canvas.drawPath(Path()..moveTo(-9, -4)..lineTo(-11, 6)..lineTo(-4, 9), bgArm);
      canvas.drawPath(Path()..moveTo(9, -4)..lineTo(11, 6)..lineTo(4, 9), bgArm);
    }

    canvas.restore();
  }

  @override bool shouldRepaint(covariant MatteOfficePainter oldDelegate) => true;
}

class OfficeHeavyButton extends StatefulWidget {
  final VoidCallback? onPressed; final Widget child; final Color color; final Color shadowColor; final double height; final double? width;
  const OfficeHeavyButton({super.key, required this.onPressed, required this.child, required this.color, required this.shadowColor, this.height = 50, this.width});
  @override State<OfficeHeavyButton> createState() => _OfficeHeavyButtonState();
}

class _OfficeHeavyButtonState extends State<OfficeHeavyButton> {
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