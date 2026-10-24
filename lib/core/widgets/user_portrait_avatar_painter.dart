import 'dart:math' as math;

import 'package:flutter/material.dart';

class UserPortraitAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8C7A6B), Color(0xFF3E352F)],
        ).createShader(rect),
    );

    final shoulders = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 1.05),
          width: size.width * 0.95,
          height: size.height * 0.65,
        ),
      );
    canvas.drawPath(shoulders, Paint()..color = const Color(0xFF1E2229));

    final shirt = Path()
      ..moveTo(size.width * 0.38, size.height * 0.75)
      ..lineTo(size.width * 0.5, size.height * 0.95)
      ..lineTo(size.width * 0.62, size.height * 0.75)
      ..close();
    canvas.drawPath(shirt, Paint()..color = const Color(0xFFEAECEF));

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.42),
      size.width * 0.22,
      Paint()..color = const Color(0xFFDDB69B),
    );

    final hair = Path()
      ..addArc(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.40),
          radius: size.width * 0.23,
        ),
        math.pi * 0.95,
        math.pi * 1.1,
      );
    canvas.drawPath(hair, Paint()..color = const Color(0xFF2B211B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
