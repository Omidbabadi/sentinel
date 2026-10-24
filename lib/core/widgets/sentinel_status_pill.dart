import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';

class SentinelStatusPill extends StatelessWidget {
  const SentinelStatusPill({
    super.key,
    required this.tokens,
    required this.label,
    this.color,
    this.icon,
    this.showDot = false,
    this.glowDot = false,
    this.isNeutral = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
    this.borderRadius = 12,
    this.fontSize = 11,
    this.semanticLabel,
    this.onTap,
  });

  final SentinelThemeTokens tokens;
  final String label;
  final Color? color;
  final IconData? icon;
  final bool showDot;
  final bool glowDot;
  final bool isNeutral;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double fontSize;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? tokens.greenAccent;
    final isDark = tokens.isDark;
    final textColor = isNeutral
        ? tokens.textSecondary
        : (isDark
              ? effectiveColor
              : Color.lerp(effectiveColor, Colors.black, 0.45) ??
                    effectiveColor);

    final pill = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isNeutral
            ? tokens.innerPillSurface
            : effectiveColor.withValues(alpha: isDark ? 0.16 : 0.14),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isNeutral
              ? tokens.innerPillBorder
              : effectiveColor.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: fontSize + 3.5,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ] else if (showDot) ...[
            Container(
              width: 5.5,
              height: 5.5,
              decoration: BoxDecoration(
                color: effectiveColor,
                shape: BoxShape.circle,
                boxShadow: glowDot
                    ? [
                        BoxShadow(
                          color: effectiveColor.withValues(alpha: 0.6),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: isNeutral ? FontWeight.w500 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(
        label: semanticLabel ?? label,
        excludeSemantics: true,
        child: pill,
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Center(child: pill),
          ),
        ),
      ),
    );
  }
}
