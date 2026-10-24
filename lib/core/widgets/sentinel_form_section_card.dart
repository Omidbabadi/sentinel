import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/glass_card.dart';

class SentinelFormSectionCard extends StatelessWidget {
  const SentinelFormSectionCard({
    super.key,
    required this.tokens,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final SentinelThemeTokens tokens;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = tokens.isDark;

    return GlassCard(
      tokens: tokens,
      borderRadius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            container: true,
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: tokens.blueAccent.withValues(
                        alpha: isDark ? 0.16 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: tokens.blueAccent.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Icon(icon, size: 16, color: tokens.blueAccent),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 0.7, color: tokens.dividerColor),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
