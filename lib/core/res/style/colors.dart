import 'package:flutter/material.dart';

abstract class Pallet {
  // --- Legacy / Existing Colors ---
  static const Color errorColor = Color(0xffEF2D56);
  static const Color succsessColor = Color(0xff397367);
  static const Color warningColor = Color(0xffED7D3A);

  // --- Base Surfaces & Infrastructure Neutrals ---
  static const Color lightCanvasBase = Color(0xFFf8f9ff); //[cite: 4]
  static const Color darkCanvasBase = Color(0xFF0A0D14); //[cite: 1]

  static const Color lightSurfaceLayer1 = Color(0xFFffffff); //[cite: 4]
  static const Color darkSurfaceLayer1 = Color(0xFF111622); //[cite: 1]

  static const Color lightSurfaceLayer2 = Color(0xFFeff4ff); //[cite: 4]
  static const Color darkSurfaceLayer2 = Color(0xFF182030); //[cite: 1]

  static const Color lightSubtleStroke = Color(0xFFc6c6cd); //[cite: 4]
  static const Color darkSubtleStroke = Color(0xFF1F293D); //[cite: 1]

  // --- Semantic Status & Metric Accents ---
  static const Color operationalEmerald = Color(0xFF10B981); //[cite: 1]
  static const Color meshCyan = Color(0xFF06B6D4); //[cite: 1]
  static const Color warningAmber = Color(0xFFF59E0B); //[cite: 1]
  static const Color criticalRose = Color(0xFFEF4444); //[cite: 1]

  // --- Material 3 Token Colors (Explicit Light & Dark) ---
  static const Color lightSurface = Color(0xFFf8f9ff); //[cite: 4]
  static const Color darkSurface = Color(0xFF10131a); //[cite: 1]

  static const Color lightSurfaceDim = Color(0xFFcbdbf5); //[cite: 4]
  static const Color darkSurfaceDim = Color(0xFF10131a); //[cite: 1]

  static const Color lightSurfaceBright = Color(0xFFf8f9ff); //[cite: 4]
  static const Color darkSurfaceBright = Color(0xFF363941); //[cite: 1]

  static const Color lightSurfaceContainerLowest = Color(
    0xFFffffff,
  ); //[cite: 4]
  static const Color darkSurfaceContainerLowest = Color(0xFF0b0e15); //[cite: 1]

  static const Color lightSurfaceContainerLow = Color(0xFFeff4ff); //[cite: 4]
  static const Color darkSurfaceContainerLow = Color(0xFF191b23); //[cite: 1]

  static const Color lightSurfaceContainer = Color(0xFFe5eeff); //[cite: 4]
  static const Color darkSurfaceContainer = Color(0xFF1d1f27); //[cite: 1]

  static const Color lightSurfaceContainerHigh = Color(0xFFdce9ff); //[cite: 4]
  static const Color darkSurfaceContainerHigh = Color(0xFF272a32); //[cite: 1]

  static const Color lightSurfaceContainerHighest = Color(
    0xFFd3e4fe,
  ); //[cite: 4]
  static const Color darkSurfaceContainerHighest = Color(
    0xFF32353d,
  ); //[cite: 1]

  static const Color lightOnSurface = Color(0xFF0b1c30); //[cite: 4]
  static const Color darkOnSurface = Color(0xFFe1e2ec); //[cite: 1]

  static const Color lightOnSurfaceVariant = Color(0xFF45464d); //[cite: 4]
  static const Color darkOnSurfaceVariant = Color(0xFFbbcabf); //[cite: 1]

  static const Color lightPrimary = Color(0xFF131B2E); //[cite: 4]
  static const Color darkPrimary = Color(0xFF4edea3); //[cite: 1]

  static const Color lightOnPrimary = Color(0xFFffffff); //[cite: 4]
  static const Color darkOnPrimary = Color(0xFF003824); //[cite: 1]

  static const Color lightPrimaryContainer = Color(0xFF131b2e); //[cite: 4]
  static const Color darkPrimaryContainer = Color(0xFF10b981); //[cite: 1]

  static const Color lightOnPrimaryContainer = Color(0xFF7c839b); //[cite: 4]
  static const Color darkOnPrimaryContainer = Color(0xFF00422b); //[cite: 1]

  static const Color lightSecondary = Color(0xFF006398); //[cite: 4]
  static const Color darkSecondary = Color(0xFF4cd7f6); //[cite: 1]

  static const Color lightOnSecondary = Color(0xFFffffff); //[cite: 4]
  static const Color darkOnSecondary = Color(0xFF003640); //[cite: 1]

  static const Color lightSecondaryContainer = Color(0xFF5bb8fe); //[cite: 4]
  static const Color darkSecondaryContainer = Color(0xFF03b5d3); //[cite: 1]

  static const Color lightOnSecondaryContainer = Color(0xFF00476e); //[cite: 4]
  static const Color darkOnSecondaryContainer = Color(0xFF00424e); //[cite: 1]

  static const Color lightTertiary = Color(0xFF000000); //[cite: 4]
  static const Color darkTertiary = Color(0xFFffb95f); //[cite: 1]

  static const Color lightOnTertiary = Color(0xFFffffff); //[cite: 4]
  static const Color darkOnTertiary = Color(0xFF472a00); //[cite: 1]

  static const Color lightTertiaryContainer = Color(0xFF002114); //[cite: 4]
  static const Color darkTertiaryContainer = Color(0xFFe29100); //[cite: 1]

  static const Color lightOnTertiaryContainer = Color(0xFF069669); //[cite: 4]
  static const Color darkOnTertiaryContainer = Color(0xFF523200); //[cite: 1]

  static const Color lightError = Color(0xFFba1a1a); //[cite: 4]
  static const Color darkError = Color(0xFFffb4ab); //[cite: 1]

  static const Color lightOnError = Color(0xFFffffff); //[cite: 4]
  static const Color darkOnError = Color(0xFF690005); //[cite: 1]

  static const Color lightErrorContainer = Color(0xFFffdad6); //[cite: 4]
  static const Color darkErrorContainer = Color(0xFF93000a); //[cite: 1]

  static const Color lightOnErrorContainer = Color(0xFF93000a); //[cite: 4]
  static const Color darkOnErrorContainer = Color(0xFFffdad6); //[cite: 1]

  static const Color lightBackground = Color(0xffEEF0FF); //[cite: 4]
  static const Color darkBackground = Color(0xFF10131a); //[cite: 1]

  static const Color lightOnBackground = Color(0xFF0b1c30); //[cite: 4]
  static const Color darkOnBackground = Color(0xFFe1e2ec); //[cite: 1]

  static const Color lightTritaryT10 = Color(0xFF002114);
  static const Color lightTritaryT20 = Color(0xFF003825);
  static const Color lightTritaryT30 = Color(0xFF005137);
  static const Color lightTritaryT40 = Color(0xFF006C4A);
  static const Color lightTritaryT50 = Color(0xFF00885F);
  static const Color lightTritaryT60 = Color(0xFF25A475);
  static const Color lightTritaryT70 = Color(0xFF49BF8F);
  static const Color lightTritaryT80 = Color(0xFF68DBA9);
  static const Color lightTritaryT90 = Color(0xFF85F8C4);

  static const Color lightPrimaryT10 = Color(0xFF131B2E);
  static const Color lightPrimaryT20 = Color(0xFF283044);
  static const Color lightPrimaryT30 = Color(0xFF3F465C);
  static const Color lightPrimaryT40 = Color(0xFF565E74);
  static const Color lightPrimaryT50 = Color(0xFF6F778E);
}
