// lib/screens/factory_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide AnimatedContainer, Container, Icon, Text;
import '../widgets/adaptive_widgets.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/game_state.dart';
import '../services/audio_service.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';

Color _uiSurface(BuildContext context) => AppColors.surfaceFor(context.watch<GameState>().useDarkTheme);
Color _uiSoftSurface(BuildContext context) => AppColors.softSurfaceFor(context.watch<GameState>().useDarkTheme);
Color _uiMutedSurface(BuildContext context) => AppColors.mutedSurfaceFor(context.watch<GameState>().useDarkTheme);

class _FactoryHeavyIconPainter extends CustomPainter {
  final String type;
  final Color color;

  const _FactoryHeavyIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case 'factory':
        canvas.drawRect(const Rect.fromLTWH(4, 10, 16, 12), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(4, 10)
            ..lineTo(8, 4)
            ..lineTo(8, 10)
            ..lineTo(14, 4)
            ..lineTo(14, 10)
            ..lineTo(20, 4)
            ..lineTo(20, 10),
          stroke,
        );
        canvas.drawLine(const Offset(16, 10), const Offset(16, 2), stroke);
        canvas.drawLine(const Offset(18, 10), const Offset(18, 2), stroke);
        break;
      case 'upgrade':
        canvas.drawPath(
          Path()
            ..moveTo(6, 12)
            ..lineTo(12, 4)
            ..lineTo(18, 12),
          stroke..strokeWidth = 3.0,
        );
        canvas.drawPath(
          Path()
            ..moveTo(6, 20)
            ..lineTo(12, 12)
            ..lineTo(18, 20),
          stroke..strokeWidth = 3.0,
        );
        break;
      case 'touch':
        canvas.drawPath(
          Path()
            ..moveTo(12, 2)
            ..lineTo(6, 12)
            ..lineTo(10, 12)
            ..lineTo(10, 22)
            ..lineTo(14, 22)
            ..lineTo(14, 12)
            ..lineTo(18, 12)
            ..close(),
          stroke,
        );
        break;
      default:
        canvas.drawCircle(const Offset(12, 12), 7, stroke);
        canvas.drawCircle(const Offset(12, 12), 2, fill);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FactoryHeavyIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}

class _FactoryHeavyTycoonButton extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color shadowColor;
  final double height;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const _FactoryHeavyTycoonButton({
    this.onTap,
    this.onPressed,
    required this.child,
    required this.color,
    required this.shadowColor,
    this.height = 50,
    this.width,
    this.padding,
  });

  @override
  State<_FactoryHeavyTycoonButton> createState() => _FactoryHeavyTycoonButtonState();
}

class _FactoryHeavyTycoonButtonState extends State<_FactoryHeavyTycoonButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? action = widget.onTap ?? widget.onPressed;
    final bool isDisabled = action == null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              action();
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
                  color: isDisabled ? Colors.grey.shade400 : widget.shadowColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 3.0),
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 3.0),
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

class ProductSvgIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;

  const ProductSvgIcon({
    super.key,
    required this.name,
    this.size = 20,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '$name ürün ikonu'.tl(),
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            isComplex: true,
            willChange: false,
            painter: _ProductVectorPainter(
              name: name,
              tint: adaptiveIconColor(context, color) ?? color,
            ),
          ),
        ),
      ),
    );
  }
}


class _ProductVectorPainter extends CustomPainter {
  final String name;
  final Color tint;

  _ProductVectorPainter({required this.name, required this.tint});

  static const Map<String, String> _legacyNames = {
    'Tereyağ': 'Tereyağı',
    'Motorsiklet': 'Motosiklet',
    'Vip Limuzin': 'VIP Limuzin',
    'Covi-19 Aşısı': 'COVID-19 Aşısı',
    'Rüzgar Tribünü': 'Rüzgar Türbini',
  };

  Paint _fill(Color c) => Paint()..color = c..style = PaintingStyle.fill;
  Paint _stroke(Color c, [double w = 1.25]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  Paint _grad(Color a, Color b, Rect r, {Alignment begin = Alignment.topLeft, Alignment end = Alignment.bottomRight}) {
    return Paint()
      ..shader = LinearGradient(begin: begin, end: end, colors: [a, b]).createShader(r)
      ..style = PaintingStyle.fill;
  }

  Paint _metal(Rect r) => _grad(const Color(0xFFF8FAFC), const Color(0xFF475569), r);
  Paint _darkMetal(Rect r) => _grad(const Color(0xFF64748B), const Color(0xFF111827), r);
  Paint _glass(Rect r) => _grad(const Color(0xFFBAE6FD), const Color(0xFF075985), r);
  Paint _gold(Rect r) => _grad(const Color(0xFFFFE38A), const Color(0xFFB7791F), r);
  Paint _wood(Rect r) => _grad(const Color(0xFFD9A066), const Color(0xFF6B3417), r);

  void _shadow(Canvas c, Rect r) {
    c.drawOval(
      Rect.fromLTWH(r.left - 1, r.bottom - 1, r.width + 2, math.max(2.0, r.height * .22)),
      _fill(Colors.black26),
    );
  }

  void _card(Canvas c, Rect r) {
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(2.5)),
      _fill(const Color(0xFF111827)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(2.5)),
      _stroke(const Color(0xFF334155), .8),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);
    // Every product illustration owns the same 24x24 drawing surface. Clipping
    // here prevents strokes and shadows from leaking into adjacent cards.
    canvas.clipRect(const Rect.fromLTWH(0, 0, 24, 24));
    final bool muted = tint != Colors.black && tint != Colors.black87;
    if (muted) {
      canvas.saveLayer(
        const Rect.fromLTWH(0, 0, 24, 24),
        Paint()..colorFilter = ColorFilter.mode(tint, BlendMode.modulate),
      );
    }

    final outline = _stroke(Colors.black87, 1.1);
    final hi = _stroke(Colors.white54, .65);

