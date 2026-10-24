import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/application/riverpod/current_theme_controller.dart';
import 'package:sentinel/core/extensions/context_extension.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/glass_card.dart';

class ToggleThemeButton extends ConsumerWidget {
  const ToggleThemeButton({super.key});

  ThemeMode _nextThemeMode(ThemeMode current) => switch (current) {
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
    ThemeMode.system => ThemeMode.light,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(currentThemeProvider);
    final tokens = SentinelThemeTokens(context.isDarkMode);

    final (icon, iconColor, label) = switch (themeMode) {
      ThemeMode.light => (Icons.wb_sunny_rounded, Colors.amber, 'Light Mode'),
      ThemeMode.dark => (
        Icons.nightlight_round,
        Colors.lightBlueAccent,
        'Dark Mode',
      ),
      ThemeMode.system => (
        Icons.brightness_auto_rounded,
        Colors.tealAccent,
        'System Mode',
      ),
    };

    return Semantics(
      button: true,
      label: 'Current theme: $label. Activate to switch theme.',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: GlassCard(
          tokens: tokens,
          padding: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              final next = _nextThemeMode(themeMode);
              ref.read(currentThemeProvider.notifier).toggleTheme(next);
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: iconColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
