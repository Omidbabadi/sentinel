part of 'router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  debugLogDiagnostics: true,
  initialLocation: SentinelRoutes.splash,
  routes: [
    GoRoute(
      path: SentinelRoutes.splash,
      builder: (_, _) => const SplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SentinelShellScaffold(
          currentLocation: state.uri.path,
          onNavigate: (route) => context.go(route),
          isDark: isDark,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: SentinelRoutes.home,
          builder: (context, state) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return SentinelHomeView(
              isDark: isDark,
              onToggleTheme: () => _toggleAppTheme(context),
              onNavigate: (route) => context.go(route),
            );
          },
        ),
        GoRoute(
          path: SentinelRoutes.hosts,
          builder: (context, state) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return SentinelHostsView(
              isDark: isDark,
              onToggleTheme: () => _toggleAppTheme(context),
              onNavigate: (route) => context.go(route),
            );
          },
        ),
        GoRoute(
          path: SentinelRoutes.addHost, // '/home/hosts/add'
          builder: (context, state) => const EditHostView(),
        ),
        GoRoute(
          path: SentinelRoutes.editHostPath, // '/home/host/edit/:id/:ip'
          builder: (context, state) {
            final host = state.extra as Host?;
            return EditHostView(host: host);
          },
        ),
        GoRoute(
          path: SentinelRoutes.terminal,
          builder: (context, state) {
            return SentinelTerminalView(
              onToggleTheme: () => _toggleAppTheme(context),
              onNavigate: (route) => context.go(route),
            );
          },
        ),
        GoRoute(
          path: SentinelRoutes.sftp,
          builder: (context, state) {
            final host = state.extra as Host?;
            return SentinelSftpView(
              host: host,
              onNavigate: (route) => context.go(route),
            );
          },
        ),
        GoRoute(
          path: SentinelRoutes.groups,
          builder: (context, state) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return SentinelGroupsView(
              isDark: isDark,
              onToggleTheme: () => _toggleAppTheme(context),
              onNavigate: (route) => context.go(route),
            );
          },
        ),
        GoRoute(
          path: SentinelRoutes.more,
          builder: (context, state) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return SentinelMoreView(
              isDark: isDark,
              onToggleTheme: () => _toggleAppTheme(context),
              onNavigate: (route) => context.go(route),
            );
          },
        ),
      ],
    ),
  ],
);

void _toggleAppTheme(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  final currentMode = container.read(currentThemeProvider);
  final nextMode = switch (currentMode) {
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
    ThemeMode.system => ThemeMode.light,
  };
  container.read(currentThemeProvider.notifier).toggleTheme(nextMode);
}

class SentinelRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String hosts = '/home/hosts';
  static const String addHost = '/home/hosts/add';
  static const String editHostPath = '/home/host/edit/:id/:ip';
  static const String terminal = '/home/terminal';
  static const String sftp = '/home/sftp';
  static const String groups = '/home/groups';
  static const String more = '/home/more';

  static String editHost([Host? host]) {
    if (host == null) return addHost;
    return '/home/host/edit/${host.id}/${Uri.encodeComponent(host.ip)}';
  }

  static String hostTerminal(String name, String ip) =>
      '/home/terminal?host=${Uri.encodeComponent(name)}&ip=${Uri.encodeComponent(ip)}';
}