    switch (_legacyNames[name] ?? name) {
      // =========================
      // 1) TEKSTİL
      // =========================
      case 'T-shirt':
        _shadow(canvas, const Rect.fromLTWH(4, 5, 16, 16));
        Path t = Path()
          ..moveTo(8, 5)..lineTo(10, 4)..lineTo(12, 6)..lineTo(14, 4)..lineTo(16, 5)
          ..lineTo(19, 9)..lineTo(16.5, 11)..lineTo(15.5, 9.5)..lineTo(15.5, 20)
          ..lineTo(8.5, 20)..lineTo(8.5, 9.5)..lineTo(7.5, 11)..lineTo(5, 9)..close();
        canvas.drawPath(t, _grad(const Color(0xFF60A5FA), const Color(0xFF1D4ED8), const Rect.fromLTWH(5, 4, 14, 16)));
        canvas.drawPath(t, outline);
        canvas.drawArc(const Rect.fromLTWH(9.5, 4.5, 5, 3), 0, math.pi, false, hi);
        break;

      case 'Pantolon':
        _shadow(canvas, const Rect.fromLTWH(5, 4, 14, 17));
        Path p = Path()..moveTo(7, 5)..lineTo(17, 5)..lineTo(15, 11)..lineTo(16, 20)..lineTo(12.5, 20)
          ..lineTo(12, 12)..lineTo(11.5, 20)..lineTo(8, 20)..lineTo(9, 11)..close();
        canvas.drawPath(p, _grad(const Color(0xFF3B82F6), const Color(0xFF172554), const Rect.fromLTWH(7, 5, 10, 15)));
        canvas.drawPath(p, outline);
        canvas.drawLine(const Offset(12, 6), const Offset(12, 11), hi);
        break;

      case 'Ayakkabı':
        _shadow(canvas, const Rect.fromLTWH(3, 10, 18, 10));
        Path s = Path()..moveTo(5, 15)..lineTo(10, 15)..lineTo(12, 10)..lineTo(15, 13)..lineTo(19, 15)
          ..lineTo(20, 18)..lineTo(4, 19)..lineTo(3.5, 17)..close();
        canvas.drawPath(s, _grad(const Color(0xFFF8FAFC), const Color(0xFFCBD5E1), const Rect.fromLTWH(3, 10, 17, 9)));
        canvas.drawPath(s, outline);
        canvas.drawLine(const Offset(11, 14), const Offset(17, 16), _stroke(const Color(0xFF475569), .8));
        canvas.drawLine(const Offset(9, 13), const Offset(15, 15), _stroke(const Color(0xFF475569), .8));
        canvas.drawPath(Path()..moveTo(4,18)..lineTo(20,17.3), _stroke(const Color(0xFF0F172A), 1.4));
        break;

      case 'Çanta':
        _shadow(canvas, const Rect.fromLTWH(4, 6, 16, 15));
        Rect b = const Rect.fromLTWH(5, 8, 14, 12);
        canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(2.5)), _grad(const Color(0xFFF59E0B), const Color(0xFF78350F), b));
        canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(2.5)), outline);
        canvas.drawArc(const Rect.fromLTWH(8, 4, 8, 7), math.pi, math.pi, false, _stroke(const Color(0xFF451A03), 1.7));
        canvas.drawLine(const Offset(6, 12), const Offset(18, 12), _stroke(const Color(0xFFFFE4A3), .8));
        break;

      case 'Takım Elbise':
        _shadow(canvas, const Rect.fromLTWH(5, 3, 14, 19));
        Path suit = Path()..moveTo(8, 5)..lineTo(10.5, 4)..lineTo(12, 6)..lineTo(13.5, 4)..lineTo(16, 5)
          ..lineTo(18, 9)..lineTo(15.5, 11)..lineTo(15, 20)..lineTo(9, 20)..lineTo(8.5, 11)..lineTo(6, 9)..close();
        canvas.drawPath(suit, _grad(const Color(0xFF475569), const Color(0xFF0F172A), const Rect.fromLTWH(6, 4, 12, 16)));
        canvas.drawPath(suit, outline);
        canvas.drawPath(Path()..moveTo(10,5)..lineTo(12,10)..lineTo(14,5), _fill(const Color(0xFFF8FAFC)));
        canvas.drawPath(Path()..moveTo(12,8)..lineTo(13,13)..lineTo(11,13)..close(), _gold(const Rect.fromLTWH(11,8,2,5)));
        break;

      // =========================
      // 2) MOBİLYA
      // =========================
      case 'Sandalye':
        _shadow(canvas, const Rect.fromLTWH(4, 5, 16, 16));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 7, 8, 6), const Radius.circular(1.2)), _wood(const Rect.fromLTWH(8,7,8,6)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 7, 8, 6), const Radius.circular(1.2)), outline);
        canvas.drawLine(const Offset(8.5, 12.5), const Offset(7, 20), _stroke(const Color(0xFF7C3F20), 1.5));
        canvas.drawLine(const Offset(15.5, 12.5), const Offset(17, 20), _stroke(const Color(0xFF7C3F20), 1.5));
        canvas.drawLine(const Offset(9, 7), const Offset(9, 4), _stroke(const Color(0xFF7C3F20), 1.5));
        canvas.drawLine(const Offset(15, 7), const Offset(15, 4), _stroke(const Color(0xFF7C3F20), 1.5));
        canvas.drawLine(const Offset(9, 4.5), const Offset(15, 4.5), _stroke(const Color(0xFFD9A066), 1));
        break;

      case 'Masa':
        _shadow(canvas, const Rect.fromLTWH(2, 7, 20, 15));
        Rect top = const Rect.fromLTWH(3, 7, 18, 4);
        canvas.drawRRect(RRect.fromRectAndRadius(top, const Radius.circular(1)), _wood(top));
        canvas.drawRRect(RRect.fromRectAndRadius(top, const Radius.circular(1)), outline);
        for (final x in [4.2, 19.2]) {
          canvas.drawLine(Offset(x, 10.5), Offset(x - 1.1, 20), _stroke(const Color(0xFF6B3417), 1.5));
        }
        break;

      case 'Koltuk':
        _shadow(canvas, const Rect.fromLTWH(3, 8, 18, 13));
        Rect base = const Rect.fromLTWH(5, 10, 14, 9);
        canvas.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(2.5)), _grad(const Color(0xFFE2E8F0), const Color(0xFF64748B), base));
        canvas.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(2.5)), outline);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 7, 5.5, 8), const Radius.circular(2)), _fill(const Color(0xFFC7D2FE)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12.5, 7, 5.5, 8), const Radius.circular(2)), _fill(const Color(0xFFC7D2FE)));
        canvas.drawLine(const Offset(7, 18.5), const Offset(6.5, 20.5), outline);
        canvas.drawLine(const Offset(17, 18.5), const Offset(17.5, 20.5), outline);
        break;

      case 'Yatak':
        _shadow(canvas, const Rect.fromLTWH(2, 8, 20, 13));
        Rect mattress = const Rect.fromLTWH(4, 10, 16, 8);
        canvas.drawRRect(RRect.fromRectAndRadius(mattress, const Radius.circular(1.5)), _grad(const Color(0xFFDBEAFE), const Color(0xFF93C5FD), mattress));
        canvas.drawRRect(RRect.fromRectAndRadius(mattress, const Radius.circular(1.5)), outline);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 6, 7, 6), const Radius.circular(1.5)), _fill(Colors.white));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, 6, 7, 6), const Radius.circular(1.5)), _fill(Colors.white));
        canvas.drawRect(const Rect.fromLTWH(4, 17, 16, 2), _darkMetal(const Rect.fromLTWH(4,17,16,2)));
        break;

      case 'Dolap':
        _shadow(canvas, const Rect.fromLTWH(5, 3, 14, 18));
        Rect d = const Rect.fromLTWH(6, 4, 12, 16);
        canvas.drawRect(d, _wood(d));
        canvas.drawRect(d, outline);
        canvas.drawLine(const Offset(12, 4), const Offset(12, 20), outline);
        canvas.drawCircle(const Offset(10.8, 12), .6, _fill(const Color(0xFFFFD66D)));
        canvas.drawCircle(const Offset(13.2, 12), .6, _fill(const Color(0xFFFFD66D)));
        canvas.drawRect(const Rect.fromLTWH(7, 5, 4, .7), _fill(Colors.white24));
        break;

      // =========================
      // 3) TARIM
      // =========================
      case 'Buğday':
        _shadow(canvas, const Rect.fromLTWH(6, 5, 12, 17));
        canvas.drawLine(const Offset(12, 20), const Offset(12, 8), _stroke(const Color(0xFF3F6212), 1.2));
        for (int i = 0; i < 4; i++) {
          final y = 8.5 + i * 2.6;
          canvas.drawOval(Rect.fromLTWH(8.2, y, 3.8, 2), _gold(Rect.fromLTWH(8.2,y,3.8,2)));
          canvas.drawOval(Rect.fromLTWH(12.0, y + .6, 3.8, 2), _gold(Rect.fromLTWH(12,y+.6,3.8,2)));
        }
        break;

      case 'Mısır':
        _shadow(canvas, const Rect.fromLTWH(6, 6, 12, 15));
        Path leaf1 = Path()..moveTo(9,20)..quadraticBezierTo(5,14,8,8)..quadraticBezierTo(10,13,11,20)..close();
        Path leaf2 = Path()..moveTo(15,20)..quadraticBezierTo(19,14,16,8)..quadraticBezierTo(14,13,13,20)..close();
        canvas.drawPath(leaf1, _fill(const Color(0xFF65A30D)));
        canvas.drawPath(leaf2, _fill(const Color(0xFF84CC16)));
        Rect cob = const Rect.fromLTWH(9,6,6,12);
        canvas.drawOval(cob, _grad(const Color(0xFFFDE047), const Color(0xFFCA8A04), cob));
        canvas.drawOval(cob, outline);
        for (int i=0;i<4;i++) {
          canvas.drawLine(Offset(10,8+i*2), Offset(14,8.7+i*2), _stroke(const Color(0xFFFEF08A), .5));
        }
        break;

      case 'Pamuk':
        _shadow(canvas, const Rect.fromLTWH(5, 7, 14, 14));
        canvas.drawLine(const Offset(12,20), const Offset(12,12), _stroke(const Color(0xFF166534), 1.1));
        for (final p in [const Offset(9,10), const Offset(12,8), const Offset(15,10), const Offset(10,13), const Offset(14,13)]) {
          canvas.drawCircle(p, 2.3, _fill(Colors.white));
          canvas.drawCircle(p, 2.3, outline);
        }
        break;

      case 'Safran':
        _shadow(canvas, const Rect.fromLTWH(6, 8, 12, 13));
        canvas.drawLine(const Offset(12,20), const Offset(12,11), _stroke(const Color(0xFF166534), 1.1));
        for (int i=0;i<3;i++) {
          final a = -0.8 + i*.8;
          final p = Offset(12 + math.cos(a)*4, 9 + math.sin(a)*3.4);
          canvas.drawOval(Rect.fromCenter(center:p, width:4.6, height:3.2), _grad(const Color(0xFFF0ABFC), const Color(0xFF86198F), Rect.fromCenter(center:p,width:5,height:4)));
        }
        canvas.drawCircle(const Offset(12,10), 1.0, _fill(const Color(0xFFF59E0B)));
        break;

      case 'Hibrit Tohum':
        _shadow(canvas, const Rect.fromLTWH(6, 7, 12, 13));
        Path seed = Path()..moveTo(12,4.5)..cubicTo(16,7,18,11,15,16)..cubicTo(13,20,8,18.5,7,14)..cubicTo(6,9,8.5,6,12,4.5)..close();
        canvas.drawPath(seed, _grad(const Color(0xFF86EFAC), const Color(0xFF14532D), const Rect.fromLTWH(7,5,11,14)));
        canvas.drawPath(seed, outline);
        canvas.drawArc(const Rect.fromLTWH(8,8,8,8), 0.2, 1.7, false, _stroke(const Color(0xFFD1FAE5), 1));
        break;

      // =========================
      // 4) SÜT
      // =========================
      case 'Süt':
        _shadow(canvas, const Rect.fromLTWH(6, 3, 12, 18));
        Rect bottle = const Rect.fromLTWH(8,6,8,14);
        canvas.drawRRect(RRect.fromRectAndRadius(bottle,const Radius.circular(1.8)),_fill(Colors.white));
        canvas.drawRRect(RRect.fromRectAndRadius(bottle,const Radius.circular(1.8)),outline);
        canvas.drawRect(const Rect.fromLTWH(8.5,10,7,4),_fill(const Color(0xFF38BDF8)));
        canvas.drawRect(const Rect.fromLTWH(10,3.8,4,2.4),_fill(const Color(0xFFCBD5E1)));
        break;

      case 'Yoğurt':
        _shadow(canvas, const Rect.fromLTWH(5, 9, 14, 11));
        Rect cup = const Rect.fromLTWH(6,9,12,10);
        canvas.drawRRect(RRect.fromRectAndRadius(cup,const Radius.circular(2)),_fill(Colors.white));
        canvas.drawRRect(RRect.fromRectAndRadius(cup,const Radius.circular(2)),outline);
        canvas.drawRect(const Rect.fromLTWH(6.6,12,10.8,4),_fill(const Color(0xFFBAE6FD)));
        canvas.drawLine(const Offset(7,9),const Offset(17,9),_stroke(const Color(0xFF7DD3FC),1.2));
        break;

      case 'Tereyağı':
        _shadow(canvas, const Rect.fromLTWH(4, 7, 16, 13));
        Rect butter = const Rect.fromLTWH(5,8,14,9);
        canvas.drawRRect(RRect.fromRectAndRadius(butter,const Radius.circular(1.5)),_grad(const Color(0xFFFFF7C2),const Color(0xFFF59E0B),butter));
        canvas.drawRRect(RRect.fromRectAndRadius(butter,const Radius.circular(1.5)),outline);
        canvas.drawLine(const Offset(6,11),const Offset(18,11),_stroke(const Color(0xFFFFFDE7),.7));
        break;

      case 'Arı Sütü':
        _shadow(canvas, const Rect.fromLTWH(5, 4, 14, 17));
        Rect jar = const Rect.fromLTWH(7,6,10,13);
        canvas.drawRRect(RRect.fromRectAndRadius(jar,const Radius.circular(2)),_fill(const Color(0xFFFFFBEB)));
        canvas.drawRRect(RRect.fromRectAndRadius(jar,const Radius.circular(2)),outline);
        canvas.drawRect(const Rect.fromLTWH(8,10,8,4),_fill(const Color(0xFFF59E0B)));
        canvas.drawCircle(const Offset(12,8),1.7,_fill(const Color(0xFFFFD66D)));
        break;

      case 'Pule Peyniri':
        _shadow(canvas, const Rect.fromLTWH(4, 8, 16, 12));
        Path cheese = Path()..moveTo(5,17)..lineTo(7,9)..lineTo(19,9)..lineTo(17,18)..close();
        canvas.drawPath(cheese,_grad(const Color(0xFFFFF7AE),const Color(0xFFD4A017),const Rect.fromLTWH(5,9,14,9)));
        canvas.drawPath(cheese,outline);
        for(final p in [const Offset(9,12),const Offset(14,14),const Offset(16,11)]) {
          canvas.drawCircle(p, .65, _fill(const Color(0xFFB7791F)));
        }
        break;

      // =========================
      // 5) ET / MEZBAHA
      // =========================
      case 'Sosis':
        _shadow(canvas, const Rect.fromLTWH(3, 8, 18, 12));
        Path sausage = Path()..moveTo(5,10)..cubicTo(7,7,10,8,12,10)..cubicTo(14,12,17,8,19,11)
          ..cubicTo(20,13,18,16,15,17)..cubicTo(12,18,9,15,7,16)..cubicTo(4,17,3,13,5,10)..close();
        canvas.drawPath(sausage,_grad(const Color(0xFFF87171),const Color(0xFF991B1B),const Rect.fromLTWH(4,8,16,9)));
        canvas.drawPath(sausage,outline);
        for(int i=0;i<4;i++) canvas.drawCircle(Offset(7+i*3.0,12+(i.isEven?0.5:-.3)),.35,_fill(const Color(0xFFFECACA)));
        break;

      case 'Tavuk':
        _shadow(canvas, const Rect.fromLTWH(4, 7, 16, 14));
        Path drum = Path()..moveTo(11,7)..cubicTo(16,6,18,10,16,14)..lineTo(13,18)..lineTo(15,19)
          ..lineTo(13,21)..lineTo(10,19)..lineTo(11,16)..cubicTo(7,14,7,8,11,7)..close();
        canvas.drawPath(drum,_grad(const Color(0xFFFFEDD5),const Color(0xFFEA580C),const Rect.fromLTWH(7,7,10,14)));
        canvas.drawPath(drum,outline);
        canvas.drawCircle(const Offset(14.2,18.8),1.1,_fill(const Color(0xFFF5F5F4)));
        break;

      case 'Kebap':
        _shadow(canvas, const Rect.fromLTWH(4, 8, 16, 12));
        canvas.drawLine(const Offset(5,18),const Offset(19,6),_stroke(const Color(0xFF92400E),1.7));
        for(int i=0;i<6;i++) {
          final p=Offset(7+i*1.8,16-i*1.7);
          canvas.drawCircle(p,1.25,_grad(const Color(0xFFFB923C),const Color(0xFF7C2D12),Rect.fromCircle(center:p,radius:2)));
        }
        canvas.drawCircle(const Offset(18.5,6.4),.8,_fill(const Color(0xFFE5E7EB)));
        break;

      case 'Timsah Derisi':
        _shadow(canvas, const Rect.fromLTWH(3, 5, 18, 16));
        Path hide = Path()..moveTo(4,8)..quadraticBezierTo(7,4,11,6)..quadraticBezierTo(14,3,20,7)
          ..lineTo(18,18)..lineTo(6,20)..close();
        canvas.drawPath(hide,_grad(const Color(0xFF84A98C),const Color(0xFF14532D),const Rect.fromLTWH(4,4,16,16)));
        canvas.drawPath(hide,outline);
        for(int r=0;r<3;r++) for(int c=0;c<5;c++) {
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(6+c*2.5,8+r*3,1.6,1.4),const Radius.circular(.5)),_fill(const Color(0xFF166534)));
        }
        break;

      case 'Wagyu Eti':
        _shadow(canvas, const Rect.fromLTWH(4, 8, 16, 12));
        Path steak = Path()..moveTo(5,10)..quadraticBezierTo(8,7,12,9)..quadraticBezierTo(16,7,19,10)
          ..quadraticBezierTo(20,14,17,18)..quadraticBezierTo(13,20,9,18)..quadraticBezierTo(5,17,5,10)..close();
        canvas.drawPath(steak,_grad(const Color(0xFFFCA5A5),const Color(0xFF7F1D1D),const Rect.fromLTWH(5,8,15,11)));
        canvas.drawPath(steak,outline);
        for(final p in [const Offset(8,11),const Offset(12,10),const Offset(15,13),const Offset(10,15),const Offset(16,16)]) {
          canvas.drawOval(Rect.fromCenter(center:p,width:1.6,height:.6),_fill(const Color(0xFFFDE68A)));
        }
        break;

      // =========================
      // 6) GIDA
      // =========================
      case 'Un':
        _shadow(canvas, const Rect.fromLTWH(4, 5, 16, 16));
        Path sack=Path()..moveTo(6,7)..lineTo(18,7)..lineTo(19,19)..lineTo(5,19)..close();
        canvas.drawPath(sack,_fill(const Color(0xFFEDE9D5))); canvas.drawPath(sack,outline);
        canvas.drawLine(const Offset(7,9),const Offset(17,9),_stroke(const Color(0xFFB7A77A),.8));
        canvas.drawLine(const Offset(8,12),const Offset(16,12),_stroke(const Color(0xFFB7A77A),.6));
        break;

      case 'Şeker':
        _shadow(canvas, const Rect.fromLTWH(4, 6, 16, 14));
        for(int r=0;r<3;r++) for(int c=0;c<4;c++) {
          Rect q=Rect.fromLTWH(6+c*3,8+r*3,2.6,2.6);
          canvas.drawRRect(RRect.fromRectAndRadius(q,const Radius.circular(.6)),_fill(const Color(0xFFF8FAFC)));
          canvas.drawRRect(RRect.fromRectAndRadius(q,const Radius.circular(.6)),outline);
        }
        break;

      case 'Konserve':
        _shadow(canvas, const Rect.fromLTWH(5, 4, 14, 17));
        Rect can=const Rect.fromLTWH(7,5,10,15);
        canvas.drawRRect(RRect.fromRectAndRadius(can,const Radius.circular(2)),_metal(can));
        canvas.drawRRect(RRect.fromRectAndRadius(can,const Radius.circular(2)),outline);
        canvas.drawRect(const Rect.fromLTWH(7.7,10,8.6,5),_fill(const Color(0xFFDC2626)));
        canvas.drawLine(const Offset(8,11),const Offset(16,11),_stroke(const Color(0xFFFECACA),.7));
        break;

      case 'Havyar':
        _shadow(canvas, const Rect.fromLTWH(5, 7, 14, 13));
        Rect jar=const Rect.fromLTWH(7,8,10,11);
        canvas.drawRRect(RRect.fromRectAndRadius(jar,const Radius.circular(2)),_fill(const Color(0xFF0F172A)));
        canvas.drawRRect(RRect.fromRectAndRadius(jar,const Radius.circular(2)),outline);
        for(int r=0;r<4;r++) for(int c=0;c<4;c++) canvas.drawCircle(Offset(9+c*2,10.2+r*2),.65,_fill(const Color(0xFFE5E7EB)));
        canvas.drawRect(const Rect.fromLTWH(7,6,10,2),_gold(const Rect.fromLTWH(7,6,10,2)));
        break;

      case 'Gurme Çikolata':
        _shadow(canvas, const Rect.fromLTWH(4, 6, 16, 15));
        Rect ch=const Rect.fromLTWH(5,8,14,10);
        canvas.drawRRect(RRect.fromRectAndRadius(ch,const Radius.circular(1.5)),_grad(const Color(0xFF8B5E34),const Color(0xFF3B1D0B),ch));
        canvas.drawRRect(RRect.fromRectAndRadius(ch,const Radius.circular(1.5)),outline);
        for(int r=0;r<2;r++) for(int c=0;c<4;c++) canvas.drawLine(Offset(6+c*3,8+r*5),Offset(6+c*3,18-r*5),_stroke(const Color(0xFFD7A86E),.35));
        break;

      // =========================
      // 7) MADEN
      // =========================
      case 'Kömür':
        _shadow(canvas, const Rect.fromLTWH(4, 8, 16, 12));
        Path ore=Path()..moveTo(5,14)..lineTo(8,8)..lineTo(14,7)..lineTo(19,11)..lineTo(17,18)..lineTo(10,20)..close();
        canvas.drawPath(ore,_grad(const Color(0xFF475569),const Color(0xFF020617),const Rect.fromLTWH(5,7,14,13))); canvas.drawPath(ore,outline);
        canvas.drawPath(Path()..moveTo(8,10)..lineTo(13,9)..lineTo(16,11),_stroke(const Color(0xFF94A3B8),.7));
        break;

      case 'Demir':
        _shadow(canvas, const Rect.fromLTWH(3, 7, 18, 12));
        Path beam=Path()..moveTo(4,7)..lineTo(9,7)..lineTo(9,10)..lineTo(17,10)..lineTo(17,14)..lineTo(9,14)..lineTo(9,18)..lineTo(4,18)..lineTo(4,14)..lineTo(12,14)..lineTo(12,10)..lineTo(4,10)..close();
        canvas.drawPath(beam,_metal(const Rect.fromLTWH(4,7,13,11))); canvas.drawPath(beam,outline);
        break;

      case 'Gümüş':
        _shadow(canvas, const Rect.fromLTWH(4, 8, 16, 11));
        Path bar=Path()..moveTo(6,10)..lineTo(17,8)..lineTo(19,11)..lineTo(8,14)..close();
        canvas.drawPath(bar,_metal(const Rect.fromLTWH(6,8,13,6))); canvas.drawPath(bar,outline);
        canvas.drawLine(const Offset(9,11),const Offset(16,9.5),_stroke(Colors.white,.6));
        break;

      case 'Altın':
        _shadow(canvas, const Rect.fromLTWH(4, 7, 16, 13));
        Rect ing=const Rect.fromLTWH(6,8,12,8);
        canvas.drawRRect(RRect.fromRectAndRadius(ing,const Radius.circular(1.4)),_gold(ing));
        canvas.drawRRect(RRect.fromRectAndRadius(ing,const Radius.circular(1.4)),outline);
        canvas.drawLine(const Offset(8,10),const Offset(15,10),_stroke(const Color(0xFFFFF2B2),.7));
        break;

      case 'Elmas':
        _shadow(canvas, const Rect.fromLTWH(5, 5, 14, 16));
        Path gem=Path()..moveTo(5,9)..lineTo(8,5)..lineTo(16,5)..lineTo(19,9)..lineTo(12,20)..close();
        canvas.drawPath(gem,_grad(const Color(0xFFE0F2FE),const Color(0xFF0EA5E9),const Rect.fromLTWH(5,5,14,15))); canvas.drawPath(gem,outline);
        canvas.drawLine(const Offset(8,5),const Offset(12,20),hi);
        canvas.drawLine(const Offset(16,5),const Offset(12,20),hi);
        canvas.drawLine(const Offset(5,9),const Offset(19,9),hi);
        break;

      // =========================
      // 8) KİMYA
      // =========================
      case 'Gübre':
        _shadow(canvas, const Rect.fromLTWH(4, 7, 16, 14));
        Rect sack=const Rect.fromLTWH(5,9,14,10);
        canvas.drawRRect(RRect.fromRectAndRadius(sack,const Radius.circular(1.5)),_fill(const Color(0xFFE7E5E4)));
        canvas.drawRRect(RRect.fromRectAndRadius(sack,const Radius.circular(1.5)),outline);
        canvas.drawRect(const Rect.fromLTWH(6,12,12,3),_fill(const Color(0xFF65A30D)));
        canvas.drawCircle(const Offset(12,10),1.5,_fill(const Color(0xFF84CC16)));
        break;

      case 'Plastik':
        _shadow(canvas, const Rect.fromLTWH(5, 8, 14, 12));
        for(int i=0;i<14;i++) {
          double x=6+(i%7)*2, y=10+(i~/7)*3.5;
          canvas.drawCircle(Offset(x,y),1.2,_fill(i.isEven?const Color(0xFF60A5FA):const Color(0xFF2563EB)));
          canvas.drawCircle(Offset(x,y),1.2,_stroke(const Color(0xFF1E3A8A),.4));
        }
        break;

      case 'Boya':
        _shadow(canvas, const Rect.fromLTWH(4, 5, 16, 16));
        for(int i=0;i<3;i++) {
          Rect can=Rect.fromLTWH(5+i*5,8-(i==1?2:0),5,10);
          canvas.drawRRect(RRect.fromRectAndRadius(can,const Radius.circular(1.2)),_grad(
            i==0?const Color(0xFFEF4444):i==1?const Color(0xFF60A5FA):const Color(0xFFFBBF24),
            i==0?const Color(0xFF991B1B):i==1?const Color(0xFF1D4ED8):const Color(0xFFB45309),can));
          canvas.drawRRect(RRect.fromRectAndRadius(can,const Radius.circular(1.2)),outline);
        }
        canvas.drawLine(const Offset(7,7),const Offset(7,4),_stroke(const Color(0xFF7C3AED),1.1));
        break;

      case 'Lüks Parfüm':
        _shadow(canvas, const Rect.fromLTWH(5, 4, 14, 17));
        Rect bottle=const Rect.fromLTWH(8,8,8,11);
        canvas.drawRRect(RRect.fromRectAndRadius(bottle,const Radius.circular(1.8)),_grad(const Color(0xFFFDE68A),const Color(0xFFB45309),bottle));
        canvas.drawRRect(RRect.fromRectAndRadius(bottle,const Radius.circular(1.8)),outline);
        canvas.drawRect(const Rect.fromLTWH(10,5,4,3),_gold(const Rect.fromLTWH(10,5,4,3)));
        canvas.drawRect(const Rect.fromLTWH(10.2,2.8,3.6,2.2),_metal(const Rect.fromLTWH(10.2,2.8,3.6,2.2)));
        break;

      case 'Karbonfiber':
        _shadow(canvas, const Rect.fromLTWH(4, 6, 16, 15));
        Rect cf=const Rect.fromLTWH(5,7,14,12);
        canvas.drawRRect(RRect.fromRectAndRadius(cf,const Radius.circular(1.5)),_darkMetal(cf));
        canvas.drawRRect(RRect.fromRectAndRadius(cf,const Radius.circular(1.5)),outline);
        for (int i = -3; i < 18; i += 3) {
          canvas.drawLine(
            Offset(5.0 + i.toDouble(), 8.0),
            Offset(9.0 + i.toDouble(), 18.0),
            _stroke(const Color(0xFF94A3B8), .45),
          );
        }
        for (int i = 0; i < 18; i += 3) {
          canvas.drawLine(
            Offset(6.0 + i.toDouble(), 8.0),
            Offset(16.0 + i.toDouble(), 18.0),
            _stroke(const Color(0xFF0F172A), .45),
          );
        }
        break;

      // =========================
      // 9) OTOMOTİV
      // =========================
      case 'Lastik':
        _shadow(canvas, const Rect.fromLTWH(4, 4, 16, 18));
        canvas.drawCircle(const Offset(12,13),7,_fill(const Color(0xFF111827)));
        canvas.drawCircle(const Offset(12,13),7,outline);
        canvas.drawCircle(const Offset(12,13),3.2,_fill(const Color(0xFF94A3B8)));
        canvas.drawCircle(const Offset(12,13),1.2,_fill(const Color(0xFF1E293B)));
        for(int i=0;i<8;i++){double a=i*math.pi/4; canvas.drawLine(Offset(12+3.5*math.cos(a),13+3.5*math.sin(a)),Offset(12+6.2*math.cos(a),13+6.2*math.sin(a)),_stroke(const Color(0xFF334155),.65));}
        break;

      case 'Motosiklet':
        _shadow(canvas, const Rect.fromLTWH(2, 7, 20, 14));
        canvas.drawCircle(const Offset(6.5,17),3,_fill(const Color(0xFF0F172A)));
        canvas.drawCircle(const Offset(17.5,17),3,_fill(const Color(0xFF0F172A)));
        canvas.drawLine(const Offset(8.5,16),const Offset(12,11),_stroke(const Color(0xFFEF4444),1.6));
        canvas.drawLine(const Offset(12,11),const Offset(16,16),_stroke(const Color(0xFFEF4444),1.6));
        canvas.drawLine(const Offset(10,13),const Offset(16,13),_stroke(const Color(0xFF475569),1.2));
        canvas.drawRect(const Rect.fromLTWH(10,9,5,3),_darkMetal(const Rect.fromLTWH(10,9,5,3)));
        break;

      case 'Otomobil':
        _shadow(canvas, const Rect.fromLTWH(2, 8, 20, 13));
        Path car=Path()..moveTo(4,16)..lineTo(6,11)..quadraticBezierTo(7,9,10,9)..lineTo(15,9)..quadraticBezierTo(18,10,20,16)
          ..lineTo(20,18)..lineTo(4,18)..close();
        canvas.drawPath(car,_grad(const Color(0xFF60A5FA),const Color(0xFF1D4ED8),const Rect.fromLTWH(4,9,16,9)));
        canvas.drawPath(car,outline);
        canvas.drawRect(const Rect.fromLTWH(9,10,6,3),_glass(const Rect.fromLTWH(9,10,6,3)));
        for(final x in [7.0,17.0]){canvas.drawCircle(Offset(x,18),2,_fill(const Color(0xFF0F172A)));canvas.drawCircle(Offset(x,18),.8,_fill(const Color(0xFFCBD5E1)));}
        break;

      case 'VIP Limuzin':
        _shadow(canvas, const Rect.fromLTWH(1, 8, 22, 13));
        Path limo=Path()..moveTo(3,15)..lineTo(5,11)..lineTo(9,10)..lineTo(16,10)..lineTo(19,12)..lineTo(21,15)..lineTo(21,18)..lineTo(3,18)..close();
        canvas.drawPath(limo,_grad(const Color(0xFF111827),const Color(0xFF020617),const Rect.fromLTWH(3,10,18,8)));
        canvas.drawPath(limo,outline);
        canvas.drawRect(const Rect.fromLTWH(6,11,12,2.5),_glass(const Rect.fromLTWH(6,11,12,2.5)));
        for(final x in [6.5,17.5]) canvas.drawCircle(Offset(x,18),2,_fill(const Color(0xFF0F172A)));
        break;

      case 'Süper Spor Araç':
        _shadow(canvas, const Rect.fromLTWH(2, 8, 20, 13));
        Path sp=Path()..moveTo(3,16)..lineTo(7,10)..lineTo(14,8)..lineTo(19,11)..lineTo(21,16)..lineTo(20,18)..lineTo(4,18)..close();
        canvas.drawPath(sp,_grad(const Color(0xFFF87171),const Color(0xFF7F1D1D),const Rect.fromLTWH(3,8,18,10)));
        canvas.drawPath(sp,outline);
        canvas.drawPath(Path()..moveTo(8,11)..lineTo(13,9)..lineTo(17,11),_stroke(const Color(0xFFBAE6FD),.9));
        for(final x in [6.5,17.5]) canvas.drawCircle(Offset(x,18),2.1,_fill(const Color(0xFF020617)));
        break;

      // =========================
      // 10) İLAÇ
      // =========================
      case 'Vitamin Hapı':
        _shadow(canvas,const Rect.fromLTWH(4,7,16,12));
        canvas.save(); canvas.translate(12,13); canvas.rotate(-.35); canvas.translate(-12,-13);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6,10,12,6),const Radius.circular(3)),_fill(const Color(0xFFF59E0B)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6,10,12,6),const Radius.circular(3)),outline);
        canvas.drawRect(const Rect.fromLTWH(12,10,6,6),_fill(Colors.white));
        canvas.restore();
        break;

      case 'Ağrı Kesici':
        _shadow(canvas,const Rect.fromLTWH(4,6,16,13));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7,8,10,12),const Radius.circular(2)),_fill(Colors.white));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7,8,10,12),const Radius.circular(2)),outline);
        for(final p in [const Offset(10,11),const Offset(14,11),const Offset(10,15),const Offset(14,15)]) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:p,width:2,height:1.1),const Radius.circular(.5)),_fill(const Color(0xFF60A5FA)));
        break;

      case 'Antibiyotik':
        _shadow(canvas,const Rect.fromLTWH(4,7,16,13));
        canvas.save(); canvas.translate(12,13); canvas.rotate(.55); canvas.translate(-12,-13);
        Rect cap=const Rect.fromLTWH(6,10,6,3.8), body=const Rect.fromLTWH(12,10,6,3.8);
        canvas.drawRRect(RRect.fromRectAndRadius(cap,const Radius.circular(2)),_fill(Colors.white));
        canvas.drawRRect(RRect.fromRectAndRadius(body,const Radius.circular(2)),_fill(const Color(0xFF2563EB)));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(9,10,6,3.8),const Radius.circular(2)),_stroke(Colors.black87,.8));
        canvas.restore();
        break;

      case 'COVID-19 Aşısı':
        _shadow(canvas,const Rect.fromLTWH(6,4,12,18));
        canvas.drawRect(const Rect.fromLTWH(9,7,6,12),_glass(const Rect.fromLTWH(9,7,6,12)));
        canvas.drawRect(const Rect.fromLTWH(9,7,6,12),outline);
        canvas.drawRect(const Rect.fromLTWH(8,4.5,8,3),_metal(const Rect.fromLTWH(8,4.5,8,3)));
        canvas.drawLine(const Offset(12,7),const Offset(12,2.5),_stroke(const Color(0xFFE2E8F0),1));
        break;

      case 'Kanser İlacı':
        _shadow(canvas,const Rect.fromLTWH(5,5,14,16));
        Rect bottle=const Rect.fromLTWH(8,8,8,11);
        canvas.drawRRect(RRect.fromRectAndRadius(bottle,const Radius.circular(1.5)),_fill(Colors.white));
        canvas.drawRRect(RRect.fromRectAndRadius(bottle,const Radius.circular(1.5)),outline);
        canvas.drawRect(const Rect.fromLTWH(8.5,12,7,3),_fill(const Color(0xFFA855F7)));
        canvas.drawRect(const Rect.fromLTWH(10,5,4,3),_darkMetal(const Rect.fromLTWH(10,5,4,3)));
        break;

      // =========================
      // 11) ELEKTRONİK
      // =========================
      case 'Hesap Makinesi':
        _shadow(canvas,const Rect.fromLTWH(3,4,18,18));
        Rect calc=const Rect.fromLTWH(5,5,14,16);
        canvas.drawRRect(RRect.fromRectAndRadius(calc,const Radius.circular(2)),_darkMetal(calc));
        canvas.drawRRect(RRect.fromRectAndRadius(calc,const Radius.circular(2)),outline);
        canvas.drawRect(const Rect.fromLTWH(7,7,10,4),_fill(const Color(0xFFDCFCE7)));
        for(int r=0;r<3;r++) for(int c=0;c<4;c++) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(7+c*2.5,12+r*2.4,1.7,1.5),const Radius.circular(.4)),_fill(const Color(0xFFE2E8F0)));
        break;

      case 'Telefon':
        _shadow(canvas,const Rect.fromLTWH(5,3,14,19));
        Rect ph=const Rect.fromLTWH(7,4,10,17);
        canvas.drawRRect(RRect.fromRectAndRadius(ph,const Radius.circular(2)),_darkMetal(ph));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7.8,5,8.4,13),const Radius.circular(1.4)),_grad(const Color(0xFF93C5FD),const Color(0xFF7C3AED),const Rect.fromLTWH(7.8,5,8.4,13)));
        canvas.drawCircle(const Offset(12,19.3),.6,_fill(Colors.white70));
        break;

      case 'Televizyon':
        _shadow(canvas,const Rect.fromLTWH(2,5,20,16));
        Rect tv=const Rect.fromLTWH(4,6,16,11);
        canvas.drawRRect(RRect.fromRectAndRadius(tv,const Radius.circular(1.5)),_darkMetal(tv));
        canvas.drawRRect(RRect.fromRectAndRadius(tv,const Radius.circular(1.5)),outline);
        canvas.drawRect(const Rect.fromLTWH(5,7,14,9),_grad(const Color(0xFF0EA5E9),const Color(0xFF1E1B4B),const Rect.fromLTWH(5,7,14,9)));
        canvas.drawLine(const Offset(10,18),const Offset(14,18),_stroke(const Color(0xFF94A3B8),1.2));
        canvas.drawLine(const Offset(12,17),const Offset(12,20),_stroke(const Color(0xFF94A3B8),1.2));
        break;

      case 'İnsansız Hava Aracı':
        _shadow(canvas,const Rect.fromLTWH(3,7,18,14));
        Path drone=Path()..moveTo(8,11)..lineTo(11,10)..lineTo(13,10)..lineTo(16,11)..lineTo(15,14)..lineTo(9,14)..close();
        canvas.drawPath(drone,_darkMetal(const Rect.fromLTWH(8,10,8,5)));canvas.drawPath(drone,outline);
        for(final p in [const Offset(5,8),const Offset(19,8),const Offset(5,18),const Offset(19,18)]) {
          canvas.drawLine(Offset(p.dx<12?p.dx+1.5:p.dx-1.5,p.dy),Offset(p.dx,p.dy),_stroke(const Color(0xFF64748B),1));
          canvas.drawCircle(p,1.7,_stroke(const Color(0xFF0F172A),.8));
        }
        break;

      case 'Kuantum PC':
        _shadow(canvas,const Rect.fromLTWH(3,4,18,18));
        Rect q=const Rect.fromLTWH(5,6,14,14);
        canvas.drawRRect(RRect.fromRectAndRadius(q,const Radius.circular(1.5)),_darkMetal(q));
        canvas.drawRRect(RRect.fromRectAndRadius(q,const Radius.circular(1.5)),outline);
        for(int i=0;i<4;i++) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(7+i*2.2,8,1.5,5),const Radius.circular(.4)),_fill(const Color(0xFF38BDF8)));
        canvas.drawLine(const Offset(7,15),const Offset(17,15),_stroke(const Color(0xFFFBBF24),.9));
        break;

      // =========================
      // 12) YAPAY ZEKA
      // =========================
      case 'Sohbet Botu':
        _shadow(canvas,const Rect.fromLTWH(4,7,16,13));
        Rect bubble=const Rect.fromLTWH(5,7,14,10);
        canvas.drawRRect(RRect.fromRectAndRadius(bubble,const Radius.circular(3)),_fill(const Color(0xFF0EA5E9)));
        canvas.drawRRect(RRect.fromRectAndRadius(bubble,const Radius.circular(3)),outline);
        canvas.drawPath(Path()..moveTo(8,17)..lineTo(7,20)..lineTo(11,17),_fill(const Color(0xFF0EA5E9)));
        for (final x in const <double>[8.5, 12, 15.5]) canvas.drawCircle(Offset(x, 12), .7, _fill(Colors.white));
        break;

      case 'Satranç Botu':
        _shadow(canvas,const Rect.fromLTWH(4,4,16,18));
        Path king=Path()..moveTo(9,20)..lineTo(15,20)..lineTo(14,16)..lineTo(16,13)..lineTo(14,11)..lineTo(14,8)..lineTo(15,8)..lineTo(15,6)..lineTo(13,6)..lineTo(13,4)..lineTo(11,4)..lineTo(11,6)..lineTo(9,6)..lineTo(9,8)..lineTo(10,8)..lineTo(10,11)..lineTo(8,13)..lineTo(10,16)..close();
        canvas.drawPath(king,_metal(const Rect.fromLTWH(8,4,8,16)));canvas.drawPath(king,outline);
        break;

      case 'Görsel Oluşturma Botu':
        _shadow(canvas,const Rect.fromLTWH(3,5,18,16));
        Rect art=const Rect.fromLTWH(5,6,14,13);
        canvas.drawRRect(RRect.fromRectAndRadius(art,const Radius.circular(2)),_fill(const Color(0xFF111827)));
        canvas.drawRRect(RRect.fromRectAndRadius(art,const Radius.circular(2)),outline);
        Path m=Path()..moveTo(6,17)..lineTo(10,12)..lineTo(13,15)..lineTo(15,11)..lineTo(18,17)..close();
        canvas.drawPath(m,_grad(const Color(0xFF38BDF8),const Color(0xFF7C3AED),const Rect.fromLTWH(6,11,12,6)));
        canvas.drawCircle(const Offset(15.5,9.2),1.3,_fill(const Color(0xFFFBBF24)));
        break;

      case 'Kodlama Botu':
        _shadow(canvas,const Rect.fromLTWH(3,7,18,14));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5,8,14,10),const Radius.circular(2)),_darkMetal(const Rect.fromLTWH(5,8,14,10)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5,8,14,10),const Radius.circular(2)),outline);
        final codePaint = TextPainter(
          text: const TextSpan(text: '</>', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 6.5, fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr,
        )..layout();
        codePaint.paint(canvas, const Offset(8.7, 10.6));
        break;

      case 'Humanoid Robot':
        _shadow(canvas,const Rect.fromLTWH(5,3,14,19));
        canvas.drawCircle(const Offset(12,6),3,_metal(Rect.fromCircle(center:Offset(12,6),radius:3)));
        canvas.drawCircle(const Offset(11,6),.55,_fill(const Color(0xFF38BDF8)));
        canvas.drawCircle(const Offset(13,6),.55,_fill(const Color(0xFF38BDF8)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8,9,8,8),const Radius.circular(1.7)),_darkMetal(const Rect.fromLTWH(8,9,8,8)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8,9,8,8),const Radius.circular(1.7)),outline);
        canvas.drawLine(const Offset(8,11),const Offset(5.5,14),outline);canvas.drawLine(const Offset(16,11),const Offset(18.5,14),outline);
        canvas.drawLine(const Offset(10,17),const Offset(9,21),outline);canvas.drawLine(const Offset(14,17),const Offset(15,21),outline);
        break;

      // =========================
      // 13) ENERJİ
      // =========================
      case 'Güneş Paneli':
        _shadow(canvas,const Rect.fromLTWH(3,6,18,14));
        Rect panel=const Rect.fromLTWH(5,6,14,9);
        canvas.drawRect(panel,_grad(const Color(0xFF2563EB),const Color(0xFF0C4A6E),panel));
        canvas.drawRect(panel,outline);
        for(int i=1;i<4;i++) canvas.drawLine(Offset(5+i*3.5,6),Offset(5+i*3.5,15),_stroke(const Color(0xFF93C5FD),.45));
        for(int i=1;i<3;i++) canvas.drawLine(Offset(5,6+i*3),Offset(19,6+i*3),_stroke(const Color(0xFF93C5FD),.45));
        canvas.drawLine(const Offset(12,15),const Offset(12,20),_stroke(const Color(0xFF64748B),1.1));
        break;

      case 'Rüzgar Türbini':
        _shadow(canvas,const Rect.fromLTWH(4,4,16,18));
        canvas.drawLine(const Offset(12,8),const Offset(12,20),_stroke(const Color(0xFFE2E8F0),1.3));
        canvas.drawCircle(const Offset(12,8),1.2,_fill(const Color(0xFFE2E8F0)));
        for(int i=0;i<3;i++){double a=i*2*math.pi/3; canvas.drawLine(const Offset(12,8),Offset(12+5*math.cos(a),8+5*math.sin(a)),_stroke(const Color(0xFFBAE6FD),1.2));}
        break;

      case 'Nükleer Santral':
        _shadow(canvas,const Rect.fromLTWH(3,7,18,14));
        Path tower=Path()..moveTo(7,20)..quadraticBezierTo(8,14,9,9)..quadraticBezierTo(12,7,15,9)..quadraticBezierTo(16,14,17,20)..close();
        canvas.drawPath(tower,_metal(const Rect.fromLTWH(7,8,10,12)));canvas.drawPath(tower,outline);
        canvas.drawCircle(const Offset(12,12),1.3,_fill(const Color(0xFFFBBF24)));
        break;

      case 'Parçacık Hızlandırıcı':
        _shadow(canvas,const Rect.fromLTWH(3,5,18,16));
        canvas.drawOval(const Rect.fromLTWH(4,7,16,10),_stroke(const Color(0xFF0EA5E9),2));
        canvas.drawOval(const Rect.fromLTWH(7,9,10,6),_stroke(const Color(0xFFFBBF24),1));
        canvas.drawCircle(const Offset(12,12),1.1,_fill(const Color(0xFF38BDF8)));
        break;

      case 'Füzyon Çekirdeği':
        _shadow(canvas,const Rect.fromLTWH(4,5,16,17));
        canvas.drawCircle(const Offset(12,13),5,_fill(const Color(0xFF0F172A)));
        canvas.drawCircle(const Offset(12,13),2,_fill(const Color(0xFFF59E0B)));
        for(int i=0;i<3;i++){
          canvas.save();
          canvas.translate(12,13);
          canvas.rotate(i*math.pi/3);
          canvas.translate(-12,-13);
          canvas.drawOval(Rect.fromCenter(center:const Offset(12,13),width:10-i*1.8,height:4+i*1.2),_stroke(const Color(0xFF38BDF8),1));
          canvas.restore();
        }
        break;

      // =========================
      // 14) BİYOTEKNOLOJİ
      // =========================
      case 'Kök Hücre':
        _shadow(canvas,const Rect.fromLTWH(4,5,16,17));
        canvas.drawCircle(const Offset(12,13),5,_fill(const Color(0xFFDBEAFE)));canvas.drawCircle(const Offset(12,13),5,outline);
        canvas.drawCircle(const Offset(10.5,11.5),1.2,_fill(const Color(0xFF60A5FA)));
        canvas.drawCircle(const Offset(13.7,12.8),1.5,_fill(const Color(0xFF34D399)));
        canvas.drawCircle(const Offset(11.8,15.2),1.1,_fill(const Color(0xFFA78BFA)));
        break;

      case '3D Biyo-Yazıcı':
        _shadow(canvas,const Rect.fromLTWH(3,4,18,18));
        Rect frame=const Rect.fromLTWH(5,5,14,15);
        canvas.drawRect(frame,_metal(frame));canvas.drawRect(frame,outline);
        canvas.drawLine(const Offset(12,6),const Offset(12,14),_stroke(const Color(0xFF38BDF8),1.1));
        canvas.drawLine(const Offset(8,15),const Offset(16,15),_stroke(const Color(0xFF94A3B8),1.1));
        canvas.drawCircle(const Offset(12,15.5),1.4,_fill(const Color(0xFF34D399)));
        break;

      case 'Biyonik Organ':
        _shadow(canvas,const Rect.fromLTWH(4,4,16,18));
        Path heart=Path()..moveTo(12,19)..cubicTo(4,14,6,7,10,9)..cubicTo(12,4,15,7,14,9)..cubicTo(18,7,20,14,12,19)..close();
        canvas.drawPath(heart,_grad(const Color(0xFFFCA5A5),const Color(0xFFBE123C),const Rect.fromLTWH(6,6,12,13)));canvas.drawPath(heart,outline);
        canvas.drawLine(const Offset(12,10),const Offset(12,17),_stroke(const Color(0xFF93C5FD),.9));
        break;

      case 'Biyoçip':
        _shadow(canvas,const Rect.fromLTWH(4,4,16,17));
        Rect chip=const Rect.fromLTWH(6,6,12,12);
        canvas.drawRRect(RRect.fromRectAndRadius(chip,const Radius.circular(1.2)),_gold(chip));canvas.drawRRect(RRect.fromRectAndRadius(chip,const Radius.circular(1.2)),outline);
        canvas.drawCircle(const Offset(12,12),2,_fill(const Color(0xFF0F172A)));
        for(int i=0;i<4;i++){canvas.drawLine(Offset(6,8+i*2.7),Offset(4.5,8+i*2.7),outline);canvas.drawLine(Offset(18,8+i*2.7),Offset(19.5,8+i*2.7),outline);}
        break;

      case 'Klon Canlı':
        _shadow(canvas,const Rect.fromLTWH(4,4,16,18));
        canvas.drawOval(const Rect.fromLTWH(6,5,12,15),_fill(const Color(0xFFECFCCB)));canvas.drawOval(const Rect.fromLTWH(6,5,12,15),outline);
        canvas.drawOval(const Rect.fromLTWH(10,6.5,2,12),_stroke(const Color(0xFF65A30D),1));
        canvas.drawOval(const Rect.fromLTWH(12,6.5,2,12),_stroke(const Color(0xFF22C55E),1));
        break;

      // =========================
      // 15) UZAY
      // =========================
      case 'Roket Motoru':
        _shadow(canvas,const Rect.fromLTWH(4,4,16,18));
        Path motor=Path()..moveTo(8,6)..lineTo(16,6)..lineTo(15,11)..lineTo(17,16)..lineTo(7,16)..lineTo(9,11)..close();
        canvas.drawPath(motor,_metal(const Rect.fromLTWH(7,6,10,10)));canvas.drawPath(motor,outline);
        Path flame=Path()..moveTo(9,16)..quadraticBezierTo(12,19,11,22)..quadraticBezierTo(15,19,15,16)..close();
        canvas.drawPath(flame,_grad(const Color(0xFFFDE047),const Color(0xFFEA580C),const Rect.fromLTWH(9,16,6,6)));
        break;

      case 'Uydu':
        _shadow(canvas,const Rect.fromLTWH(2,7,20,14));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8,9,8,7),const Radius.circular(1)),_metal(const Rect.fromLTWH(8,9,8,7)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8,9,8,7),const Radius.circular(1)),outline);
        canvas.drawRect(const Rect.fromLTWH(3,8,5,9),_glass(const Rect.fromLTWH(3,8,5,9)));
        canvas.drawRect(const Rect.fromLTWH(16,8,5,9),_glass(const Rect.fromLTWH(16,8,5,9)));
        break;

      case 'Uzay Mekiği':
        _shadow(canvas,const Rect.fromLTWH(2,5,20,16));
        Path shuttle=Path()..moveTo(12,4)..lineTo(17,11)..lineTo(15,17)..lineTo(12,20)..lineTo(9,17)..lineTo(7,11)..close();
        canvas.drawPath(shuttle,_metal(const Rect.fromLTWH(7,4,10,16)));canvas.drawPath(shuttle,outline);
        canvas.drawLine(const Offset(10,9),const Offset(14,9),_stroke(const Color(0xFF0EA5E9),.9));
        break;

      case 'Ay İniş Aracı':
        _shadow(canvas,const Rect.fromLTWH(3,8,18,13));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8,8,8,7),const Radius.circular(1)),_gold(const Rect.fromLTWH(8,8,8,7)));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8,8,8,7),const Radius.circular(1)),outline);
        for(final x in [7.0,17.0]){canvas.drawLine(Offset(x,15),Offset(x-2,20),outline);canvas.drawLine(Offset(x,15),Offset(x+2,20),outline);}
        canvas.drawCircle(const Offset(12,11),1,_fill(const Color(0xFF0F172A)));
        break;

      case 'Yıldız Gemisi':
        _shadow(canvas,const Rect.fromLTWH(2,5,20,16));
        Path ship=Path()..moveTo(3,15)..lineTo(12,4)..lineTo(21,15)..lineTo(17,17)..lineTo(7,17)..close();
        canvas.drawPath(ship,_grad(const Color(0xFFE2E8F0),const Color(0xFF334155),const Rect.fromLTWH(3,4,18,13)));canvas.drawPath(ship,outline);
        canvas.drawCircle(const Offset(12,12),2,_fill(const Color(0xFF38BDF8)));
        canvas.drawPath(Path()..moveTo(7,17)..lineTo(9,21)..lineTo(12,17)..lineTo(15,21)..lineTo(17,17)..close(),_grad(const Color(0xFFFDE047),const Color(0xFFEA580C),const Rect.fromLTWH(7,17,10,4)));
        break;

      default:
        _card(canvas, const Rect.fromLTWH(5,5,14,14));
        canvas.drawCircle(const Offset(12,12),4,_fill(const Color(0xFF38BDF8)));
        canvas.drawCircle(const Offset(12,12),4,outline);
        break;
    }

    if (muted) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProductVectorPainter oldDelegate) =>
      oldDelegate.name != name || oldDelegate.tint != tint;
}

