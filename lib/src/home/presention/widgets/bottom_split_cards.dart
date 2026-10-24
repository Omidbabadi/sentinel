import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/src/groups/presention/widgets/edit_group_sheet.dart';

import 'open_terminal_host_sheet.dart';
import 'quick_action_button.dart';

class BottomSplitCards extends StatelessWidget {
  const BottomSplitCards({
    super.key,
    required this.tokens,
    required this.isDark,
    required this.onNavigate,
  });

  final SentinelThemeTokens tokens;
  final bool isDark;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GlassCard(
              tokens: tokens,
              padding: const EdgeInsets.all(12),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  QuickActionButton(
                    tokens: tokens,
                    isDark: isDark,
                    icon: Icons.add_rounded,
                    label: 'Add Host',
                    onTap: () => context.push(SentinelRoutes.editHost()),
                  ),
                  const SizedBox(height: 7),
                  QuickActionButton(
                    tokens: tokens,
                    isDark: isDark,
                    icon: Icons.terminal_rounded,
                    label: 'Open Terminal',
                    onTap: () => OpenTerminalHostSheet.show(
                      context: context,
                      tokens: tokens,
                      isDark: isDark,
                      onNavigate: onNavigate,
                    ),
                  ),
                  const SizedBox(height: 7),
                  QuickActionButton(
                    tokens: tokens,
                    isDark: isDark,
                    icon: Icons.people_outline_rounded,
                    label: 'Create Group',
                    onTap: () async {
                      final created = await EditGroupSheet.show(
                        context,
                        isDark: isDark,
                      );
                      if (created == true && context.mounted) {
                        onNavigate(SentinelRoutes.groups);
                      }
                    },
                  ),
                  const SizedBox(height: 7),
                  QuickActionButton(
                    tokens: tokens,
                    isDark: isDark,
                    icon: Icons.folder_open_rounded,
                    label: 'SFTP Browser',
                    onTap: () async {
                      final host = await OpenTerminalHostSheet.pickHost(
                        context: context,
                        tokens: tokens,
                        isDark: isDark,
                      );
                      if (host != null && context.mounted) {
                        context.push(SentinelRoutes.sftp, extra: host);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
