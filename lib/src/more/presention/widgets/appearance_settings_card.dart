import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/application/riverpod/current_theme_controller.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/sentinel_form_section_card.dart';

class AppearanceSettingsCard extends ConsumerWidget {
  const AppearanceSettingsCard({super.key, required this.tokens});

  final SentinelThemeTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(currentThemeProvider);
    final themeNotifier = ref.read(currentThemeProvider.notifier);

    return SentinelFormSectionCard(
      tokens: tokens,
      title: 'Appearance',
      subtitle: 'Color mode & glassmorphic surface contrast',
      icon: Icons.palette_outlined,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: tokens.innerPillSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tokens.innerPillBorder, width: 0.9),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ThemeModeSegment(
                  tokens: tokens,
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: currentThemeMode == ThemeMode.system,
                  onTap: () => themeNotifier.toggleTheme(ThemeMode.system),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _ThemeModeSegment(
                  tokens: tokens,
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  isSelected: currentThemeMode == ThemeMode.dark,
                  onTap: () => themeNotifier.toggleTheme(ThemeMode.dark),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _ThemeModeSegment(
                  tokens: tokens,
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  isSelected: currentThemeMode == ThemeMode.light,
                  onTap: () => themeNotifier.toggleTheme(ThemeMode.light),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeModeSegment extends StatelessWidget {
  const _ThemeModeSegment({
    required this.tokens,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final SentinelThemeTokens tokens;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label theme mode',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? tokens.greenAccent.withValues(
                      alpha: tokens.isDark ? 0.18 : 0.14,
                    )
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              border: isSelected
                  ? Border.all(
                      color: tokens.greenAccent.withValues(alpha: 0.45),
                      width: 0.9,
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? tokens.greenTextAccent
                      : tokens.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? tokens.greenTextAccent
                        : tokens.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