class _FactoryAnimatedMoneyText extends ImplicitlyAnimatedWidget {
  final double money;
  final TextStyle style;
  final String Function(double) formatNum;
  final String prefix;

  const _FactoryAnimatedMoneyText({
    required this.money,
    required this.style,
    required this.formatNum,
    this.prefix = '\$',
    super.duration = const Duration(milliseconds: 500),
  });

  @override
  ImplicitlyAnimatedWidgetState<_FactoryAnimatedMoneyText> createState() =>
      _FactoryAnimatedMoneyTextState();
}

class _FactoryAnimatedMoneyTextState
    extends AnimatedWidgetBaseState<_FactoryAnimatedMoneyText> {
  Tween<double>? _moneyTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _moneyTween = visitor(
      _moneyTween,
      widget.money,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final value = _moneyTween?.evaluate(animation) ?? widget.money;
    return Text(
      '${widget.prefix}${widget.formatNum(value)}',
      style: widget.style,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class FactoryInsideModal extends StatefulWidget {
  final String factoryId; 
  final String Function(double) formatNum;
  const FactoryInsideModal({super.key, required this.factoryId, required this.formatNum});
  @override State<FactoryInsideModal> createState() => _FactoryInsideModalState();
}

class _FactoryInsideModalState extends State<FactoryInsideModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override 
  void initState() { 
    super.initState(); 
    _tabController = TabController(length: 2, vsync: this); 
  }
  
  @override 
  void dispose() { 
    _tabController.dispose(); 
    super.dispose(); 
  }

  @override 
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final currentFac = gameState.factories.firstWhere((f) => f.id == widget.factoryId);
        final localizedFactoryName = TranslationService.instance.factoryName(
          currentFac.id,
          fallback: currentFac.name,
        );
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.86, 
          decoration: BoxDecoration(
            color: _uiSurface(context), 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.black, width: 4.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -6))],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 56, height: 8,
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.neonCyan, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)),
                      child: SizedBox(width: 28, height: 28, child: CustomPaint(painter: _FactoryHeavyIconPainter(type: 'factory', color: adaptiveIconColor(context, Colors.white) ?? Colors.white))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              localizedFactoryName.toUpperCase(), 
                              style: AppTheme.titleStyle(fontSize: 20).copyWith(color: Colors.black, shadows: []),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Aşama ${currentFac.currentStage + 1}  •  Tesis: ${currentFac.totalLevel}/300', 
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _FactoryAnimatedMoneyText(money: gameState.money, formatNum: widget.formatNum, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(color: _uiSoftSurface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3)),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black, width: 2)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.black,
                    unselectedLabelColor: AppColors.textMuted,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 18, height: 18, child: Builder(builder: (tabContext) => CustomPaint(painter: _FactoryHeavyIconPainter(type: 'touch', color: IconTheme.of(tabContext).color ?? Colors.black)))), const SizedBox(width: 8), const Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text("ÜRETİM BANDI")))])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 18, height: 18, child: Builder(builder: (tabContext) => CustomPaint(painter: _FactoryHeavyIconPainter(type: 'upgrade', color: IconTheme.of(tabContext).color ?? Colors.black)))), const SizedBox(width: 8), const Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text("TESİS GELİŞTİRME")))])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: currentFac.products.length, 
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final prod = currentFac.products[index];
                        if (prod.level == 0) return const SizedBox.shrink(); 
                        return ProductionLineWidget(
                          key: ValueKey('prodline_${currentFac.id}_${prod.name}'),
                          factoryId: currentFac.id,
                          productIndex: index,
                          product: prod, 
                          multiplier: gameState.manualProductionMultiplier(currentFac.id, index),
                          formatNum: widget.formatNum, 
                          onProduceComplete: () => gameState.completeManualProduction(currentFac.id, index),
                        );
                      },
                    ),

                    ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: currentFac.products.length, 
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final prod = currentFac.products[index];
                        final localizedProductName =
                            TranslationService.instance.productName(
                          currentFac.id,
                          index,
                          fallback: prod.name,
                        );
                        const unlockLevels = <int>[0, 30, 60, 90, 120];
                        bool canUnlock = prod.level > 0 || currentFac.totalLevel >= unlockLevels[index];

                        if (!canUnlock) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: _uiSoftSurface(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black, width: 3)),
                            child: Row(
                              children: [
                                SizedBox.square(
                                  dimension: 52,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(color: _uiSurface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 2)),
                                    child: Stack(
                                      clipBehavior: Clip.hardEdge,
                                      children: [
                                        Center(child: ProductSvgIcon(name: prod.name, size: 28, color: AppColors.textMuted)),
                                        Positioned(
                                          right: 3,
                                          bottom: 3,
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                                            child: const Icon(Icons.lock_rounded, size: 11, color: Colors.black),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(localizedProductName, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 15)),
                                      const SizedBox(height: 6),
                                      FittedBox(fit: BoxFit.scaleDown, child: Text('Tesisi toplam Seviye ${unlockLevels[index]} yapın', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        double cost = gameState.productUpgradeCost(currentFac.id, index) ?? prod.upgradeCost;
                        bool isMax = prod.level >= 60;
                        bool canAfford = gameState.money >= cost && !isMax;
                        double progressRatio = (prod.level / 60.0).clamp(0.0, 1.0);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _uiSurface(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: canAfford ? AppColors.neonCyan : Colors.black, width: 3.0),
                            boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                      color: canAfford ? const Color(0xFFE0F2FE) : _uiSoftSurface(context),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: canAfford ? AppColors.neonCyan : Colors.black, width: 3),
                                    ),
                                    child: Center(
                                      child: ProductSvgIcon(
                                        name: prod.name,
                                        size: 28,
                                        color: canAfford ? Colors.black : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(localizedProductName, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8, runSpacing: 6,
                                          children: [
                                            Text('Lvl ${prod.level}/60', style: TextStyle(color: isMax ? AppColors.profit : Colors.black, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)),
                                              child: Text('+\$${widget.formatNum(prod.passiveIncome)}/s', style: const TextStyle(color: AppColors.profit, fontSize: 11, fontWeight: FontWeight.w900)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _FactoryHeavyTycoonButton(
                                    width: 90, height: 52,
                                    color: isMax ? _uiMutedSurface(context) : (canAfford ? AppColors.gold : _uiSoftSurface(context)),
                                    shadowColor: isMax ? Colors.grey.shade400 : (canAfford ? Colors.orange.shade700 : Colors.grey.shade400),
                                    onPressed: isMax || !canAfford 
                                        ? null 
                                        : () {
                                            HapticFeedback.lightImpact();
                                            AudioService.instance.playSfx('cash.mp3');
                                            gameState.upgradeProduct(currentFac.id, index);
                                          },
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(isMax ? 'MAKS' : 'GELİŞTİR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: isMax || !canAfford ? Colors.grey.shade600 : Colors.black)),
                                        ),
                                        if (!isMax) ...[
                                          const SizedBox(height: 4),
                                          FittedBox(fit: BoxFit.scaleDown, child: Text('\$${widget.formatNum(cost)}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono', color: canAfford ? Colors.black : Colors.grey.shade600))),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(8)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progressRatio,
                                    minHeight: 10,
                                    backgroundColor: _uiSoftSurface(context),
                                    valueColor: AlwaysStoppedAnimation<Color>(isMax ? AppColors.profit : (canAfford ? AppColors.neonCyan : Colors.grey.shade400)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProductionLineWidget extends StatefulWidget {
  final String factoryId;
  final int productIndex;
  final FactoryProduct product; 
  final double multiplier; 
  final String Function(double) formatNum; 
  final VoidCallback onProduceComplete;
  
  const ProductionLineWidget({
    super.key,
    required this.factoryId,
    required this.productIndex,
    required this.product, 
    required this.multiplier, 
    required this.formatNum, 
    required this.onProduceComplete,
  });

  @override 
  State<ProductionLineWidget> createState() => _ProductionLineWidgetState();
}

class _ProductionLineWidgetState extends State<ProductionLineWidget> with TickerProviderStateMixin {
  final List<int> _tokenIds = [];
  final List<_FloatingTextItem> _floatingTexts = [];
  int _counter = 0;
  int _packingTrigger = 0;

  late final AnimationController _beltAnimController;

  @override
  void initState() {
    super.initState();
    _beltAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _beltAnimController.dispose();
    super.dispose();
  }

  void _triggerProduction() {
    final int currentId = _counter++;
    final double rewardAmount = widget.product.manualIncome * widget.multiplier;
    final double randomOffsetX = (math.Random().nextDouble() * 30) - 15;
    widget.onProduceComplete();
    try { AudioService.instance.playSfx('cash.mp3'); } catch (_) {}

    setState(() {
      _tokenIds.add(currentId);
      _floatingTexts.add(_FloatingTextItem(key: UniqueKey(), id: currentId, text: '+\$${widget.formatNum(rewardAmount)}', offsetX: randomOffsetX));
      if (_tokenIds.length > 8) _tokenIds.removeAt(0);
      if (_floatingTexts.length > 8) _floatingTexts.removeAt(0);
    });
  }

  void _onTokenReachedEnd(int id) {
    if (!mounted) return;
    setState(() {
      _tokenIds.remove(id);
      _packingTrigger++;
    });
  }

  void _onTextAnimationComplete(int id) {
    if (!mounted) return;
    setState(() { _floatingTexts.removeWhere((item) => item.id == id); });
  }

  @override 
  Widget build(BuildContext context) {
    final double incomePerClick = widget.product.manualIncome * widget.multiplier;
    final localizedProductName = TranslationService.instance.productName(
      widget.factoryId,
      widget.productIndex,
      fallback: widget.product.name,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _uiSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 4.0),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 0, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)),
                child: Text('Lvl ${widget.product.level}', style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(localizedProductName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.trending_up_rounded, color: AppColors.profit, size: 18),
                      const SizedBox(width: 6),
                      Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('+\$${widget.formatNum(incomePerClick)}', style: const TextStyle(color: AppColors.profit, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'SpaceMono')))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final double btnWidth = constraints.maxWidth < 340 ? 90.0 : 100.0;
              final double depotWidth = constraints.maxWidth < 340 ? 52.0 : 60.0;

              return SizedBox(
                height: 70,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 64,
                      decoration: BoxDecoration(color: _uiMutedSurface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3.0)),
                      child: Row(
                        children: [
                          Container(
                            width: depotWidth,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: _uiSurface(context),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                              border: const Border(right: BorderSide(color: Colors.black, width: 3.0)),
                            ),
                            child: PackingTransferStation(
                              productName: widget.product.name,
                              trigger: _packingTrigger,
                            ),
                          ),
                          Expanded(
                            child: ClipRect(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: AnimatedBuilder(
                                      animation: _beltAnimController,
                                      builder: (context, child) {
                                        return CustomPaint(painter: ContinuousConveyorTrackPainter(progress: _beltAnimController.value));
                                      },
                                    ),
                                  ),
                                  ..._tokenIds.map((id) => SelfDismissingToken(
                                    key: ValueKey('token_$id'), id: id, productName: widget.product.name, onComplete: _onTokenReachedEnd,
                                  )),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: btnWidth),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -2, top: -2, bottom: 4, width: btnWidth + 4,
                      child: PreciseIndustrialButton(
                        width: btnWidth + 4, height: 68, onTap: _triggerProduction,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CustomPaint(painter: _FactoryHeavyIconPainter(type: 'touch', color: Colors.black))),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('ÜRET', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ..._floatingTexts.map((fItem) => Positioned(
                      key: fItem.key, right: (btnWidth / 2 - 24) - fItem.offsetX, bottom: 50,
                      child: SelfDismissingIncomeText(id: fItem.id, text: fItem.text, onComplete: _onTextAnimationComplete),
                    )),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PackingTransferStation extends StatefulWidget {
  final String productName;
  final int trigger;

  const PackingTransferStation({
    super.key,
    required this.productName,
    required this.trigger,
  });

  @override
  State<PackingTransferStation> createState() => _PackingTransferStationState();
}

class _PackingTransferStationState extends State<PackingTransferStation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _playing = false;
  bool _pendingReplay = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
  }

  @override
  void didUpdateWidget(covariant PackingTransferStation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger > oldWidget.trigger) {
      // Collapse a burst of arrivals into at most one additional cycle. This
      // keeps the station alive while the player is producing rapidly without
      // leaving a long queue of boxes running after production has stopped.
      if (_playing) {
        _pendingReplay = true;
      } else {
        _playCycle();
      }
    }
  }

  void _playCycle() {
    if (!mounted || _playing) return;
    setState(() => _playing = true);
    _controller.forward(from: 0.0).whenComplete(() {
      if (!mounted) return;

      final bool replayLatest = _pendingReplay;
      _pendingReplay = false;
      setState(() => _playing = false);

      if (replayLatest) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _playCycle();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(double value, double start, double end) {
    return ((value - start) / (end - start)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_playing) {
      return Center(
        child: SizedBox(
          width: 42,
          height: 42,
          child: CustomPaint(
            painter: _PackingBoxPainter(closeProgress: 0.0),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final drop = Curves.easeIn.transform(_phase(t, 0.00, 0.34));
        final close = Curves.easeInOut.transform(_phase(t, 0.28, 0.62));
        final boxFall = Curves.easeInCubic.transform(_phase(t, 0.70, 1.00));
        return ClipRect(
          child: Transform.translate(
            offset: Offset(0, boxFall * 52.0),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Draw the product first so the box/front wall stays in front of it
                // while the product drops inside.
                Positioned(
                  top: ui.lerpDouble(-18.0, 28.0, drop)!,
                  child: Opacity(
                    opacity: (1.0 - close).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: ui.lerpDouble(1.0, 0.70, drop)!,
                      child: DepthProductIcon(
                        name: widget.productName,
                        size: 25,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 26,
                  child: SizedBox(
                    width: 44,
                    height: 36,
                    child: CustomPaint(
                      painter: _PackingBoxPainter(closeProgress: close),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PackingBoxPainter extends CustomPainter {
  final double closeProgress;

  const _PackingBoxPainter({required this.closeProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;
    final body = Paint()
      ..color = const Color(0xFFD99A4E)
      ..style = PaintingStyle.fill;
    final flap = Paint()
      ..color = const Color(0xFFF2BD6C)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final top = h * 0.34;
    final bottom = h * 0.94;
    final left = w * 0.10;
    final right = w * 0.90;
    final mid = w * 0.50;

    final boxRect = Rect.fromLTRB(left, top, right, bottom);
    canvas.drawRect(boxRect, body);
    canvas.drawRect(boxRect, outline);
    canvas.drawLine(Offset(mid, top), Offset(mid, bottom), outline);

    final openLift = h * 0.23 * (1.0 - closeProgress);
    final closedInset = h * 0.12 * closeProgress;

    final leftFlap = Path()
      ..moveTo(left, top)
      ..lineTo(mid, top)
      ..lineTo(mid - w * 0.08, top - openLift - closedInset)
      ..lineTo(left - w * 0.06 * (1.0 - closeProgress), top - openLift * 0.55 - closedInset)
      ..close();
    final rightFlap = Path()
      ..moveTo(mid, top)
      ..lineTo(right, top)
      ..lineTo(right + w * 0.06 * (1.0 - closeProgress), top - openLift * 0.55 - closedInset)
      ..lineTo(mid + w * 0.08, top - openLift - closedInset)
      ..close();

    canvas.drawPath(leftFlap, flap);
    canvas.drawPath(leftFlap, outline);
    canvas.drawPath(rightFlap, flap);
    canvas.drawPath(rightFlap, outline);

    if (closeProgress > 0.70) {
      final tapeOpacity = ((closeProgress - 0.70) / 0.30).clamp(0.0, 1.0);
      final tape = Paint()
        ..color = const Color(0xFFFDE68A).withValues(alpha: tapeOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(mid, top - h * 0.06), width: w * 0.13, height: h * 0.14),
        tape,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PackingBoxPainter oldDelegate) => oldDelegate.closeProgress != closeProgress;
}

class _FloatingTextItem { final Key key; final int id; final String text; final double offsetX; _FloatingTextItem({required this.key, required this.id, required this.text, required this.offsetX}); }

class ContinuousConveyorTrackPainter extends CustomPainter {
  final double progress;
  ContinuousConveyorTrackPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint railPaint = Paint()..color = Colors.black..strokeWidth = 3.0..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 10), Offset(size.width, 10), railPaint);
    canvas.drawLine(Offset(0, size.height - 10), Offset(size.width, size.height - 10), railPaint);

    final Paint rollerShadow = Paint()..color = Colors.black26..strokeWidth = 6.0..strokeCap = StrokeCap.round;
    final Paint rollerPaint = Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 4.0..strokeCap = StrokeCap.round;
    const double step = 24.0;
    final double offset = progress * step;

    for (double x = -step - offset; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x + 2, 12), Offset(x + 2, size.height - 12), rollerShadow);
      canvas.drawLine(Offset(x, 12), Offset(x, size.height - 12), rollerPaint);
    }
  }
  @override bool shouldRepaint(covariant ContinuousConveyorTrackPainter oldDelegate) => oldDelegate.progress != progress;
}


class DepthProductIcon extends StatelessWidget {
  final String name;
  final double size;

  const DepthProductIcon({
    super.key,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final double depthOffset = math.max(1.8, size * 0.075);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(depthOffset, depthOffset),
            child: Opacity(
              opacity: 0.72,
              child: ProductSvgIcon(
                name: name,
                size: size,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          ProductSvgIcon(
            name: name,
            size: size,
            color: Colors.black,
          ),
        ],
      ),
    );
  }
}

class SelfDismissingToken extends StatefulWidget {
  final int id;
  final String productName;
  final void Function(int id) onComplete;

  const SelfDismissingToken({super.key, required this.id, required this.productName, required this.onComplete});

  @override
  State<SelfDismissingToken> createState() => _SelfDismissingTokenState();
}

class _SelfDismissingTokenState extends State<SelfDismissingToken> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final double _rotation;
  late final double _verticalOffset;
  late final double _scale;

  @override
  void initState() {
    super.initState();
    final random = math.Random(widget.id * 7919 + widget.productName.hashCode);
    _rotation = random.nextDouble() * math.pi * 2.0; // Full 0-360 degree rotation
    _verticalOffset = (random.nextDouble() * 8.0) - 4.0;
    _scale = 0.92 + (random.nextDouble() * 0.16);

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    _slideAnimation = Tween<double>(begin: 1.0, end: -1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onComplete(widget.id);
        });
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Align(
          alignment: Alignment(_slideAnimation.value, 0.0),
          child: Transform.translate(
            offset: Offset(0, _verticalOffset),
            child: Transform.rotate(
              angle: _rotation,
              child: Transform.scale(
                scale: _scale,
                child: DepthProductIcon(
                  name: widget.productName,
                  size: 30,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SelfDismissingIncomeText extends StatefulWidget {
  final int id; final String text; final void Function(int id) onComplete;
  const SelfDismissingIncomeText({super.key, required this.id, required this.text, required this.onComplete});
  @override State<SelfDismissingIncomeText> createState() => _SelfDismissingIncomeTextState();
}

class _SelfDismissingIncomeTextState extends State<SelfDismissingIncomeText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller; late final Animation<double> _fadeAnimation; late final Animation<Offset> _slideAnimation; late final Animation<double> _scaleAnimation;
  @override void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -1.9)).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scaleAnimation = TweenSequence<double>([TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)), weight: 35), TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 65)]).animate(_controller);
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)));
    _controller.addStatusListener((status) { if (status == AnimationStatus.completed) { WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) widget.onComplete(widget.id); }); } });
    _controller.forward();
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return SlideTransition(position: _slideAnimation, child: FadeTransition(opacity: _fadeAnimation, child: ScaleTransition(scale: _scaleAnimation, child: Text(widget.text, style: const TextStyle(color: Color(0xFF22C55E), fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'SpaceMono', shadows: [Shadow(color: Colors.black, blurRadius: 0, offset: Offset(1, 2))])))));
  }
}

class PreciseIndustrialButton extends StatefulWidget {
  final VoidCallback onTap; final Widget child; final double width; final double height;
  const PreciseIndustrialButton({super.key, required this.onTap, required this.child, required this.width, required this.height});
  @override State<PreciseIndustrialButton> createState() => _PreciseIndustrialButtonState();
}

class _PreciseIndustrialButtonState extends State<PreciseIndustrialButton> {
  bool _isPressed = false;
  @override Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () { HapticFeedback.lightImpact(); setState(() => _isPressed = false); widget.onTap(); },
      child: SizedBox(
        width: widget.width, height: widget.height,
        child: Stack(
          children: [
            Positioned(bottom: 0, left: 0, right: 0, top: 6, child: Container(decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3.0)))),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 30),
              bottom: _isPressed ? 0 : 6, left: 0, right: 0, top: _isPressed ? 6 : 0,
              child: Container(decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 3.0)), child: Center(child: widget.child)),
            ),
          ],
        ),
      ),
    );
  }
}
