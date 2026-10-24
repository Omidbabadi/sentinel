import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/glass_card.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.tokens,
    required this.count,
    required this.label,
    required this.accentColor,
    required this.iconWidget,
    this.dotIndicatorColor,
  });

  final SentinelThemeTokens tokens;
  final String count;
  final String label;
  final Color accentColor;
  final Widget iconWidget;
  final Color? dotIndicatorColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tokens: tokens,
      padding: const EdgeInsets.all(12),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget,
          const SizedBox(height: 10),
          Text(
            count,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (dotIndicatorColor != null)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotIndicatorColor,
                    boxShadow: [
                      BoxShadow(
                        color: dotIndicatorColor!.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
