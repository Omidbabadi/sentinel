import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/common/entities/server_group.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/sentinel_botton.dart';
import 'package:sentinel/core/widgets/sentinel_glass_field.dart';
import 'package:sentinel/core/widgets/sentinel_primary_button.dart';
import 'package:sentinel/src/groups/presention/app/adapter/groups_adapter.dart';
import 'package:sentinel/src/groups/presention/widgets/edit_group_sheet.dart';
import 'package:sentinel/src/groups/presention/widgets/group_card.dart';
import 'package:sentinel/src/hosts/domain/usecases/ping_al_host.dart';
import 'package:sentinel/src/hosts/presention/app/adapter/hosts_adapter.dart';
import 'package:sentinel/src/ssh/presention/app/adapter/ssh_adapter.dart';

class SentinelGroupsView extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final ValueChanged<String> onNavigate;

  const SentinelGroupsView({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onNavigate,
  });

  @override
  ConsumerState<SentinelGroupsView> createState() => _SentinelGroupsViewState();
}

class _SentinelGroupsViewState extends ConsumerState<SentinelGroupsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupsState = ref.read(groupsAdapterProvider);
      if (groupsState is GroupsInitial) {
        ref.read(groupsAdapterProvider.notifier).getGroupsFromLocalBase();
      }
    });
  }

  void _onSearchChanged() {
    final next = _searchController.text.trim();
    if (next != _searchQuery) {
      setState(() => _searchQuery = next);
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
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

  void _openHostTerminal(Host host) {
    ref.read(activeHostTabControllerProvider.notifier).openHost(host);
    widget.onNavigate(SentinelRoutes.hostTerminal(host.hostname, host.ip));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SentinelThemeTokens(widget.isDark);
    final groupsState = ref.watch(groupsAdapterProvider);
    final hostsState = ref.watch(hostsAdapterProvider);
    final activeTabsState = ref.watch(activeHostTabControllerProvider);
    final sshStates = ref.watch(sshAdapterProvider);

    final allHosts = switch (hostsState) {
      HostsLoaded(:final hosts) => hosts,
      _ => const <Host>[],
    };

    final groups = switch (groupsState) {
      GroupsLoaded(:final groups) => groups,
      _ => const <ServerGroup>[],
    };

    final knownGroupNamesLower = {
      for (final g in groups) g.name.trim().toLowerCase(),
    };

    final ungroupedHosts = allHosts.where((h) {
      final gName = h.groupName?.trim() ?? '';
      return gName.isEmpty ||
          !knownGroupNamesLower.contains(gName.toLowerCase());
    }).toList();

    final query = _searchQuery.toLowerCase();
    final filteredGroups = query.isEmpty
        ? groups
        : groups.where((g) {
            final groupMatches =
                g.name.toLowerCase().contains(query) ||
                (g.description?.toLowerCase().contains(query) ?? false);
            if (groupMatches) return true;
            final groupHosts = allHosts.where(
              (h) =>
                  h.groupName?.trim().toLowerCase() ==
                  g.name.trim().toLowerCase(),
            );
            return groupHosts.any(
              (h) =>
                  h.hostname.toLowerCase().contains(query) ||
                  h.ip.toLowerCase().contains(query),
            );
          }).toList();

    final filteredUngrouped = query.isEmpty
        ? ungroupedHosts
        : ungroupedHosts
              .where(
                (h) =>
                    h.hostname.toLowerCase().contains(query) ||
                    h.ip.toLowerCase().contains(query) ||
                    'ungrouped'.contains(query),
              )
              .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 104),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),

          // Header + Add Group Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Server Groups',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${groups.length} ${groups.length == 1 ? 'Cluster' : 'Clusters'} • ${allHosts.length - ungroupedHosts.length} Grouped Hosts',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              SentinelButton(
                tokens: tokens,
                isDark: widget.isDark,
                width: null,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                borderRadius: 12,
                isHighlighted: true,
                accentColor: tokens.greenAccent,
                semanticLabel: 'Create new server group',
                tooltip: 'New server group',
                onTap: () => EditGroupSheet.show(
                  context,
                  isDark: widget.isDark,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.create_new_folder_outlined,
                      size: 15,
                      color: tokens.greenTextAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'New Group',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Bar (shown when there are groups or hosts)
          if (groups.isNotEmpty || allHosts.isNotEmpty) ...[
            SentinelGlassField(
              controller: _searchController,
              tokens: tokens,
              isDark: widget.isDark,
              label: 'Search Clusters',
              hint: 'Search groups, regions, or member hosts...',
              prefixIcon: Icons.search_rounded,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      icon: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: tokens.textSecondary,
                      ),
                      onPressed: _searchController.clear,
                    )
                  : null,
            ),
            const SizedBox(height: 14),
          ],

          if (groupsState is GroupsLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: tokens.greenAccent,
                ),
              ),
            )
          else if (groups.isEmpty && ungroupedHosts.isEmpty)
            _buildEmptyGroupsCard(context, tokens)
          else ...[
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEmptyGroupsCard(context, tokens),
              ),
            for (var i = 0; i < filteredGroups.length; i++) ...[
              Builder(
                builder: (context) {
                  final group = filteredGroups[i];
                  final groupHosts = allHosts
                      .where(
                        (h) =>
                            h.groupName?.trim().toLowerCase() ==
                            group.name.trim().toLowerCase(),
                      )
                      .toList();
                  return GroupCard(
                    key: ValueKey('group_${group.id ?? group.name}'),
                    group: group,
                    hosts: groupHosts,
                    isHostConnected: (h) =>
                        _hasOpenConnection(activeTabsState, sshStates, h),
                    onOpenHostTerminal: _openHostTerminal,
                    tokens: tokens,
                    isDark: widget.isDark,
                    initiallyExpanded: i == 0 || _searchQuery.isNotEmpty,
                    onEditGroup: () => EditGroupSheet.show(
                      context,
                      isDark: widget.isDark,
                      existingGroup: group,
                    ),
                    onPingGroup: groupHosts.isEmpty
                        ? null
                        : () {
                            for (final host in groupHosts) {
                              ref
                                  .read(hostsAdapterProvider.notifier)
                                  .pingSingleHost(host: host);
                            }
                          },
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
            if (filteredUngrouped.isNotEmpty) ...[
              const SizedBox(height: 4),
              GroupCard(
                key: const ValueKey('ungrouped_hosts_bucket'),
                group: ServerGroup(
                  name: 'Ungrouped Hosts',
                  description: 'Standalone nodes without a cluster',
                  colorHex: '#64748B',
                  iconName: 'folder',
                  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
                ),
                hosts: filteredUngrouped,
                isHostConnected: (h) =>
                    _hasOpenConnection(activeTabsState, sshStates, h),
                onOpenHostTerminal: _openHostTerminal,
                tokens: tokens,
                isDark: widget.isDark,
                isUngroupedBucket: true,
                initiallyExpanded: groups.isEmpty || _searchQuery.isNotEmpty,
                onPingGroup: () {
                  ref
                      .read(hostsAdapterProvider.notifier)
                      .pingAllHosts(
                        params: PingAlHostParams(host: filteredUngrouped),
                      );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyGroupsCard(
    BuildContext context,
    SentinelThemeTokens tokens,
  ) {
    return GlassCard(
      tokens: tokens,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      borderRadius: 20,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tokens.greenAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: tokens.greenAccent.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              Icons.account_tree_rounded,
              size: 24,
              color: tokens.greenTextAccent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Server Groups Yet',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create clusters like Production, Staging, or Home Lab to organize your SSH hosts and monitor group health.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SentinelPrimaryButton(
            tokens: tokens,
            height: 42,
            icon: Icons.add_circle_outline_rounded,
            label: 'Create First Group',
            onPressed: () => EditGroupSheet.show(
              context,
              isDark: widget.isDark,
            ),
          ),
        ],
      ),
    );
  }
}
