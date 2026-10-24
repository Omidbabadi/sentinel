import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/common/application/riverpod/user_prefs.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/common/singelton/user_prefs.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/src/ssh/presention/app/adapter/ssh_adapter.dart';
import 'package:sentinel/src/ssh/widget/glass_terminal_accessory_bar.dart';
import 'package:sentinel/src/ssh/widget/terminal_session_body.dart';
import 'package:sentinel/src/ssh/widget/terminal_theme.dart';
import 'package:sentinel/src/ssh/widget/window_traffic_bar.dart';
import 'package:sentinel/src/ssh/widget/windowed_host_header.dart';
import 'package:sentinel/src/ssh/widget/windowed_tabbar.dart';

class WindowedGlassTerminalLayout extends ConsumerWidget {
  final Host activeHost;
  final int activeHostId;
  final List<HostTab> allTabs;
  final SshState sshState;
  final Map<int, SshState> sshStateMap;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final VoidCallback onNavigateBack;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<int> onCloseTab;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onReconnect;
  final VoidCallback? onOpenSftp;

  const WindowedGlassTerminalLayout({
    super.key,
    required this.activeHost,
    required this.activeHostId,
    required this.allTabs,
    required this.sshState,
    required this.sshStateMap,
    required this.tokens,
    required this.isDark,
    required this.onToggleTheme,
    required this.onNavigateBack,
    required this.onSelectTab,
    required this.onCloseTab,
    required this.onToggleFullscreen,
    required this.onReconnect,
    this.onOpenSftp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 10;
    final prefs = ref.watch(userPrefsProvider);
    final isDefaultTerminalTheme =
        prefs.terminalThemeId == UserPrefs.defaultTerminalThemeId;
    final activeTerminalTheme = terminalPresetThemes(
      tokens,
      isDark,
      themeId: prefs.terminalThemeId,
    );
    final cardBg = isDefaultTerminalTheme
        ? tokens.cardSurface
        : activeTerminalTheme.background.withValues(alpha: 0.90);
    final headerTextColor = isDefaultTerminalTheme
        ? tokens.textSecondary
        : activeTerminalTheme.foreground.withValues(alpha: 0.72);

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(seconds: 1),
        padding: EdgeInsets.only(
          top: 12,
          left: 16,
          right: 16,
          bottom: isKeyboardOpen ? 8 : 92,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WindowedTabsBar(
              allTabs: allTabs,
              activeHostId: activeHostId,
              sshStateMap: sshStateMap,
              tokens: tokens,
              onSelectTab: onSelectTab,
              onCloseTab: onCloseTab,
              onAddSession: onNavigateBack,
              onToggleFullscreen: onToggleFullscreen,
            ),
            const SizedBox(height: 14),
            WindowedHostHeader(
              activeHost: activeHost,
              sshState: sshState,
              tokens: tokens,
              onCloseActive: () => onCloseTab(activeHostId),
              onOpenSftp: onOpenSftp,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GlassCard(
                tokens: tokens,
                backgroundColor: cardBg,
                padding: const EdgeInsets.all(14),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WindowTrafficLightsBar(
                      activeHost: activeHost,
                      tokens: tokens,
                      isFullscreen: false,
                      textColor: headerTextColor,
                      onClose: () => onCloseTab(activeHostId),
                      onToggleFullscreen: onToggleFullscreen,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: TerminalSessionBody(
                          activeHost: activeHost,
                          activeHostId: activeHostId,
                          sshState: sshState,
                          tokens: tokens,
                          isDark: isDark,
                          onReconnect: onReconnect,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (sshState is SshConnected) ...[
              const SizedBox(height: 8),
              GlassTerminalAccessoryBar(
                terminal: (sshState as SshConnected).terminal,
                tokens: tokens,
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
