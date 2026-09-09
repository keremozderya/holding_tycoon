// lib/screens/office_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state.dart';
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) {
        return Consumer<GameState>(
          builder: (context, gameState, child) {
            final currentStaff = gameState.officeStaff.firstWhere((s) => s.id == staff.id);
            final bool isMax = currentStaff.isMaxed;
            final bool canAfford = gameState.money >= currentStaff.currentCost && !isMax;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                        child: Icon(isMax ? Icons.workspace_premium_rounded : Icons.badge_rounded, color: AppColors.gold, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currentStaff.title.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.0)),
                            const SizedBox(height: 4),
                            Text('Mevcut Kadro: ${currentStaff.level}/${currentStaff.maxLevel}', style: TextStyle(color: isMax ? AppColors.profit : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(currentStaff.baseDescription, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Mevcut Etki:', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(currentStaff.currentEffectText, style: TextStyle(color: currentStaff.level > 0 ? AppColors.profit : AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (!isMax) ...[
                          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: AppColors.border, height: 1)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Terfi Sonrası:', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(currentStaff.nextEffectText, style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMax ? AppColors.background : (canAfford ? AppColors.gold : AppColors.surfaceElevated),
                        foregroundColor: isMax || !canAfford ? AppColors.textMuted : AppColors.darkBrown,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        side: BorderSide(color: isMax ? AppColors.border : Colors.transparent),
                      ),
                      onPressed: canAfford ? () => gameState.hireStaff(currentStaff.id) : null,
                      child: Text(
                        isMax ? 'MAKSİMUM KAPASİTE' : 'TERFİ VER (\$${_formatNum(currentStaff.currentCost)})',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                      ),
                    ),
                  )
                ],
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

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text('YAZIHANE', style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.textPrimary)),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text('HOLDİNG YÖNETİM MERKEZİ', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      const Text(
                        'Departmanları genişletmek ve personeli terfi ettirmek için ilgili odaya dokunun.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                        child: Text('KASA: \$${_formatNum(gameState.money)}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'SpaceMono')),
                      )
                    ],
                  ),
                ),
              ),
            ),

            // GÖRSEL OFİS ODALARI
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
                      onTap: () => _showHireSheet(context, staff, gameState),
                      child: VisualRoomWidget(staff: staff),
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
  const VisualRoomWidget({super.key, required this.staff});
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
      case 'staff_1': return const Color(0xFF5A728A); // Muhasebe
      case 'staff_2': return const Color(0xFF9E7E5A); // Üretim
      case 'staff_3': return const Color(0xFF5A8A63); // İK
      case 'staff_4': return const Color(0xFF7A5A8A); // Borsa
      default: return Colors.white54;
    }
  }

  IconData _getDepartmentIcon() {
    switch (widget.staff.id) {
      case 'staff_1': return Icons.calculate_rounded;
      case 'staff_2': return Icons.precision_manufacturing_rounded;
      case 'staff_3': return Icons.groups_rounded;
      case 'staff_4': return Icons.candlestick_chart_rounded;
      default: return Icons.business_rounded;
    }
  }

  @override 
  Widget build(BuildContext context) {
    final bool isActive = widget.staff.level > 0;
    final Color deptColor = _getDepartmentColor();
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
                )
              ),
            ),
            
            Positioned(top: 10, left: 10, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: isActive ? AppColors.profit : AppColors.loss, shape: BoxShape.circle))),
            Positioned(
              top: 8, right: 8, 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border)), 
                child: Text('Lvl ${widget.staff.level}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono'))
              )
            ),
            
            Positioned(
              bottom: 0, left: 0, right: 0, 
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8), 
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.95),
                  border: const Border(top: BorderSide(color: AppColors.border))
                ), 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getDepartmentIcon(), color: isActive ? deptColor : AppColors.textMuted, size: 14),
                    const SizedBox(width: 6),
                    Text(widget.staff.title.replaceAll(' Departmanı', '').replaceAll(' Müdürlüğü', '').toUpperCase(), style: TextStyle(color: isActive ? AppColors.textPrimary : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
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

  MatteOfficePainter({
    required this.time, 
    required this.isActive, 
    required this.staffLevel, 
    required this.deptColor, 
    required this.deptId
  });

  @override 
  void paint(Canvas canvas, Size size) {
    final double w = size.width; 
    final double h = size.height;
    final double tPI = time * math.pi * 2; 

    // Katman 1: DUVAR VE ZEMİN (Zemin tam olarak Y = h * 0.65'ten başlar)
    Path leftWall = Path()..moveTo(0, 0)..lineTo(w * 0.15, h * 0.1)..lineTo(w * 0.15, h * 0.65)..lineTo(0, h)..close();
    canvas.drawPath(leftWall, Paint()..color = isActive ? const Color(0xFF1E2128) : const Color(0xFF111216)); 
    
    canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.1, w * 0.85, h * 0.55), Paint()..color = isActive ? const Color(0xFF242731) : const Color(0xFF16181D));
    
    Path floor = Path()..moveTo(0, h)..lineTo(w * 0.15, h * 0.65)..lineTo(w, h * 0.65)..lineTo(w, h)..close();
    canvas.drawPath(floor, Paint()..color = isActive ? const Color(0xFF1A1C23) : const Color(0xFF0D0E12));
    canvas.drawLine(Offset(w * 0.15, h * 0.65), Offset(w, h * 0.65), Paint()..color = const Color(0xFF0F1115)..strokeWidth = 3);

    // Katman 2: DUVAR DEKORASYONLARI
    if (isActive) {
      if (deptId == 'staff_1') {
        _drawSafe(canvas, w, h);
        _drawWallClock(canvas, w, h, tPI);
      } 
      else if (deptId == 'staff_2') {
        _drawBlueprintWall(canvas, w, h);
      } 
      else if (deptId == 'staff_3') {
        _drawHRPosters(canvas, w, h);
      } 
      else if (deptId == 'staff_4') {
        _drawStockTickerWall(canvas, w, h, tPI);
      }

      // Katman 3: ARKA PLAN ASİSTANLARI (Masalar, Karakterler ve Monitörleri)
      int assistants = math.min(4, staffLevel ~/ 10);
      for (int i = 0; i < assistants; i++) {
        double phase = i * 1.5;
        double ax = w * 0.25 + (i * w * 0.15);
        double ay = h * 0.68; // Tam zemin çizgisi üstü
        
        _drawMatteDesk(canvas, ax, ay);
        // Arka plan karakteri (Masanın arkasında dursun diye önce çizilebilir ama izometrikte vücudu masayı örter, sorun yok)
        _drawMatteWorker(canvas, ax + 10, ay - 8, tPI + phase, 0.45, isMain: false, deptId: deptId);
        _drawBgMonitor(canvas, ax, ay, deptColor);
      }

      // Katman 4: ANA MASA
      final double deskY = h * 0.80; // Ön planda (aşağıda)
      _drawMatteDesk(canvas, w * 0.55, deskY, width: w * 0.6, dark: false);
      
      // Katman 5: ANA ŞEF
      _drawMatteWorker(canvas, w * 0.55, deskY - 14, tPI, 0.8, isMain: true, deptId: deptId);

      // Katman 6: MASAÜSTÜ AKSESUARLARI (Karakterin ve masanın ÖNÜNDE)
      _drawMainAccessories(canvas, w, deskY, tPI, deptId);

      // Katman 7: ZEMİN ÖN PLAN DEKORASYONLARI (Saksı, Çizgiler)
      if (deptId == 'staff_3') {
        _drawPottedPlant(canvas, w, h, tPI);
      }
      if (deptId == 'staff_2') {
        _drawWarningLines(canvas, w, h);
      }

    } else {
      // BOŞ ODA
      _drawMatteDesk(canvas, w * 0.55, h * 0.80, width: w * 0.6, dark: true);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black.withValues(alpha: 0.6)); 
    }
  }

  // --- DUVAR ÇİZİMLERİ ---

  void _drawSafe(Canvas canvas, double w, double h) {
    // Çelik Kasa (Tam zemine otursun diye y: h*0.35, height: h*0.30 kullanıldı)
    final Rect safeRect = Rect.fromLTWH(w * 0.18, h * 0.35, w * 0.25, h * 0.30);
    canvas.drawRRect(RRect.fromRectAndRadius(safeRect, const Radius.circular(4)), Paint()..color = const Color(0xFF383E4C));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.20, h * 0.38, w * 0.21, h * 0.24), const Radius.circular(2)), Paint()..color = const Color(0xFF242731));
    canvas.drawCircle(Offset(w * 0.38, h * 0.50), 6, Paint()..color = const Color(0xFF94A3B8));
    canvas.drawRect(Rect.fromLTWH(w * 0.37, h * 0.50, 2, 10), Paint()..color = const Color(0xFFE2E8F0));
  }

  void _drawBlueprintWall(Canvas canvas, double w, double h) {
    final Rect board = Rect.fromLTWH(w * 0.25, h * 0.20, w * 0.5, h * 0.25);
    canvas.drawRect(board, Paint()..color = const Color(0xFF1E3A8A)); 
    canvas.drawRect(board, Paint()..color = const Color(0xFF94A3B8)..style=PaintingStyle.stroke..strokeWidth=2);
    final Paint line = Paint()..color = Colors.white54..style=PaintingStyle.stroke..strokeWidth=1.5;
    canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.25, w * 0.15, h * 0.1), line);
    canvas.drawCircle(Offset(w * 0.6, h * 0.3), 10, line);
    canvas.drawLine(Offset(w * 0.5, h * 0.35), Offset(w * 0.7, h * 0.35), line);
  }

  void _drawHRPosters(Canvas canvas, double w, double h) {
    canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.2, w * 0.15, h * 0.18), Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawRect(Rect.fromLTWH(w * 0.32, h * 0.22, w * 0.11, h * 0.14), Paint()..color = const Color(0xFF94A3B8)..style=PaintingStyle.stroke..strokeWidth=1);
    canvas.drawRect(Rect.fromLTWH(w * 0.55, h * 0.25, w * 0.2, h * 0.12), Paint()..color = const Color(0xFFF1F5F9));
    canvas.drawCircle(Offset(w * 0.65, h * 0.31), 6, Paint()..color = const Color(0xFFC5A059)); 
  }

  void _drawStockTickerWall(Canvas canvas, double w, double h, double tPI) {
    final Rect screen = Rect.fromLTWH(w * 0.2, h * 0.15, w * 0.6, h * 0.28);
    canvas.drawRect(screen, Paint()..color = const Color(0xFF0F1115));
    canvas.drawRect(screen, Paint()..color = const Color(0xFF383E4C)..style=PaintingStyle.stroke..strokeWidth=2);

    final Path trend = Path();
    final Paint trendPaint = Paint()..color = AppColors.profit..style = PaintingStyle.stroke..strokeWidth = 2;
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
    
    for(int i=0; i<4; i++) {
      canvas.drawRect(Rect.fromLTWH(screen.left + 10 + (i*25), screen.top + 10, 15, 4), Paint()..color = i%2==0 ? AppColors.profit : AppColors.loss);
    }
  }

  void _drawWallClock(Canvas canvas, double w, double h, double tPI) {
    final Offset center = Offset(w * 0.8, h * 0.25);
    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFF383E4C)..style = PaintingStyle.stroke..strokeWidth = 2);
    final Paint hand = Paint()..color = Colors.black..strokeWidth = 1.5;
    canvas.drawLine(center, Offset(center.dx + math.cos(tPI) * 5, center.dy + math.sin(tPI) * 5), hand); 
  }

  // --- ZEMİN ÇİZİMLERİ ---

  void _drawWarningLines(Canvas canvas, double w, double h) {
    double stripY = h * 0.88;
    for(int i = 0; i < 12; i++) {
      canvas.drawRect(Rect.fromLTWH(w * 0.05 + (i*15), stripY, 15, 6), Paint()..color = (i%2==0) ? const Color(0xFFD97706) : const Color(0xFF111111));
    }
  }

  void _drawPottedPlant(Canvas canvas, double w, double h, double tPI) {
    final Offset base = Offset(w * 0.85, h * 0.85); // Tam zemine yerleşti
    canvas.drawPath(Path()..moveTo(base.dx - 8, base.dy)..lineTo(base.dx + 8, base.dy)..lineTo(base.dx + 6, base.dy + 12)..lineTo(base.dx - 6, base.dy + 12)..close(), Paint()..color = const Color(0xFF4A3B32));
    final Paint leaf = Paint()..color = const Color(0xFF4CAF50)..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    double sway = math.sin(tPI) * 2;
    canvas.drawPath(Path()..moveTo(base.dx, base.dy - 5)..quadraticBezierTo(base.dx - 10 + sway, base.dy - 10, base.dx - 15 + sway, base.dy - 20), leaf);
    canvas.drawPath(Path()..moveTo(base.dx, base.dy - 5)..quadraticBezierTo(base.dx + 10 + sway, base.dy - 10, base.dx + 15 + sway, base.dy - 15), leaf);
  }

  // --- MASA VE AKSESUARLAR ---

  void _drawMatteDesk(Canvas canvas, double cx, double cy, {double width = 30, bool dark = false}) {
    final Paint wood = Paint()..color = dark ? const Color(0xFF1E1E1E) : const Color(0xFF2D3748); 
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: width, height: 4), wood);
    canvas.drawRect(Rect.fromLTWH(cx - width/2 + 2, cy + 2, 3, 20), Paint()..color = const Color(0xFF111216)); 
    canvas.drawRect(Rect.fromLTWH(cx + width/2 - 5, cy + 2, 3, 20), Paint()..color = const Color(0xFF111216)); 
  }

  void _drawBgMonitor(Canvas canvas, double cx, double cy, Color deptColor) {
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 8), width: 16, height: 10), Paint()..color = const Color(0xFF1A1D24));
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 8), width: 14, height: 8), Paint()..color = deptColor.withValues(alpha: 0.5));
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 2), width: 4, height: 4), Paint()..color = const Color(0xFF475569));
  }

  void _drawMainAccessories(Canvas canvas, double w, double deskY, double tPI, String deptId) {
    // 1. Standart Monitör (Borsa Hariç Herkese)
    if (deptId != 'staff_4') {
      canvas.drawRect(Rect.fromLTWH(w * 0.45, deskY - 18, 4, 18), Paint()..color = const Color(0xFF475569)); // Ayak
      canvas.drawRect(Rect.fromLTWH(w * 0.35, deskY - 45, 26, 28), Paint()..color = const Color(0xFF1A1D24)); // Kasa
      canvas.drawRect(Rect.fromLTWH(w * 0.36, deskY - 44, 24, 26), Paint()..color = const Color(0xFF242731)); // Ekran Paneli
      // Ekrandaki Yazılar
      canvas.drawLine(Offset(w * 0.38, deskY - 35), Offset(w * 0.48, deskY - 35), Paint()..color = Colors.white24..strokeWidth = 2);
      canvas.drawLine(Offset(w * 0.38, deskY - 30), Offset(w * 0.55, deskY - 30), Paint()..color = Colors.white24..strokeWidth = 2);
    }

    // 2. Departmana Özel Eşyalar
    if (deptId == 'staff_1') {
      // Muhasebe Klasörleri
      canvas.drawRect(Rect.fromLTWH(w * 0.30, deskY - 12, 18, 12), Paint()..color = const Color(0xFFE2E8F0));
      canvas.drawLine(Offset(w * 0.30, deskY - 8), Offset(w * 0.48, deskY - 8), Paint()..color = const Color(0xFF94A3B8));
      canvas.drawLine(Offset(w * 0.30, deskY - 4), Offset(w * 0.48, deskY - 4), Paint()..color = const Color(0xFF94A3B8));
    } 
    else if (deptId == 'staff_4') {
      // Borsa Çoklu Monitör Seti
      final Paint frame = Paint()..color = const Color(0xFF1A1D24);
      final Paint screen = Paint()..color = const Color(0xFF242731);
      
      canvas.save(); 
      canvas.translate(w * 0.42, deskY - 20); 
      canvas.rotate(math.pi/8);
      canvas.drawRect(const Rect.fromLTWH(-10, -15, 20, 20), frame); 
      canvas.drawRect(const Rect.fromLTWH(-9, -14, 18, 18), screen);
      canvas.restore();
      
      canvas.drawRect(Rect.fromLTWH(w * 0.52, deskY - 40, 25, 25), frame); 
      canvas.drawRect(Rect.fromLTWH(w * 0.53, deskY - 39, 23, 23), screen);
      
      canvas.save(); 
      canvas.translate(w * 0.72, deskY - 20); 
      canvas.rotate(-math.pi/8);
      canvas.drawRect(const Rect.fromLTWH(-10, -15, 20, 20), frame); 
      canvas.drawRect(const Rect.fromLTWH(-9, -14, 18, 18), screen);
      canvas.restore();
    }
  }

  // --- KARAKTER ÇİZİMİ ---

  void _drawMatteWorker(Canvas canvas, double cx, double cy, double tPI, double scale, {required bool isMain, required String deptId}) {
    canvas.save(); canvas.translate(cx, cy); canvas.scale(scale);

    final Paint skin = Paint()..color = const Color(0xFFD4A373); 
    final Paint shirt = Paint()..color = isMain ? const Color(0xFFF1F5F9) : const Color(0xFF94A3B8); 

    canvas.translate(0, math.sin(tPI) * 1.5);
    
    // YENİ: Gövde biraz uzatıldı, böylece masanın altına giriyormuş hissi netleşti
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -10, 24, 28), const Radius.circular(4)), shirt);
    
    canvas.drawCircle(const Offset(0, -20), 8, skin);
    
    if (deptId == 'staff_2') {
      canvas.drawArc(const Rect.fromLTWH(-9, -29, 18, 18), math.pi, math.pi, true, Paint()..color = const Color(0xFFF59E0B));
      canvas.drawRect(const Rect.fromLTWH(-10, -21, 20, 2), Paint()..color = const Color(0xFFD97706));
    } else {
      canvas.drawPath(Path()..moveTo(-9, -20)..quadraticBezierTo(0, -32, 9, -20)..close(), Paint()..color = const Color(0xFF2C1E16));
    }

    double speedMult = deptId == 'staff_4' ? 12 : 6;
    double typeAnim = math.sin(tPI * speedMult) * 3; 

    // YENİ: Kollar net bir şekilde aşağıya, klavyeye yönlendirildi
    final Paint arm = Paint()..color = shirt.color..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(-10, -5)..lineTo(-16, 8)..lineTo(-6, 15 + typeAnim), arm);
    canvas.drawPath(Path()..moveTo(10, -5)..lineTo(16, 8)..lineTo(6, 15 - typeAnim), arm);

    canvas.restore();
  }

  @override bool shouldRepaint(covariant MatteOfficePainter oldDelegate) => true;
}