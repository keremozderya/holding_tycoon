import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Holding Tycoon factory renderer.
///
/// Visual target: modular, isometric heavy-industry diorama with dark charcoal
/// buildings, gold/yellow industrial accents, corrugated roofs, HVAC units,
/// chimneys, loading docks, fenced service yards and sector-specific machinery.
///
/// factoryId: 1..15
/// stage: 0 = beginning, 1 = middle, 2 = max
class FactoryDrawingRenderer {
  FactoryDrawingRenderer._();

  // --------------------------------------------------------------------------
  // Palette
  // --------------------------------------------------------------------------

  static const Color ink = Color(0xFF0A0F14);
  static const Color charcoal = Color(0xFF20272E);
  static const Color charcoal2 = Color(0xFF2D353E);
  static const Color charcoal3 = Color(0xFF39434E);
  static const Color steel = Color(0xFF89939D);
  static const Color steel2 = Color(0xFFB7C0C8);
  static const Color concrete = Color(0xFF787F87);
  static const Color concrete2 = Color(0xFFA5ABB1);
  static const Color gold = Color(0xFFFFB61F);
  static const Color gold2 = Color(0xFFFFD75A);
  static const Color cyan = Color(0xFF4FD1FF);
  static const Color green = Color(0xFF4ED07A);
  static const Color red = Color(0xFFFF5C5C);
  static const Color purple = Color(0xFFA97BFF);
  static const Color white = Color(0xFFF6F8FA);

  static const double ox = 90;
  static const double oy = 131;
  static const double sx = 2.25;
  static const double sy = 1.18;

  static void paint(
    Canvas canvas,
    Size size, {
    required String factoryId,
    required int stage,
  }) {
    final id = int.tryParse(factoryId) ?? 1;
    final s = stage.clamp(0, 2).toInt();

    canvas.save();
    canvas.scale(size.width / 180, size.height / 180);

    _shadow(canvas, s);
    _industrialBase(canvas, s);

    switch (id) {
      case 1:
        _textile(canvas, s);
        break;
      case 2:
        _furniture(canvas, s);
        break;
      case 3:
        _agriculture(canvas, s);
        break;
      case 4:
        _dairy(canvas, s);
        break;
      case 5:
        _meat(canvas, s);
        break;
      case 6:
        _food(canvas, s);
        break;
      case 7:
        _mine(canvas, s);
        break;
      case 8:
        _chemical(canvas, s);
        break;
      case 9:
        _automotive(canvas, s);
        break;
      case 10:
        _pharma(canvas, s);
        break;
      case 11:
        _electronics(canvas, s);
        break;
      case 12:
        _ai(canvas, s);
        break;
      case 13:
        _energy(canvas, s);
        break;
      case 14:
        _biotech(canvas, s);
        break;
      case 15:
        _space(canvas, s);
        break;
      default:
        _generic(canvas, s);
    }

    canvas.restore();
  }

  // --------------------------------------------------------------------------
  // Core geometry / paint
  // --------------------------------------------------------------------------

  static Paint _fill(Color c) => Paint()
    ..style = PaintingStyle.fill
    ..color = c;

  static Paint _stroke([Color c = ink, double w = 1.9]) => Paint()
    ..style = PaintingStyle.stroke
    ..color = c
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  static Offset _p(double x, double y, [double z = 0]) => Offset(
        ox + (x - y) * sx,
        oy + (x + y) * sy - z,
      );

  static Path _poly(List<Offset> pts) => Path()
    ..moveTo(pts.first.dx, pts.first.dy)
    ..addPolygon(pts, true);

  static Color _lighten(Color c, double t) => Color.lerp(c, Colors.white, t)!;
  static Color _darken(Color c, double t) => Color.lerp(c, ink, t)!;

