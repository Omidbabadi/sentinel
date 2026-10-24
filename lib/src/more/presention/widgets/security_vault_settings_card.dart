import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/application/riverpod/current_theme_controller.dart';
import 'package:sentinel/core/common/application/riverpod/user_prefs.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/security/credential_store.dart';
import 'package:sentinel/core/services/injection_container.dart';
import 'package:sentinel/core/utils/core_utils.dart';
import 'package:sentinel/core/widgets/sentinel_form_section_card.dart';
import 'package:sentinel/core/widgets/sentinel_toast.dart';
import 'package:sentinel/src/hosts/domain/usecases/ping_al_host.dart';
import 'package:sentinel/src/hosts/presention/app/adapter/hosts_adapter.dart';
import 'package:sentinel/src/ssh/presention/app/adapter/ssh_adapter.dart';

import 'settings_tile_widgets.dart';

class SecurityVaultSettingsCard extends ConsumerWidget {
  const SecurityVaultSettingsCard({super.key, required this.tokens});

  final SentinelThemeTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostsState = ref.watch(hostsAdapterProvider);
    final sshMap = ref.watch(sshAdapterProvider);
    final activeSshCount = sshMap.values.whereType<SshConnected>().length;

    return SentinelFormSectionCard(
      tokens: tokens,
      title: 'Security & Vault',
      subtitle: 'Encrypted keystore, fingerprints & diagnostics',
      icon: Icons.shield_outlined,
      children: [
        SentinelSettingsActionTile(
          tokens: tokens,
          icon: Icons.network_ping_rounded,
          accentColor: tokens.greenAccent,
          title: 'Run Network Ping Sweep',
          subtitle: 'Test TCP reachability across all saved hosts now',
          trailingBadge: hostsState is HostsLoaded
              ? '${hostsState.hosts.length} hosts'
              : null,
          onTap: () async {
            if (hostsState is! HostsLoaded || hostsState.hosts.isEmpty) {
              CoreUtils.showToast(
                'No saved hosts available to ping.',
                title: 'Ping Sweep',
                type: SentinelToastType.info,
              );
              return;
            }
            final updated = await ref
                .read(hostsAdapterProvider.notifier)
                .pingAllHosts(
                  params: PingAlHostParams(host: hostsState.hosts),
                );
            final online = updated.where((h) => h.isReachable).length;
            CoreUtils.showToast(
              '$online of ${updated.length} hosts reachable.',
              title: 'Ping Sweep Complete',
              type: online > 0
                  ? SentinelToastType.success
                  : SentinelToastType.warning,
            );
          },
        ),
        Divider(height: 12, thickness: 0.7, color: tokens.dividerColor),
        SentinelSettingsActionTile(
          tokens: tokens,
          icon: Icons.fingerprint_rounded,
          accentColor: tokens.blueAccent,
          title: 'Clear Trusted SSH Fingerprints',
          subtitle: 'Reset saved server host keys in secure storage',
          onTap: () async {
            final cleared = await sl<CredentialStore>()
                .clearAllHostFingerprints();
            CoreUtils.showToast(
              cleared > 0
                  ? 'Cleared $cleared saved SSH host key fingerprint${cleared == 1 ? '' : 's'}.'
                  : 'No saved SSH host key fingerprints to clear.',
              title: 'Vault Updated',
              type: SentinelToastType.info,
            );
          },
        ),
        Divider(height: 12, thickness: 0.7, color: tokens.dividerColor),
        SentinelSettingsActionTile(
          tokens: tokens,
          icon: Icons.power_settings_new_rounded,
          accentColor: tokens.yellowAccent,
          title: 'Disconnect All SSH Sessions',
          subtitle: 'Close all active remote shells immediately',
          trailingBadge: '$activeSshCount active',
          onTap: () async {
            if (activeSshCount == 0) {
              CoreUtils.showToast(
                'There are no active SSH sessions to disconnect.',
                title: 'SSH Sessions',
                type: SentinelToastType.info,
              );
              return;
            }
            await ref.read(sshAdapterProvider.notifier).disconnectAll();
            CoreUtils.showToast(
              'Closed $activeSshCount active SSH session${activeSshCount == 1 ? '' : 's'}.',
              title: 'Disconnected',
              type: SentinelToastType.success,
            );
          },
        ),
        Divider(height: 12, thickness: 0.7, color: tokens.dividerColor),
        SentinelSettingsActionTile(
          tokens: tokens,
          icon: Icons.restart_alt_rounded,
          isDestructive: true,
          title: 'Reset Settings to Defaults',
          subtitle: 'Restore default theme, terminal & network preferences',
          onTap: () async {
            await ref.read(userPrefsProvider.notifier).resetToDefaults();
            ref
                .read(currentThemeProvider.notifier)
                .toggleTheme(ThemeMode.system);
            CoreUtils.showToast(
              'All preferences have been restored to factory defaults.',
              title: 'Settings Reset',
              type: SentinelToastType.info,
            );
          },
        ),
      ],
    );
  }
}
