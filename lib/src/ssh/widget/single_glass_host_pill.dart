import 'package:flutter/material.dart';
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/enums/os_names.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/distro_avatar.dart';

import '../presention/app/adapter/ssh_adapter.dart';

class SingleGlassHostPill extends StatelessWidget {
  final HostTab tab;
  final SshState? sshState;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final VoidCallback onClose;

  const SingleGlassHostPill({
    super.key,
    required this.tab,
    required this.sshState,
    required this.tokens,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final (dotColor, statusLabel) = switch (sshState) {
      SshConnected() => (tokens.greenAccent, 'Connected'),
      SshConnecting() => (tokens.yellowAccent, 'Connecting'),
      SshError() => (tokens.redAccent, 'Connection error'),
      _ => (tokens.textSecondary, 'Disconnected'),
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.innerPillSurface.withValues(alpha: isDark ? 0.92 : 0.85),
            tokens.greenAccent.withValues(alpha: isDark ? 0.14 : 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: tokens.greenAccent.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 0.9,
        ),
      ),
      child: Row(
        children: [
          DistroAvatar(
            distro: tab.host.os?.osName ?? OsNames.unknown,
            tokens: tokens,
            size: 18,
          ),
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              label: '${tab.host.hostname}, $statusLabel',
              excludeSemantics: true,
              child: Text(
                tab.host.hostname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Semantics(
            button: true,
            label: 'Close ${tab.host.hostname} tab',
            child: Tooltip(
              message: 'Close ${tab.host.hostname} tab',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(8),
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
          ),
        ],
      ),
    );
  }
}