  static void _shadow(Canvas canvas, int stage) {
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(90, 145),
        width: 158 + stage * 7,
        height: 30 + stage * 2,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  static void _prism(
    Canvas canvas,
    double x,
    double y,
    double w,
    double d,
    double h, {
    required Color top,
    required Color left,
    required Color right,
    double outline = 1.8,
  }) {
    final a = _p(x, y, h);
    final b = _p(x + w, y, h);
    final c = _p(x + w, y + d, h);
    final d0 = _p(x, y + d, h);
    final a0 = _p(x, y);
    final b0 = _p(x + w, y);
    final c0 = _p(x + w, y + d);
    final d1 = _p(x, y + d);

    final leftFace = [a, d0, d1, a0];
    final rightFace = [b, c, c0, b0];
    final topFace = [a, b, c, d0];

    canvas.drawPath(_poly(leftFace), _fill(left));
    canvas.drawPath(_poly(rightFace), _fill(right));
    canvas.drawPath(_poly(topFace), _fill(top));

    canvas.drawPath(_poly(leftFace), _stroke(ink, outline));
    canvas.drawPath(_poly(rightFace), _stroke(ink, outline));
    canvas.drawPath(_poly(topFace), _stroke(ink, outline));
  }

  static void _industrialBase(Canvas canvas, int stage) {
    _prism(
      canvas,
      4.5,
      4.5,
      31,
      27,
      2,
      top: const Color(0xFF666D74),
      left: const Color(0xFF4C535A),
      right: const Color(0xFF3F464D),
    );

    // main internal road
    _quad(canvas, 15.5, 17.0, 7.5, 13.7, const Color(0xFF4D545B));
    _quad(canvas, 21.0, 22.0, 10.0, 5.7, const Color(0xFF4D545B));

    // lane markings
    for (int i = 0; i < 5; i++) {
      final y = 18.4 + i * 2.3;
      canvas.drawLine(_p(18.9, y, 2.1), _p(19.8, y, 2.1), _stroke(gold2, .9));
    }

    // fence
    _fence(canvas, 5.1, 5.0, 35.0, 5.0, 6);
    _fence(canvas, 35.0, 5.0, 35.0, 31.0, 5);
    _fence(canvas, 5.0, 5.0, 5.0, 31.0, 5);
    _fence(canvas, 5.0, 31.0, 15.7, 31.0, 2);
    _fence(canvas, 23.0, 31.0, 35.0, 31.0, 2);

    // entrance gate
    for (final gx in [16.0, 22.5]) {
      _prism(canvas, gx, 30.2, .7, .7, 7, top: gold, left: gold, right: _darken(gold, .2));
    }
    canvas.drawLine(_p(16.6, 30.55, 5.4), _p(22.5, 30.55, 5.4), _stroke(ink, 1.1));

    // generic small yard hardware
    _crate(canvas, 7.0, 21.3, gold);
    _crate(canvas, 8.9, 20.1, steel2);
    if (stage >= 1) _utilityCabinet(canvas, 31.5, 23.5);
    if (stage >= 2) _lightPole(canvas, 8.0, 27.8);
  }

  static void _quad(Canvas canvas, double x, double y, double w, double d, Color color) {
    final pts = [_p(x, y, 2.05), _p(x + w, y, 2.05), _p(x + w, y + d, 2.05), _p(x, y + d, 2.05)];
    canvas.drawPath(_poly(pts), _fill(color));
    canvas.drawPath(_poly(pts), _stroke(ink, .9));
  }

  static void _fence(Canvas canvas, double x1, double y1, double x2, double y2, int posts) {
    final a = _p(x1, y1, 2.1);
    final b = _p(x2, y2, 2.1);
    canvas.drawLine(a, b, _stroke(ink, 1.0));
    for (int i = 0; i <= posts; i++) {
      final t = i / posts;
      final x = x1 + (x2 - x1) * t;
      final y = y1 + (y2 - y1) * t;
      canvas.drawLine(_p(x, y, 2), _p(x, y, 7), _stroke(ink, 1.1));
    }
  }

  // --------------------------------------------------------------------------
  // Modular industrial building kit
  // --------------------------------------------------------------------------

  static void _hangar(
    Canvas canvas,
    double x,
    double y,
    double w,
    double d,
    double h, {
    Color accent = gold,
    int roofVents = 2,
    int skylights = 2,
    bool loadingDoor = true,
    bool sideWindows = true,
  }) {
    _prism(
      canvas,
      x,
      y,
      w,
      d,
      h,
      top: charcoal3,
      left: charcoal2,
      right: charcoal,
    );

    // gold roof perimeter
    final r = [_p(x, y, h + .6), _p(x + w, y, h + .6), _p(x + w, y + d, h + .6), _p(x, y + d, h + .6)];
    canvas.drawPath(_poly(r), _stroke(accent, 1.5));

    // corrugation lines
    for (double t = .12; t < .95; t += .11) {
      canvas.drawLine(_p(x + w * t, y, h + .1), _p(x + w * t, y + d, h + .1), _stroke(_lighten(charcoal3, .18), .55));
    }

    // long skylights
    for (int i = 0; i < skylights; i++) {
      final yy = y + 1.0 + i * (d / math.max(1, skylights));
      final a = _p(x + 1.0, yy, h + 1.0);
      final b = _p(x + w - 1.0, yy, h + 1.0);
      final c = _p(x + w - 1.0, yy + .7, h + 1.0);
      final d0 = _p(x + 1.0, yy + .7, h + 1.0);
      canvas.drawPath(_poly([a, b, c, d0]), _fill(_darken(accent, .12)));
      canvas.drawPath(_poly([a, b, c, d0]), _stroke(ink, .9));
    }

    // roof HVAC / vents
    for (int i = 0; i < roofVents; i++) {
      final vx = x + 1.4 + (i % 3) * 2.8;
      final vy = y + 1.8 + (i ~/ 3) * 2.2;
      _hvac(canvas, vx, vy, .95);
    }

    // large roller shutter
    if (loadingDoor) {
      _rollerDoor(canvas, x + w, y + d * .36, h, d * .38, accent);
    }

    // left-side windows
    if (sideWindows) {
      for (int i = 0; i < 3; i++) {
        _windowPanel(canvas, x, y + 1.2 + i * 1.8, h * .55, accent);
      }
    }

    // wall accent strip
    canvas.drawLine(_p(x + w, y + .2, h * .32), _p(x + w, y + d - .2, h * .32), _stroke(accent, 1.1));
  }

  static void _rollerDoor(Canvas canvas, double x, double y, double h, double depth, Color accent) {
    final a = _p(x, y, h * .15);
    final b = _p(x, y + depth, h * .15);
    final c = _p(x, y + depth, h * .72);
    final d = _p(x, y, h * .72);
    canvas.drawPath(_poly([a, b, c, d]), _fill(const Color(0xFF171C21)));
    canvas.drawPath(_poly([a, b, c, d]), _stroke(accent, 1.4));
    for (int i = 1; i < 5; i++) {
      final t = i / 5;
      canvas.drawLine(_lerp(a, d, t), _lerp(b, c, t), _stroke(_lighten(charcoal, .3), .6));
    }
    canvas.drawLine(a, b, _stroke(gold, 1.1));
  }

  static Offset _lerp(Offset a, Offset b, double t) => Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);

  static void _windowPanel(Canvas canvas, double x, double y, double z, Color accent) {
    final a = _p(x, y, z - 4);
    final b = _p(x, y + 1.2, z - 4);
    final c = _p(x, y + 1.2, z + 2);
    final d = _p(x, y, z + 2);
    canvas.drawPath(_poly([a, b, c, d]), _fill(const Color(0xFF29343C)));
    canvas.drawPath(_poly([a, b, c, d]), _stroke(accent, .9));
    canvas.drawLine(_lerp(a, d, .5), _lerp(b, c, .5), _stroke(_lighten(accent, .25), .55));
  }

