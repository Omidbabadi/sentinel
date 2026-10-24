import 'package:flutter/material.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/enums/os_names.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/distro_avatar.dart';
import 'package:sentinel/core/widgets/sentinel_status_pill.dart';

class HostListTile extends StatelessWidget {
  const HostListTile({
    super.key,
    required this.host,
    required this.tokens,
    this.subtitle,
    this.subtitleMonospace = false,
    this.isConnected = false,
    this.showActivePill = false,
    this.showPingPill = false,
    this.trailing,
    this.verticalPadding = 6,
    this.avatarSize = 34,
    this.onTap,
  });

  final Host host;
  final SentinelThemeTokens tokens;
  final String? subtitle;
  final bool subtitleMonospace;
  final bool isConnected;
  final bool showActivePill;
  final bool showPingPill;
  final Widget? trailing;
  final double verticalPadding;
  final double avatarSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final osName = host.os?.osName ?? OsNames.unknown;
    final ping = host.ping;
    final hasPing = ping != null && ping > 0;
    final pingColor = !hasPing
        ? tokens.textSecondary
        : (ping < 100
              ? tokens.greenAccent
              : (ping < 250 ? tokens.yellowAccent : tokens.redAccent));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: Row(
              children: [
                DistroAvatar(
                  distro: osName,
                  tokens: tokens,
                  size: avatarSize,
                  showActiveBadge: isConnected,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    button: onTap != null,
                    label:
                        '${host.hostname}, ${subtitle ?? host.ip}${isConnected ? ", active SSH session" : ""}',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          host.hostname,
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle ?? host.ip,
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 11.5,
                            fontFamily: subtitleMonospace ? 'monospace' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showPingPill) ...[
                  SentinelStatusPill(
                    tokens: tokens,
                    label: hasPing ? '${ping.round()} ms' : 'Offline',
                    semanticLabel: hasPing
                        ? 'Latency ${ping.round()} milliseconds'
                        : 'Host offline',
                    color: pingColor,
                    showDot: true,
                  ),
                  const SizedBox(width: 10),
                ],
                if (showActivePill && isConnected) ...[
                  SentinelStatusPill(
                    tokens: tokens,
                    label: 'Active',
                    semanticLabel: 'Active SSH session',
                    color: tokens.greenAccent,
                    showDot: true,
                    glowDot: true,
                  ),
                  const SizedBox(width: 8),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
