import 'package:flutter/material.dart';

/// The looki logo mark — navy squircle, blue ring, white eye, lashes.
/// ViewBox mirrors the SVG: -100 -140 200 240.
class LookiLogo extends StatelessWidget {
  const LookiLogo({super.key, this.width = 100});

  final double width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 240.0 / 200.0),
      painter: _LookiLogoPainter(),
    );
  }
}

class _LookiLogoPainter extends CustomPainter {
  static const _navy = Color(0xFF0A2A6B);   // T.ink — deep navy
  static const _blue = Color(0xFF1E6FE8);   // T.accent — sky blue
  static const _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    // Map SVG viewBox (-100,-140 → 100,100) onto the canvas.
    final scale = size.width / 200.0;
    canvas.translate(size.width / 2, size.height * (140.0 / 240.0));
    canvas.scale(scale);

    // Lashes
    final lashPaint = Paint()
      ..color = _navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const lashes = [
      [Offset(-60, -92), Offset(-66, -108), Offset(-72, -118)],
      [Offset(-30, -98), Offset(-32, -116), Offset(-34, -128)],
      [Offset(0, -100), Offset(0, -118), Offset(0, -130)],
      [Offset(30, -98), Offset(32, -116), Offset(34, -128)],
      [Offset(60, -92), Offset(66, -108), Offset(72, -118)],
    ];
    for (final pts in lashes) {
      canvas.drawPath(
        Path()
          ..moveTo(pts[0].dx, pts[0].dy)
          ..quadraticBezierTo(pts[1].dx, pts[1].dy, pts[2].dx, pts[2].dy),
        lashPaint,
      );
    }

    // Outer squircle — navy
    canvas.drawPath(
      Path()
        ..moveTo(-90, 0)
        ..cubicTo(-90, -63, -63, -90, 0, -90)
        ..cubicTo(63, -90, 90, -63, 90, 0)
        ..cubicTo(90, 63, 63, 90, 0, 90)
        ..cubicTo(-63, 90, -90, 63, -90, 0)
        ..close(),
      Paint()..color = _navy,
    );

    // Blue ring
    canvas.drawPath(
      Path()
        ..moveTo(-68, 0)
        ..cubicTo(-68, -47, -47, -68, 0, -68)
        ..cubicTo(47, -68, 68, -47, 68, 0)
        ..cubicTo(68, 47, 47, 68, 0, 68)
        ..cubicTo(-47, 68, -68, 47, -68, 0)
        ..close(),
      Paint()..color = _blue,
    );

    // White sclera
    canvas.drawCircle(Offset.zero, 42, Paint()..color = _white);

    // Pupil — curious glance up-right
    canvas.drawCircle(const Offset(11, -11), 22, Paint()..color = _navy);

    // Catch-light
    canvas.drawCircle(const Offset(4, -18), 6.5, Paint()..color = _white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