  static void _hvac(Canvas canvas, double x, double y, double scale) {
    _prism(canvas, x, y, 2.5 * scale, 2.0 * scale, 2.4 * scale, top: steel2, left: steel, right: _darken(steel, .2), outline: 1.1);
    final c = _p(x + 1.25 * scale, y + 1.0 * scale, 2.6 * scale);
    canvas.drawCircle(c, 3.0 * scale, _fill(const Color(0xFF4B5560)));
    canvas.drawCircle(c, 3.0 * scale, _stroke(ink, .9));
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      canvas.drawLine(c, Offset(c.dx + math.cos(a) * 2.2 * scale, c.dy + math.sin(a) * 2.2 * scale), _stroke(ink, .7));
    }
  }

  static void _chimney(Canvas canvas, double x, double y, double h, {double w = 2.3, Color accent = gold, bool smoke = true}) {
    _prism(canvas, x, y, w, w, h, top: charcoal2, left: charcoal3, right: charcoal, outline: 1.4);
    final top = _p(x + w / 2, y + w / 2, h + .8);
    canvas.drawCircle(top, 4.3, _fill(ink));
    canvas.drawCircle(top, 4.3, _stroke(steel2, 1.0));
    for (double z in [h * .62, h * .78]) {
      canvas.drawLine(_p(x, y, z), _p(x + w, y, z), _stroke(accent, 1.3));
    }
    if (smoke) {
      canvas.drawCircle(top.translate(4, -6), 3.4, _fill(Colors.white.withValues(alpha: .25)));
      canvas.drawCircle(top.translate(9, -12), 4.3, _fill(Colors.white.withValues(alpha: .18)));
    }
  }

  static void _tank(Canvas canvas, double x, double y, double h, {double w = 3.5, Color accent = gold}) {
    _prism(canvas, x, y, w, w, h, top: steel2, left: const Color(0xFFCED4DA), right: steel, outline: 1.3);
    for (double z in [h * .33, h * .66]) {
      canvas.drawLine(_p(x, y, z), _p(x + w, y, z), _stroke(accent, 1.0));
    }
    _pipeRack(canvas, x + w, y + .7, 3.8, 6, accent);
  }

  static void _pipeRack(Canvas canvas, double x, double y, double length, double height, Color color) {
    for (double yy in [y, y + .8]) {
      canvas.drawLine(_p(x, yy, 2), _p(x, yy, height), _stroke(ink, 1.1));
      canvas.drawLine(_p(x + length, yy, 2), _p(x + length, yy, height), _stroke(ink, 1.1));
      canvas.drawLine(_p(x, yy, height), _p(x + length, yy, height), _stroke(color, 1.8));
    }
  }

  static void _loadingDock(Canvas canvas, double x, double y, double w, double d) {
    _prism(canvas, x, y, w, d, 1.1, top: concrete2, left: concrete, right: _darken(concrete, .14), outline: 1.0);
    for (int i = 0; i < 3; i++) {
      final xx = x + .6 + i * (w / 3);
      canvas.drawLine(_p(xx, y + d - .1, 1.2), _p(xx + .7, y + d - .1, 1.2), _stroke(gold, .9));
    }
  }

  static void _crate(Canvas canvas, double x, double y, Color color) {
    _prism(canvas, x, y, 2.0, 1.8, 1.7, top: _lighten(color, .18), left: color, right: _darken(color, .16), outline: 1.0);
  }

  static void _barrel(Canvas canvas, double x, double y, Color color) {
    final c = _p(x, y, 3);
    final r = Rect.fromCenter(center: c, width: 7, height: 11);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _fill(color));
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _stroke(ink, 1.0));
    canvas.drawLine(Offset(r.left, r.top + 3), Offset(r.right, r.top + 3), _stroke(ink, .7));
    canvas.drawLine(Offset(r.left, r.bottom - 3), Offset(r.right, r.bottom - 3), _stroke(ink, .7));
  }

  static void _utilityCabinet(Canvas canvas, double x, double y) {
    _prism(canvas, x, y, 2.2, 1.8, 4.8, top: steel2, left: steel, right: _darken(steel, .18), outline: 1.0);
    final c = _p(x + 1.2, y + 1.8, 2.5);
    canvas.drawCircle(c, 1.2, _fill(red));
  }

  static void _lightPole(Canvas canvas, double x, double y) {
    canvas.drawLine(_p(x, y, 2), _p(x, y, 11), _stroke(ink, 1.1));
    final c = _p(x, y, 11);
    canvas.drawCircle(c, 2.0, _fill(gold2));
    canvas.drawCircle(c, 2.0, _stroke(ink, .7));
  }

  static void _forklift(Canvas canvas, double x, double y, {double scale = 1}) {
    final c = _p(x, y, 2.4);
    final body = Rect.fromCenter(center: c, width: 11 * scale, height: 7 * scale);
    canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(2 * scale)), _fill(gold));
    canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(2 * scale)), _stroke(ink, 1.1));
    canvas.drawCircle(c.translate(-4 * scale, 4 * scale), 2.2 * scale, _fill(ink));
    canvas.drawCircle(c.translate(4 * scale, 4 * scale), 2.2 * scale, _fill(ink));
    canvas.drawLine(c.translate(5 * scale, -2 * scale), c.translate(5 * scale, -11 * scale), _stroke(ink, 1.2));
    canvas.drawLine(c.translate(7 * scale, -2 * scale), c.translate(7 * scale, -11 * scale), _stroke(ink, 1.2));
  }

  static void _truck(Canvas canvas, double x, double y, {double scale = 1, Color cab = white}) {
    final c = _p(x, y, 2.2);
    final trailer = Rect.fromCenter(center: c.translate(-5 * scale, 0), width: 20 * scale, height: 9 * scale);
    canvas.drawRRect(RRect.fromRectAndRadius(trailer, Radius.circular(2 * scale)), _fill(steel2));
    canvas.drawRRect(RRect.fromRectAndRadius(trailer, Radius.circular(2 * scale)), _stroke(ink, 1.1));
    final cabRect = Rect.fromCenter(center: c.translate(8 * scale, 0), width: 9 * scale, height: 9 * scale);
    canvas.drawRRect(RRect.fromRectAndRadius(cabRect, Radius.circular(2 * scale)), _fill(cab));
    canvas.drawRRect(RRect.fromRectAndRadius(cabRect, Radius.circular(2 * scale)), _stroke(ink, 1.1));
    for (final dx in [-9.0, -1.0, 9.0]) {
      canvas.drawCircle(c.translate(dx * scale, 5 * scale), 2.1 * scale, _fill(ink));
    }
  }

  static void _sign(Canvas canvas, double x, double y, String text, Color color) {
    final c = _p(x, y, 7);
    final rect = Rect.fromCenter(center: c, width: 34, height: 12);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), _fill(color));
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), _stroke(ink, 1.2));
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.black, fontSize: 7.6, fontWeight: FontWeight.w900, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 4);
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
  }

  // --------------------------------------------------------------------------
  // Sector-specific machinery
  // --------------------------------------------------------------------------

  static void _fabricRoll(Canvas canvas, double x, double y, Color color) {
    final c = _p(x, y, 2.4);
    final r = Rect.fromCenter(center: c, width: 13, height: 8);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), _fill(color));
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), _stroke(ink, 1.0));
    canvas.drawCircle(c.translate(-4, 0), 2.0, _fill(white));
  }

  static void _plankStack(Canvas canvas, double x, double y, int n) {
    for (int i = 0; i < n; i++) {
      _prism(canvas, x + i * .18, y + i * .16, 3.6, .85, .65, top: const Color(0xFFFFC76B), left: const Color(0xFFD58B2B), right: const Color(0xFFA65D12), outline: .8);
    }
  }

  static void _greenhouse(Canvas canvas, double x, double y, double w, double d, double h) {
    _prism(canvas, x, y, w, d, h, top: const Color(0xFF9EDFFF), left: const Color(0xFF8DCBEC), right: const Color(0xFF6FAFCE), outline: 1.2);
    for (double t = .2; t < .9; t += .2) {
      canvas.drawLine(_p(x + w * t, y, h + .1), _p(x + w * t, y + d, h + .1), _stroke(white, .6));
    }
  }

  static void _cropRows(Canvas canvas, double x, double y, int rows, int cols) {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final px = x + c * 1.15;
        final py = y + r * 1.15;
        canvas.drawLine(_p(px, py, 2.1), _p(px, py, 5.3), _stroke(const Color(0xFF2F7D43), .8));
        canvas.drawCircle(_p(px, py, 5.7), 1.2, _fill(green));
      }
    }
  }

  static void _cowPen(Canvas canvas, double x, double y) {
    _fence(canvas, x, y, x + 5, y, 2);
    _fence(canvas, x + 5, y, x + 5, y + 4, 2);
    _fence(canvas, x, y, x, y + 4, 2);
    final c = _p(x + 2.4, y + 2.0, 3.1);
    final body = Rect.fromCenter(center: c, width: 10, height: 6);
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), _fill(white));
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), _stroke(ink, .8));
    canvas.drawCircle(c.translate(-2, 0), 1.4, _fill(ink));
    canvas.drawCircle(c.translate(2, -1), 1.2, _fill(ink));
  }

  static void _meatCrate(Canvas canvas, double x, double y) {
    _crate(canvas, x, y, red);
    final c = _p(x + 1, y + .9, 3.1);
    canvas.drawCircle(c, 1.6, _fill(const Color(0xFFFFC6C6)));
  }

  static void _oreCart(Canvas canvas, double x, double y, double scale) {
    _prism(canvas, x, y, 3.2 * scale, 2.0 * scale, 2.0 * scale, top: charcoal3, left: charcoal2, right: charcoal, outline: 1.0);
    canvas.drawCircle(_p(x + .8 * scale, y + 2.1 * scale, 2), 1.8 * scale, _fill(ink));
    canvas.drawCircle(_p(x + 2.5 * scale, y + 2.1 * scale, 2), 1.8 * scale, _fill(ink));
  }

  static void _mineHeadframe(Canvas canvas, double x, double y, double scale) {
    final topL = _p(x, y, 23 * scale);
    final topR = _p(x + 5 * scale, y, 23 * scale);
    final botL = _p(x + .8 * scale, y + 3, 2);
    final botR = _p(x + 4.2 * scale, y + 3, 2);
    canvas.drawLine(topL, botL, _stroke(steel2, 1.7));
    canvas.drawLine(topR, botR, _stroke(steel2, 1.7));
    canvas.drawLine(topL, topR, _stroke(gold, 1.3));
    canvas.drawCircle(_p(x + 2.5 * scale, y, 20 * scale), 3.5 * scale, _fill(gold));
    canvas.drawCircle(_p(x + 2.5 * scale, y, 20 * scale), 3.5 * scale, _stroke(ink, .9));
  }

  static void _flask(Canvas canvas, double x, double y, Color liquid) {
    final c = _p(x, y, 5);
    final path = Path()
      ..moveTo(c.dx - 3, c.dy - 12)
      ..lineTo(c.dx + 3, c.dy - 12)
      ..lineTo(c.dx + 2, c.dy - 5)
      ..lineTo(c.dx + 8, c.dy + 6)
      ..quadraticBezierTo(c.dx + 8, c.dy + 10, c.dx + 4, c.dy + 10)
      ..lineTo(c.dx - 4, c.dy + 10)
      ..quadraticBezierTo(c.dx - 8, c.dy + 10, c.dx - 8, c.dy + 6)
      ..lineTo(c.dx - 2, c.dy - 5)
      ..close();
    canvas.drawPath(path, _fill(white));
    canvas.drawPath(path, _stroke(ink, 1.0));
    canvas.drawRect(Rect.fromCenter(center: c.translate(0, 5), width: 12, height: 7), _fill(liquid));
  }

  static void _car(Canvas canvas, double x, double y, double scale, Color color) {
    final c = _p(x, y, 2.6);
    final body = Path()
      ..moveTo(c.dx - 14 * scale, c.dy + 2 * scale)
      ..lineTo(c.dx - 8 * scale, c.dy - 6 * scale)
      ..lineTo(c.dx + 3 * scale, c.dy - 7 * scale)
      ..lineTo(c.dx + 11 * scale, c.dy - 2 * scale)
      ..lineTo(c.dx + 15 * scale, c.dy + 1 * scale)
      ..lineTo(c.dx + 15 * scale, c.dy + 5 * scale)
      ..lineTo(c.dx - 14 * scale, c.dy + 5 * scale)
      ..close();
    canvas.drawPath(body, _fill(color));
    canvas.drawPath(body, _stroke(ink, 1.0));
    canvas.drawCircle(c.translate(-8 * scale, 5 * scale), 2.3 * scale, _fill(ink));
    canvas.drawCircle(c.translate(9 * scale, 5 * scale), 2.3 * scale, _fill(ink));
  }

  static void _medicalCross(Canvas canvas, double x, double y, Color color) {
    final c = _p(x, y, 4.5);
    final a = Rect.fromCenter(center: c, width: 7, height: 21);
    final b = Rect.fromCenter(center: c, width: 21, height: 7);
    canvas.drawRRect(RRect.fromRectAndRadius(a, const Radius.circular(2)), _fill(color));
    canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(2)), _fill(color));
    canvas.drawRRect(RRect.fromRectAndRadius(a, const Radius.circular(2)), _stroke(ink, .8));
    canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(2)), _stroke(ink, .8));
  }

  static void _chip(Canvas canvas, double x, double y, Color color) {
    final c = _p(x, y, 3.5);
    final r = Rect.fromCenter(center: c, width: 18, height: 14);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), _fill(ink));
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), _stroke(color, 1.0));
    canvas.drawRect(Rect.fromCenter(center: c, width: 8, height: 6), _fill(color));
  }

  static void _serverRack(Canvas canvas, double x, double y, double scale) {
    _prism(canvas, x, y, 2.6 * scale, 1.8 * scale, 9 * scale, top: steel2, left: charcoal2, right: charcoal, outline: 1.0);
    for (int i = 0; i < 4; i++) {
      final c = _p(x + 2.6 * scale, y + .5 * scale, 2.7 + i * 1.5);
      canvas.drawCircle(c, 1.0 * scale, _fill(green));
    }
  }

  static void _antenna(Canvas canvas, double x, double y, double scale) {
    canvas.drawLine(_p(x, y, 2), _p(x, y, 21 * scale), _stroke(steel2, 1.5));
    final top = _p(x, y, 22 * scale);
    canvas.drawCircle(top, 2.3 * scale, _fill(cyan));
    canvas.drawArc(Rect.fromCenter(center: top, width: 13 * scale, height: 13 * scale), math.pi * 1.15, math.pi * .7, false, _stroke(purple, 1.1));
  }

  static void _turbine(Canvas canvas, double x, double y, double scale) {
    final hub = _p(x, y, 18 * scale);
    canvas.drawLine(_p(x, y, 2), hub, _stroke(steel2, 1.8));
    canvas.drawCircle(hub, 2.6 * scale, _fill(white));
    canvas.drawCircle(hub, 2.6 * scale, _stroke(ink, .8));
    for (int i = 0; i < 3; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / 3;
      final tip = Offset(hub.dx + math.cos(a) * 13 * scale, hub.dy + math.sin(a) * 13 * scale);
      final blade = Path()
        ..moveTo(hub.dx, hub.dy)
        ..quadraticBezierTo(hub.dx + math.cos(a + .18) * 7 * scale, hub.dy + math.sin(a + .18) * 7 * scale, tip.dx, tip.dy)
        ..quadraticBezierTo(hub.dx + math.cos(a - .1) * 4 * scale, hub.dy + math.sin(a - .1) * 4 * scale, hub.dx, hub.dy)
        ..close();
      canvas.drawPath(blade, _fill(white));
      canvas.drawPath(blade, _stroke(ink, .8));
    }
  }

  static void _solar(Canvas canvas, double x, double y, double w, double d) {
    final pts = [_p(x, y, 5), _p(x + w, y, 5), _p(x + w, y + d, 5), _p(x, y + d, 5)];
    canvas.drawPath(_poly(pts), _fill(const Color(0xFF1A49A1)));
    canvas.drawPath(_poly(pts), _stroke(ink, 1.0));
    for (double t = .25; t < .9; t += .25) {
      canvas.drawLine(_lerp(pts[0], pts[3], t), _lerp(pts[1], pts[2], t), _stroke(cyan, .5));
    }
  }

  static void _dna(Canvas canvas, double x, double y, double scale) {
    final l = Path();
    final r = Path();
    for (int i = 0; i <= 18; i++) {
      final t = i / 18;
      final yy = y + t * 6 * scale;
      final dx = math.sin(t * math.pi * 2) * 1.7 * scale;
      final a = _p(x + dx, yy, 17 - t * 13);
      final b = _p(x - dx, yy, 17 - t * 13);
      if (i == 0) {
        l.moveTo(a.dx, a.dy);
        r.moveTo(b.dx, b.dy);
      } else {
        l.lineTo(a.dx, a.dy);
        r.lineTo(b.dx, b.dy);
      }
      if (i % 3 == 0) canvas.drawLine(a, b, _stroke(ink, .7));
    }
    canvas.drawPath(l, _stroke(green, 1.6));
    canvas.drawPath(r, _stroke(purple, 1.6));
  }

  static void _rocket(Canvas canvas, double x, double y, double scale) {
    final c = _p(x, y, 2.5);
    final path = Path()
      ..moveTo(c.dx, c.dy - 25 * scale)
      ..quadraticBezierTo(c.dx + 9 * scale, c.dy - 16 * scale, c.dx + 7 * scale, c.dy)
      ..lineTo(c.dx + 4 * scale, c.dy + 9 * scale)
      ..lineTo(c.dx - 4 * scale, c.dy + 9 * scale)
      ..lineTo(c.dx - 7 * scale, c.dy)
      ..quadraticBezierTo(c.dx - 9 * scale, c.dy - 16 * scale, c.dx, c.dy - 25 * scale)
      ..close();
    canvas.drawPath(path, _fill(white));
    canvas.drawPath(path, _stroke(ink, 1.2));
    canvas.drawCircle(c.translate(0, -7 * scale), 3.4 * scale, _fill(cyan));
    canvas.drawCircle(c.translate(0, -7 * scale), 3.4 * scale, _stroke(ink, .8));
    final flame = Path()
      ..moveTo(c.dx - 3 * scale, c.dy + 9 * scale)
      ..lineTo(c.dx, c.dy + 17 * scale)
      ..lineTo(c.dx + 3 * scale, c.dy + 9 * scale)
      ..close();
    canvas.drawPath(flame, _fill(gold));
  }

  static void _gantry(Canvas canvas, double x, double y, double scale) {
    final tl = _p(x, y, 25 * scale);
    final tr = _p(x + 4 * scale, y, 25 * scale);
    final bl = _p(x, y + 1.2, 2);
    final br = _p(x + 4 * scale, y + 1.2, 2);
    canvas.drawLine(tl, bl, _stroke(steel2, 1.6));
    canvas.drawLine(tr, br, _stroke(steel2, 1.6));
    for (int i = 0; i < 5; i++) {
      final t0 = i / 5;
      final t1 = (i + 1) / 5;
      canvas.drawLine(_lerp(tl, bl, t0), _lerp(tr, br, t1), _stroke(red, 1.0));
      canvas.drawLine(_lerp(tr, br, t0), _lerp(tl, bl, t1), _stroke(red, 1.0));
    }
  }

  // --------------------------------------------------------------------------
  // 1. TEXTILE
  // --------------------------------------------------------------------------

  static void _textile(Canvas canvas, int s) {
    final accent = const Color(0xFFF6B51B);
    _hangar(canvas, 10.0, 9.0, 13.2, 9.8, (20 + s * 2).toDouble(), accent: accent, roofVents: 2 + s, skylights: 2 + s);
    _chimney(canvas, 24.7, 8.8, (24 + s * 3).toDouble(), accent: accent);
    _loadingDock(canvas, 23.6, 20.0, 5.2 + s, 2.1);
    _fabricRoll(canvas, 7.3, 23.5, cyan);
    _fabricRoll(canvas, 9.2, 24.7, purple);
    if (s >= 1) {
      _fabricRoll(canvas, 11.1, 26.0, gold2);
      _pipeRack(canvas, 22.2, 17.8, 4.8, 6, cyan);
      _forklift(canvas, 29.3, 25.0, scale: .75);
    }
    if (s >= 2) {
      _hangar(canvas, 22.8, 10.8, 5.3, 5.2, 13, accent: accent, roofVents: 1, skylights: 1, loadingDoor: false);
      _chimney(canvas, 29.1, 9.6, 19, accent: accent);
    }
    _sign(canvas, 25.2, 28.0, 'TEXTILE', accent);
  }

  // --------------------------------------------------------------------------
  // 2. FURNITURE
  // --------------------------------------------------------------------------

  static void _furniture(Canvas canvas, int s) {
    final accent = const Color(0xFFF7A21B);
    _hangar(canvas, 9.8, 9.3, 13.0, 9.5, (20 + s * 2).toDouble(), accent: accent, roofVents: 2 + s, skylights: 1 + s);
    _chimney(canvas, 24.5, 9.0, (20 + s * 3).toDouble(), accent: accent);
    _loadingDock(canvas, 23.5, 20.3, 5.4 + s, 2.1);
    _plankStack(canvas, 7.2, 23.3, 4 + s);
    _crate(canvas, 9.5, 25.0, accent);
    if (s >= 1) {
      _hangar(canvas, 22.7, 11.0, 5.2, 4.8, 12, accent: accent, roofVents: 1, skylights: 1, loadingDoor: false);
      _forklift(canvas, 29.0, 24.6, scale: .75);
    }
    if (s >= 2) {
      _pipeRack(canvas, 21.6, 17.8, 5.5, 6.2, accent);
      _crate(canvas, 30.0, 22.0, const Color(0xFFD5811A));
    }
    _sign(canvas, 25.0, 28.0, 'FURNITURE', accent);
  }

  // --------------------------------------------------------------------------
  // 3. AGRICULTURE
  // --------------------------------------------------------------------------

  static void _agriculture(Canvas canvas, int s) {
    final accent = const Color(0xFF78C850);
    _hangar(canvas, 10.0, 10.0, 10.5, 8.4, (17 + s * 2).toDouble(), accent: accent, roofVents: 1 + s, skylights: 1 + s);
    _greenhouse(canvas, 21.4, 10.8, 7.0 + s, 4.8 + s * .3, (10 + s).toDouble());
    _cropRows(canvas, 6.8, 18.8, 5 + s, 4 + s);
    _tank(canvas, 29.0, 10.0, (17 + s * 2).toDouble(), w: 2.8, accent: accent);
    if (s >= 1) _forklift(canvas, 29.0, 24.0, scale: .68);
    if (s >= 2) {
      _tank(canvas, 25.8, 9.7, 14, w: 2.4, accent: gold);
      _pipeRack(canvas, 22.0, 18.2, 5.4, 5.4, accent);
    }
    _sign(canvas, 25.2, 28.0, 'AGRO', accent);
  }

  // --------------------------------------------------------------------------
  // 4. DAIRY
  // --------------------------------------------------------------------------

  static void _dairy(Canvas canvas, int s) {
    final accent = const Color(0xFF4BBDF4);
    _hangar(canvas, 10.0, 9.6, 11.0, 8.8, (18 + s * 2).toDouble(), accent: accent, roofVents: 2 + s, skylights: 1 + s);
    _tank(canvas, 22.6, 9.3, (20 + s * 2).toDouble(), accent: accent);
    if (s >= 1) _tank(canvas, 26.5, 10.0, (16 + s * 2).toDouble(), w: 3.0, accent: gold);
    _cowPen(canvas, 7.0, 21.2);
    _loadingDock(canvas, 22.6, 20.4, 5.6, 2.1);
    _pipeRack(canvas, 20.5, 17.8, 5.6, 5.4, accent);
    if (s >= 2) _truck(canvas, 30.0, 24.0, scale: .48);
    _sign(canvas, 25.0, 28.0, 'DAIRY', accent);
  }

  // --------------------------------------------------------------------------
  // 5. MEAT
  // --------------------------------------------------------------------------

  static void _meat(Canvas canvas, int s) {
    final accent = const Color(0xFFFF5B5B);
    _hangar(canvas, 9.8, 9.3, 12.0, 9.2, (19 + s * 2).toDouble(), accent: accent, roofVents: 3 + s, skylights: 0, loadingDoor: true);
    _chimney(canvas, 23.4, 9.1, (19 + s * 3).toDouble(), accent: accent);
    _loadingDock(canvas, 22.8, 20.3, 6.0, 2.2);
    _meatCrate(canvas, 7.0, 23.0);
    _meatCrate(canvas, 9.2, 24.5);
    if (s >= 1) {
      _tank(canvas, 27.0, 10.0, 14, w: 2.8, accent: accent);
      _truck(canvas, 29.2, 24.2, scale: .45, cab: white);
    }
    if (s >= 2) {
      _pipeRack(canvas, 21.2, 18.0, 6.0, 6.2, accent);
      _chimney(canvas, 29.2, 9.4, 17, accent: accent);
    }
    _sign(canvas, 25.0, 28.0, 'MEAT', accent);
  }

  // --------------------------------------------------------------------------
  // 6. FOOD
  // --------------------------------------------------------------------------

  static void _food(Canvas canvas, int s) {
    final accent = const Color(0xFFFFB923);
    _hangar(canvas, 9.8, 9.4, 12.2, 9.2, (19 + s * 2).toDouble(), accent: accent, roofVents: 2 + s, skylights: 2);
    _chimney(canvas, 23.8, 9.1, (18 + s * 2).toDouble(), accent: accent);
    _loadingDock(canvas, 23.0, 20.2, 5.7, 2.1);
    _crate(canvas, 6.9, 23.0, accent);
    _crate(canvas, 8.8, 24.2, green);
    _crate(canvas, 10.7, 25.5, red);
    if (s >= 1) _tank(canvas, 27.2, 10.0, 16, w: 2.9, accent: accent);
    if (s >= 2) {
      _truck(canvas, 29.2, 24.0, scale: .46);
      _pipeRack(canvas, 21.6, 17.8, 5.2, 5.4, accent);
    }
    _sign(canvas, 25.0, 28.0, 'FOOD', accent);
  }

  // --------------------------------------------------------------------------
  // 7. MINE
  // --------------------------------------------------------------------------

  static void _mine(Canvas canvas, int s) {
    final accent = const Color(0xFFFFB51B);
    _hangar(canvas, 9.4, 11.3, 7.5, 6.4, (14 + s).toDouble(), accent: accent, roofVents: 1, skylights: 0, loadingDoor: false);
    _mineHeadframe(canvas, 18.0, 9.5, .95 + s * .12);
    _chimney(canvas, 25.0, 10.3, (18 + s * 2).toDouble(), accent: accent);
    _oreCart(canvas, 7.0, 23.0, .95);
    _oreCart(canvas, 10.0, 24.7, .82);
    _pipeRack(canvas, 21.0, 18.3, 5.5, 5.2, accent);
    if (s >= 1) {
      _hangar(canvas, 23.0, 12.0, 5.2, 4.8, 12, accent: accent, roofVents: 1, skylights: 0, loadingDoor: false);
      _oreCart(canvas, 13.0, 26.0, .72);
    }
    if (s >= 2) {
      _chimney(canvas, 29.0, 9.5, 22, accent: accent);
      _forklift(canvas, 29.0, 24.0, scale: .7);
    }
    _sign(canvas, 25.0, 28.0, 'MINING', accent);
  }

  // --------------------------------------------------------------------------
  // 8. CHEMICAL
  // --------------------------------------------------------------------------

  static void _chemical(Canvas canvas, int s) {
    final accent = const Color(0xFF55D96C);
    _hangar(canvas, 9.6, 10.4, 8.8, 7.2, (17 + s * 2).toDouble(), accent: accent, roofVents: 2, skylights: 1, loadingDoor: false);
    _tank(canvas, 19.5, 9.4, (19 + s * 2).toDouble(), accent: accent);
    _tank(canvas, 23.3, 10.0, (16 + s * 2).toDouble(), w: 3.1, accent: cyan);
    _chimney(canvas, 27.0, 9.5, (25 + s * 2).toDouble(), accent: accent);
    _pipeRack(canvas, 17.8, 17.5, 9.0, 6.2, accent);
    _barrel(canvas, 7.2, 22.8, accent);
    _barrel(canvas, 9.0, 24.0, cyan);
    _flask(canvas, 30.0, 23.5, accent);
    if (s >= 1) _tank(canvas, 28.7, 11.2, (13 + s * 2).toDouble(), w: 2.7, accent: gold);
    if (s >= 2) _forklift(canvas, 31.0, 25.0, scale: .68);
    _sign(canvas, 25.0, 28.0, 'CHEM', accent);
  }

  // --------------------------------------------------------------------------
  // 9. AUTOMOTIVE
  // --------------------------------------------------------------------------

  static void _automotive(Canvas canvas, int s) {
    final accent = const Color(0xFFFF5D50);
    _hangar(canvas, 9.4, 8.8, 14.0, 10.2, (21 + s * 2).toDouble(), accent: accent, roofVents: 3 + s, skylights: 2 + s);
    _loadingDock(canvas, 23.8, 20.0, 6.2, 2.2);
    _car(canvas, 7.2, 23.5, .72, red);
    _car(canvas, 10.3, 25.2, .66, cyan);
    if (s >= 1) {
      _car(canvas, 13.0, 26.5, .60, gold);
      _chimney(canvas, 25.0, 9.0, 18, accent: accent);
      _forklift(canvas, 29.0, 24.2, scale: .72);
    }
    if (s >= 2) {
      _hangar(canvas, 23.2, 11.2, 5.7, 5.0, 13, accent: accent, roofVents: 1, skylights: 1, loadingDoor: false);
      _truck(canvas, 30.2, 22.8, scale: .42);
    }
    _sign(canvas, 25.0, 28.0, 'AUTO', accent);
  }

  // --------------------------------------------------------------------------
  // 10. PHARMA
  // --------------------------------------------------------------------------

  static void _pharma(Canvas canvas, int s) {
    final accent = const Color(0xFFA778FF);
    _hangar(canvas, 9.8, 9.6, 11.5, 8.8, (19 + s * 2).toDouble(), accent: accent, roofVents: 3 + s, skylights: 2);
    _tank(canvas, 23.0, 9.7, (16 + s * 2).toDouble(), w: 3.0, accent: accent);
    _pipeRack(canvas, 20.6, 17.8, 5.5, 5.5, accent);
    _medicalCross(canvas, 7.7, 22.4, red);
    _crate(canvas, 9.4, 24.5, white);
    if (s >= 1) {
      _tank(canvas, 26.4, 10.2, 14, w: 2.7, accent: cyan);
      _loadingDock(canvas, 23.0, 20.4, 5.4, 2.0);
    }
    if (s >= 2) {
      _chimney(canvas, 29.2, 9.6, 17, accent: accent, smoke: false);
      _forklift(canvas, 30.0, 24.0, scale: .64);
    }
    _sign(canvas, 25.0, 28.0, 'PHARMA', accent);
  }

  // --------------------------------------------------------------------------
  // 11. ELECTRONICS
  // --------------------------------------------------------------------------

  static void _electronics(Canvas canvas, int s) {
    final accent = const Color(0xFF45C6FF);
    _hangar(canvas, 9.5, 9.1, 12.8, 9.6, (20 + s * 2).toDouble(), accent: accent, roofVents: 4 + s, skylights: 1 + s);
    _chimney(canvas, 24.5, 9.0, (17 + s * 2).toDouble(), accent: accent, smoke: false);
    _chip(canvas, 7.5, 22.5, accent);
    _utilityCabinet(canvas, 29.0, 22.7);
    if (s >= 1) {
      _antenna(canvas, 27.0, 11.0, .85);
      _loadingDock(canvas, 23.2, 20.1, 5.6, 2.0);
      _crate(canvas, 9.8, 24.3, steel2);
    }
    if (s >= 2) {
      _hangar(canvas, 23.0, 11.4, 5.6, 4.8, 12, accent: accent, roofVents: 2, skylights: 0, loadingDoor: false);
      _forklift(canvas, 30.0, 24.5, scale: .66);
    }
    _sign(canvas, 25.0, 28.0, 'CHIP FAB', accent);
  }

  // --------------------------------------------------------------------------
  // 12. AI
  // --------------------------------------------------------------------------

  static void _ai(Canvas canvas, int s) {
    final accent = const Color(0xFF9A73FF);
    _hangar(canvas, 9.8, 9.6, 10.0, 8.2, (18 + s * 2).toDouble(), accent: accent, roofVents: 3 + s, skylights: 0, loadingDoor: false);
    _serverRack(canvas, 20.7, 10.7, 1.0);
    _serverRack(canvas, 23.8, 11.6, .95);
    _antenna(canvas, 27.5, 11.2, .9 + s * .08);
    _utilityCabinet(canvas, 7.5, 22.5);
    if (s >= 1) {
      _serverRack(canvas, 26.6, 12.4, .85);
      _solar(canvas, 7.0, 24.0, 5.0, 2.5);
    }
    if (s >= 2) {
      _serverRack(canvas, 29.0, 13.1, .75);
      _solar(canvas, 11.0, 25.5, 4.5, 2.2);
      _chimney(canvas, 21.0, 9.7, 15, accent: accent, smoke: false);
    }
    _sign(canvas, 25.0, 28.0, 'AI CORE', accent);
  }

  // --------------------------------------------------------------------------
  // 13. ENERGY
  // --------------------------------------------------------------------------

  static void _energy(Canvas canvas, int s) {
    final accent = const Color(0xFFFFC11A);
    _hangar(canvas, 9.6, 10.0, 9.0, 7.4, (17 + s * 2).toDouble(), accent: accent, roofVents: 2, skylights: 1, loadingDoor: false);
    _turbine(canvas, 24.0, 12.0, .95 + s * .08);
    _solar(canvas, 6.7, 22.5, 5.4, 3.0);
    _tank(canvas, 20.2, 11.5, (10 + s).toDouble(), w: 2.8, accent: cyan);
    if (s >= 1) {
      _turbine(canvas, 29.7, 15.2, .65);
      _solar(canvas, 10.8, 24.3, 4.8, 2.5);
    }
    if (s >= 2) {
      _pipeRack(canvas, 19.8, 18.3, 5.6, 5.0, accent);
      _solar(canvas, 14.0, 25.7, 4.0, 2.1);
    }
    _sign(canvas, 25.0, 28.0, 'ENERGY', accent);
  }

  // --------------------------------------------------------------------------
  // 14. BIOTECH
  // --------------------------------------------------------------------------

  static void _biotech(Canvas canvas, int s) {
    final accent = const Color(0xFF3BD3A5);
    _hangar(canvas, 9.8, 9.5, 10.8, 8.6, (19 + s * 2).toDouble(), accent: accent, roofVents: 3 + s, skylights: 2);
    _greenhouse(canvas, 22.0, 11.2, 5.5 + s * .5, 4.0, (9 + s).toDouble());
    _tank(canvas, 28.2, 10.0, (16 + s * 2).toDouble(), w: 2.8, accent: accent);
    _dna(canvas, 7.6, 21.5, .95 + s * .06);
    if (s >= 1) _pipeRack(canvas, 20.8, 17.8, 5.8, 5.5, accent);
    if (s >= 2) _antenna(canvas, 20.0, 10.0, .72);
    _sign(canvas, 25.0, 28.0, 'BIOTECH', accent);
  }

  // --------------------------------------------------------------------------
  // 15. SPACE
  // --------------------------------------------------------------------------

  static void _space(Canvas canvas, int s) {
    final accent = const Color(0xFFFFB81C);
    _hangar(canvas, 8.8, 9.0, 13.6, 9.8, (20 + s * 2).toDouble(), accent: accent, roofVents: 3 + s, skylights: 1 + s);
    _rocket(canvas, 26.7, 20.2, .82 + s * .10);
    _gantry(canvas, 29.2, 12.0, .88 + s * .08);
    _antenna(canvas, 7.5, 22.0, .75 + s * .05);
    if (s >= 1) {
      _loadingDock(canvas, 22.7, 20.0, 5.6, 2.0);
      _chimney(canvas, 23.7, 9.1, 16, accent: accent, smoke: false);
    }
    if (s >= 2) {
      _hangar(canvas, 22.9, 11.4, 5.5, 4.8, 12, accent: accent, roofVents: 1, skylights: 0, loadingDoor: false);
      _truck(canvas, 30.0, 24.0, scale: .42);
    }
    _sign(canvas, 25.0, 28.0, 'SPACE', accent);
  }

  static void _generic(Canvas canvas, int s) {
    _hangar(canvas, 9.8, 9.4, 12, 9, (19 + s * 2).toDouble(), accent: gold, roofVents: 2 + s, skylights: 2);
    _chimney(canvas, 24.0, 9.3, (22 + s * 2).toDouble(), accent: gold);
    _loadingDock(canvas, 23.0, 20.1, 5.6, 2.0);
    _forklift(canvas, 29.0, 24.0, scale: .7);
    _sign(canvas, 25.0, 28.0, 'FACTORY', gold);
  }
}
