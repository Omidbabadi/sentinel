import 'package:flutter/material.dart';
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/glass_card.dart';

import '../presention/app/adapter/ssh_adapter.dart';
import 'glass_action_botton.dart';
import 'multi_glass_host_pill.dart';
import 'single_glass_host_pill.dart';

class FullscreenGlassTopBar extends StatelessWidget {
  final List<HostTab> allTabs;
  final int activeHostId;
  final Map<int, SshState> sshStateMap;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final bool isPanelOpen;
  final VoidCallback onExitFullscreen;
  final VoidCallback onAddHost;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<int> onCloseTab;
  final VoidCallback onTogglePanel;
  final VoidCallback? onOpenSftp;

  const FullscreenGlassTopBar({
    super.key,
    required this.allTabs,
    required this.activeHostId,
    required this.sshStateMap,
    required this.tokens,
    required this.isDark,
    this.isPanelOpen = false,
    required this.onExitFullscreen,
    required this.onAddHost,
    required this.onSelectTab,
    required this.onCloseTab,
    required this.onTogglePanel,
    this.onOpenSftp,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tokens: tokens,
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SizedBox(
        height: 38,
        child: Row(
          children: [
            GlassActionIconButton(
              tokens: tokens,
              isDark: isDark,
              onTap: onExitFullscreen,
              semanticLabel: 'Exit fullscreen',
              tooltip: 'Exit fullscreen',
              child: Icon(
                Icons.chevron_left_rounded,
                color: tokens.textPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: allTabs.length <= 1
                  ? SingleGlassHostPill(
                      tab: allTabs.first,
                      sshState: sshStateMap[allTabs.first.id],
                      tokens: tokens,
                      isDark: isDark,
                      onClose: () => onCloseTab(allTabs.first.id),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: allTabs.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final tab = allTabs[index];
                        final isSelected = tab.id == activeHostId;
                        return MultiGlassHostTabPill(
                          tab: tab,
                          isSelected: isSelected,
                          sshState: sshStateMap[tab.id],
                          tokens: tokens,
                          isDark: isDark,
                          onSelect: () => onSelectTab(tab.id),
                          onClose: () => onCloseTab(tab.id),
                        );
                      },
                    ),
            ),
            const SizedBox(width: 8),
            GlassActionIconButton(
              tokens: tokens,
              isDark: isDark,
              onTap: onAddHost,
              semanticLabel: 'Add SSH session',
              tooltip: 'Add SSH session',
              child: Icon(
                Icons.add_rounded,
                color: tokens.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 6),
            if (onOpenSftp != null) ...[
              GlassActionIconButton(
                tokens: tokens,
                isDark: isDark,
                onTap: onOpenSftp!,
                semanticLabel: 'Open SFTP file manager',
                tooltip: 'SFTP File Manager',
                child: Icon(
                  Icons.folder_open_rounded,
                  color: tokens.blueAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
            ],
            GlassActionIconButton(
              tokens: tokens,
              isDark: isDark,
              isHighlighted: isPanelOpen,
              onTap: onTogglePanel,
              semanticLabel: isPanelOpen
                  ? 'Show keyboard'
                  : 'Open terminal tools panel',
              tooltip: isPanelOpen
                  ? 'Show keyboard'
                  : 'Open terminal tools panel',
              child: Icon(
                isPanelOpen
                    ? Icons.keyboard_alt_outlined
                    : Icons.grid_view_rounded,
                color: tokens.greenAccent,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
