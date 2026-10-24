import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    super.key,
    required this.tokens,
    required this.selectedNavIndex,
    required this.onSelectIndex,
  });

  final SentinelThemeTokens tokens;
  final int selectedNavIndex;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    final isTerminalSelected = selectedNavIndex == 2;
    final isDark = tokens.isDark;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.35,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 66),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1E24).withValues(alpha: 0.82)
                        : Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: tokens.cardBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.4 : 0.08,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home_filled,
                        label: 'Home',
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.dns_outlined,
                        label: 'Hosts',
                      ),
                      const SizedBox(width: 54), // Space for center orb
                      _buildNavItem(
                        index: 3,
                        icon: Icons.people_outline_rounded,
                        label: 'Groups',
                      ),
                      _buildNavItem(
                        index: 4,
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Raised Center Glowing Terminal Button
            Positioned(
              top: 0,
              child: Semantics(
                button: true,
                selected: isTerminalSelected,
                label: 'Terminal tab',
                excludeSemantics: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelectIndex(2),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.4),
                          radius: 0.9,
                          colors: isDark
                              ? [
                                  const Color(0xFF3A4352),
                                  const Color(0xFF1F242D),
                                  const Color(0xFF15181F),
                                ]
                              : [
                                  const Color(0xFFFFFFFF),
                                  const Color(0xFFE0DDD5),
                                  const Color(0xFFCCC8BE),
                                ],
                        ),
                        border: Border.all(
                          color: isTerminalSelected
                              ? tokens.greenAccent
                              : (isDark
                                    ? const Color(0xFF7096B8)
                                          .withValues(alpha: 0.55)
                                    : Colors.white.withValues(alpha: 0.9)),
                          width: 1.4,
                        ),
                        boxShadow: [
                          if (isDark)
                            BoxShadow(
                              color:
                                  (isTerminalSelected
                                          ? tokens.greenAccent
                                          : const Color(0xFF4788C7))
                                      .withValues(alpha: 0.28),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.5 : 0.15,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '>_',
                          style: TextStyle(
                            color: isTerminalSelected
                                ? tokens.greenTextAccent
                                : tokens.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedNavIndex == index;
    final color = isSelected ? tokens.textPrimary : tokens.textSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label tab',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelectIndex(index),
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
