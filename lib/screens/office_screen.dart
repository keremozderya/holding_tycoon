// lib/screens/office_screen.dart
import 'dart:math' as math;
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

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final staffList = gameState.officeStaff;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('YAZIHANE', style: AppTheme.titleStyle(fontSize: 18).copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    const Text('HOLDİNG YÖNETİM MERKEZİ', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    const Text('Kadro büyüdükçe tesislerinizin verimliliği ve kapasitesi artar.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 12),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Text('KASA: \$${_formatNum(gameState.money)}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'SpaceMono'))),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisSpacing: 16, childAspectRatio: 1.8),
              delegate: SliverChildBuilderDelegate((context, index) => VisualRoomWidget(staff: staffList[index]), childCount: staffList.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Icon(Icons.badge_rounded, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  const Text('İŞE ALIM / TERFİ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const Expanded(child: Divider(color: AppColors.border, indent: 12)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final staff = staffList[index];
                  final bool isMax = staff.isMaxed;
                  final bool canAfford = gameState.money >= staff.currentCost && !isMax;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Icon(isMax ? Icons.workspace_premium_rounded : Icons.person_add_alt_1_rounded, color: AppColors.textSecondary, size: 24)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(staff.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text('Mevcut Kadro: ${staff.level}/${staff.maxLevel}', style: TextStyle(color: isMax ? AppColors.profit : AppColors.gold, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(staff.baseDescription, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Etki: ${staff.currentEffectText}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                                if (!isMax) ...[const SizedBox(height: 2), Text('Sonraki: ${staff.nextEffectText}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10))],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity, height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: isMax ? AppColors.background : (canAfford ? AppColors.textPrimary : AppColors.surfaceElevated), foregroundColor: isMax || !canAfford ? AppColors.textMuted : AppColors.background, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                              onPressed: canAfford ? () { gameState.hireStaff(staff.id); } : null,
                              child: Text(isMax ? 'KADRO DOLU' : 'TERFİ ET (\$${_formatNum(staff.currentCost)})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
                childCount: staffList.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VisualRoomWidget extends StatefulWidget {
  final OfficeStaff staff;
  const VisualRoomWidget({super.key, required this.staff});
  @override State<VisualRoomWidget> createState() => _VisualRoomWidgetState();
}

class _VisualRoomWidgetState extends State<VisualRoomWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 8000))..repeat();
  }

  @override void dispose() { _animController.dispose(); super.dispose(); }

  // YENİ: Neon olmayan (Muted) Kurumsal Renkler
  Color _getDepartmentColor() {
    switch (widget.staff.id) {
      case 'staff_1': return const Color(0xFF5A728A); // Mat Mavi
      case 'staff_2': return const Color(0xFF9E7E5A); // Mat Bakır
      case 'staff_3': return const Color(0xFF5A8A63); // Mat Yeşil
      case 'staff_4': return const Color(0xFF7A5A8A); // Mat Mürdüm
      default: return Colors.white54;
    }
  }

  @override Widget build(BuildContext context) {
    final bool isActive = widget.staff.level > 0;
    final Color deptColor = _getDepartmentColor();
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) => CustomPaint(size: Size.infinite, painter: MatteOfficePainter(time: _animController.value, isActive: isActive, staffLevel: widget.staff.level, deptColor: deptColor)),
            ),
            Positioned(top: 8, left: 8, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: isActive ? AppColors.profit : AppColors.textMuted, shape: BoxShape.circle))),
            Positioned(top: 6, right: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border)), child: Text('Lvl ${widget.staff.level}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')))),
            Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(vertical: 6), color: AppColors.surface.withValues(alpha: 0.9), child: Center(child: Text(widget.staff.title.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0))))),
          ],
        ),
      ),
    );
  }
}

// YENİ: YAPAY ZEKA GİBİ DURMAYAN GERÇEKÇİ MAT OFİS ÇİZİMİ
class MatteOfficePainter extends CustomPainter {
  final double time; 
  final bool isActive;
  final int staffLevel;
  final Color deptColor;

  MatteOfficePainter({required this.time, required this.isActive, required this.staffLevel, required this.deptColor});

