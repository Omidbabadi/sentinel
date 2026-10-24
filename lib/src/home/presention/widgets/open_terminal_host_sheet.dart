import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/host_list_tile.dart';
import 'package:sentinel/core/widgets/sentinel_botton.dart';
import 'package:sentinel/core/widgets/sentinel_state_view.dart';
import 'package:sentinel/src/hosts/presention/app/adapter/hosts_adapter.dart';
import 'package:sentinel/src/ssh/presention/app/adapter/ssh_adapter.dart';

class OpenTerminalHostSheet extends ConsumerStatefulWidget {
  const OpenTerminalHostSheet({
    super.key,
    required this.tokens,
    required this.isDark,
    required this.onSelectHost,
    required this.onAddHost,
  });

  final SentinelThemeTokens tokens;
  final bool isDark;
  final ValueChanged<Host> onSelectHost;
  final VoidCallback onAddHost;

  static Future<Host?> pickHost({
    required BuildContext context,
    required SentinelThemeTokens tokens,
    required bool isDark,
  }) {
    return showModalBottomSheet<Host>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (sheetContext) {
        return OpenTerminalHostSheet(
          tokens: tokens,
          isDark: isDark,
          onSelectHost: (host) => Navigator.of(sheetContext).pop(host),
          onAddHost: () {
            Navigator.of(sheetContext).pop();
            context.push(SentinelRoutes.editHost());
          },
        );
      },
    );
  }

  static Future<void> show({
    required BuildContext context,
    required SentinelThemeTokens tokens,
    required bool isDark,
    required ValueChanged<String> onNavigate,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final selectedHost = await pickHost(
      context: context,
      tokens: tokens,
      isDark: isDark,
    );

    if (selectedHost != null) {
      container
          .read(activeHostTabControllerProvider.notifier)
          .openHost(selectedHost);
      onNavigate(
        SentinelRoutes.hostTerminal(selectedHost.hostname, selectedHost.ip),
      );
    }
  }

  @override
  ConsumerState<OpenTerminalHostSheet> createState() =>
      _OpenTerminalHostSheetState();
}

class _OpenTerminalHostSheetState extends ConsumerState<OpenTerminalHostSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _hasOpenConnection(
    ActiveTabsState activeTabsState,
    Map<int, SshState> sshStates,
    Host host,
  ) {
    final hostId = host.id;
    if (hostId != null) {
      if (sshStates[hostId] is SshConnected) return true;
      if (activeTabsState.tabs.any((tab) => tab.id == hostId)) return true;
    }
    return activeTabsState.tabs.any(
      (tab) => tab.host.ip == host.ip && tab.host.hostname == host.hostname,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final isDark = widget.isDark;
    final hostsState = ref.watch(hostsAdapterProvider);
    final activeTabsState = ref.watch(activeHostTabControllerProvider);
    final sshStates = ref.watch(sshAdapterProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.72;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: maxSheetHeight,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: GlassCard(
                tokens: tokens,
                borderRadius: 26,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle
                    Center(
                      child: ExcludeSemantics(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: tokens.textMuted.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header Row
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.greenAccent.withValues(alpha: 0.15),
                            border: Border.all(
                              color: tokens.greenAccent.withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: tokens.greenAccent.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.terminal_rounded,
                            size: 18,
                            color: tokens.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  'Open SSH Terminal',
                                  style: TextStyle(
                                    color: tokens.textPrimary,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select a host to connect or switch session',
                                style: TextStyle(
                                  color: tokens.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SentinelButton(
                          tokens: tokens,
                          isDark: isDark,
                          width: 34,
                          height: 34,
                          borderRadius: 11,
                          semanticLabel: 'Close host selector',
                          tooltip: 'Close',
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(
                            Icons.close_rounded,
                            size: 17,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Body Content based on HostsState
                    Flexible(
                      child: switch (hostsState) {
                        HostsInitial() || HostsLoading() => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Loading hosts',
                            ),
                          ),
                        ),
                        HostsError(:final message) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: SentinelStateView(
                            tokens: tokens,
                            icon: Icons.error_outline_rounded,
                            title: 'Failed to Load Hosts',
                            subtitle: message,
                            accentColor: tokens.redAccent,
                            actionLabel: 'Retry',
                            actionIcon: Icons.refresh_rounded,
                            onAction: () {
                              ref
                                  .read(hostsAdapterProvider.notifier)
                                  .getHostFromLocalBase();
                            },
                          ),
                        ),
                        HostsLoaded(:final hosts) =>
                          hosts.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: SentinelStateView(
                                    tokens: tokens,
                                    icon: Icons.dns_outlined,
                                    title: 'No Hosts Available',
                                    subtitle:
                                        'Add your first server host to launch an SSH terminal.',
                                    accentColor: tokens.greenAccent,
                                    actionLabel: 'Add Host',
                                    actionIcon: Icons.add_rounded,
                                    onAction: widget.onAddHost,
                                  ),
                                )
                              : _buildHostsList(
                                  hosts: hosts,
                                  tokens: tokens,
                                  activeTabsState: activeTabsState,
                                  sshStates: sshStates,
                                ),
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHostsList({
    required List<Host> hosts,
    required SentinelThemeTokens tokens,
    required ActiveTabsState activeTabsState,
    required Map<int, SshState> sshStates,
  }) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredHosts = normalizedQuery.isEmpty
        ? hosts
        : hosts.where((h) {
            return h.hostname.toLowerCase().contains(normalizedQuery) ||
                h.ip.toLowerCase().contains(normalizedQuery) ||
                h.username.toLowerCase().contains(normalizedQuery) ||
                (h.groupName?.toLowerCase().contains(normalizedQuery) ?? false);
          }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hosts.length > 2) ...[
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: tokens.innerPillSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.innerPillBorder, width: 0.8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: tokens.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _query = val),
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 12.5,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search hostname, IP or user...',
                      hintStyle: TextStyle(
                        color: tokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: tokens.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (filteredHosts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              'No hosts match "$_query"',
              style: TextStyle(color: tokens.textSecondary, fontSize: 12.5),
            ),
          )
        else
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.innerPillSurface.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: tokens.innerPillBorder, width: 0.8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: filteredHosts.length,
                separatorBuilder: (_, _) => Divider(
                  height: 10,
                  thickness: 0.7,
                  color: tokens.dividerColor,
                ),
                itemBuilder: (context, index) {
                  final host = filteredHosts[index];
                  final isConnected = _hasOpenConnection(
                    activeTabsState,
                    sshStates,
                    host,
                  );

                  return HostListTile(
                    host: host,
                    tokens: tokens,
                    subtitle: '${host.username}@${host.ip}:${host.port}',
                    subtitleMonospace: true,
                    isConnected: isConnected,
                    showPingPill: true,
                    showActivePill: true,
                    onTap: () => widget.onSelectHost(host),
                    trailing: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.greenAccent.withValues(alpha: 0.14),
                        border: Border.all(
                          color: tokens.greenAccent.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: tokens.greenAccent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
