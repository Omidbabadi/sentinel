import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/sentinel_primary_button.dart';

class SentinelStateView extends StatelessWidget {
  const SentinelStateView({
    super.key,
    required this.tokens,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.accentColor,
    this.wrapInGlassCard = false,
    this.showGlowingBadge = false,
    this.isLiveRegion = false,
  });

  final SentinelThemeTokens tokens;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Color? accentColor;
  final bool wrapInGlassCard;
  final bool showGlowingBadge;
  final bool isLiveRegion;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = accentColor ?? tokens.blueAccent;
    final isDark = tokens.isDark;

    final content = Semantics(
      container: true,
      liveRegion: isLiveRegion,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: showGlowingBadge
                ? Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: effectiveColor.withValues(
                        alpha: isDark ? 0.14 : 0.10,
                      ),
                      border: Border.all(
                        color: effectiveColor.withValues(alpha: 0.30),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: effectiveColor.withValues(
                            alpha: isDark ? 0.22 : 0.12,
                          ),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 28, color: effectiveColor),
                  )
                : Icon(icon, size: 46, color: effectiveColor),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accentColor == tokens.redAccent
                    ? tokens.redTextAccent
                    : tokens.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 22),
            SentinelPrimaryButton(
              tokens: tokens,
              label: actionLabel!,
              icon: actionIcon,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );

    if (!wrapInGlassCard) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: content,
        ),
      );
    }

    return GlassCard(
      tokens: tokens,
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: SizedBox(
        width: double.infinity,
        child: Center(child: content),
      ),
    );
  }
}
