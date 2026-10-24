import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/extensions/context_extension.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';

class MyBackButton extends ConsumerWidget {
  const MyBackButton({
    super.key,
    required this.onPop,
    this.tooltip = 'Back',
  });

  final void Function()? onPop;
  final String tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = context.isDarkMode;
    final tokens = SentinelThemeTokens(isDark);
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPop,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: tokens.cardSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: tokens.cardBorder),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
