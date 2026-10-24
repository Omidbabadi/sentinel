import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/application/riverpod/user_prefs.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/sentinel_botton.dart';
import 'package:sentinel/core/widgets/sentinel_form_section_card.dart';
import 'package:sentinel/src/ssh/widget/terminal_theme.dart';

class TerminalSettingsCard extends ConsumerWidget {
  const TerminalSettingsCard({
    super.key,
    required this.tokens,
    required this.isDark,
  });

  final SentinelThemeTokens tokens;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPrefsProvider);
    final prefsNotifier = ref.read(userPrefsProvider.notifier);

    final activePreset = kSentinelTerminalThemePresets.firstWhere(
      (p) => p.id == prefs.terminalThemeId,
      orElse: () => kSentinelTerminalThemePresets.first,
    );

    return SentinelFormSectionCard(
      tokens: tokens,
      title: 'Terminal & Shell',
      subtitle: 'Typography scale & xterm color palette',
      icon: Icons.terminal_rounded,
      children: [
        // 1. Font Size Stepper Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Font Size',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'JetBrains Mono • Supports two-finger pinch zoom',
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                SentinelButton(
                  tokens: tokens,
                  isDark: isDark,
                  width: 36,
                  height: 36,
                  borderRadius: 10,
                  semanticLabel: 'Decrease terminal font size',
                  tooltip: 'Decrease font size',
                  onTap: () => prefsNotifier.decrementFontSize(1.0),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 17,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 54,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tokens.innerPillSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: tokens.innerPillBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${prefs.terminalFontSize.toStringAsFixed(0)} pt',
                    style: TextStyle(
                      color: tokens.greenTextAccent,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SentinelButton(
                  tokens: tokens,
                  isDark: isDark,
                  width: 36,
                  height: 36,
                  borderRadius: 10,
                  semanticLabel: 'Increase terminal font size',
                  tooltip: 'Increase font size',
                  onTap: () => prefsNotifier.incrementFontSize(1.0),
                  child: Icon(
                    Icons.add_rounded,
                    size: 17,
                    color: tokens.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. Live Terminal Prompt Preview Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: activePreset.effectivePreviewBg(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: activePreset
                  .effectivePreviewAccent(isDark)
                  .withValues(alpha: 0.35),
              width: 0.9,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'root@sentinel-node',
                    style: TextStyle(
                      color: activePreset.effectivePreviewAccent(isDark),
                      fontSize: prefs.terminalFontSize.clamp(9.0, 16.0),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    ':~# ',
                    style: TextStyle(
                      color: activePreset.effectivePreviewSecondary(isDark),
                      fontSize: prefs.terminalFontSize.clamp(9.0, 16.0),
                      fontFamily: 'monospace',
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'systemctl status sshd',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: activePreset.effectivePreviewPrimary(isDark),
                        fontSize: prefs.terminalFontSize.clamp(9.0, 16.0),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '● ssh.service - OpenBSD Secure Shell server (active)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: activePreset.effectivePreviewSecondary(isDark),
                  fontSize: (prefs.terminalFontSize - 1).clamp(8.5, 14.0),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Terminal Color Scheme Grid
        Text(
          'Color Palette (${activePreset.name})',
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.45,
          ),
          itemCount: kSentinelTerminalThemePresets.length,
          itemBuilder: (context, index) {
            final preset = kSentinelTerminalThemePresets[index];
            final isSelected = preset.id == prefs.terminalThemeId;
            return _TerminalPaletteTile(
              preset: preset,
              isSelected: isSelected,
              tokens: tokens,
              isDark: isDark,
              onTap: () => prefsNotifier.setTerminalThemeId(preset.id),
            );
          },
        ),
      ],
    );
  }
}

class _TerminalPaletteTile extends StatelessWidget {
  const _TerminalPaletteTile({
    required this.preset,
    required this.isSelected,
    required this.tokens,
    required this.isDark,
    required this.onTap,
  });

  final SentinelTerminalThemePreset preset;
  final bool isSelected;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = preset.effectivePreviewBg(isDark);
    final primary = preset.effectivePreviewPrimary(isDark);
    final secondary = preset.effectivePreviewSecondary(isDark);
    final accent = preset.effectivePreviewAccent(isDark);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${preset.name} terminal theme',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? tokens.greenAccent
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.black.withValues(alpha: 0.12)),
                width: isSelected ? 1.6 : 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: secondary,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: tokens.greenAccent,
                      ),
                  ],
                ),
                Text(
                  preset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primary,
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
