import 'package:flutter/material.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/enums/os_names.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/distro_avatar.dart';
import 'package:sentinel/core/widgets/sentinel_status_pill.dart';

import '../presention/app/adapter/ssh_adapter.dart';

class WindowedHostHeader extends StatelessWidget {
  final Host activeHost;
  final SshState sshState;
  final SentinelThemeTokens tokens;
  final VoidCallback onCloseActive;
  final VoidCallback? onOpenSftp;

  const WindowedHostHeader({
    super.key,
    required this.activeHost,
    required this.sshState,
    required this.tokens,
    required this.onCloseActive,
    this.onOpenSftp,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = switch (sshState) {
      SshConnected() =>
        'Connected via SSH • ${activeHost.ip}:${activeHost.port}',
      SshConnecting() ||
      SshInitial() => 'Connecting • ${activeHost.ip}:${activeHost.port}',
      SshError() => 'Connection Failed • ${activeHost.ip}',
      SshDisconnected() => 'Disconnected • ${activeHost.ip}',
    };

    final statusColor = switch (sshState) {
      SshConnected() => tokens.greenTextAccent,
      SshConnecting() || SshInitial() => tokens.yellowTextAccent,
      SshError() => tokens.redTextAccent,
      SshDisconnected() => tokens.textSecondary,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              DistroAvatar(
                distro: activeHost.os?.osName ?? OsNames.unknown,
                tokens: tokens,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Semantics(
                            header: true,
                            child: Text(
                              activeHost.hostname,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tokens.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        if (activeHost.os != null &&
                            activeHost.os!.osVersion.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          SentinelStatusPill(
                            tokens: tokens,
                            label: activeHost.os!.osVersion,
                            isNeutral: true,
                            borderRadius: 8,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (onOpenSftp != null) ...[
          Semantics(
            button: true,
            label: 'Open SFTP file manager',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpenSftp,
                borderRadius: BorderRadius.circular(14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 36),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.blueAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: tokens.blueAccent.withValues(alpha: 0.38),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          size: 13.5,
                          color: tokens.blueAccent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'SFTP',
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Semantics(
          button: true,
          label: 'Close SSH session',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCloseActive,
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 36),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tokens.innerPillSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.innerPillBorder),
                  ),
                  child: Text(
                    'Close SSH',
                    style: TextStyle(color: tokens.textPrimary, fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
