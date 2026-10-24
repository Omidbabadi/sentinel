import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/sentinel_section_header.dart';
import 'package:sentinel/core/widgets/sentinel_state_view.dart';
import 'package:sentinel/src/hosts/presention/widgets/hosts_list.dart';
import 'package:sentinel/src/ssh/presention/app/adapter/ssh_adapter.dart';

import '../app/adapter/hosts_adapter.dart';

class SentinelHostsView extends ConsumerWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final ValueChanged<String> onNavigate;

  const SentinelHostsView({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onNavigate,
  });

  Widget _buildEmptyHostsState(
    BuildContext context,
    SentinelThemeTokens tokens,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        SentinelSectionHeader(title: 'All Hosts', tokens: tokens),
        const SizedBox(height: 28),
        SentinelStateView(
          tokens: tokens,
          icon: Icons.dns_outlined,
          title: 'No SSH Hosts Configured',
          subtitle:
              'Add your first remote server or Linux instance to start managing SSH sessions and monitoring latency.',
          actionLabel: 'Add First Host',
          actionIcon: Icons.add_rounded,
          onAction: () => context.push(SentinelRoutes.editHost()),
          wrapInGlassCard: true,
          showGlowingBadge: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = SentinelThemeTokens(isDark);
    final state = ref.watch(hostsAdapterProvider);
    final activeTabsState = ref.watch(activeHostTabControllerProvider);
    final sshStates = ref.watch(sshAdapterProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 104),
      child: switch (state) {
        HostsInitial() => SentinelStateView(
          tokens: tokens,
          icon: Icons.storage_outlined,
          title: 'Load hosts from database',
          actionLabel: 'Load Hosts',
          actionIcon: Icons.refresh_rounded,
          onAction: () {
            ref.read(hostsAdapterProvider.notifier).getHostFromLocalBase();
          },
        ),
        HostsLoading() => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Loading hosts'),
        ),
        HostsError(:final message) => SentinelStateView(
          tokens: tokens,
          icon: Icons.error_outline_rounded,
          title: 'Error Loading Hosts',
          subtitle: message,
          accentColor: tokens.redAccent,
          isLiveRegion: true,
          actionLabel: 'Retry',
          actionIcon: Icons.refresh_rounded,
          onAction: () {
            ref.read(hostsAdapterProvider.notifier).getHostFromLocalBase();
          },
        ),
        HostsLoaded(:final hosts) =>
          hosts.isEmpty
              ? _buildEmptyHostsState(context, tokens)
              : HostsList(
                  tokens: tokens,
                  hosts: hosts,
                  onNavigate: onNavigate,
                  activeTabsState: activeTabsState,
                  sshStates: sshStates,
                ),
      },
    );
  }
}
