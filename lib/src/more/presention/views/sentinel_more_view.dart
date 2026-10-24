import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/sentinel_section_header.dart';
import 'package:sentinel/src/more/presention/widgets/appearance_settings_card.dart';
import 'package:sentinel/src/more/presention/widgets/security_vault_settings_card.dart';
import 'package:sentinel/src/more/presention/widgets/settings_overview_card.dart';
import 'package:sentinel/src/more/presention/widgets/ssh_network_settings_card.dart';
import 'package:sentinel/src/more/presention/widgets/terminal_settings_card.dart';

class SentinelMoreView extends ConsumerWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final ValueChanged<String> onNavigate;

  const SentinelMoreView({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = SentinelThemeTokens(isDark);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 108),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          SentinelSectionHeader(
            title: 'Settings',
            tokens: tokens,
            fontSize: 24,
          ),
          const SizedBox(height: 12),
          SettingsOverviewCard(tokens: tokens, isDark: isDark),
          const SizedBox(height: 14),
          AppearanceSettingsCard(tokens: tokens),
          const SizedBox(height: 14),
          TerminalSettingsCard(tokens: tokens, isDark: isDark),
          const SizedBox(height: 14),
          SshNetworkSettingsCard(tokens: tokens),
          const SizedBox(height: 14),
          SecurityVaultSettingsCard(tokens: tokens),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Sentinel SSH & Infrastructure Controller • Built with Flutter',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textMuted,
                fontSize: 10.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
