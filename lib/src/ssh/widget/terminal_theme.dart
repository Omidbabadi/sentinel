import 'package:flutter/material.dart';
import 'package:xterm2/ui.dart';

import '../../../core/common/singelton/user_prefs.dart';
import '../../../core/res/style/theme_tokens.dart';

class SentinelTerminalThemePreset {
  final String id;
  final String name;
  final Color previewBg;
  final Color previewPrimary;
  final Color previewSecondary;
  final Color previewAccent;
  final TerminalTheme Function(SentinelThemeTokens tokens, bool isDark) builder;

  const SentinelTerminalThemePreset({
    required this.id,
    required this.name,
    required this.previewBg,
    required this.previewPrimary,
    required this.previewSecondary,
    required this.previewAccent,
    required this.builder,
  });

  bool get isAdaptive => id == UserPrefs.defaultTerminalThemeId;

  Color effectivePreviewBg(bool isDark) =>
      isAdaptive && !isDark ? const Color(0xFFF3F1EC) : previewBg;

  Color effectivePreviewPrimary(bool isDark) =>
      isAdaptive && !isDark ? const Color(0xFF0F766E) : previewPrimary;

  Color effectivePreviewSecondary(bool isDark) =>
      isAdaptive && !isDark ? const Color(0xFF1D4ED8) : previewSecondary;

  Color effectivePreviewAccent(bool isDark) =>
      isAdaptive && !isDark ? const Color(0xFFB45309) : previewAccent;
}

/// Default adaptive Sentinel theme (matches your original `terminalPresetThemes` behavior)
TerminalTheme _buildSentinelDefaultTheme(
  SentinelThemeTokens tokens,
  bool isDark,
) {
  if (isDark) {
    return TerminalThemes.defaultTheme;
  }

  // High-contrast palette for Light Mode on a translucent GlassCard
  return TerminalTheme(
    cursor: const Color(0xFF0F766E),
    selection: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
    foreground: const Color(0xFF1E293B),
    background: Colors.transparent,
    black: const Color(0xFF1E293B),
    white: const Color(0xFF475569),
    red: const Color(0xFFDC2626),
    green: const Color(0xFF15803D),
    yellow: const Color(0xFFB45309),
    blue: const Color(0xFF1D4ED8),
    magenta: const Color(0xFF7E22CE),
    cyan: const Color(0xFF0E7490),
    brightBlack: const Color(0xFF64748B),
    brightRed: const Color(0xFFB91C1C),
    brightGreen: const Color(0xFF166534),
    brightYellow: const Color(0xFF92400E),
    brightBlue: const Color(0xFF1E40AF),
    brightMagenta: const Color(0xFF6B21A8),
    brightCyan: const Color(0xFF155E75),
    brightWhite: const Color(0xFF0F172A),
    searchHitBackground: const Color(0xFFFDE047),
    searchHitBackgroundCurrent: const Color(0xFFF59E0B),
    searchHitForeground: const Color(0xFF0F172A),
  );
}

