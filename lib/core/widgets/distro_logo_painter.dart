import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sentinel/core/enums/os_names.dart';

class DistroLogoPainter extends CustomPainter {
  final OsNames distro;

  DistroLogoPainter({required this.distro});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    switch (distro) {
      case OsNames.ubuntu:
        canvas.drawCircle(
          center,
          radius,
          Paint()..color = const Color(0xFFE95420),
        );
        final ringRadius = radius * 0.46;
        canvas.drawCircle(
          center,
          ringRadius,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
        for (int i = 0; i < 3; i++) {
          final angle = (i * 120 - 30) * math.pi / 180;
          final nodeCenter = Offset(
            center.dx + (ringRadius + 2.2) * math.cos(angle),
            center.dy + (ringRadius + 2.2) * math.sin(angle),
          );
          canvas.drawCircle(
            nodeCenter,
            3.3,
            Paint()..color = const Color(0xFFE95420),
          );
          canvas.drawCircle(nodeCenter, 2.1, Paint()..color = Colors.white);
        }
        break;

      case OsNames.arch:
        canvas.drawCircle(
          center,
          radius,
          Paint()..color = const Color(0xFF1793D1),
        );
        final path = Path()
          ..moveTo(center.dx, center.dy - radius * 0.58)
          ..lineTo(center.dx - radius * 0.48, center.dy + radius * 0.48)
          ..quadraticBezierTo(
            center.dx - radius * 0.18,
            center.dy + radius * 0.32,
            center.dx - radius * 0.12,
            center.dy + radius * 0.30,
          )
          ..arcToPoint(
            Offset(center.dx + radius * 0.12, center.dy + radius * 0.30),
            radius: Radius.circular(radius * 0.16),
            clockwise: true,
          )
          ..quadraticBezierTo(
            center.dx + radius * 0.18,
            center.dy + radius * 0.32,
            center.dx + radius * 0.48,
            center.dy + radius * 0.48,
          )
          ..close();
        canvas.drawPath(path, Paint()..color = Colors.white);
        break;

      case OsNames.debian:
        canvas.drawCircle(
          center,
          radius,
          Paint()..color = const Color(0xFFD70A53),
        );
        final swirlPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        final swirlPath = Path();
        for (double t = 0; t < 3.6 * math.pi; t += 0.15) {
          final r = (t / (3.6 * math.pi)) * radius * 0.56;
          final x = center.dx + r * math.cos(t + 0.8);
          final y = center.dy + r * math.sin(t + 0.8);
          if (t == 0) {
            swirlPath.moveTo(x, y);
          } else {
            swirlPath.lineTo(x, y);
          }
        }
        canvas.drawPath(swirlPath, swirlPaint);
        break;

      case OsNames.fedora:
        canvas.drawCircle(
          center,
          radius,
          Paint()..color = const Color(0xFF294172),
        );
        final fPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
        final fPath = Path()
          ..moveTo(center.dx + radius * 0.25, center.dy - radius * 0.38)
          ..cubicTo(
            center.dx - radius * 0.1,
            center.dy - radius * 0.48,
            center.dx - radius * 0.08,
            center.dy + radius * 0.48,
            center.dx - radius * 0.32,
            center.dy + radius * 0.42,
          )
          ..moveTo(center.dx - radius * 0.28, center.dy + 0.5)
          ..lineTo(center.dx + radius * 0.22, center.dy + 0.5);
        canvas.drawPath(fPath, fPaint);
        break;

      case OsNames.cachyOS:
        // Teal/Cyan background with CachyOS geometric hexagon "C" + nodes
        canvas.drawCircle(
          center,
          radius,
          Paint()..color = const Color(0xFF00AA88),
        );
        final cachyPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        final cPath = Path();
        // Draw open hexagon (angles from 60° to 300°)
        final angles = [60, 120, 180, 240, 300];
        for (int i = 0; i < angles.length; i++) {
          final rad = angles[i] * math.pi / 180;
          final pt = Offset(
            center.dx + radius * 0.48 * math.cos(rad),
            center.dy + radius * 0.48 * math.sin(rad),
          );
          if (i == 0) {
            cPath.moveTo(pt.dx, pt.dy);
          } else {
            cPath.lineTo(pt.dx, pt.dy);
          }
        }
        canvas.drawPath(cPath, cachyPaint);

        // Inner accent dots on right opening
        canvas.drawCircle(
          Offset(center.dx + radius * 0.28, center.dy - radius * 0.18),
          1.8,
          Paint()..color = const Color(0xFF80FFE5),
        );
        canvas.drawCircle(
          Offset(center.dx + radius * 0.28, center.dy + radius * 0.18),
          1.8,
          Paint()..color = Colors.white,
        );
        break;

      case OsNames.centOS:
        // Deep slate base with the 4 rotated CentOS diamonds/squares
        canvas.drawCircle(
          center,
          radius,
          Paint()..color = const Color(0xFF262577),
        );
        final d = radius * 0.28;
        final gap = radius * 0.06;
        final diamondColors = [
          const Color(0xFF932279), // Top (Purple)
          const Color(0xFFEFA724), // Right (Orange/Gold)
          const Color(0xFF262577), // Bottom (Blue - outlined in white)
          const Color(0xFF9CCD2A), // Left (Green)
        ];
        final offsets = [
          Offset(center.dx, center.dy - d - gap), // Top
          Offset(center.dx + d + gap, center.dy), // Right
          Offset(center.dx, center.dy + d + gap), // Bottom
          Offset(center.dx - d - gap, center.dy), // Left
        ];

        for (int i = 0; i < 4; i++) {
          final o = offsets[i];
          final diamond = Path()
            ..moveTo(o.dx, o.dy - d)
            ..lineTo(o.dx + d, o.dy)
            ..lineTo(o.dx, o.dy + d)
            ..lineTo(o.dx - d, o.dy)
            ..close();
          canvas.drawPath(diamond, Paint()..color = diamondColors[i]);
          canvas.drawPath(
            diamond,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2,
          );
        }
        break;

      case OsNames.rockyLinux:
        // Rocky Linux official emerald green with mountain peak cutout
        canvas.drawCircle(
          center,
          radius,
          Paint()..color = const Color(0xFF10B981),
        );
        canvas.save();
        canvas.clipPath(
          Path()
            ..addOval(Rect.fromCircle(center: center, radius: radius * 0.62)),
        );
        canvas.drawCircle(
          center,
          radius * 0.62,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
        final mountainPath = Path()
          ..moveTo(center.dx - radius * 0.65, center.dy + radius * 0.55)
          ..lineTo(center.dx - radius * 0.12, center.dy - radius * 0.22)
          ..lineTo(center.dx + radius * 0.12, center.dy + radius * 0.08)
          ..lineTo(center.dx + radius * 0.32, center.dy - radius * 0.10)
          ..lineTo(center.dx + radius * 0.65, center.dy + radius * 0.55)
          ..close();
        canvas.drawPath(mountainPath, Paint()..color = Colors.white);
        canvas.restore();
        break;

      case OsNames.almaLinux:
        // Dark navy circle with AlmaLinux's 5 colorful petals
        canvas.drawCircle(
          center,
          radius,
          Paint()..color = const Color(0xFF0F1C2E),
        );
        final petalColors = [
          const Color(0xFFFF4649), // Red
          const Color(0xFFFFC400), // Yellow
          const Color(0xFF20C997), // Green
          const Color(0xFF0088FF), // Blue
          const Color(0xFFDA5597), // Magenta
        ];
        for (int i = 0; i < 5; i++) {
          final angle = (i * 72 - 90) * math.pi / 180;
          final petalCenter = Offset(
            center.dx + radius * 0.36 * math.cos(angle),
            center.dy + radius * 0.36 * math.sin(angle),
          );
          canvas.drawCircle(
            petalCenter,
            radius * 0.22,
            Paint()..color = petalColors[i],
          );
        }
        // Center cutout
        canvas.drawCircle(
          center,
          radius * 0.18,
          Paint()..color = const Color(0xFF0F1C2E),
        );
        break;

      case OsNames.unknown:
        // Neutral slate background with a clean terminal ">_" prompt icon
        canvas.drawCircle(
          center,
          radius,
          Paint()..color = const Color(0xFF475569),
        );
        final promptPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        final promptPath = Path()
          // '>' chevron
          ..moveTo(center.dx - radius * 0.36, center.dy - radius * 0.24)
          ..lineTo(center.dx - radius * 0.08, center.dy)
          ..lineTo(center.dx - radius * 0.36, center.dy + radius * 0.24)
          // '_' underscore
          ..moveTo(center.dx + radius * 0.04, center.dy + radius * 0.24)
          ..lineTo(center.dx + radius * 0.36, center.dy + radius * 0.24);

        canvas.drawPath(promptPath, promptPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DistroLogoPainter oldDelegate) =>
      oldDelegate.distro != distro;
}
