// lib/screens/office_screen.dart
// ignore_for_file: discarded_futures, curly_braces_in_flow_control_structures

import 'dart:math' as math;
import 'package:flutter/material.dart' hide AnimatedContainer, Container, Icon, Text;
import '../widgets/adaptive_widgets.dart';
import 'package:flutter/services.dart'; 
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class WorkerStyle {
  final Color skinColor;
  final Color hairColor;
  final int hairType; 
  final bool hasGlasses;
  final bool hasMustache;
  final bool hasBeard;

  WorkerStyle(this.skinColor, this.hairColor, this.hairType, this.hasGlasses, this.hasMustache, this.hasBeard);
}

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)), 
        side: BorderSide(color: Colors.black, width: 4)
      ),
      builder: (c) {
        return Consumer<GameState>(
          builder: (context, gameState, child) {
            final currentStaff = gameState.officeStaff.firstWhere((s) => s.id == staff.id);
            final bool isMax = currentStaff.isMaxed;
            final staffCost = gameState.staffCost(currentStaff);
            final bool canAfford = gameState.money >= staffCost && !isMax;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 50, height: 8, decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4))),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background, 
                            borderRadius: BorderRadius.circular(16), 
                            border: Border.all(color: Colors.black, width: 3)
                          ),
                          child: Icon(isMax ? Icons.workspace_premium_rounded : Icons.badge_rounded, color: AppColors.gold, size: 36),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(currentStaff.title.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.0))),
                              const SizedBox(height: 4),
                              Text('Mevcut Kadro: ${currentStaff.level}/${currentStaff.maxLevel}', style: TextStyle(color: isMax ? AppColors.profit : AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(currentStaff.baseDescription, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black87, 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: Colors.black, width: 3)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Mevcut Etki:', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w900)),
                              Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(currentStaff.currentEffectText, style: TextStyle(color: currentStaff.level > 0 ? AppColors.profit : AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')))),
                            ],
                          ),
                          if (!isMax) ...[
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white24, height: 1, thickness: 2)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Terfi Sonrası:', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w900)),
                                Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(currentStaff.nextEffectText, style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    OfficeHeavyButton(
                      width: double.infinity, height: 60,
                      color: isMax ? AppColors.background : (canAfford ? AppColors.gold : AppColors.surfaceElevated),
                      shadowColor: Colors.black,
                      onPressed: canAfford ? () {
                        HapticFeedback.lightImpact(); 
                        AudioService.instance.playSfx('cash.mp3');
                        gameState.hireStaff(currentStaff.id);
                      } : null,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isMax ? 'MAKSİMUM KAPASİTE' : 'TERFİ VER (\$${_formatNum(staffCost)})',
                          style: TextStyle(color: isMax || !canAfford ? AppColors.textMuted : AppColors.darkBrown, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
                        ),
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
        title: const Text('YAZIHANE', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Rubik', letterSpacing: 1.0)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
          onPressed: () {
            AudioService.instance.playSfx('click.mp3');
            Navigator.pop(context);
          }
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF38BDF8), Color(0xFF0369A1)], 
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
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black, width: 4.0),
                    boxShadow: const [BoxShadow(color: Colors.black54, offset: Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      const Text('HOLDİNG MERKEZİ', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'Departmanları genişletmek ve personeli terfi ettirmek için odalara dokun!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E), 
                          borderRadius: BorderRadius.circular(16), 
                          border: Border.all(color: Colors.black, width: 3),
                          boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4))]
                        ),
                        child: FittedBox(fit: BoxFit.scaleDown, child: Text('KASA: \$${_formatNum(gameState.money)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
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
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
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
                      child: CartoonRoomWidget(staff: staff, incomePerSecond: incomePerSecond), 
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

class CartoonRoomWidget extends StatefulWidget {
  final OfficeStaff staff;
  final double incomePerSecond; 

  const CartoonRoomWidget({super.key, required this.staff, required this.incomePerSecond});
  @override 
  State<CartoonRoomWidget> createState() => _CartoonRoomWidgetState();
}

class _CartoonRoomWidgetState extends State<CartoonRoomWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override 
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
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
      default: return Colors.white;
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black, 
          width: 4.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive ? deptColor.withValues(alpha: 0.4) : Colors.black54, 
            blurRadius: 0, 
            offset: const Offset(0, 6)
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) => CustomPaint(
                size: Size.infinite, 
                painter: CartoonOfficePainter(
                  time: _animController.value, 
                  isActive: isActive, 
                  staffLevel: widget.staff.level, 
                  deptColor: deptColor,
                  deptId: widget.staff.id,
                  incomePerSecond: widget.incomePerSecond, 
                )
              ),
            ),
            
            Positioned(
              top: 12, left: 12, 
              child: Container(
                width: 16, height: 16, 
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF4ADE80) : const Color(0xFFF87171), 
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2.5)
                )
              )
            ),
            Positioned(
              top: 8, right: 8, 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: Colors.black, width: 2.5)
                ), 
                child: Text(
                  'Lvl ${widget.staff.level}', 
                  style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900)
                )
              )
            ),
            
            Positioned(
              bottom: 0, left: 0, right: 0, 
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), 
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.black, width: 3))
                ), 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getDepartmentIcon(), color: isActive ? deptColor : Colors.grey, size: 20),
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
                          style: TextStyle(color: isActive ? Colors.black : Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0)
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

