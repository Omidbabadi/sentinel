import 'package:flutter/material.dart';

import '../../../core/res/style/theme_tokens.dart';

class GlassShortcutKey extends StatelessWidget {
  final String label;
  final SentinelThemeTokens tokens;
  final bool isHighlighted;
  final bool isActive;
  final VoidCallback onTap;
  final String? semanticLabel;

  const GlassShortcutKey({
    super.key,
    required this.label,
    required this.tokens,
    this.isHighlighted = false,
    this.isActive = false,
    required this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: semanticLabel ?? label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: isActive
                  ? tokens.greenAccent.withValues(alpha: 0.24)
                  : tokens.innerPillSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive
                    ? tokens.greenAccent
                    : isHighlighted
                        ? tokens.blueAccent.withValues(alpha: 0.35)
                        : tokens.innerPillBorder,
                width: isActive ? 1.2 : 0.8,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? tokens.greenTextAccent
                      : isHighlighted
                          ? tokens.blueTextAccent
                          : tokens.textPrimary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
