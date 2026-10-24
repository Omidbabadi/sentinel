import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';

class GreetingSection extends StatelessWidget {
  const GreetingSection({
    super.key,
    required this.isDark,
    required this.tokens,
  });

  final bool isDark;
  final SentinelThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final greeting = isDark ? 'Good evening,' : 'Good morning,';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            '$greeting\nOmid',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'This Is Your 127.0.0.1 🤗',
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
