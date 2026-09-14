// lib/widgets/factory_drawings.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FactoryDrawingRenderer {
  static void paint(Canvas canvas, Size size, {required String factoryId, required int stage}) {
    if (factoryId == '3') { 
      _drawAgricultureFactory(canvas, size, stage);
    } else {
      _drawPlaceholder(canvas, size, factoryId);
    }
  }

  static void _drawAgricultureFactory(Canvas canvas, Size size, int stage) {
    // Animasyon rotasyonu (Modulo ile donma koruması)
    final double time = (DateTime.now().millisecondsSinceEpoch % 100000) / 1000.0;
    
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + 10);
    canvas.scale(1.35, 1.35); 
    canvas.translate(-120, -120); // 240x240 İzometrik Çalışma Alanı

    final Paint outline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
      
    Paint fill(Color c) {
      return Paint()
        ..color = c
        ..style = PaintingStyle.fill;
    }

    // ==========================================
    // GELİŞMİŞ EĞİMLİ GÖLGE MOTORU
    // Güneş Doğu-Güneydoğu'dan vuruyor. Gölgeler Kuzeybatı (Sol Üst) yönüne yatarak uzuyor.
    // ==========================================
    void drawCastShadow(Path path, double anchorX, double anchorY) {
      canvas.save();
      canvas.translate(anchorX, anchorY);
      
      Float64List m = Float64List(16);
      m[0] = 1.0;  m[1] = 0.0; m[2] = 0.0; m[3] = 0.0;
      m[4] = 0.65; // Sola yatırır
      m[5] = 0.45; // Yere basık yapar
      m[6] = 0.0;  m[7] = 0.0;
      m[8] = 0.0;  m[9] = 0.0; m[10] = 1.0; m[11] = 0.0;
      m[12] = 0.0; m[13] = 0.0; m[14] = 0.0; m[15] = 1.0;
      
      canvas.transform(m);
      canvas.translate(-anchorX, -anchorY);
      canvas.translate(-8.0, -2.5); 
      canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
      canvas.restore();
    }

    void drawDropShadow(Path path) {
      canvas.save();
      canvas.translate(-8.0, -2.5);
      canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
      canvas.restore();
    }
    
    void drawMiniShadow(double cx, double cy, double w, double h) {
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - 3, cy - 2), width: w, height: h), fill(Colors.black.withValues(alpha: 0.3)));
    }

    // ==========================================
    // 1. 3D ÇEVRE ÇİTİ
    // ==========================================


    void draw3DFence(double x1, double y1, double x2, double y2) {
      double len = math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1));
      int posts = (len / 16).floor(); 
      double dx = (x2-x1)/posts;
      double dy = (y2-y1)/posts;

      canvas.drawLine(Offset(x1, y1 - 3), Offset(x2, y2 - 3), fill(const Color(0xFF8B5A2B))..strokeWidth=2);
      canvas.drawLine(Offset(x1, y1 - 7), Offset(x2, y2 - 7), fill(const Color(0xFF8B5A2B))..strokeWidth=2);
      canvas.drawLine(Offset(x1, y1 - 3), Offset(x2, y2 - 3), outline..strokeWidth=1);
      canvas.drawLine(Offset(x1, y1 - 7), Offset(x2, y2 - 7), outline..strokeWidth=1);

      for(int i = 0; i <= posts; i++) {
        double px = x1 + dx*i;
        double py = y1 + dy*i;
        if (px > 90 && px < 150 && y1 > 200) {
          continue; 
        }

        drawMiniShadow(px, py, 7.5, 3.5); 
        Rect post = Rect.fromLTWH(px-1.5, py-10, 3, 10);
        canvas.drawRect(post, outline..strokeWidth=1);
        canvas.drawRect(post, fill(const Color(0xFF5D4037)));
      }
    }

    draw3DFence(10, 225, 95, 225);  
    draw3DFence(145, 225, 230, 225); 
    draw3DFence(10, 10, 230, 10);    
    draw3DFence(10, 10, 10, 225);    
    draw3DFence(230, 10, 230, 225);  

    // ==========================================
    // 2. KUSURSUZ HİZALANMIŞ TOPRAK PATİKA 
    // ==========================================
    Path dirtPath = Path()
      ..moveTo(45, 80) // Hangar Kapısı Nokta Atışı
      ..lineTo(45, 90)
      ..quadraticBezierTo(45, 105, 60, 105)
      ..lineTo(105, 105)
      ..quadraticBezierTo(120, 105, 120, 115) 
      ..lineTo(120, 230) 
      ..moveTo(120, 105) 
      ..quadraticBezierTo(120, 90, 135, 90)
      ..lineTo(180, 90)
      ..quadraticBezierTo(190, 90, 190, 75) // Değirmen Kapısı Nokta Atışı
      ..moveTo(120, 125) 
      ..lineTo(105, 125)
      ..moveTo(120, 125)
      ..lineTo(135, 125)
      ..moveTo(120, 180) 
      ..lineTo(105, 180)
      ..moveTo(120, 180)
      ..lineTo(135, 180);

    canvas.drawPath(dirtPath, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    canvas.drawPath(dirtPath, Paint()..color = const Color(0xFFD4A373)..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    // ==========================================
    // 3. MİNİK VE YOĞUN EKİN FONKSİYONLARI 
    // ==========================================
    void drawWheat(double cx, double cy) {
      drawMiniShadow(cx, cy, 4, 2);
      canvas.drawRect(Rect.fromLTWH(cx - 1, cy - 3, 2, 3), outline..strokeWidth = 1.0);
      canvas.drawRect(Rect.fromLTWH(cx - 1, cy - 3, 2, 3), fill(const Color(0xFF65A30D))); 
      canvas.drawRect(Rect.fromLTWH(cx - 1.5, cy - 7, 3, 4), outline..strokeWidth = 1.0);
      canvas.drawRect(Rect.fromLTWH(cx - 1.5, cy - 7, 3, 4), fill(AppColors.gold)); 
    }

    void drawCorn(double cx, double cy) {
      drawMiniShadow(cx, cy, 4, 2);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 8), outline..strokeWidth = 1.5);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 8), fill(const Color(0xFF166534))..strokeWidth = 1.0);
      Path leaf = Path()..moveTo(cx, cy - 5)..quadraticBezierTo(cx - 4, cy - 7, cx - 5, cy - 10)..quadraticBezierTo(cx - 2, cy - 8, cx, cy - 6)..close();
      canvas.drawPath(leaf, outline..strokeWidth = 1.0); 
      canvas.drawPath(leaf, fill(const Color(0xFF4ADE80)));
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + 1.5, cy - 6), width: 2, height: 4), outline..strokeWidth = 1.0);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + 1.5, cy - 6), width: 2, height: 4), fill(const Color(0xFFFDE047)));
    }

    void drawCotton(double cx, double cy) {
      drawMiniShadow(cx, cy, 4, 2);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 6), outline..strokeWidth = 1.0);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 6), fill(const Color(0xFF78350F))..strokeWidth = 1.0);
      for (double dx in [-1.5, 1.5, 0.0]) {
        canvas.drawCircle(Offset(cx + dx, cy - 6 - (dx == 0 ? 2 : 0)), 1.5, fill(Colors.white));
      }
    }

    void drawSaffron(double cx, double cy) {
      drawMiniShadow(cx, cy, 4, 2);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 5), fill(const Color(0xFF4ADE80))..strokeWidth = 1.0);
      for(int i = -1; i <= 1; i++) {
        canvas.drawCircle(Offset(cx + i * 1.5, cy - 6 - (i == 0 ? 1.5 : 0)), 1.5, fill(const Color(0xFFA855F7)));
      }
    }

    void drawDrone(double cx, double cy) {
      cy += math.sin(time * 5 + cx) * 3; 
      Rect body = Rect.fromCenter(center: Offset(cx, cy), width: 14, height: 8);
      drawDropShadow(Path()..addRect(body)); 
      canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), outline..strokeWidth = 2);
      canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), fill(Colors.white));
      canvas.drawLine(Offset(cx - 10, cy - 2), Offset(cx + 10, cy - 2), outline..strokeWidth = 2);
      canvas.drawCircle(Offset(cx, cy + 2), 1.5, fill(AppColors.neonCyan));
    }

    // ==========================================
    // 4. TARLALAR VE EKİNLER 
    // ==========================================
    void drawFieldBase(Rect rect) {
      Path fieldPath = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)));
      canvas.drawPath(fieldPath, outline..strokeWidth = 2.0);
      canvas.drawPath(fieldPath, fill(const Color(0xFFB47A4D)));
      for(double r = rect.left + 5; r < rect.right; r += 7) {
        canvas.drawLine(Offset(r, rect.top + 3), Offset(r, rect.bottom - 3), fill(const Color(0xFF8B5A2B))..strokeWidth = 2.5..strokeCap = StrokeCap.round);
      }
    }

    Rect fieldWheat = const Rect.fromLTWH(15, 105, 90, 40); 
    Rect fieldCorn = const Rect.fromLTWH(135, 105, 90, 40);
    Rect fieldCotton = const Rect.fromLTWH(15, 160, 90, 45);
    Rect fieldSaffron = const Rect.fromLTWH(135, 160, 90, 45);

    drawFieldBase(fieldWheat); 
    drawFieldBase(fieldCorn);
    drawFieldBase(fieldCotton); 
    drawFieldBase(fieldSaffron);

    for (double y = 108; y <= 200; y += 6) {
      if (y <= 140) {
        for (double x = 20; x <= 100; x += 6) { drawWheat(x, y); }
        for (double x = 140; x <= 220; x += 7) { drawCorn(x, y); }
      } else if (y >= 163) {
        for (double x = 20; x <= 100; x += 7) { drawCotton(x, y); }
        for (double x = 140; x <= 220; x += 6) { drawSaffron(x, y); }
      }
    }

    // ==========================================