class CartoonOfficePainter extends CustomPainter {
  final double time; 
  final bool isActive;
  final int staffLevel;
  final Color deptColor;
  final String deptId;
  final double incomePerSecond;

  final Paint blackOutline = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3.0..strokeJoin = StrokeJoin.round;

  CartoonOfficePainter({
    required this.time, 
    required this.isActive, 
    required this.staffLevel, 
    required this.deptColor, 
    required this.deptId,
    required this.incomePerSecond,
  });

  void drawCartoonRRect(Canvas canvas, Rect rect, double radius, Color fill) {
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = fill);
    canvas.drawRRect(rrect, blackOutline);
  }

  void drawCartoonCircle(Canvas canvas, Offset center, double radius, Color fill) {
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawCircle(center, radius, blackOutline);
  }

  WorkerStyle _getWorkerStyle(String dept, int index) {
    Color blackSkin = const Color(0xFF6B4423);
    Color darkSkin = const Color(0xFF4A2E15);
    Color turkishSkin = const Color(0xFFD2996C);
    Color oliveSkin = const Color(0xFFE0AC69);
    Color chineseSkin = const Color(0xFFF1C27D);
    Color paleSkin = const Color(0xFFFFE0BD);
    Color whiteSkin = const Color(0xFFFFDBAC);

    Color blackHair = const Color(0xFF1A1A1A);
    Color brownHair = const Color(0xFF4A3018);
    Color blondeHair = const Color(0xFFE5C07B);
    Color grayHair = const Color(0xFF9CA3AF);

    int hash = (dept.hashCode + index * 17).abs();

    // Özel Müdür Tasarımları
    if (index == 0) {
      if (dept == 'staff_1') return WorkerStyle(turkishSkin, grayHair, 4, true, true, false); // Muhasebeci: Kel, Bıyıklı, Gözlüklü, Türk
      if (dept == 'staff_2') return WorkerStyle(blackSkin, blackHair, 1, false, false, true); // Üretim: Afro, Sakallı, Siyahi
      if (dept == 'staff_3') return WorkerStyle(chineseSkin, blackHair, 5, true, false, false); // İK: Topuzlu, Gözlüklü, Asyalı
      if (dept == 'staff_4') return WorkerStyle(whiteSkin, blondeHair, 0, false, false, false); // Borsa: Kısa Sarı Saç, Beyaz
      if (dept == 'staff_5') return WorkerStyle(oliveSkin, brownHair, 2, false, false, false); // Pazarlama: Uzun Kahverengi Saç
      if (dept == 'staff_6') return WorkerStyle(darkSkin, blackHair, 3, false, true, true); // Lojistik: Sivri Saç, Sakallı
      if (dept == 'staff_7') return WorkerStyle(paleSkin, blackHair, 0, true, false, false); // Vardiya: Kısa Siyah, Gözlüklü
    }

    // Asistanlar İçin Benzersiz Tasarımlar
    List<Color> skins = [blackSkin, darkSkin, turkishSkin, oliveSkin, chineseSkin, paleSkin, whiteSkin];
    List<Color> hairs = [blackHair, brownHair, blondeHair, grayHair];
    int hairType = hash % 6;
    bool glasses = (hash % 4) == 0;
    bool mustache = (hash % 5) == 0 && hairType != 2 && hairType != 5; 
    bool beard = (hash % 7) == 0 && hairType != 2 && hairType != 5;

    return WorkerStyle(
      skins[hash % skins.length],
      hairs[(hash ~/ 3) % hairs.length],
      hairType,
      glasses,
      mustache,
      beard
    );
  }

  @override 
  void paint(Canvas canvas, Size size) {
    final double w = size.width; 
    final double h = size.height;
    final double tPI = time * math.pi * 2; 

    Color backWallColor = isActive ? Color.lerp(deptColor, Colors.white, 0.7)! : const Color(0xFF64748B);
    Color floorColor = isActive ? const Color(0xFFFDE68A) : const Color(0xFF475569);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.65), Paint()..color = backWallColor);
    
    // Pencereler ve Arka Plan Detayları
    if (isActive) {
      double winX = (deptId == 'staff_1' || deptId == 'staff_4') ? w * 0.1 : w * 0.6;
      drawCartoonRRect(canvas, Rect.fromLTWH(winX, h * 0.1, w * 0.3, h * 0.4), 8, const Color(0xFFE0F2FE));
      canvas.drawLine(Offset(winX + w * 0.15, h * 0.1), Offset(winX + w * 0.15, h * 0.5), blackOutline..strokeWidth = 2.5);
      canvas.drawLine(Offset(winX, h * 0.3), Offset(winX + w * 0.3, h * 0.3), blackOutline..strokeWidth = 2.5);
      
      canvas.drawCircle(Offset(winX + w * 0.1, h * 0.2), 8, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(winX + w * 0.15, h * 0.2), 12, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(winX + w * 0.2, h * 0.22), 8, Paint()..color = Colors.white);
    }

    final Path floorPath = Path()..moveTo(0, h * 0.65)..lineTo(w, h * 0.65)..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(floorPath, Paint()..color = floorColor);
    canvas.drawLine(Offset(0, h * 0.65), Offset(w, h * 0.65), blackOutline..strokeWidth = 3.0);

    if (isActive) {
      canvas.drawRect(Rect.fromLTWH(0, h * 0.65, w, 12), Paint()..color = const Color(0xFFFBBF24));
      canvas.drawLine(Offset(0, h * 0.65 + 12), Offset(w, h * 0.65 + 12), blackOutline);
    }

    if (isActive) {
      if (deptId == 'staff_1') {
        _drawCartoonSafe(canvas, w, h, tPI);
        _drawCartoonClock(canvas, w, h, tPI);
      } 
      else if (deptId == 'staff_2') {
        _drawCartoonBlueprint(canvas, w, h, tPI);
      } 
      else if (deptId == 'staff_3') {
        _drawCartoonHRPosters(canvas, w, h);
      } 
      else if (deptId == 'staff_4') {
        _drawCartoonStockScreen(canvas, w, h, tPI);
      }
      else if (deptId == 'staff_5') {
        _drawCartoonMarketingBoard(canvas, w, h, tPI);
      }
      else if (deptId == 'staff_6') {
        _drawCartoonMap(canvas, w, h, tPI);
      }
      else if (deptId == 'staff_7') {
        _drawCartoonShiftBoard(canvas, w, h, tPI);
      }

      int assistants = math.min(4, staffLevel ~/ 10);
      for (int i = 0; i < assistants; i++) {
        double phase = i * 1.5;
        double ax = w * 0.2 + (i * w * 0.18);
        double ay = h * 0.58;
        
        _drawCartoonWorker(canvas, ax, ay, tPI + phase, 0.45, isMain: false, deptId: deptId, index: i + 1);
        _drawCartoonDesk(canvas, ax, ay + 20, width: 35, isAssist: true);
      }

      final double deskY = h * 0.85;
      final double workerX = w * 0.5;
      
      _drawCartoonChair(canvas, workerX, deskY - 15, tPI);
      _drawCartoonWorker(canvas, workerX, deskY - 15, tPI, 1.0, isMain: true, deptId: deptId, index: 0);
      _drawCartoonDesk(canvas, workerX, deskY, width: w * 0.75);
      _drawCartoonAccessories(canvas, workerX, deskY, tPI, deptId);

      if (deptId == 'staff_3') {
        _drawCartoonPlant(canvas, w, h, tPI);
      }

    } else {
      _drawCartoonDesk(canvas, w * 0.5, h * 0.85, width: w * 0.6, isDark: true);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black54); 
    }
  }

  void _drawCartoonDesk(Canvas canvas, double cx, double cy, {double width = 60, bool isDark = false, bool isAssist = false}) {
    Color topColor = isDark ? const Color(0xFF64748B) : const Color(0xFF93C5FD);
    Color legColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    // Zemin Gölgesi
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 30), width: width * 1.2, height: 15), Paint()..color = Colors.black26);

    final Path leg1 = Path()..moveTo(cx - width * 0.4, cy)..lineTo(cx - width * 0.45, cy + 30)..lineTo(cx - width * 0.35, cy + 30)..close();
    final Path leg2 = Path()..moveTo(cx + width * 0.4, cy)..lineTo(cx + width * 0.35, cy + 30)..lineTo(cx + width * 0.45, cy + 30)..close();
    
    canvas.drawPath(leg1, Paint()..color = legColor);
    canvas.drawPath(leg1, blackOutline);
    canvas.drawPath(leg2, Paint()..color = legColor);
    canvas.drawPath(leg2, blackOutline);

    drawCartoonRRect(canvas, Rect.fromCenter(center: Offset(cx, cy), width: width, height: 16), 8, topColor);

    if (!isDark && !isAssist) {
      drawCartoonRRect(canvas, Rect.fromLTWH(cx - width * 0.3, cy + 2, width * 0.3, 10), 2, Colors.white);
      drawCartoonRRect(canvas, Rect.fromLTWH(cx + width * 0.25, cy - 8, 10, 12), 2, Colors.white);
    } else if (!isDark && isAssist) {
      drawCartoonRRect(canvas, Rect.fromCenter(center: Offset(cx, cy - 5), width: 14, height: 10), 2, const Color(0xFF94A3B8));
    }
  }

  void _drawCartoonChair(Canvas canvas, double cx, double cy, double tPI) {
    double sway = math.sin(tPI * 1.5) * 2; 
    drawCartoonRRect(canvas, Rect.fromCenter(center: Offset(cx + sway, cy), width: 36, height: 40), 12, const Color(0xFFEF4444));
    drawCartoonRRect(canvas, Rect.fromCenter(center: Offset(cx + sway, cy - 25), width: 24, height: 16), 8, const Color(0xFFB91C1C));
  }

  void _drawCartoonPlant(Canvas canvas, double w, double h, double tPI) {
    double px = w * 0.85;
    double py = h * 0.8;
    
    drawCartoonRRect(canvas, Rect.fromCenter(center: Offset(px, py), width: 24, height: 28), 6, const Color(0xFFF97316));
    drawCartoonRRect(canvas, Rect.fromCenter(center: Offset(px, py - 14), width: 30, height: 8), 4, const Color(0xFFEA580C));

    double bounce = math.sin(tPI * 2) * 2;
    final Path leaf = Path()
      ..moveTo(px, py - 14)
      ..quadraticBezierTo(px - 30 + bounce, py - 40, px - 10 + bounce, py - 60)
      ..quadraticBezierTo(px, py - 30, px, py - 14);
    
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF22C55E));
    canvas.drawPath(leaf, blackOutline);

    final Path leaf2 = Path()
      ..moveTo(px, py - 14)
      ..quadraticBezierTo(px + 30 - bounce, py - 30, px + 15 - bounce, py - 50)
      ..quadraticBezierTo(px + 5, py - 20, px, py - 14);
      
    canvas.drawPath(leaf2, Paint()..color = const Color(0xFF4ADE80));
    canvas.drawPath(leaf2, blackOutline);
  }

  void _drawCartoonSafe(Canvas canvas, double w, double h, double tPI) {
    canvas.save();
    canvas.translate(w * 0.8, h * 0.4);
    
    drawCartoonRRect(canvas, const Rect.fromLTWH(-20, -20, 40, 40), 8, const Color(0xFF94A3B8));
    drawCartoonCircle(canvas, const Offset(0, 0), 12, const Color(0xFFCBD5E1));
    canvas.drawLine(const Offset(0, 0), const Offset(8, 0), blackOutline);
    
    canvas.restore();
  }

  void _drawCartoonClock(Canvas canvas, double w, double h, double tPI) {
    double cx = w * 0.5;
    double cy = h * 0.2;
    drawCartoonCircle(canvas, Offset(cx, cy), 18, Colors.white);
    
    double secAngle = tPI * 4;
    canvas.drawLine(Offset(cx, cy), Offset(cx + math.cos(secAngle) * 12, cy + math.sin(secAngle) * 12), Paint()..color = Colors.red..strokeWidth = 3..strokeCap = StrokeCap.round);
  }

  void _drawCartoonBlueprint(Canvas canvas, double w, double h, double tPI) {
    drawCartoonRRect(canvas, Rect.fromLTWH(w * 0.2, h * 0.15, w * 0.6, h * 0.25), 4, const Color(0xFF3B82F6));
    
    canvas.save();
    canvas.translate(w * 0.5, h * 0.27);
    canvas.rotate(tPI * 0.5);
    drawCartoonCircle(canvas, const Offset(0,0), 12, Colors.white);
    for(int i=0; i<4; i++){
      canvas.rotate(math.pi/2);
      drawCartoonRRect(canvas, const Rect.fromLTWH(-4, -18, 8, 8), 2, Colors.white);
    }
    canvas.restore();
  }

  void _drawCartoonHRPosters(Canvas canvas, double w, double h) {
    drawCartoonRRect(canvas, Rect.fromLTWH(w * 0.25, h * 0.15, 30, 40), 4, Colors.white);
    drawCartoonCircle(canvas, Offset(w * 0.25 + 15, h * 0.15 + 15), 8, const Color(0xFFFBBF24));
    
    drawCartoonRRect(canvas, Rect.fromLTWH(w * 0.6, h * 0.2, 25, 30), 2, const Color(0xFF6EE7B7));
  }

  void _drawCartoonStockScreen(Canvas canvas, double w, double h, double tPI) {
    Rect screen = Rect.fromLTWH(w * 0.55, h * 0.12, w * 0.35, h * 0.3);
    drawCartoonRRect(canvas, screen, 12, const Color(0xFF1E293B));

    Path line = Path()..moveTo(screen.left + 5, screen.bottom - 10);
    for (int i = 1; i <= 3; i++) {
      double px = screen.left + 5 + (screen.width * 0.3 * i);
      double py = screen.bottom - 10 - (i * 15) + (math.sin(tPI * 2 + i) * 10);
      line.lineTo(px, py);
    }
    canvas.drawPath(line, Paint()..color = const Color(0xFF22C55E)..style = PaintingStyle.stroke..strokeWidth = 4..strokeJoin = StrokeJoin.round);
  }

  void _drawCartoonMarketingBoard(Canvas canvas, double w, double h, double tPI) {
    drawCartoonRRect(canvas, Rect.fromLTWH(w * 0.2, h * 0.15, w * 0.6, h * 0.25), 8, const Color(0xFFF472B6));
    
    double heartScale = 1.0 + math.sin(tPI * 3) * 0.15;
    canvas.save();
    canvas.translate(w * 0.5, h * 0.27);
    canvas.scale(heartScale);
    drawCartoonCircle(canvas, const Offset(-8, -4), 10, const Color(0xFFE11D48));
    drawCartoonCircle(canvas, const Offset(8, -4), 10, const Color(0xFFE11D48));
    Path tri = Path()..moveTo(-16, 2)..lineTo(16, 2)..lineTo(0, 18)..close();
    canvas.drawPath(tri, Paint()..color = const Color(0xFFE11D48));
    canvas.drawPath(tri, blackOutline);
    canvas.restore();
  }

  void _drawCartoonMap(Canvas canvas, double w, double h, double tPI) {
    drawCartoonRRect(canvas, Rect.fromLTWH(w * 0.2, h * 0.15, w * 0.6, h * 0.25), 12, const Color(0xFF7DD3FC));
    
    double rx = w * 0.5;
    double ry = h * 0.27;
    double rad = (time * 15) % 25;
    canvas.drawCircle(Offset(rx, ry), rad, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
    drawCartoonCircle(canvas, Offset(rx, ry), 6, const Color(0xFFEF4444));
  }

  void _drawCartoonShiftBoard(Canvas canvas, double w, double h, double tPI) {
    drawCartoonRRect(canvas, Rect.fromLTWH(w * 0.2, h * 0.15, w * 0.6, h * 0.25), 8, const Color(0xFFFEF08A));
    
    for (int i=0; i<3; i++){
      drawCartoonRRect(canvas, Rect.fromLTWH(w * 0.25, h * 0.18 + (i * 12), w * 0.4, 6), 3, Colors.white);
    }
  }

  void _drawCartoonAccessories(Canvas canvas, double cx, double cy, double tPI, String deptId) {
    // Bilgisayar Monitörü Standı
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 12), width: 12, height: 16), Paint()..color = const Color(0xFF475569));
    
    // Bilgisayar Ekranı
    drawCartoonRRect(canvas, Rect.fromCenter(center: Offset(cx, cy - 25), width: 56, height: 36), 4, const Color(0xFF1E293B)); 
    drawCartoonRRect(canvas, Rect.fromCenter(center: Offset(cx, cy - 26), width: 48, height: 26), 2, const Color(0xFF38BDF8)); 
    
    // Klavye
    Path kb = Path()..moveTo(cx - 20, cy + 2)..lineTo(cx + 20, cy + 2)..lineTo(cx + 24, cy + 10)..lineTo(cx - 24, cy + 10)..close();
    canvas.drawPath(kb, Paint()..color = const Color(0xFF94A3B8));
    canvas.drawPath(kb, blackOutline..strokeWidth = 2);

    // Kupa Kahve
    drawCartoonRRect(canvas, Rect.fromCenter(center: Offset(cx - 35, cy - 6), width: 14, height: 16), 2, const Color(0xFFF97316)); 
    canvas.drawArc(Rect.fromLTWH(cx - 42, cy - 10, 8, 8), math.pi/2, math.pi, false, blackOutline..strokeWidth=2);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 35, cy - 14), width: 14, height: 4), Paint()..color = const Color(0xFF451A03));

    // Evraklar / Klasör
    drawCartoonRRect(canvas, Rect.fromCenter(center: Offset(cx + 35, cy - 2), width: 18, height: 24), 2, Colors.white);
    canvas.drawLine(Offset(cx + 30, cy - 8), Offset(cx + 40, cy - 8), Paint()..color = Colors.blueGrey..strokeWidth=2);
    canvas.drawLine(Offset(cx + 30, cy - 4), Offset(cx + 40, cy - 4), Paint()..color = Colors.blueGrey..strokeWidth=2);
  }

  void _drawCartoonWorker(Canvas canvas, double cx, double cy, double tPI, double scale, {required bool isMain, required String deptId, required int index}) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    double speedMult = isMain ? 2.0 + (incomePerSecond / 100000).clamp(0.0, 1.5) : 1.2;
    double bounce = math.sin(tPI * speedMult * 0.5) * 1.5;
    canvas.translate(0, bounce);

    WorkerStyle style = _getWorkerStyle(deptId, index);

    Color shirt = isMain ? const Color(0xFFE2E8F0) : const Color(0xFF94A3B8);
    if (deptId == 'staff_6') shirt = const Color(0xFF38BDF8);
    if (deptId == 'staff_7') shirt = const Color(0xFFFACC15);

    // Boyun
    drawCartoonRRect(canvas, const Rect.fromLTWH(-5, -20, 10, 15), 2, style.skinColor);

    // Gövde
    drawCartoonRRect(canvas, const Rect.fromLTWH(-22, -10, 44, 32), 12, shirt);

    // Yaka ve Kravat
    if (isMain || deptId == 'staff_1' || deptId == 'staff_4') {
      canvas.drawPath(Path()..moveTo(-10, -10)..lineTo(0, 0)..lineTo(10, -10), blackOutline..strokeWidth=2);
      Path tie = Path()..moveTo(-3, -6)..lineTo(3, -6)..lineTo(4, 12)..lineTo(0, 16)..lineTo(-4, 12)..close();
      canvas.drawPath(tie, Paint()..color = const Color(0xFFDC2626));
      canvas.drawPath(tie, blackOutline..strokeWidth=1.5);
    }

    // Kollar
    if (isMain) {
      double lArmRot = math.sin(tPI * speedMult) * 0.25;
      double rArmRot = math.sin(tPI * speedMult + math.pi) * 0.25;
      
      final Paint armPaint = Paint()..color = style.skinColor..style = PaintingStyle.stroke..strokeWidth = 9..strokeCap = StrokeCap.round;
      final Paint armSleeve = Paint()..color = shirt..style = PaintingStyle.stroke..strokeWidth = 11..strokeCap = StrokeCap.round;
      final Paint armOutline = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 15..strokeCap = StrokeCap.round;

      canvas.save();
      canvas.translate(-20, -2);
      canvas.rotate(lArmRot);
      canvas.drawLine(Offset.zero, const Offset(-10, 20), armOutline);
      canvas.drawLine(Offset.zero, const Offset(-10, 20), armPaint);
      canvas.drawLine(Offset.zero, const Offset(-6, 12), armSleeve);
      canvas.restore();

      canvas.save();
      canvas.translate(20, -2);
      canvas.rotate(rArmRot);
      canvas.drawLine(Offset.zero, const Offset(10, 20), armOutline);
      canvas.drawLine(Offset.zero, const Offset(10, 20), armPaint);
      canvas.drawLine(Offset.zero, const Offset(6, 12), armSleeve);
      canvas.restore();
    } else {
      drawCartoonRRect(canvas, const Rect.fromLTWH(-28, -5, 10, 20), 5, shirt);
      drawCartoonRRect(canvas, const Rect.fromLTWH(18, -5, 10, 20), 5, shirt);
    }

    // Kafa
    drawCartoonCircle(canvas, const Offset(0, -38), 24, style.skinColor);

    // Gözler (Kırpma animasyonu dahil)
    double eyeS = 1.0 + math.sin(tPI * 2) * 0.1;
    canvas.save();
    canvas.translate(0, -40);
    canvas.scale(1.0, eyeS);
    drawCartoonCircle(canvas, const Offset(-8, 0), 6, Colors.white);
    drawCartoonCircle(canvas, const Offset(8, 0), 6, Colors.white);
    canvas.drawCircle(const Offset(-8, 0), 2.5, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(8, 0), 2.5, Paint()..color = Colors.black);
    canvas.restore();

    // Burun
    canvas.drawArc(const Rect.fromLTWH(-3, -35, 6, 6), 0, math.pi, false, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth=2);

    // Ağız
    canvas.drawArc(const Rect.fromLTWH(-5, -28, 10, 6), 0, math.pi, false, blackOutline..strokeWidth=2);

    // Bıyık
    if (style.hasMustache) {
      Path mustache = Path()..moveTo(-10, -28)..quadraticBezierTo(0, -32, 10, -28)..quadraticBezierTo(0, -24, -10, -28)..close();
      canvas.drawPath(mustache, Paint()..color = style.hairColor);
      canvas.drawPath(mustache, blackOutline..strokeWidth=1.5);
    }

    // Sakal
    if (style.hasBeard) {
      Path beard = Path()..moveTo(-22, -35)..quadraticBezierTo(-25, -15, 0, -12)..quadraticBezierTo(25, -15, 22, -35)
        ..quadraticBezierTo(18, -25, 12, -25)..quadraticBezierTo(0, -18, -12, -25)..close();
      canvas.drawPath(beard, Paint()..color = style.hairColor);
      canvas.drawPath(beard, blackOutline..strokeWidth=1.5);
    }

    // Gözlük
    if (style.hasGlasses) {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -46, 14, 12), const Radius.circular(3)), Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2.5);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, -46, 14, 12), const Radius.circular(3)), Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2.5);
      canvas.drawLine(const Offset(-2, -40), const Offset(2, -40), Paint()..color = Colors.black..strokeWidth = 2.5);
    }

    // Saçlar
    final Paint hairPaint = Paint()..color = style.hairColor;
    if (style.hairType == 0) { 
      Path hair = Path()..moveTo(-24, -38)..arcTo(const Rect.fromLTWH(-24, -62, 48, 45), math.pi, math.pi, false)..close();
      canvas.drawPath(hair, hairPaint);
      canvas.drawPath(hair, blackOutline);
    } else if (style.hairType == 1) { 
      canvas.drawCircle(const Offset(-15, -52), 14, hairPaint);
      canvas.drawCircle(const Offset(0, -60), 16, hairPaint);
      canvas.drawCircle(const Offset(15, -52), 14, hairPaint);
      canvas.drawCircle(const Offset(-15, -52), 14, blackOutline..strokeWidth=2);
      canvas.drawCircle(const Offset(0, -60), 16, blackOutline..strokeWidth=2);
      canvas.drawCircle(const Offset(15, -52), 14, blackOutline..strokeWidth=2);
    } else if (style.hairType == 2) { 
      Path hair = Path()..moveTo(-24, -38)..arcTo(const Rect.fromLTWH(-25, -60, 50, 50), math.pi, math.pi, false)
        ..lineTo(28, -15)..lineTo(15, -15)..lineTo(15, -35)..lineTo(-15, -35)..lineTo(-15, -15)..lineTo(-28, -15)..close();
      canvas.drawPath(hair, hairPaint);
      canvas.drawPath(hair, blackOutline);
    } else if (style.hairType == 3) { 
      Path hair = Path()..moveTo(-22, -45)..lineTo(-15, -65)..lineTo(-5, -50)..lineTo(5, -68)..lineTo(15, -50)..lineTo(22, -65)..lineTo(22, -45)..close();
      canvas.drawPath(hair, hairPaint);
      canvas.drawPath(hair, blackOutline);
    } else if (style.hairType == 4) { 
      Path hair = Path()..moveTo(-24, -35)..quadraticBezierTo(-26, -45, -20, -50)..lineTo(-20, -35)..close();
      canvas.drawPath(hair, hairPaint);
      Path hair2 = Path()..moveTo(24, -35)..quadraticBezierTo(26, -45, 20, -50)..lineTo(20, -35)..close();
      canvas.drawPath(hair2, hairPaint);
    } else if (style.hairType == 5) { 
      Path hair = Path()..moveTo(-24, -38)..arcTo(const Rect.fromLTWH(-24, -62, 48, 45), math.pi, math.pi, false)..close();
      canvas.drawPath(hair, hairPaint);
      canvas.drawPath(hair, blackOutline);
      canvas.drawCircle(const Offset(18, -55), 10, hairPaint);
      canvas.drawCircle(const Offset(18, -55), 10, blackOutline..strokeWidth=2);
    }

    canvas.restore();
  }

  @override bool shouldRepaint(covariant CartoonOfficePainter oldDelegate) => true;
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
          Positioned(bottom: 0, left: 0, right: 0, top: 8, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey : widget.shadowColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)))),
          AnimatedPositioned(duration: const Duration(milliseconds: 60), bottom: _isPressed || isDisabled ? 0 : 8, left: 0, right: 0, top: _isPressed || isDisabled ? 8 : 0, child: Container(decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade300 : widget.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)), child: Center(child: widget.child))),
        ]),
      ),
    );
  }
}
