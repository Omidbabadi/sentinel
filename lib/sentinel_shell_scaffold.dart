import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/common/application/riverpod/current_theme_controller.dart';
import 'package:sentinel/core/common/application/riverpod/internet_connectivity_controller.dart';
import 'package:sentinel/core/common/internet_conectivity.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/injection_container.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/bottom_navigation.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/glass_orb_painter.dart';
import 'package:sentinel/core/widgets/sentinel_top_bar.dart';
import 'package:sentinel/src/hosts/domain/usecases/ping_al_host.dart';
import 'package:sentinel/src/hosts/presention/app/adapter/hosts_adapter.dart';

/// Drop-in `ShellRoute` builder widget for `go_router`.
/// Pass `state.uri.path` to `currentLocation` and `(route) => context.go(route)`
/// to `onNavigate`.
class SentinelShellScaffold extends ConsumerWidget {
  final String currentLocation;
  final ValueChanged<String> onNavigate;
  final bool isDark;
  final Widget child;

  const SentinelShellScaffold({
    super.key,
    required this.currentLocation,
    required this.onNavigate,
    required this.isDark,
    required this.child,
  });

  int _locationToIndex(String path) {
    if (path.startsWith(SentinelRoutes.hosts)) return 1;
    if (path.startsWith(SentinelRoutes.terminal)) return 2;
    if (path.startsWith(SentinelRoutes.groups)) return 3;
    if (path.startsWith(SentinelRoutes.more)) return 4;
    if (path.startsWith(SentinelRoutes.home)) return 0;
    return 0;
  }

  String _indexToLocation(int index) {
    switch (index) {
      case 0:
        return SentinelRoutes.home;
      case 1:
        return SentinelRoutes.hosts;
      case 2:
        return SentinelRoutes.terminal;
      case 3:
        return SentinelRoutes.groups;
      case 4:
        return SentinelRoutes.more;
      default:
        return SentinelRoutes.home;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyboardBottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final tokens = SentinelThemeTokens(isDark);
    final selectedIndex = _locationToIndex(currentLocation);
    final isTerminalRoute = currentLocation.startsWith(SentinelRoutes.terminal);
    final isSftpRoute = currentLocation.startsWith(SentinelRoutes.sftp);
    final isTerminalFullscreen =
        selectedIndex == 2 &&
        ref.watch(
          activeHostTabControllerProvider.select((s) => s.isFullscreen),
        );
    final connectivityAsync = ref.watch(internetConnectivityControllerProvider);
    final isOffline = connectivityAsync.value == false;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tokens.bgTop, tokens.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 90,
              right: -35,
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: CustomPaint(
                    size: const Size(210, 210),
                    painter: GlassOrbPainter(isDark: isDark),
                  ),
                ),
              ),
            ),

            if (isDark)
              Positioned(
                top: 300,
                left: 70,
                child: ExcludeSemantics(
                  child: IgnorePointer(
                    child: Container(
                      width: 180,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF32789A)
                                .withValues(alpha: 0.18),
                            blurRadius: 65,
                            spreadRadius: 25,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Active GoRoute Child View
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    if (!isTerminalRoute && !isSftpRoute)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: SentinelTopBar(
                          tokens: tokens,
                          isDark: isDark,
                          currentPath: currentLocation,
                          onToggleTheme: () {
                            final currentMode = ref.read(currentThemeProvider);
                            final nextMode = switch (currentMode) {
                              ThemeMode.light => ThemeMode.dark,
                              ThemeMode.dark => ThemeMode.system,
                              ThemeMode.system => ThemeMode.light,
                            };
                            ref
                                .read(currentThemeProvider.notifier)
                                .toggleTheme(nextMode);
                          },
                        ),
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) => SizeTransition(
                        sizeFactor: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: isOffline
                          ? Padding(
                              key: const ValueKey('offline-banner'),
                              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                              child: _OfflineConnectionBanner(tokens: tokens),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('online-banner'),
                            ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: keyboardBottomInset),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              left: 16,
              right: 16,
              bottom: isTerminalFullscreen ? -100 : 16,
              child: ExcludeSemantics(
                excluding: isTerminalFullscreen,
                child: ExcludeFocus(
                  excluding: isTerminalFullscreen,
                  child: IgnorePointer(
                    ignoring: isTerminalFullscreen,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: isTerminalFullscreen ? 0.0 : 1.0,
                      child: BottomNavigation(
                        tokens: tokens,
                        selectedNavIndex: selectedIndex,
                        onSelectIndex: (index) =>
                            onNavigate(_indexToLocation(index)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineConnectionBanner extends ConsumerWidget {
  const _OfflineConnectionBanner({required this.tokens});

  final SentinelThemeTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'No internet connection. Tap Retry to check network.',
      child: GlassCard(
        tokens: tokens,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.redAccent.withValues(alpha: 0.16),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 14,
                color: tokens.redAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Internet Connection',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Hosts & SSH will reconnect automatically when online',
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Retry network check',
              excludeSemantics: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final connected = await sl<NetworkInfo>()
                        .checkConnectivity();
                    if (connected) {
                      final hostsState = ref.read(hostsAdapterProvider);
                      if (hostsState is HostsLoaded &&
                          hostsState.hosts.isNotEmpty) {
                        await ref
                            .read(hostsAdapterProvider.notifier)
                            .pingAllHosts(
                              params: PingAlHostParams(host: hostsState.hosts),
                            );
                      } else {
                        await ref
                            .read(hostsAdapterProvider.notifier)
                            .getHostFromLocalBase();
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.redAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: tokens.redAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: tokens.redTextAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