// 5. NİZAMİ 2.5D TOHUM AMBARI (Hangar - Düzeltilmiş Cam ve Çerçeve)
// ==========================================
Path hLeft = Path()
  ..moveTo(20, 75)
  ..lineTo(50, 85)
  ..lineTo(50, 55)
  ..quadraticBezierTo(35, 25, 20, 45)
  ..close();

Path hRight = Path()
  ..moveTo(50, 85)
  ..lineTo(85, 70)
  ..lineTo(85, 40)
  ..lineTo(50, 55)
  ..close();

// 1. Kavisli Çatı
Path hRoof = Path()
  ..moveTo(20, 45)
  ..quadraticBezierTo(35, 25, 50, 55)
  ..lineTo(85, 40)
  ..quadraticBezierTo(70, 20, 55, 30)
  ..close();

Path hangarAll = Path()
  ..addPath(hLeft, Offset.zero)
  ..addPath(hRight, Offset.zero)
  ..addPath(hRoof, Offset.zero);

drawCastShadow(hangarAll, 50, 85); 

// 2. Çatıya Kusursuz Oturan, Sol Alttaki Taşması Giderilmiş Cam Tavan
Path glass = Path()
  ..moveTo(28, 43) // Sol alt taşma yapmaması için içeri çekildi
  ..quadraticBezierTo(38, 28, 48, 51)
  ..lineTo(78, 38) // Sağ üst kenar kısıtlandı
  ..quadraticBezierTo(65, 21, 54, 32)
  ..close();

