import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/common/application/riverpod/current_theme_controller.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/extensions/context_extension.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/src/home/presention/widgets/open_terminal_host_sheet.dart';
import 'package:sentinel/src/ssh/presention/app/adapter/ssh_adapter.dart';
import 'package:sentinel/src/ssh/widget/no_active_host.dart';

import '../../widget/full_screen_glass_terminal_layout.dart';
import '../../widget/windowed_glass_terminal_layout.dart';

class SentinelTerminalView extends ConsumerWidget {
  const SentinelTerminalView({super.key, this.onToggleTheme, this.onNavigate});

  final VoidCallback? onToggleTheme;
  final ValueChanged<String>? onNavigate;

  static const path = '/hosts/terminal';

  void _navigateBackToHosts(BuildContext context) {
    if (onNavigate != null) {
      onNavigate!(SentinelRoutes.hosts);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(SentinelRoutes.hosts);
    }
  }

  void _openHostSelector(
    BuildContext context,
    SentinelThemeTokens tokens,
    bool isDark,
  ) {
    OpenTerminalHostSheet.show(
      context: context,
      tokens: tokens,
      isDark: isDark,
      onNavigate: (route) {
        if (onNavigate != null) {
          onNavigate!(route);
        } else {
          context.go(route);
        }
      },
    );
  }

  void _openSftpBrowser(BuildContext context, Host activeHost) {
    context.push(SentinelRoutes.sftp, extra: activeHost);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currentThemeProvider);
    final isDark = context.isDarkMode;
    final tokens = SentinelThemeTokens(isDark);
    final tabState = ref.watch(activeHostTabControllerProvider);
    final tabNotifier = ref.read(activeHostTabControllerProvider.notifier);
    final sshStateMap = ref.watch(sshAdapterProvider);

    final activeHost = tabState.activeHost;
    final activeHostId = activeHost?.id;
    final allTabs = tabState.tabs;
    final isFullscreen = tabState.isFullscreen;

    if (activeHost == null || activeHostId == null) {
      return NoActiveHost(
        onNavigate: onNavigate,
        onToggleTheme: onToggleTheme,
        tokens: tokens,
      );
    }

    final sshState = sshStateMap[activeHostId] ?? const SshInitial();

    if (isFullscreen) {
      return FullscreenGlassTerminalLayout(
        activeHost: activeHost,
        activeHostId: activeHostId,
        allTabs: allTabs,
        sshState: sshState,
        sshStateMap: sshStateMap,
        tokens: tokens,
        isDark: isDark,
        onExitFullscreen: tabNotifier.toggleFullscreen,
        onAddHost: () => _openHostSelector(context, tokens, isDark),
        onSelectTab: tabNotifier.selectTab,
        onCloseTab: (id) {
          final hasRemaining = tabNotifier.closeTab(id);
          if (!hasRemaining) {
            _navigateBackToHosts(context);
          }
        },
        onReconnect: () => tabNotifier.reconnect(activeHost),
        onOpenSftp: () => _openSftpBrowser(context, activeHost),
      );
    }

    return WindowedGlassTerminalLayout(
      activeHost: activeHost,
      activeHostId: activeHostId,
      allTabs: allTabs,
      sshState: sshState,
      sshStateMap: sshStateMap,
      tokens: tokens,
      isDark: isDark,
      onToggleTheme: onToggleTheme,
      onNavigateBack: () => _openHostSelector(context, tokens, isDark),
      onSelectTab: tabNotifier.selectTab,
      onCloseTab: (id) {
        final hasRemaining = tabNotifier.closeTab(id);
        if (!hasRemaining) {
          _navigateBackToHosts(context);
        }
      },
      onToggleFullscreen: tabNotifier.toggleFullscreen,
      onReconnect: () => tabNotifier.reconnect(activeHost),
      onOpenSftp: () => _openSftpBrowser(context, activeHost),
    );
  }
}
