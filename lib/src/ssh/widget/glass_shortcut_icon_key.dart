import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';

class GlassShortcutIconKey extends StatelessWidget {
  final IconData icon;
  final SentinelThemeTokens tokens;
  final Color? accentColor;
  final VoidCallback onTap;
  final String? semanticLabel;
  final String? tooltip;

  const GlassShortcutIconKey({
    super.key,
    required this.icon,
    required this.tokens,
    this.accentColor,
    required this.onTap,
    this.semanticLabel,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = semanticLabel ?? tooltip;
    Widget button = Semantics(
      button: true,
      label: effectiveLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            decoration: BoxDecoration(
              color: tokens.innerPillSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.innerPillBorder, width: 0.8),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 15,
                color: accentColor ?? tokens.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );

    if (effectiveLabel != null) {
      button = Tooltip(message: effectiveLabel, child: button);
    }

    return button;
  }
}