canvas.drawPath(hLeft, fill(const Color(0xFF7F1D1D))); 
canvas.drawPath(hRight, fill(const Color(0xFFB91C1C))); 
canvas.drawPath(hRoof, fill(const Color(0xFF1E293B))); 
canvas.drawPath(hangarAll, outline..strokeWidth = 2.0);
canvas.drawLine(const Offset(50, 85), const Offset(50, 55), outline..strokeWidth = 1.5); 

// Cam Tavan Çizimi ve Boyaması
canvas.drawPath(glass, fill(const Color(0xFFBAE6FD).withValues(alpha: 0.8)));
canvas.drawPath(glass, outline..strokeWidth = 1.5);

// --- CAM TAVANI DÖRDE BÖLEN METAL ÇERÇEVELER ---
// Yatay Metal Bölücü
canvas.drawLine(
  const Offset(33, 47), 
  const Offset(66, 35), 
  outline..strokeWidth = 1.2
);
// Dikey Metal Bölücü
canvas.drawLine(
  const Offset(38, 38), 
  const Offset(63, 42), 
  outline..strokeWidth = 1.2
);

// İzometrik Çift Kapı
Path door = Path()
  ..moveTo(28, 77.6)
  ..lineTo(42, 82.3)
  ..lineTo(42, 62.3)
  ..lineTo(28, 57.6)
  ..close();

