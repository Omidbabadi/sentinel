import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/handler/host_key_prompts_handler.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/utils/core_utils.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/host_list_tile.dart';
import 'package:sentinel/core/widgets/sentinel_section_header.dart';
import 'package:sentinel/core/widgets/sentinel_state_view.dart';
import 'package:sentinel/core/widgets/sentinel_status_pill.dart';
import 'package:sentinel/src/ssh/presention/app/adapter/ssh_adapter.dart';

import '../app/adapter/hosts_adapter.dart';
import 'host_action_dropdown_button.dart';

enum HostFilterMode { all, activeSsh, online }

class HostsList extends ConsumerStatefulWidget {
  const HostsList({
    super.key,
    required this.tokens,
    required this.hosts,
    required this.onNavigate,
    required this.activeTabsState,
    required this.sshStates,
  });

  final SentinelThemeTokens tokens;
  final List<Host> hosts;
  final ValueChanged<String> onNavigate;
  final ActiveTabsState activeTabsState;
  final Map<int, SshState> sshStates;

  @override
  ConsumerState<HostsList> createState() => _HostsListState();
}

class _HostsListState extends ConsumerState<HostsList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  HostFilterMode _filterMode = HostFilterMode.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Checks if [host] currently has an open session in [activeTabsState] or [sshStates].
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

  List<Host> _filterHosts() {
    final query = _searchQuery.trim().toLowerCase();
    return widget.hosts.where((host) {
      final isConnected = _hasOpenConnection(
        widget.activeTabsState,
        widget.sshStates,
        host,
      );

      final matchesFilter = switch (_filterMode) {
        HostFilterMode.all => true,
        HostFilterMode.activeSsh => isConnected,
        HostFilterMode.online => host.isReachable,
      };
      if (!matchesFilter) return false;

      if (query.isEmpty) return true;

      final osName = host.os?.osName.name.toLowerCase() ?? '';
      final osVersion = host.os?.osVersion.toLowerCase() ?? '';
      final group = host.groupName?.toLowerCase() ?? '';

      return host.hostname.toLowerCase().contains(query) ||
          host.ip.toLowerCase().contains(query) ||
          host.username.toLowerCase().contains(query) ||
          '${host.port}'.contains(query) ||
          osName.contains(query) ||
          osVersion.contains(query) ||
          group.contains(query);
    }).toList();
  }

  void _clearSearchAndFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filterMode = HostFilterMode.all;
    });
  }

  void _handleEditHost(BuildContext context, Host host) {
    context.push(SentinelRoutes.editHost(host), extra: host);
  }

  Future<void> _handleDeleteHost(BuildContext context, Host host) async {
    if (host.id == null) return;

    final confirmed = await PromptsHandlerImpl().confirmDeletion(host: host);
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(hostsAdapterProvider.notifier).deleteHost(host.id!);
      if (context.mounted) {
        CoreUtils.showSnackBar('Host "${host.hostname}" deleted');
      }
    } catch (e) {
      if (context.mounted) {
        CoreUtils.showSnackBar('Failed to delete host: $e', isError: true);
      }
    }
  }

  void _openHostTerminal(Host host) {
    ref.read(activeHostTabControllerProvider.notifier).openHost(host);
    widget.onNavigate(SentinelRoutes.hostTerminal(host.hostname, host.ip));
  }

  void _openHostSftp(BuildContext context, Host host) {
    ref.read(activeHostTabControllerProvider.notifier).openHost(host);
    context.push(SentinelRoutes.sftp, extra: host);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final filteredHosts = _filterHosts();
    final isFiltering =
        _searchQuery.trim().isNotEmpty || _filterMode != HostFilterMode.all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        SentinelSectionHeader(
          title: 'All Hosts',
          tokens: tokens,
          trailing: SentinelStatusPill(
            tokens: tokens,
            label: 'Add Host',
            icon: Icons.add_rounded,
            color: tokens.greenAccent,
            fontSize: 11.5,
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            onTap: () => context.push(SentinelRoutes.editHost()),
          ),
        ),
        const SizedBox(height: 14),

        // Search Bar
        GlassCard(
          tokens: tokens,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: _searchQuery.isNotEmpty
                      ? tokens.greenAccent
                      : tokens.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    label: 'Search hosts by hostname, IP, username or OS',
                    textField: true,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search hostname, IP, user or OS...',
                        hintStyle: TextStyle(
                          color: tokens.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isFiltering) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.innerPillSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tokens.innerPillBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '${filteredHosts.length}/${widget.hosts.length}',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 10.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (_searchQuery.isNotEmpty)
                  Semantics(
                    button: true,
                    label: 'Clear search query',
                    child: Tooltip(
                      message: 'Clear search',
                      child: InkWell(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Filter Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _FilterChipPill(
                tokens: tokens,
                label: 'All (${widget.hosts.length})',
                icon: Icons.dns_outlined,
                isSelected: _filterMode == HostFilterMode.all,
                onTap: () => setState(() => _filterMode = HostFilterMode.all),
              ),
              const SizedBox(width: 8),
              _FilterChipPill(
                tokens: tokens,
                label: 'Online',
                icon: Icons.speed_rounded,
                isSelected: _filterMode == HostFilterMode.online,
                onTap: () => setState(
                  () => _filterMode = _filterMode == HostFilterMode.online
                      ? HostFilterMode.all
                      : HostFilterMode.online,
                ),
              ),
              const SizedBox(width: 8),
              _FilterChipPill(
                tokens: tokens,
                label: 'Active SSH',
                icon: Icons.terminal_rounded,
                isSelected: _filterMode == HostFilterMode.activeSsh,
                onTap: () => setState(
                  () => _filterMode = _filterMode == HostFilterMode.activeSsh
                      ? HostFilterMode.all
                      : HostFilterMode.activeSsh,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Filtered Hosts List or Empty Search State
        if (filteredHosts.isEmpty)
          SentinelStateView(
            tokens: tokens,
            icon: Icons.search_off_rounded,
            title: 'No Matching Hosts',
            subtitle: _searchQuery.trim().isNotEmpty
                ? 'No hosts matched "${_searchQuery.trim()}".'
                : 'No hosts match the selected filter.',
            accentColor: tokens.blueAccent,
            wrapInGlassCard: true,
            actionLabel: 'Reset Filter',
            actionIcon: Icons.refresh_rounded,
            onAction: _clearSearchAndFilters,
          )
        else
          GlassCard(
            tokens: tokens,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderRadius: 20,
            child: Column(
              children: [
                for (int i = 0; i < filteredHosts.length; i++) ...[
                  Builder(
                    builder: (context) {
                      final host = filteredHosts[i];
                      final isConnected = _hasOpenConnection(
                        widget.activeTabsState,
                        widget.sshStates,
                        host,
                      );

                      return HostListTile(
                        host: host,
                        tokens: tokens,
                        subtitle: 'ssh ${host.username}@${host.ip}',
                        subtitleMonospace: true,
                        isConnected: isConnected,
                        showPingPill: true,
                        showActivePill: true,
                        onTap: () => _openHostTerminal(host),
                        trailing: HostActionDropdownButton(
                          isConnected: isConnected,
                          tokens: tokens,
                          isDark: tokens.isDark,
                          onEdit: () => _handleEditHost(context, host),
                          onDelete: () => _handleDeleteHost(context, host),
                          onOpenNewTerminal: () => _openHostTerminal(host),
                          onOpenSftp: () => _openHostSftp(context, host),
                        ),
                      );
                    },
                  ),
                  if (i < filteredHosts.length - 1)
                    Divider(
                      height: 14,
                      thickness: 0.7,
                      color: tokens.dividerColor,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.tokens,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final SentinelThemeTokens tokens;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label filter',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? tokens.greenAccent.withValues(
                      alpha: tokens.isDark ? 0.18 : 0.14,
                    )
                  : tokens.innerPillSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? tokens.greenAccent.withValues(alpha: 0.50)
                    : tokens.innerPillBorder,
                width: isSelected ? 1.0 : 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13.5,
                  color: isSelected
                      ? tokens.greenTextAccent
                      : tokens.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? tokens.greenTextAccent
                        : tokens.textSecondary,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
