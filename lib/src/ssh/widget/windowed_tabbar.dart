import 'package:flutter/material.dart';
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/sentinel_botton.dart';

import '../presention/app/adapter/ssh_adapter.dart';

class WindowedTabsBar extends StatelessWidget {
  final List<HostTab> allTabs;
  final int activeHostId;
  final Map<int, SshState> sshStateMap;
  final SentinelThemeTokens tokens;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<int> onCloseTab;
  final VoidCallback onAddSession;
  final VoidCallback onToggleFullscreen;

  const WindowedTabsBar({
    super.key,
    required this.allTabs,
    required this.activeHostId,
    required this.sshStateMap,
    required this.tokens,
    required this.onSelectTab,
    required this.onCloseTab,
    required this.onAddSession,
    required this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allTabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tab = allTabs[index];
                final isSelected = tab.id == activeHostId;
                final itemSshState = sshStateMap[tab.id];

                final (dotColor, statusLabel) = switch (itemSshState) {
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
                      onTap: () => onSelectTab(tab.id),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tokens.innerPillSurface.withValues(alpha: 0.9)
                              : tokens.innerPillSurface.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? tokens.greenAccent.withValues(alpha: 0.6)
                                : tokens.innerPillBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dotColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tab.host.hostname,
                              style: TextStyle(
                                color: tokens.textPrimary,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Semantics(
                              button: true,
                              label: 'Close ${tab.host.hostname} tab',
                              child: Tooltip(
                                message: 'Close ${tab.host.hostname} tab',
                                child: InkWell(
                                  onTap: () => onCloseTab(tab.id),
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
              },
            ),
          ),
          const SizedBox(width: 8),
          SentinelButton(
            width: 36,
            height: 36,
            isDark: tokens.isDark,
            tokens: tokens,
            onTap: onAddSession,
            semanticLabel: 'New SSH session',
            tooltip: 'New SSH session',
            child: Icon(
              Icons.add_rounded,
              size: 18,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          SentinelButton(
            width: 36,
            height: 36,
            isDark: tokens.isDark,
            tokens: tokens,
            onTap: onToggleFullscreen,
            semanticLabel: 'Enter fullscreen terminal',
            tooltip: 'Enter fullscreen',
            child: Icon(
              Icons.fullscreen_rounded,
              size: 18,
              color: tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
