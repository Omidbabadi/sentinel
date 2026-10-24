import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/application/riverpod/internet_connectivity_controller.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/sentinel_cube_logo_painter.dart';
import 'package:sentinel/core/widgets/sentinel_status_pill.dart';
import 'package:sentinel/src/hosts/presention/app/adapter/hosts_adapter.dart';
import 'package:sentinel/src/ssh/presention/app/adapter/ssh_adapter.dart';

class SettingsOverviewCard extends ConsumerWidget {
  const SettingsOverviewCard({
    super.key,
    required this.tokens,
    required this.isDark,
  });

  final SentinelThemeTokens tokens;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostsState = ref.watch(hostsAdapterProvider);
    final sshMap = ref.watch(sshAdapterProvider);
    final connectivityAsync = ref.watch(internetConnectivityControllerProvider);
    final isOffline = connectivityAsync.value == false;

    final hostCount = hostsState is HostsLoaded ? hostsState.hosts.length : 0;
    final activeSshCount = sshMap.values.whereType<SshConnected>().length;

    return GlassCard(
      tokens: tokens,
      borderRadius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tokens.innerPillSurface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: tokens.greenAccent.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.greenAccent.withValues(alpha: 0.16),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: SentinelCubeLogoPainter(isDark: isDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sentinel Mesh Core',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'v1.0.0 • AES-256 Encrypted Vault',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              SentinelStatusPill(
                tokens: tokens,
                label: isOffline ? 'Offline' : 'Online',
                color: isOffline ? tokens.redAccent : tokens.greenAccent,
                showDot: true,
                glowDot: !isOffline,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: tokens.innerPillSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.innerPillBorder, width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniMetricItem(
                  tokens: tokens,
                  label: 'Saved Hosts',
                  value: '$hostCount',
                  color: tokens.blueTextAccent,
                ),
                Container(width: 1, height: 24, color: tokens.dividerColor),
                _MiniMetricItem(
                  tokens: tokens,
                  label: 'Active SSH',
                  value: '$activeSshCount',
                  color: activeSshCount > 0
                      ? tokens.greenTextAccent
                      : tokens.textPrimary,
                ),
                Container(width: 1, height: 24, color: tokens.dividerColor),
                _MiniMetricItem(
                  tokens: tokens,
                  label: 'Keystore',
                  value: 'Hardware',
                  color: tokens.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricItem extends StatelessWidget {
  const _MiniMetricItem({
    required this.tokens,
    required this.label,
    required this.value,
    required this.color,
  });

  final SentinelThemeTokens tokens;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13.5,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
