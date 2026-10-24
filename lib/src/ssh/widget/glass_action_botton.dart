import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/sentinel_botton.dart';

class GlassActionIconButton extends StatelessWidget {
  final SentinelThemeTokens tokens;
  final bool isDark;
  final bool isHighlighted;
  final VoidCallback onTap;
  final Widget child;
  final String? semanticLabel;
  final String? tooltip;

  const GlassActionIconButton({
    super.key,
    required this.tokens,
    required this.isDark,
    this.isHighlighted = false,
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return SentinelButton(
      isDark: isDark,
      tokens: tokens,
      width: 38,
      height: 38,
      isHighlighted: isHighlighted,
      onTap: onTap,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      child: child,
    );
  }
}
