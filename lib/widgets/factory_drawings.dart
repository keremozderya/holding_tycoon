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
    
    // --- TÜM TESİSİ SOL ÜSTE KAYDIRMA ---
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
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - 2, cy - 1), width: w, height: h), fill(Colors.black.withValues(alpha: 0.3)));
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

        drawMiniShadow(px, py, 5, 2); 
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
    // 2. KUSURSUZ HİZALANMIŞ AŞAMALI PATİKA
    // ==========================================
    Path dirtPath = Path();
    
    // TEMEL AŞAMA (Aşama 0): Çıkış kapısı, Değirmen ve Buğday Tarlası Yolları
    dirtPath.moveTo(120, 230);
    dirtPath.lineTo(120, 105); // Ana dikey omurga
    
    dirtPath.moveTo(120, 105);
    dirtPath.quadraticBezierTo(120, 90, 135, 90);
    dirtPath.lineTo(180, 90);
    dirtPath.quadraticBezierTo(190, 90, 190, 75); // Değirmen Yolu
    
    dirtPath.moveTo(120, 125);
    dirtPath.lineTo(105, 125); // Buğday Tarlası Yolu
    
    if (stage >= 1) {
      // Ambar Yolu
      dirtPath.moveTo(66, 80);
      dirtPath.lineTo(60, 65);
      dirtPath.quadraticBezierTo(60, 55, 60, 75);
      dirtPath.lineTo(105, 105);
      dirtPath.quadraticBezierTo(120, 105, 120, 115);
      
      // Mısır Tarlası Yolu
      dirtPath.moveTo(120, 125);
      dirtPath.lineTo(135, 125);
    }
    
    if (stage >= 2) {
      // Pamuk Tarlası Yolu
      dirtPath.moveTo(120, 125);
      dirtPath.lineTo(120, 180); // Dikey yol uzatması
      dirtPath.moveTo(120, 180);
      dirtPath.lineTo(105, 180);
    }
    
    if (stage >= 3) {
      // Safran Tarlası Yolu
      dirtPath.moveTo(120, 180);
      dirtPath.lineTo(135, 180);
    }
    
    if (stage >= 4) {
      // Sera Yolu
      dirtPath.moveTo(125, 90);
      dirtPath.lineTo(125, 75);
    }

    // Seviye 45'ten itibaren toprak patika taş(kaldırım) yol rengini alır
    Color pathColor = stage >= 45 ? const Color(0xFF9CA3AF) : const Color(0xFFD4A373);

    canvas.drawPath(dirtPath, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    canvas.drawPath(dirtPath, Paint()..color = pathColor..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    // ==========================================
    // 3. BÜYÜTÜLMÜŞ VE SIKLIĞI AZALTILMIŞ EKİN FONKSİYONLARI 
    // ==========================================
    final Paint cropOutline = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 0.6;

    void drawWheat(double cx, double cy) {
      drawMiniShadow(cx, cy, 3.1, 1.9);
      canvas.drawRect(Rect.fromLTWH(cx - 0.6, cy - 2.5, 1.2, 2.5), cropOutline);
      canvas.drawRect(Rect.fromLTWH(cx - 0.6, cy - 2.5, 1.2, 2.5), fill(const Color(0xFF65A30D))); 
      canvas.drawRect(Rect.fromLTWH(cx - 1.2, cy - 5.6, 2.5, 3.1), cropOutline);
      canvas.drawRect(Rect.fromLTWH(cx - 1.2, cy - 5.6, 2.5, 3.1), fill(AppColors.gold)); 
    }

    void drawCorn(double cx, double cy) {
      drawMiniShadow(cx, cy, 3.1, 1.9);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 6.2), outline..strokeWidth = 1.2);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 6.2), fill(const Color(0xFF166534))..strokeWidth = 0.6);
      Path leaf = Path()..moveTo(cx, cy - 3.7)..quadraticBezierTo(cx - 3.1, cy - 5, cx - 3.7, cy - 7.5)..quadraticBezierTo(cx - 1.2, cy - 5.6, cx, cy - 4.3)..close();
      canvas.drawPath(leaf, cropOutline); 
      canvas.drawPath(leaf, fill(const Color(0xFF4ADE80)));
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + 1.2, cy - 5), width: 1.9, height: 3.1), cropOutline);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + 1.2, cy - 5), width: 1.9, height: 3.1), fill(const Color(0xFFFDE047)));
    }

    void drawCotton(double cx, double cy) {
      drawMiniShadow(cx, cy, 3.1, 1.9);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 5), cropOutline);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 5), fill(const Color(0xFF78350F))..strokeWidth = 0.6);
      for (double dx in [-1.2, 1.2, 0.0]) {
        canvas.drawCircle(Offset(cx + dx, cy - 5 - (dx == 0 ? 1.9 : 0)), 1.25, fill(Colors.white));
        canvas.drawCircle(Offset(cx + dx, cy - 5 - (dx == 0 ? 1.9 : 0)), 1.25, cropOutline);
      }
    }

    void drawSaffron(double cx, double cy) {
      drawMiniShadow(cx, cy, 3.1, 1.9);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 3.7), fill(const Color(0xFF4ADE80))..strokeWidth = 1.0);
      for(int i = -1; i <= 1; i++) {
        canvas.drawCircle(Offset(cx + i * 1.2, cy - 5 - (i == 0 ? 1.2 : 0)), 1.25, fill(const Color(0xFFA855F7)));
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
    // 4. AŞAMALI TARLALAR VE ŞEFFAF SERA
    // ==========================================
    void drawFieldBase(Rect rect) {
      Path fieldPath = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)));
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
    if (stage >= 1) drawFieldBase(fieldCorn);
    if (stage >= 2) drawFieldBase(fieldCotton); 
    if (stage >= 3) drawFieldBase(fieldSaffron);

    for (double y = 108; y <= 204; y += 5.5) { 
      if (y <= 144) { 
        for (double x = 20; x <= 100; x += 5.5) { drawWheat(x, y); }
        if (stage >= 1) {
          for (double x = 140; x <= 220; x += 6.0) { drawCorn(x, y); }
        }
      } else if (y >= 163) {
        if (stage >= 2) {
          for (double x = 20; x <= 100; x += 6.0) { drawCotton(x, y); }
        }
        if (stage >= 3) {
          for (double x = 140; x <= 220; x += 5.5) { drawSaffron(x, y); }
        }
      }
    }

    // --- ŞEFFAF TÜNEL SERA ---
    if (stage >= 4) {
      // Sera Zemini
      canvas.drawRect(const Rect.fromLTWH(105, 30, 40, 45), outline..strokeWidth = 2.0); 
      canvas.drawRect(const Rect.fromLTWH(105, 30, 40, 45), fill(const Color(0xFF5D4037))); 
      canvas.drawRect(const Rect.fromLTWH(120, 30, 10, 45), outline..strokeWidth = 1.0); 
      canvas.drawRect(const Rect.fromLTWH(120, 30, 10, 45), fill(const Color(0xFF9CA3AF))); 

      // Sera İçindeki Minik Fidanlar
      void drawSapling(double sx, double sy) {
        drawMiniShadow(sx, sy, 2, 1);
        canvas.drawLine(Offset(sx, sy), Offset(sx, sy - 3), fill(const Color(0xFF166534))..strokeWidth = 1.0);
        canvas.drawCircle(Offset(sx, sy - 3), 1.5, fill(const Color(0xFF4ADE80)));
      }

      for (double sy = 35; sy <= 70; sy += 7) {
        drawSapling(110, sy); 
        drawSapling(115, sy);
        drawSapling(135, sy); 
        drawSapling(140, sy);
      }

      // Sera Cam Tavanı
      Path backArch = Path()..moveTo(105, 30)..lineTo(105, 20)..quadraticBezierTo(125, 0, 145, 20)..lineTo(145, 30)..close();
      Path domeTop = Path()..moveTo(105, 50)..quadraticBezierTo(125, 30, 145, 50)..lineTo(145, 20)..quadraticBezierTo(125, 0, 105, 20)..close();
      Path frontArch = Path()..moveTo(105, 75)..lineTo(145, 75)..lineTo(145, 50)..quadraticBezierTo(125, 30, 105, 50)..close();

      drawCastShadow(Path()..addPath(domeTop, Offset.zero)..addPath(frontArch, Offset.zero), 125, 75);

      canvas.drawPath(backArch, fill(const Color(0xFFBAE6FD).withValues(alpha: 0.6)));
      canvas.drawPath(domeTop, fill(const Color(0xFFBAE6FD).withValues(alpha: 0.4)));
      canvas.drawPath(frontArch, fill(const Color(0xFFBAE6FD).withValues(alpha: 0.3)));

      canvas.drawPath(domeTop, outline..strokeWidth = 1.2);
      canvas.drawPath(frontArch, outline..strokeWidth = 1.2);
      
      for(double dy = 30; dy <= 75; dy += 11.25) {
        double t = (dy - 30) / 45.0; 
        double wallTopY = 20 + 30 * t; 
        double archTopY = 0 + 30 * t;  
        
        Path frame = Path()
          ..moveTo(105, dy)
          ..lineTo(105, wallTopY)
          ..quadraticBezierTo(125, archTopY, 145, wallTopY)
          ..lineTo(145, dy);
        canvas.drawPath(frame, outline..strokeWidth = 1.0);
      }
      
      // Sera Kapısı
      canvas.drawRect(const Rect.fromLTWH(120, 55, 10, 20), outline..strokeWidth = 1.5);
      canvas.drawRect(const Rect.fromLTWH(120, 55, 10, 20), fill(Colors.white.withValues(alpha: 0.2)));
      canvas.drawLine(const Offset(125, 55), const Offset(125, 75), outline..strokeWidth = 1.0);
    }

    // ==========================================
    // 5. GELENEKSEL KIRMIZI TOHUM AMBARI
    // ==========================================
    if (stage >= 1) {
      Path hLeft = Path()
        ..moveTo(20, 60)
        ..lineTo(35, 75)
        ..lineTo(35, 45)
        ..lineTo(20, 30)
        ..close();

      Path hFront = Path()
        ..moveTo(35, 75)
        ..lineTo(85, 75)
        ..lineTo(85, 45)
        ..lineTo(35, 45)
        ..close();

      Path hRoof = Path()
        ..moveTo(35, 45)
        ..quadraticBezierTo(60, 15, 85, 45)
        ..lineTo(70, 30)
        ..quadraticBezierTo(45, 0, 20, 30)
        ..close();

      Path hAttic = Path()
        ..moveTo(35, 45)
        ..quadraticBezierTo(60, 15, 85, 45)
        ..close();

      Path hangarAll = Path()..addPath(hLeft, Offset.zero)..addPath(hFront, Offset.zero)..addPath(hAttic, Offset.zero)..addPath(hRoof, Offset.zero);
      drawCastShadow(hangarAll, 60, 75); 

      canvas.drawPath(hLeft, fill(const Color(0xFF7F1D1D))); 
      canvas.drawPath(hFront, fill(const Color(0xFFB91C1C))); 
      canvas.drawPath(hAttic, fill(const Color(0xFFB91C1C))); 
      canvas.drawPath(hRoof, fill(const Color(0xFF1E293B))); 
      
      canvas.drawPath(hRoof, outline..strokeWidth = 2.0);

      for (double t = 0.15; t < 1.0; t += 0.15) {
        Path roofCurve = Path()
          ..moveTo(20 + 15 * t, 30 + 15 * t)
          ..quadraticBezierTo(45 + 15 * t, 15 * t, 70 + 15 * t, 30 + 15 * t);
        canvas.drawPath(roofCurve, Paint()..color = Colors.black.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 1.2);
      }

      canvas.drawRect(const Rect.fromLTWH(50, 55, 20, 20), fill(const Color(0xFF78350F)));
      canvas.drawRect(const Rect.fromLTWH(50, 55, 20, 20), outline..strokeWidth = 1.5);
      canvas.drawLine(const Offset(60, 55), const Offset(60, 75), outline..strokeWidth = 1.5); 
      canvas.drawCircle(const Offset(57, 65), 1.0, fill(Colors.black87)); 
      canvas.drawCircle(const Offset(63, 65), 1.0, fill(Colors.black87)); 

      Path windowLeft = Path()..moveTo(24, 48)..lineTo(31, 55)..lineTo(31, 63)..lineTo(24, 56)..close();
      canvas.drawPath(windowLeft, fill(const Color(0xFFBAE6FD)));
      canvas.drawPath(windowLeft, outline..strokeWidth = 1.2);
      canvas.drawLine(const Offset(27.5, 51.5), const Offset(27.5, 59.5), outline..strokeWidth = 1.0);
      canvas.drawLine(const Offset(24, 52), const Offset(31, 59), outline..strokeWidth = 1.0);

      canvas.drawRect(const Rect.fromLTWH(73, 55, 8, 10), fill(const Color(0xFFBAE6FD)));
      canvas.drawRect(const Rect.fromLTWH(73, 55, 8, 10), outline..strokeWidth = 1.2);
      canvas.drawLine(const Offset(77, 55), const Offset(77, 65), outline..strokeWidth = 1.0);
      canvas.drawLine(const Offset(73, 60), const Offset(81, 60), outline..strokeWidth = 1.0);

      canvas.drawRect(const Rect.fromLTWH(39, 55, 8, 10), fill(const Color(0xFFBAE6FD)));
      canvas.drawRect(const Rect.fromLTWH(39, 55, 8, 10), outline..strokeWidth = 1.2);
      canvas.drawLine(const Offset(43, 54), const Offset(43, 65), outline..strokeWidth = 1.0);
      canvas.drawLine(const Offset(39, 60), const Offset(47, 60), outline..strokeWidth = 1.0);

      // AMBAR TABELASI 
      Rect signRect = const Rect.fromLTWH(38, 44, 45, 8);
      canvas.drawRect(signRect, fill(AppColors.gold));
      canvas.drawRect(signRect, outline..strokeWidth = 1.0);

      String holdingName = "HOLDİNG"; // buraya holdingin adı otomatik gelecek
      double fontSize = 14.0;
      TextPainter textPainter;
      
      do {
        textPainter = TextPainter(
          text: TextSpan(
            text: holdingName,
            style: AppTheme.titleStyle(fontSize: fontSize).copyWith(color: Colors.black, shadows: []),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: 43); 
        fontSize -= 0.5;
      } while ((textPainter.width > 43 || textPainter.height > 6) && fontSize > 1.0);

      textPainter.paint(canvas, Offset(60.5 - textPainter.width / 2, 48 - textPainter.height / 2));

      // 3 BOYUTLU DİKDÖRTGEN SAMAN BALYASI 
      double bx = 35; 
      double by = 85; 
      
      drawMiniShadow(bx + -1.8, by + -2, 12, 6); 

      Rect baleFront = Rect.fromLTWH(bx, by - 8, 10, 8);
      canvas.drawRect(baleFront, fill(const Color(0xFFD97706)));
      canvas.drawRect(baleFront, outline..strokeWidth = 1.0);

      Path baleTop = Path()
        ..moveTo(bx, by - 8)
        ..lineTo(bx + 4, by - 12)
        ..lineTo(bx + 14, by - 12)
        ..lineTo(bx + 10, by - 8)
        ..close();
      canvas.drawPath(baleTop, fill(const Color(0xFFFDE047)));
      canvas.drawPath(baleTop, outline..strokeWidth = 1.0);

      Path baleRight = Path()
        ..moveTo(bx + 10, by - 8)
        ..lineTo(bx + 14, by - 12)
        ..lineTo(bx + 14, by - 4)
        ..lineTo(bx + 10, by)
        ..close();
      canvas.drawPath(baleRight, fill(const Color(0xFFB45309)));
      canvas.drawPath(baleRight, outline..strokeWidth = 1.0);

      canvas.drawLine(Offset(bx + 3, by - 8), Offset(bx + 3, by), outline..strokeWidth = 0.5); 
      canvas.drawLine(Offset(bx + 7, by - 8), Offset(bx + 7, by), outline..strokeWidth = 0.5); 
      canvas.drawLine(Offset(bx + 3, by - 8), Offset(bx + 7, by - 12), outline..strokeWidth = 0.5); 
      canvas.drawLine(Offset(bx + 7, by - 8), Offset(bx + 11, by - 12), outline..strokeWidth = 0.5);
    }

    // ==========================================
    // 6. TAŞ YEL DEĞİRMENİ (Sağ Üst - Aşama 0)
    // ==========================================
    Path millOuter = Path()..moveTo(170, 35)..lineTo(170, 75)..lineTo(210, 75)..lineTo(210, 35)..close();
    Path roofOuter = Path()..moveTo(160, 35)..lineTo(190, 0)..lineTo(220, 35)..close();
    drawCastShadow(Path()..addPath(millOuter, Offset.zero)..addPath(roofOuter, Offset.zero), 190, 75);

    canvas.drawPath(Path()..moveTo(170, 35)..lineTo(170, 75)..lineTo(183, 75)..lineTo(183, 35)..close(), fill(const Color(0xFF57534E))); 
    canvas.drawPath(Path()..moveTo(183, 35)..lineTo(183, 75)..lineTo(197, 75)..lineTo(197, 35)..close(), fill(const Color(0xFF78716C))); 
    canvas.drawPath(Path()..moveTo(197, 35)..lineTo(197, 75)..lineTo(210, 75)..lineTo(210, 35)..close(), fill(const Color(0xFFA8A29E))); 
    
    Path roofWallShadow = Path()
      ..moveTo(170, 35)
      ..lineTo(210, 35)
      ..lineTo(210, 37) 
      ..lineTo(170, 44) 
      ..close();
    canvas.drawPath(roofWallShadow, fill(Colors.black.withValues(alpha: 0.25)));

    Path millDoor = Path()..moveTo(187, 75)..lineTo(187, 60)..quadraticBezierTo(190, 56, 193, 60)..lineTo(193, 75)..close();
    canvas.drawPath(millDoor, outline); 
    canvas.drawPath(millDoor, fill(const Color(0xFF78350F)));
    
    canvas.drawPath(Path()..moveTo(160, 35)..lineTo(190, 0)..lineTo(180, 35)..close(), fill(const Color(0xFF7F1D1D))); 
    canvas.drawPath(Path()..moveTo(180, 35)..lineTo(190, 0)..lineTo(200, 35)..close(), fill(const Color(0xFFB91C1C))); 
    canvas.drawPath(Path()..moveTo(200, 35)..lineTo(190, 0)..lineTo(220, 35)..close(), fill(const Color(0xFFFCA5A5))); 

    canvas.drawCircle(const Offset(190, 22), 4, outline);
    canvas.drawCircle(const Offset(190, 22), 4, fill(const Color(0xFFBAE6FD)));

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
    // 7. ANA GİRİŞ KAPISI (Aşama 0)
    // ==========================================
    canvas.drawRect(const Rect.fromLTWH(96, 210, 5, 20), outline);
    canvas.drawRect(const Rect.fromLTWH(96, 210, 5, 20), fill(const Color(0xFF5D4037)));
    canvas.drawRect(const Rect.fromLTWH(139, 210, 5, 20), outline);
    canvas.drawRect(const Rect.fromLTWH(139, 210, 5, 20), fill(const Color(0xFF5D4037)));
    
    canvas.drawRect(const Rect.fromLTWH(94, 198, 52, 13), outline);
    canvas.drawRect(const Rect.fromLTWH(94, 198, 52, 13), fill(AppColors.gold));

    String gateText = "TARIM ALANI"; // TODO: tr.json key -> 'agriculture_area'
    
    final gateTextPainter = TextPainter(
      text: TextSpan(
        text: gateText,
        style: AppTheme.titleStyle(fontSize: 4.5).copyWith(color: Colors.black, shadows: []),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 50);

    // Tabelanın tam merkezine hizalama
    gateTextPainter.paint(canvas, Offset(120 - gateTextPainter.width / 2, 204.5 - gateTextPainter.height / 2));

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