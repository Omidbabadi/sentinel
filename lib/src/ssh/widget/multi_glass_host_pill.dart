import 'package:flutter/material.dart';
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/enums/os_names.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/distro_avatar.dart';

import '../presention/app/adapter/ssh_adapter.dart';

class MultiGlassHostTabPill extends StatelessWidget {
  final HostTab tab;
  final bool isSelected;
  final SshState? sshState;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  const MultiGlassHostTabPill({
    super.key,
    required this.tab,
    required this.isSelected,
    required this.sshState,
    required this.tokens,
    required this.isDark,
    required this.onSelect,
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

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${tab.host.hostname}, $statusLabel',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(
              minWidth: 128,
              maxWidth: 200,
              minHeight: 38,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tokens.innerPillSurface.withValues(
                          alpha: isDark ? 0.92 : 0.85,
                        ),
                        tokens.greenAccent.withValues(
                          alpha: isDark ? 0.14 : 0.10,
                        ),
                      ],
                    )
                  : null,
              color: isSelected
                  ? null
                  : tokens.innerPillSurface.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isSelected
                    ? tokens.greenAccent.withValues(alpha: 0.5)
                    : tokens.innerPillBorder,
                width: 0.9,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DistroAvatar(
                  distro: tab.host.os?.osName ?? OsNames.unknown,
                  tokens: tokens,
                  size: 16,
                ),
                const SizedBox(width: 7),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    tab.host.hostname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? tokens.textPrimary
                          : tokens.textSecondary,
                      fontSize: 12.5,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  label: 'Close ${tab.host.hostname} tab',
                  child: Tooltip(
                    message: 'Close ${tab.host.hostname} tab',
                    child: InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
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
      ),
    );
  }
}
