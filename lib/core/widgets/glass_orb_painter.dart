import 'package:flutter/material.dart';

class GlassOrbPainter extends CustomPainter {
  final bool isDark;

  GlassOrbPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.width * 0.44;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Soft outer shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.45 : 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(center.translate(-6, 14), radius * 0.92, shadowPaint);

    // Base sphere body gradient
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 1.1,
        colors: isDark
            ? [
                const Color(0xFF565B66).withValues(alpha: 0.85),
                const Color(0xFF22262E).withValues(alpha: 0.92),
                const Color(0xFF0E1014).withValues(alpha: 0.96),
                const Color(0xFF393E47).withValues(alpha: 0.85),
              ]
            : [
                const Color(0xFFFFFFFF).withValues(alpha: 0.95),
                const Color(0xFFE3E0D8).withValues(alpha: 0.75),
                const Color(0xFFC5C0B4).withValues(alpha: 0.65),
                const Color(0xFFF7F5F0).withValues(alpha: 0.9),
              ],
        stops: const [0.0, 0.45, 0.82, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, bodyPaint);

    // Internal caustic / glass refraction bands
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    final refractionPath = Path()
      ..moveTo(center.dx - radius, center.dy + radius * 0.2)
      ..quadraticBezierTo(
        center.dx - radius * 0.2,
        center.dy - radius * 0.7,
        center.dx + radius * 0.8,
        center.dy - radius * 0.2,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.2,
        center.dy + radius * 0.6,
        center.dx - radius,
        center.dy + radius * 0.2,
      );

    final refractionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.18 : 0.55),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(refractionPath, refractionPaint);

    // Top-left bright specular reflection
    final highlightCenter = center.translate(-radius * 0.35, -radius * 0.35);
    final highlightPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: isDark ? 0.55 : 0.9),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(center: highlightCenter, radius: radius * 0.45),
          );
    canvas.drawCircle(highlightCenter, radius * 0.45, highlightPaint);

    canvas.restore();

    // Crisp rim highlight
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.45 : 0.85),
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: isDark ? 0.25 : 0.6),
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: isDark ? 0.45 : 0.85),
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius, rimPaint);
  }

  @override
  bool shouldRepaint(covariant GlassOrbPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
