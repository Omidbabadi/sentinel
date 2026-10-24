import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';

class SentinelButton extends StatelessWidget {
  const SentinelButton({
    super.key,
    required this.tokens,
    required this.child,
    this.isDark = false,
    this.width = 38,
    this.height = 38,
    this.borderRadius = 12,
    this.padding,
    this.isHighlighted = false,
    this.accentColor,
    this.semanticLabel,
    this.tooltip,
    this.onTap,
  });

  final bool isDark;
  final SentinelThemeTokens tokens;
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isHighlighted;
  final Color? accentColor;
  final String? semanticLabel;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? tokens.greenAccent;
    final effectiveWidth = (padding != null && width == 38) ? null : width;
    Widget button = Container(
      width: effectiveWidth,
      height: height,
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isHighlighted
            ? effectiveAccent.withValues(
                alpha: tokens.isDark ? 0.16 : 0.12,
              )
            : tokens.innerPillSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isHighlighted
              ? effectiveAccent.withValues(alpha: 0.45)
              : tokens.innerPillBorder,
          width: 0.9,
        ),
      ),
      child: child,
    );

    if (onTap == null) {
      if (semanticLabel != null) {
        return Semantics(label: semanticLabel, child: button);
      }
      return button;
    }

    button = Semantics(
      button: true,
      enabled: true,
      label: semanticLabel ?? tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: button,
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
