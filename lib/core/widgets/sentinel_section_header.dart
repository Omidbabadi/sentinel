import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';

class SentinelSectionHeader extends StatelessWidget {
  const SentinelSectionHeader({
    super.key,
    required this.title,
    required this.tokens,
    this.trailing,
    this.fontSize = 25,
  });

  final String title;
  final SentinelThemeTokens tokens;
  final Widget? trailing;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
