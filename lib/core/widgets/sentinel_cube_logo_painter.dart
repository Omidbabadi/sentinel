import 'dart:math' as math;

import 'package:flutter/material.dart';

class SentinelCubeLogoPainter extends CustomPainter {
  final bool isDark;

  SentinelCubeLogoPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.48;

    Offset hexPoint(int i, double radius) {
      final angle = (i * 60 - 90) * math.pi / 180;
      return Offset(
        cx + radius * math.cos(angle),
        cy + radius * math.sin(angle),
      );
    }

    final outerPath = Path();
    for (int i = 0; i < 6; i++) {
      final pt = hexPoint(i, r);
      if (i == 0) {
        outerPath.moveTo(pt.dx, pt.dy);
      } else {
        outerPath.lineTo(pt.dx, pt.dy);
      }
    }
    outerPath.close();

    canvas.drawPath(
      outerPath,
      Paint()
        ..color = isDark ? const Color(0xFF3A3F47) : const Color(0xFF2C2A29),
    );

    final leftFace = Path()
      ..moveTo(cx, cy)
      ..lineTo(hexPoint(4, r).dx, hexPoint(4, r).dy)
      ..lineTo(hexPoint(5, r).dx, hexPoint(5, r).dy)
      ..lineTo(hexPoint(0, r).dx, hexPoint(0, r).dy)
      ..close();
    canvas.drawPath(
      leftFace,
      Paint()
        ..color = isDark ? const Color(0xFFD5D9E0) : const Color(0xFF8C857B),
    );

    final ir = r * 0.52;
    final innerTop = Path()
      ..moveTo(cx, cy)
      ..lineTo(hexPoint(5, ir).dx, hexPoint(5, ir).dy)
      ..lineTo(hexPoint(0, ir).dx, hexPoint(0, ir).dy)
      ..lineTo(hexPoint(1, ir).dx, hexPoint(1, ir).dy)
      ..close();
    canvas.drawPath(innerTop, Paint()..color = Colors.white);

    final innerRight = Path()
      ..moveTo(cx, cy)
      ..lineTo(hexPoint(1, ir).dx, hexPoint(1, ir).dy)
      ..lineTo(hexPoint(2, ir).dx, hexPoint(2, ir).dy)
      ..lineTo(hexPoint(3, ir).dx, hexPoint(3, ir).dy)
      ..close();
    canvas.drawPath(
      innerRight,
      Paint()
        ..color = isDark ? const Color(0xFF9EA4B0) : const Color(0xFFD6D1C7),
    );
  }

  @override
  bool shouldRepaint(covariant SentinelCubeLogoPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
