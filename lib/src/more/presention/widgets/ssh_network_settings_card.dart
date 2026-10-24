import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/application/riverpod/user_prefs.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/sentinel_form_section_card.dart';

import 'settings_tile_widgets.dart';

class SshNetworkSettingsCard extends ConsumerWidget {
  const SshNetworkSettingsCard({super.key, required this.tokens});

  final SentinelThemeTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPrefsProvider);
    final prefsNotifier = ref.read(userPrefsProvider.notifier);

    return SentinelFormSectionCard(
      tokens: tokens,
      title: 'SSH & Network',
      subtitle: 'Timeouts, keep-alive packets & automation',
      icon: Icons.lan_outlined,
      children: [
        SentinelSettingsOptionChips<int>(
          tokens: tokens,
          label: 'Connection Timeout',
          subtitle: 'Maximum wait time for TCP handshake & SSH auth',
          icon: Icons.timer_outlined,
          selectedValue: prefs.sshConnectionTimeoutSeconds,
          options: const [
            (value: 5, label: '5s'),
            (value: 10, label: '10s'),
            (value: 15, label: '15s'),
            (value: 30, label: '30s'),
            (value: 60, label: '60s'),
          ],
          onSelected: prefsNotifier.setSshConnectionTimeout,
        ),
        Divider(height: 16, thickness: 0.7, color: tokens.dividerColor),
        SentinelSettingsOptionChips<int>(
          tokens: tokens,
          label: 'SSH Keep-Alive Interval',
          subtitle: 'Prevent idle firewall disconnects during sessions',
          icon: Icons.monitor_heart_outlined,
          selectedValue: prefs.sshKeepAliveSeconds,
          options: const [
            (value: 0, label: 'Off'),
            (value: 15, label: '15s'),
            (value: 30, label: '30s'),
            (value: 60, label: '60s'),
          ],
          onSelected: prefsNotifier.setSshKeepAlive,
        ),
        Divider(height: 16, thickness: 0.7, color: tokens.dividerColor),
        SentinelSettingsSwitchTile(
          tokens: tokens,
          icon: Icons.radar_rounded,
          title: 'Auto-Ping Hosts on Startup',
          subtitle: 'Measure TCP latency for all saved hosts on launch',
          value: prefs.autoPingOnStartup,
          onChanged: prefsNotifier.setAutoPingOnStartup,
        ),
        Divider(height: 12, thickness: 0.7, color: tokens.dividerColor),
        SentinelSettingsSwitchTile(
          tokens: tokens,
          icon: Icons.sync_rounded,
          title: 'Auto-Reconnect SSH Sessions',
          subtitle: 'Reconnect open terminal tabs when internet is restored',
          value: prefs.autoReconnectSsh,
          onChanged: prefsNotifier.setAutoReconnectSsh,
        ),
        Divider(height: 12, thickness: 0.7, color: tokens.dividerColor),
        SentinelSettingsSwitchTile(
          tokens: tokens,
          icon: Icons.verified_user_outlined,
          title: 'Strict Host Key Verification',
          subtitle: 'Prompt before trusting new SSH server fingerprints',
          value: prefs.strictHostKeyChecking,
          onChanged: prefsNotifier.setStrictHostKeyChecking,
        ),
      ],
    );
  }
}