final List<SentinelTerminalThemePreset> kSentinelTerminalThemePresets = [
  SentinelTerminalThemePreset(
    id: UserPrefs.defaultTerminalThemeId,
    name: 'Sentinel Adaptive',
    previewBg: const Color(0xFF181C24),
    previewPrimary: const Color(0xFF39C98A),
    previewSecondary: const Color(0xFF4796E5),
    previewAccent: const Color(0xFFE9A93B),
    builder: _buildSentinelDefaultTheme,
  ),
  SentinelTerminalThemePreset(
    id: 'sentinel_emerald',
    name: 'Sentinel Emerald',
    previewBg: const Color(0xFF0F1917),
    previewPrimary: const Color(0xFF34D399),
    previewSecondary: const Color(0xFF10B981),
    previewAccent: const Color(0xFFA7F3D0),
    builder: (_, _) => TerminalTheme(
      cursor: const Color(0xFF34D399),
      selection: const Color(0xFF10B981).withValues(alpha: 0.28),
      foreground: const Color(0xFFD1FAE5),
      background: const Color(0xFF0F1917),
      black: const Color(0xFF064E3B),
      white: const Color(0xFFD1FAE5),
      red: const Color(0xFFF87171),
      green: const Color(0xFF34D399),
      yellow: const Color(0xFFFBBF24),
      blue: const Color(0xFF38BDF8),
      magenta: const Color(0xFFC084FC),
      cyan: const Color(0xFF2DD4BF),
      brightBlack: const Color(0xFF6EE7B7),
      brightRed: const Color(0xFFFCA5A5),
      brightGreen: const Color(0xFF6EE7B7),
      brightYellow: const Color(0xFFFDE68A),
      brightBlue: const Color(0xFF7DD3FC),
      brightMagenta: const Color(0xFFD8B4FE),
      brightCyan: const Color(0xFF5EEAD4),
      brightWhite: const Color(0xFFECFDF5),
      searchHitBackground: const Color(0xFFFDE047),
      searchHitBackgroundCurrent: const Color(0xFF10B981),
      searchHitForeground: const Color(0xFF064E3B),
    ),
  ),
  SentinelTerminalThemePreset(
    id: 'flexoki_dark',
    name: 'Flexoki Dark',
    previewBg: const Color(0xFF1C1B1A),
    previewPrimary: const Color(0xFFCECDC3),
    previewSecondary: const Color(0xFF879A39),
    previewAccent: const Color(0xFFD0A215),
    builder: (_, _) => TerminalTheme(
      cursor: const Color(0xFF879A39),
      selection: const Color(0xFF4385BE).withValues(alpha: 0.30),
      foreground: const Color(0xFFCECDC3),
      background: const Color(0xFF1C1B1A),
      black: const Color(0xFF100F0F),
      white: const Color(0xFFCECDC3),
      red: const Color(0xFFD14D41),
      green: const Color(0xFF879A39),
      yellow: const Color(0xFFD0A215),
      blue: const Color(0xFF4385BE),
      magenta: const Color(0xFF8B7EC8),
      cyan: const Color(0xFF3AA99F),
      brightBlack: const Color(0xFF575653),
      brightRed: const Color(0xFFAF3029),
      brightGreen: const Color(0xFF66800B),
      brightYellow: const Color(0xFFAD8301),
      brightBlue: const Color(0xFF205EA6),
      brightMagenta: const Color(0xFF5E409D),
      brightCyan: const Color(0xFF24837B),
      brightWhite: const Color(0xFFFFFCF0),
      searchHitBackground: const Color(0xFFD0A215),
      searchHitBackgroundCurrent: const Color(0xFFDA702C),
      searchHitForeground: const Color(0xFF100F0F),
    ),
  ),
  SentinelTerminalThemePreset(
    id: 'flexoki_light',
    name: 'Flexoki Light',
    previewBg: const Color(0xFFFFFCF0),
    previewPrimary: const Color(0xFF100F0F),
    previewSecondary: const Color(0xFF66800B),
    previewAccent: const Color(0xFF24837B),
    builder: (_, _) => TerminalTheme(
      cursor: const Color(0xFF66800B),
      selection: const Color(0xFF205EA6).withValues(alpha: 0.22),
      foreground: const Color(0xFF100F0F),
      background: const Color(0xFFFFFCF0),
      black: const Color(0xFF100F0F),
      white: const Color(0xFF6F6E69),
      red: const Color(0xFFAF3029),
      green: const Color(0xFF66800B),
      yellow: const Color(0xFFAD8301),
      blue: const Color(0xFF205EA6),
      magenta: const Color(0xFF5E409D),
      cyan: const Color(0xFF24837B),
      brightBlack: const Color(0xFF878580),
      brightRed: const Color(0xFFD14D41),
      brightGreen: const Color(0xFF879A39),
      brightYellow: const Color(0xFFD0A215),
      brightBlue: const Color(0xFF4385BE),
      brightMagenta: const Color(0xFF8B7EC8),
      brightCyan: const Color(0xFF3AA99F),
      brightWhite: const Color(0xFF100F0F),
      searchHitBackground: const Color(0xFFFDE047),
      searchHitBackgroundCurrent: const Color(0xFFDA702C),
      searchHitForeground: const Color(0xFF100F0F),
    ),
  ),
  SentinelTerminalThemePreset(
    id: 'kanagawa_wave',
    name: 'Kanagawa Wave',
    previewBg: const Color(0xFF1F1F28),
    previewPrimary: const Color(0xFFDCD7BA),
    previewSecondary: const Color(0xFF98BB6C),
    previewAccent: const Color(0xFF7E9CD8),
    builder: (_, _) => TerminalTheme(
      cursor: const Color(0xFFC8C093),
      selection: const Color(0xFF2D4F67).withValues(alpha: 0.55),
      foreground: const Color(0xFFDCD7BA),
      background: const Color(0xFF1F1F28),
      black: const Color(0xFF090618),
      white: const Color(0xFFC8C093),
      red: const Color(0xFFC34043),
      green: const Color(0xFF76946A),
      yellow: const Color(0xFFC0A36E),
      blue: const Color(0xFF7E9CD8),
      magenta: const Color(0xFF957FB8),
      cyan: const Color(0xFF6A9589),
      brightBlack: const Color(0xFF727169),
      brightRed: const Color(0xFFE82424),
      brightGreen: const Color(0xFF98BB6C),
      brightYellow: const Color(0xFFE6C384),
      brightBlue: const Color(0xFF7FB4CA),
      brightMagenta: const Color(0xFF938AA9),
      brightCyan: const Color(0xFF7AA89F),
      brightWhite: const Color(0xFFDCD7BA),
      searchHitBackground: const Color(0xFFE6C384),
      searchHitBackgroundCurrent: const Color(0xFFFF9E3B),
      searchHitForeground: const Color(0xFF1F1F28),
    ),
  ),
  SentinelTerminalThemePreset(
    id: 'cyber_cyan',
    name: 'Cyber Cyan',
    previewBg: const Color(0xFF0B1622),
    previewPrimary: const Color(0xFF38BDF8),
    previewSecondary: const Color(0xFF22D3EE),
    previewAccent: const Color(0xFF818CF8),
    builder: (_, _) => TerminalTheme(
      cursor: const Color(0xFF22D3EE),
      selection: const Color(0xFF0284C7).withValues(alpha: 0.35),
      foreground: const Color(0xFFE0F2FE),
      background: const Color(0xFF0B1622),
      black: const Color(0xFF082F49),
      white: const Color(0xFFBAE6FD),
      red: const Color(0xFFFB7185),
      green: const Color(0xFF34D399),
      yellow: const Color(0xFFFBBF24),
      blue: const Color(0xFF38BDF8),
      magenta: const Color(0xFFA78BFA),
      cyan: const Color(0xFF22D3EE),
      brightBlack: const Color(0xFF0284C7),
      brightRed: const Color(0xFFFDA4AF),
      brightGreen: const Color(0xFF6EE7B7),
      brightYellow: const Color(0xFFFDE047),
      brightBlue: const Color(0xFF7DD3FC),
      brightMagenta: const Color(0xFFC4B5FD),
      brightCyan: const Color(0xFF67E8F9),
      brightWhite: const Color(0xFFF0F9FF),
      searchHitBackground: const Color(0xFF22D3EE),
      searchHitBackgroundCurrent: const Color(0xFF38BDF8),
      searchHitForeground: const Color(0xFF082F49),
    ),
  ),
];

TerminalTheme terminalPresetThemes(
  SentinelThemeTokens tokens,
  bool isDark, {
  String themeId = UserPrefs.defaultTerminalThemeId,
}) {
  for (final preset in kSentinelTerminalThemePresets) {
    if (preset.id == themeId) {
      return preset.builder(tokens, isDark);
    }
  }
  return _buildSentinelDefaultTheme(tokens, isDark);
}
