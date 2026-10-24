import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/common/entities/server_group.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/host_list_tile.dart';
import 'package:sentinel/core/widgets/sentinel_botton.dart';
import 'package:sentinel/core/widgets/sentinel_status_pill.dart';
import 'package:sentinel/src/groups/presention/widgets/group_style_helpers.dart';

class GroupCard extends StatefulWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.hosts,
    required this.isHostConnected,
    required this.onOpenHostTerminal,
    required this.tokens,
    required this.isDark,
    this.initiallyExpanded = false,
    this.isUngroupedBucket = false,
    this.onEditGroup,
    this.onPingGroup,
  });

  final ServerGroup group;
  final List<Host> hosts;
  final bool Function(Host host) isHostConnected;
  final ValueChanged<Host> onOpenHostTerminal;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final bool initiallyExpanded;
  final bool isUngroupedBucket;
  final VoidCallback? onEditGroup;
  final VoidCallback? onPingGroup;

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final group = widget.group;
    final hosts = widget.hosts;

    final accentColor = widget.isUngroupedBucket
        ? tokens.textSecondary
        : GroupStyleHelpers.parseColor(group.colorHex);
    final groupIcon = widget.isUngroupedBucket
        ? Icons.folder_off_outlined
        : GroupStyleHelpers.resolveIcon(group.iconName);

    final onlineHosts = hosts
        .where((h) => h.ping != null && h.ping! > 0)
        .toList();
    final onlineCount = onlineHosts.length;
    final totalCount = hosts.length;

    final double? avgPing = onlineHosts.isEmpty
        ? null
        : onlineHosts.fold<double>(0, (sum, h) => sum + h.ping!) /
              onlineHosts.length;

    final (statusLabel, statusColor) = switch ((totalCount, onlineCount)) {
      (0, _) => ('Empty', tokens.textSecondary),
      (_, final on) when on == totalCount => ('Operational', tokens.greenAccent),
      (_, > 0) => ('Degraded', tokens.yellowAccent),
      _ => ('Offline', tokens.redAccent),
    };

    final hostCountLabel =
        '$totalCount ${totalCount == 1 ? 'Host' : 'Hosts'}';
    final avgPingLabel = avgPing != null ? ' • ${avgPing.round()} ms avg' : '';
    final descriptionText =
        (group.description != null && group.description!.trim().isNotEmpty)
        ? '${group.description!.trim()} • $hostCountLabel$avgPingLabel'
        : '$hostCountLabel$avgPingLabel';

    return GlassCard(
      tokens: tokens,
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Semantics(
            button: true,
            toggled: _isExpanded,
            label:
                '${group.name}, $descriptionText, status $statusLabel. Tap to ${_isExpanded ? "collapse" : "expand"} hosts',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(groupIcon, size: 19, color: accentColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            descriptionText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SentinelStatusPill(
                      tokens: tokens,
                      label: statusLabel,
                      semanticLabel: 'Group status $statusLabel',
                      color: statusColor,
                      showDot: true,
                      glowDot: statusLabel == 'Operational',
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded Host List & Group Actions
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Divider(height: 1, color: tokens.dividerColor),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '$onlineCount/$totalCount Online',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (hosts.isNotEmpty && widget.onPingGroup != null) ...[
                      SentinelButton(
                        tokens: tokens,
                        isDark: widget.isDark,
                        width: null,
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        borderRadius: 9,
                        semanticLabel: 'Ping hosts in ${group.name}',
                        tooltip: 'Ping group hosts',
                        onTap: widget.onPingGroup,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.radar_rounded,
                              size: 13,
                              color: tokens.greenTextAccent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Ping',
                              style: TextStyle(
                                color: tokens.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (!widget.isUngroupedBucket &&
                        widget.onEditGroup != null)
                      SentinelButton(
                        tokens: tokens,
                        isDark: widget.isDark,
                        width: null,
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        borderRadius: 9,
                        semanticLabel: 'Edit ${group.name}',
                        tooltip: 'Edit group & hosts',
                        onTap: widget.onEditGroup,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 13,
                              color: tokens.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Manage',
                              style: TextStyle(
                                color: tokens.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (hosts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: tokens.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No SSH hosts assigned yet. Tap "Manage" to assign hosts to this cluster.',
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (var i = 0; i < hosts.length; i++) ...[
                    HostListTile(
                      host: hosts[i],
                      tokens: tokens,
                      subtitle:
                          '${hosts[i].username}@${hosts[i].ip}:${hosts[i].port}',
                      subtitleMonospace: true,
                      isConnected: widget.isHostConnected(hosts[i]),
                      showPingPill: true,
                      showActivePill: true,
                      onTap: () => widget.onOpenHostTerminal(hosts[i]),
                      trailing: Semantics(
                        button: true,
                        label: 'Edit ${hosts[i].hostname}',
                        excludeSemantics: true,
                        child: InkWell(
                          onTap: () => context.push(
                            SentinelRoutes.editHost(hosts[i]),
                            extra: hosts[i],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (i < hosts.length - 1)
                      Divider(height: 1, color: tokens.dividerColor),
                  ],
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
