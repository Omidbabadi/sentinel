import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/sentinel_state_view.dart';
import 'package:sentinel/core/widgets/sentinel_top_bar.dart';
import 'package:sentinel/src/home/presention/widgets/open_terminal_host_sheet.dart';

class NoActiveHost extends ConsumerWidget {
  const NoActiveHost({
    super.key,
    required this.onToggleTheme,
    required this.tokens,
    this.onNavigate,
  });

  final void Function()? onToggleTheme;
  final SentinelThemeTokens tokens;
  final ValueChanged<String>? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SentinelTopBar(
              tokens: tokens,
              isDark: tokens.isDark,
              onToggleTheme: onToggleTheme ?? () {},
              currentPath: SentinelRoutes.terminal,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GlassCard(
                tokens: tokens,
                borderRadius: 20,
                padding: const EdgeInsets.all(24),
                child: SentinelStateView(
                  tokens: tokens,
                  icon: Icons.terminal_rounded,
                  accentColor: tokens.textSecondary,
                  title: 'No Active SSH Sessions',
                  subtitle:
                      'Select a host to connect and launch an SSH terminal session.',
                  actionLabel: 'Select a Host',
                  actionIcon: Icons.dns_rounded,
                  onAction: () => OpenTerminalHostSheet.show(
                    context: context,
                    tokens: tokens,
                    isDark: tokens.isDark,
                    onNavigate: (route) {
                      if (onNavigate != null) {
                        onNavigate!(route);
                      } else {
                        context.go(route);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
