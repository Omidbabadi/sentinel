import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/application/riverpod/internet_connectivity_controller.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/common/internet_conectivity.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/injection_container.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/sentinel_state_view.dart';
import 'package:sentinel/src/home/presention/widgets/server_stack_badge.dart';
import 'package:sentinel/src/hosts/domain/usecases/ping_al_host.dart';
import 'package:sentinel/src/hosts/presention/app/adapter/hosts_adapter.dart';

import 'stat_card.dart';

class SummaryRow extends ConsumerWidget {
  const SummaryRow({
    super.key,
    required this.tokens,
    required this.onNavigate,
    required this.state,
  });

  final SentinelThemeTokens tokens;
  final ValueChanged<String> onNavigate;
  final HostsState state;

  double? _calculateAvgPing(List<Host> hosts) {
    final validPings = hosts
        .where((h) => h.ping != null && h.ping! > 0)
        .map((h) => h.ping!)
        .toList();
    if (validPings.isEmpty) return null;
    final total = validPings.reduce((a, b) => a + b);
    return total / validPings.length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(internetConnectivityControllerProvider);
    final isOffline = connectivityAsync.value == false;

    return switch (state) {
      HostsInitial() => Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Total Hosts: 0. Tap to view hosts.',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onNavigate(SentinelRoutes.hosts),
                borderRadius: BorderRadius.circular(18),
                child: StatCard(
                  tokens: tokens,
                  count: '0',
                  label: 'Total Hosts',
                  accentColor: tokens.blueAccent,
                  dotIndicatorColor: tokens.blueAccent,
                  iconWidget: _GlowingOrbBadge(color: tokens.greenAccent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: isOffline
                  ? 'Average Ping: Offline, no internet connection.'
                  : 'Average Ping: Not available.',
              excludeSemantics: true,
              child: StatCard(
                tokens: tokens,
                count: isOffline ? 'Offline' : '-- ms',
                label: 'Avg Ping',
                accentColor: isOffline ? tokens.redAccent : tokens.greenAccent,
                dotIndicatorColor: isOffline
                    ? tokens.redAccent
                    : tokens.textSecondary,
                iconWidget: _PingBadge(
                  color: isOffline ? tokens.redAccent : tokens.textSecondary,
                  isOffline: isOffline,
                ),
              ),
            ),
          ),
        ],
      ),
      HostsLoading() => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading hosts'),
      ),
      HostsError(:final message) => SentinelStateView(
        tokens: tokens,
        icon: Icons.error_outline_rounded,
        title: 'Failed to Load Hosts',
        subtitle: message,
        accentColor: tokens.redAccent,
        isLiveRegion: true,
        actionLabel: 'Retry',
        actionIcon: Icons.refresh_rounded,
        onAction: () {
          ref.read(hostsAdapterProvider.notifier).getHostFromLocalBase();
        },
      ),
      HostsLoaded(:final hosts) => Builder(
        builder: (context) {
          final avgPing = isOffline ? null : _calculateAvgPing(hosts);
          final hasPing = avgPing != null;
          final avgPingText = isOffline
              ? 'Offline'
              : (hasPing ? '${avgPing.round()} ms' : '-- ms');
          final pingColor = isOffline
              ? tokens.redAccent
              : (!hasPing
                    ? tokens.textSecondary
                    : (avgPing < 100
                          ? tokens.greenAccent
                          : (avgPing < 250
                                ? tokens.yellowAccent
                                : tokens.redAccent)));

          return Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Total Hosts: ${hosts.length}. Tap to view hosts.',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => onNavigate(SentinelRoutes.hosts),
                    borderRadius: BorderRadius.circular(18),
                    child: StatCard(
                      tokens: tokens,
                      count: '${hosts.length}',
                      label: 'Total Hosts',
                      accentColor: tokens.blueAccent,
                      dotIndicatorColor: isOffline
                          ? tokens.redAccent
                          : tokens.greenAccent,
                      iconWidget: hosts.isEmpty
                          ? ServerStackBadge(color: tokens.blueAccent)
                          : _GlowingOrbBadge(color: tokens.blueAccent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  button: true,
                  label: isOffline
                      ? 'Average Ping: Offline, no internet connection. Tap to retry.'
                      : (hasPing
                            ? 'Average Ping: ${avgPing.round()} milliseconds. Tap to refresh ping.'
                            : 'Average Ping: Not available. Tap to refresh ping.'),
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () async {
                      final connected = await sl<NetworkInfo>()
                          .checkConnectivity();
                      if (!connected) return;
                      if (hosts.isEmpty) {
                        onNavigate(SentinelRoutes.hosts);
                      } else {
                        await ref
                            .read(hostsAdapterProvider.notifier)
                            .pingAllHosts(params: PingAlHostParams(host: hosts));
                      }
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: StatCard(
                      tokens: tokens,
                      count: avgPingText,
                      label: 'Avg Ping',
                      accentColor: pingColor,
                      dotIndicatorColor: pingColor,
                      iconWidget: _PingBadge(
                        color: pingColor,
                        isOffline: isOffline,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    };
  }
}

class _PingBadge extends StatelessWidget {
  const _PingBadge({required this.color, this.isOffline = false});

  final Color color;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
      child: Center(
        child: Icon(
          isOffline ? Icons.wifi_off_rounded : Icons.speed_rounded,
          size: 14,
          color: color,
        ),
      ),
    );
  }
}

class _GlowingOrbBadge extends StatelessWidget {
  const _GlowingOrbBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 7.5,
          height: 7.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