  @override void paint(Canvas canvas, Size size) {
    final double w = size.width; final double h = size.height;
    final double tPI = time * math.pi * 2; 

    // MAT DUVARLAR
    Path leftWall = Path()..moveTo(0, 0)..lineTo(w * 0.15, h * 0.1)..lineTo(w * 0.15, h * 0.65)..lineTo(0, h)..close();
    canvas.drawPath(leftWall, Paint()..color = isActive ? const Color(0xFF1E2128) : const Color(0xFF111216)); // Slate gri
    canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.1, w * 0.85, h * 0.55), Paint()..color = isActive ? const Color(0xFF242731) : const Color(0xFF16181D));
    
    // MAT ZEMİN (Açık gri lamine parke hissi)
    Path floor = Path()..moveTo(0, h)..lineTo(w * 0.15, h * 0.65)..lineTo(w, h * 0.65)..lineTo(w, h)..close();
    canvas.drawPath(floor, Paint()..color = isActive ? const Color(0xFF1A1C23) : const Color(0xFF0D0E12));
    canvas.drawLine(Offset(w * 0.15, h * 0.65), Offset(w, h * 0.65), Paint()..color = const Color(0xFF0F1115)..strokeWidth = 3);

    if (isActive) {
      // 1. GERÇEKÇİ PENCERE (Sarımsı sokak lambaları, mat gökdelenler)
      final Rect winRect = Rect.fromLTWH(w * 0.65, h * 0.15, w * 0.2, h * 0.35);
      canvas.drawRect(winRect, Paint()..color = const Color(0xFF0A0B10)); // Koyu lacivert gece
      canvas.save(); canvas.clipRect(winRect);
      canvas.drawRect(Rect.fromLTWH(winRect.left + 5, winRect.bottom - 40, 20, 40), Paint()..color = const Color(0xFF111218));
      canvas.drawRect(Rect.fromLTWH(winRect.left + 30, winRect.bottom - 60, 25, 60), Paint()..color = const Color(0xFF16181D));
      // Sokak Lambası / Bina Işıkları (Mat sarı, parlamasız)
      final Paint warmLight = Paint()..color = const Color(0xFFFFF176).withValues(alpha: 0.4);
      if (math.sin(tPI * 2) > 0) canvas.drawRect(Rect.fromLTWH(winRect.left + 35, winRect.bottom - 40, 4, 6), warmLight);
      if (math.cos(tPI * 2) > 0) canvas.drawRect(Rect.fromLTWH(winRect.left + 45, winRect.bottom - 50, 4, 6), warmLight);
      canvas.restore();
      canvas.drawRect(winRect, Paint()..color = const Color(0xFF383E4C)..style = PaintingStyle.stroke..strokeWidth = 2);

      // 2. MAT BEYAZ TAHTA
      final Rect boardRect = Rect.fromLTWH(w * 0.25, h * 0.20, w * 0.25, h * 0.25);
      canvas.drawRRect(RRect.fromRectAndRadius(boardRect, const Radius.circular(2)), Paint()..color = const Color(0xFFCFD8DC)); // Mat Beyaz
      canvas.drawRRect(RRect.fromRectAndRadius(boardRect, const Radius.circular(2)), Paint()..color = const Color(0xFF64748B)..style = PaintingStyle.stroke..strokeWidth = 2);
      final Path trend = Path()..moveTo(boardRect.left + 5, boardRect.bottom - 5)..lineTo(boardRect.left + 20, boardRect.bottom - 15)..lineTo(boardRect.right - 5, boardRect.top + 10);
      canvas.drawPath(trend, Paint()..color = const Color(0xFF475569)..style = PaintingStyle.stroke..strokeWidth = 2);

      // 3. SUNUCU (Neon olmayan yeşil-turuncu LED)
      canvas.drawRect(Rect.fromLTWH(w * 0.08, h * 0.3, w * 0.05, h * 0.35), Paint()..color = const Color(0xFF121418));
      Color ledColor = math.sin(tPI * 10) > 0 ? const Color(0xFF388E3C) : const Color(0xFFE65100); // Mat yeşil veya mat turuncu
      canvas.drawRect(Rect.fromLTWH(w * 0.09, h * 0.35, 2, 2), Paint()..color = ledColor);

      // 4. ARKA PLAN MASALARI
      int assistants = math.min(4, staffLevel ~/ 10);
      for (int i = 0; i < assistants; i++) {
        double phase = i * 1.5;
        double ax = w * 0.2 + (i * w * 0.18);
        double ay = h * 0.50;
        _drawMatteDesk(canvas, ax, ay);
        _drawMatteWorker(canvas, ax + 20, ay - 5, tPI + phase, 0.45, isMain: false);
      }

      // 5. ANA MASA VE ŞEF
      final double deskY = h * 0.70;
      _drawMatteDesk(canvas, w * 0.5, deskY, width: w * 0.7, dark: false);
      _drawMatteWorker(canvas, w * 0.5, deskY - 15, tPI, 0.8, isMain: true);

      // Dell Ultrasharp tarzı Profesyonel Monitör
      canvas.drawRect(Rect.fromLTWH(w * 0.48, deskY - 20, 4, 20), Paint()..color = const Color(0xFF475569)); // Alüminyum Ayak
      canvas.drawRect(Rect.fromLTWH(w * 0.35, deskY - 45, 30, 25), Paint()..color = const Color(0xFF1A1D24)); // Ekran Kasası
      canvas.drawRect(Rect.fromLTWH(w * 0.36, deskY - 44, 28, 23), Paint()..color = const Color(0xFF242731)); // Ekran İçi (Parlama yok)
      // Sade ekran çizgileri (Kod)
      canvas.drawLine(Offset(w * 0.38, deskY - 35), Offset(w * 0.45, deskY - 35), Paint()..color = Colors.white24..strokeWidth = 1.5);
      canvas.drawLine(Offset(w * 0.38, deskY - 30), Offset(w * 0.55, deskY - 30), Paint()..color = Colors.white24..strokeWidth = 1.5);

      // Kurumsal Çift Monitör (Sağ Ekran)
      canvas.drawRect(Rect.fromLTWH(w * 0.52, deskY - 45, 30, 25), Paint()..color = const Color(0xFF1A1D24)); 
      canvas.drawRect(Rect.fromLTWH(w * 0.53, deskY - 44, 28, 23), Paint()..color = const Color(0xFF242731)); 

      // Standart Siyah/Gri Klavye (RGB YOK)
      canvas.save();
      canvas.translate(w * 0.5, deskY + 8);
      canvas.drawRect(const Rect.fromLTWH(-15, -4, 30, 8), Paint()..color = const Color(0xFF121418));
      canvas.drawLine(const Offset(-12, 0), const Offset(12, 0), Paint()..color = Colors.white24..strokeWidth = 1); // Basit arka aydınlatma (RGB değil)
      canvas.restore();
    } else {
      _drawMatteDesk(canvas, w * 0.5, h * 0.70, width: w * 0.7, dark: true);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black.withValues(alpha: 0.5)); // Oda boşken karartma
    }
  }

  void _drawMatteDesk(Canvas canvas, double cx, double cy, {double width = 40, bool dark = false}) {
    final Paint wood = Paint()..color = dark ? const Color(0xFF1E1E1E) : const Color(0xFF333333); // Siyah veya Antrasit Ofis Masası
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: width, height: 6), wood);
    canvas.drawRect(Rect.fromLTWH(cx - width/2 + 5, cy + 3, 4, 25), Paint()..color = const Color(0xFF222222)); // Ayak
    canvas.drawRect(Rect.fromLTWH(cx + width/2 - 9, cy + 3, 4, 25), Paint()..color = const Color(0xFF222222)); // Ayak
  }

  void _drawMatteWorker(Canvas canvas, double cx, double cy, double tPI, double scale, {required bool isMain}) {
    canvas.save(); canvas.translate(cx, cy); canvas.scale(scale);

    final Paint skin = Paint()..color = const Color(0xFFD4A373); // Gerçekçi ten
    final Paint shirt = Paint()..color = isMain ? const Color(0xFFF1F5F9) : const Color(0xFF94A3B8); // Şef beyaz gömlekli, diğerleri gri

    // Gövde (Hafif nefes alma)
    canvas.translate(0, math.sin(tPI) * 1.5);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -10, 24, 20), const Radius.circular(4)), shirt);
    
    // Kafa
    canvas.drawCircle(const Offset(0, -20), 8, skin);
    canvas.drawPath(Path()..moveTo(-9, -20)..quadraticBezierTo(0, -32, 9, -20)..close(), Paint()..color = const Color(0xFF2C1E16)); // Saç

    // Gözlük (Gamer kulaklığı yerine kurumsal gözlük)
    if (isMain) {
      canvas.drawRect(const Rect.fromLTWH(-5, -22, 4, 3), Paint()..color = const Color(0xFF111111)..style = PaintingStyle.stroke);
      canvas.drawRect(const Rect.fromLTWH(1, -22, 4, 3), Paint()..color = const Color(0xFF111111)..style = PaintingStyle.stroke);
    }

    // Sakin Yazı Yazma (Kollar klavyeye doğru ince çizgiler)
    double typeAnim = math.sin(tPI * 6) * 3; // Hız düşürüldü
    final Paint arm = Paint()..color = shirt.color..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(-10, -5)..lineTo(-15, 5)..lineTo(-5, 10 + typeAnim), arm);
    canvas.drawPath(Path()..moveTo(10, -5)..lineTo(15, 5)..lineTo(5, 10 - typeAnim), arm);

    canvas.restore();
  }

  @override bool shouldRepaint(covariant MatteOfficePainter oldDelegate) => true;
}