canvas.drawPath(door, outline); 
canvas.drawPath(door, fill(const Color(0xFF78350F)));
canvas.drawLine(const Offset(35, 80), const Offset(35, 60), outline..strokeWidth = 1.5); 
canvas.drawCircle(const Offset(33, 70), 1.0, fill(Colors.black87)); 
canvas.drawCircle(const Offset(37, 71.3), 1.0, fill(Colors.black87));
    // ==========================================
    // 6. TAŞ YEL DEĞİRMENİ (Sağ Üst)
    // ==========================================
    Path millOuter = Path()..moveTo(170, 35)..lineTo(170, 75)..lineTo(210, 75)..lineTo(210, 35)..close();
    Path roofOuter = Path()..moveTo(160, 35)..lineTo(190, 0)..lineTo(220, 35)..close();
    drawCastShadow(Path()..addPath(millOuter, Offset.zero)..addPath(roofOuter, Offset.zero), 190, 75);

    canvas.drawPath(Path()..moveTo(170, 35)..lineTo(170, 75)..lineTo(183, 75)..lineTo(183, 35)..close(), fill(const Color(0xFF57534E))); 
    canvas.drawPath(Path()..moveTo(183, 35)..lineTo(183, 75)..lineTo(197, 75)..lineTo(197, 35)..close(), fill(const Color(0xFF78716C))); 
    canvas.drawPath(Path()..moveTo(197, 35)..lineTo(197, 75)..lineTo(210, 75)..lineTo(210, 35)..close(), fill(const Color(0xFFA8A29E))); 

    canvas.drawPath(millOuter, outline..strokeWidth = 2.0);
    
    // Değirmen İnce Kapı
    Path millDoor = Path()..moveTo(187, 75)..lineTo(187, 60)..quadraticBezierTo(190, 56, 193, 60)..lineTo(193, 75)..close();
    canvas.drawPath(millDoor, outline); 
    canvas.drawPath(millDoor, fill(const Color(0xFF78350F)));
    
    canvas.drawPath(Path()..moveTo(160, 35)..lineTo(190, 0)..lineTo(180, 35)..close(), fill(const Color(0xFF7F1D1D))); 
    canvas.drawPath(Path()..moveTo(180, 35)..lineTo(190, 0)..lineTo(200, 35)..close(), fill(const Color(0xFFB91C1C))); 
    canvas.drawPath(Path()..moveTo(200, 35)..lineTo(190, 0)..lineTo(220, 35)..close(), fill(const Color(0xFFFCA5A5))); 
    canvas.drawPath(roofOuter, outline..strokeWidth = 2.0);

    canvas.drawCircle(const Offset(190, 22), 4, outline);
    canvas.drawCircle(const Offset(190, 22), 4, fill(const Color(0xFFBAE6FD)));

    // Pervane Gölgesi
    canvas.save();
    canvas.clipPath(Path.combine(PathOperation.union, millOuter, roofOuter)); 
    canvas.translate(-4, -1); 
    canvas.translate(190, 38); 
    canvas.rotate(time * 1.5); 
    for(int i = 0; i < 4; i++) {
       canvas.drawRect(const Rect.fromLTWH(-1.5, -30, 3, 30), fill(Colors.black.withValues(alpha: 0.25)));
       canvas.drawRect(const Rect.fromLTWH(1.5, -28, 10, 22), fill(Colors.black.withValues(alpha: 0.25)));
       canvas.rotate(math.pi / 2);
    }
    canvas.restore();

    // Pervane Kendisi
    canvas.save();
    canvas.translate(190, 38); 
    canvas.rotate(time * 1.5); 
    for(int i = 0; i < 4; i++) {
       canvas.drawRect(const Rect.fromLTWH(-1.5, -30, 3, 30), outline..strokeWidth=1.5);
       canvas.drawRect(const Rect.fromLTWH(-1.5, -30, 3, 30), fill(const Color(0xFF78350F)));
       Rect sail = const Rect.fromLTWH(1.5, -28, 10, 22);
       canvas.drawRect(sail, outline..strokeWidth=1.5); 
       canvas.drawRect(sail, fill(Colors.white.withValues(alpha: 0.95)));
       for(double sy = -26; sy < -6; sy += 4.5) {
         canvas.drawLine(Offset(1.5, sy), Offset(11.5, sy), outline..strokeWidth = 1.0);
       }
       canvas.rotate(math.pi / 2);
    }
    canvas.drawCircle(Offset.zero, 4, outline); 
    canvas.drawCircle(Offset.zero, 4, fill(const Color(0xFF475569)));
    canvas.restore();

    // ==========================================
    // 7. ANA GİRİŞ KAPISI
    // ==========================================
    canvas.drawRect(const Rect.fromLTWH(96, 210, 5, 20), outline);
    canvas.drawRect(const Rect.fromLTWH(96, 210, 5, 20), fill(const Color(0xFF5D4037)));
    canvas.drawRect(const Rect.fromLTWH(139, 210, 5, 20), outline);
    canvas.drawRect(const Rect.fromLTWH(139, 210, 5, 20), fill(const Color(0xFF5D4037)));
    
    canvas.drawRect(const Rect.fromLTWH(94, 200, 52, 10), outline);
    canvas.drawRect(const Rect.fromLTWH(94, 200, 52, 10), fill(AppColors.gold));
    canvas.drawLine(const Offset(104, 205), const Offset(136, 205), outline..strokeWidth = 2);

    // ==========================================
    // 8. OTONOM DRONLAR
    // ==========================================
    if (stage >= 1) {
      drawDrone(60, 105); 
    }
    if (stage >= 2) {
      drawDrone(180, 105); 
      drawDrone(60, 160); 
    }

    canvas.restore();
  }

  static void _drawPlaceholder(Canvas canvas, Size size, String id) {
    final Paint outline = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 4.0;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(15, 15, size.width - 30, size.height - 30), const Radius.circular(20)), Paint()..color = const Color(0xFFF1F5F9));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(15, 15, size.width - 30, size.height - 30), const Radius.circular(20)), outline);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'SEKTÖR $id\nÇİZİM BEKLİYOR', 
        style: AppTheme.titleStyle(fontSize: 16).copyWith(color: Colors.black, shadows: [])
      ), 
      textDirection: TextDirection.ltr, 
      textAlign: TextAlign.center
    )..layout();
    
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2));
  }
}