import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/sentinel_cube_logo_painter.dart';
import 'package:sentinel/core/widgets/user_portrait_avatar_painter.dart';

import 'toggle_theme_button.dart';

class SentinelTopBar extends StatelessWidget {
  final SentinelThemeTokens tokens;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final String currentPath;

  const SentinelTopBar({
    super.key,
    required this.tokens,
    required this.isDark,
    required this.onToggleTheme,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final isHome = currentPath == SentinelRoutes.home;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              header: true,
              button: true,
              label: 'Sentinel, tap to switch theme',
              excludeSemantics: true,
              child: InkWell(
                onTap: onToggleTheme,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CustomPaint(
                          painter: SentinelCubeLogoPainter(isDark: isDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sentinel',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: onToggleTheme,
                  tooltip: 'Notifications',
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: tokens.textPrimary.withValues(alpha: 0.75),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 4),
                Semantics(
                  image: true,
                  label: 'User profile avatar',
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: tokens.cardBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CustomPaint(painter: UserPortraitAvatarPainter()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isHome) const ToggleThemeButton(),
      ],
    );
  }
}
