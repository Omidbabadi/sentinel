import 'package:flutter/material.dart';
import 'package:sentinel/core/enums/os_names.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/distro_logo_painter.dart';

class DistroAvatar extends StatelessWidget {
  const DistroAvatar({
    super.key,
    required this.distro,
    required this.tokens,
    this.size = 34,
    this.showActiveBadge = false,
  });

  final OsNames distro;
  final SentinelThemeTokens tokens;
  final double size;
  final bool showActiveBadge;

  @override
  Widget build(BuildContext context) {
    final logo = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: DistroLogoPainter(distro: distro)),
    );

    final Widget visual = !showActiveBadge
        ? logo
        : Stack(
            clipBehavior: Clip.none,
            children: [
              logo,
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: tokens.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: tokens.isDark
                          ? const Color(0xFF1E2229)
                          : Colors.white,
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.greenAccent.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

    return Semantics(
      image: true,
      label: showActiveBadge
          ? '${distro.name} distribution, active SSH connection'
          : '${distro.name} distribution',
      excludeSemantics: true,
      child: visual,
    );
  }
}
