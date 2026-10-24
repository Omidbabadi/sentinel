import 'package:flutter/material.dart';

class SentinelThemeTokens {
  final bool isDark;

  SentinelThemeTokens(this.isDark);

  Color get backGroundColor =>
      isDark ? const Color(0xFF121417) : const Color(0xFFEFECE6);

  Color get bgTop => isDark ? const Color(0xFF15181E) : const Color(0xFFF3F1EC);
  Color get bgBottom =>
      isDark ? const Color(0xFF0E1014) : const Color(0xFFE7E4DD);

  Color get textPrimary =>
      isDark ? const Color(0xFFF7F8FA) : const Color(0xFF1C1E21);

  /// WCAG AA >= 4.5:1 against both backgrounds and card surfaces
  Color get textSecondary =>
      isDark ? const Color(0xFF9EA4B0) : const Color(0xFF52565E);

  /// WCAG AA >= 4.5:1 in both dark and light modes
  Color get textMuted =>
      isDark ? const Color(0xFF8A909E) : const Color(0xFF5F636B);

  Color get cardSurface => isDark
      ? const Color(0xFF232830).withValues(alpha: 0.58)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.54);

  Color get cardBorder => isDark
      ? Colors.white.withValues(alpha: 0.11)
      : Colors.white.withValues(alpha: 0.75);

  Color get innerPillSurface => isDark
      ? const Color(0xFF2B303A).withValues(alpha: 0.65)
      : const Color(0xFFF4F3EF).withValues(alpha: 0.72);

  Color get innerPillBorder => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.05);

  Color get dividerColor => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.05);

  Color get greenAccent => const Color(0xFF39C98A);
  Color get redAccent => const Color(0xFFF05454);
  Color get yellowAccent => const Color(0xFFE9A93B);
  Color get blueAccent => const Color(0xFF4796E5);

  /// Accessible text accent colors ensuring >= 4.5:1 contrast on light & dark surfaces
  Color get greenTextAccent =>
      isDark ? const Color(0xFF39C98A) : const Color(0xFF0E7448);
  Color get redTextAccent =>
      isDark ? const Color(0xFFF66A6A) : const Color(0xFFC81E1E);
  Color get yellowTextAccent =>
      isDark ? const Color(0xFFF0B44C) : const Color(0xFF945800);
  Color get blueTextAccent =>
      isDark ? const Color(0xFF5CA3EC) : const Color(0xFF1D5BB8);
}
