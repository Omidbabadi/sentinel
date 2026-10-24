import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/res/style/colors.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/toggle_theme_button.dart';

import 'core/common/application/riverpod/current_theme_controller.dart';
import 'core/res/style/theme_tokens.dart';
import 'phone_wrapper.dart';

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  bool _usePhoneFrameOnWideScreens = true;

  void _toggleTheme(ThemeMode currentMode) {
    final nextMode = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    try {
      (ref.read(currentThemeProvider.notifier) as dynamic).changeTheme(
        nextMode,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(currentThemeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final tokens = SentinelThemeTokens(isDark);
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: tokens.backGroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Pallet.lightTritaryT10,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.backGroundColor,
        elevation: 0,
      ),
    );

    return MaterialApp.router(
      title: 'Sentinel',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: theme,
      darkTheme: theme.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: tokens.backGroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Pallet.lightTritaryT10,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: tokens.backGroundColor,
          elevation: 0,
        ),
      ),
      routerConfig: router,
      builder: (context, routerChild) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final content = routerChild ?? const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;

            if (!isWide || !_usePhoneFrameOnWideScreens) {
              return Stack(
                children: [
                  content,
                  // if (!isWide)
                  //   Positioned(
                  //     top: constraints.maxHeight / 12,
                  //     right: 20,
                  //     child: ToggleThemeButton(),
                  //   ),
                ],
              );
            }

            // Desktop / Web / Tablet with PhoneFrameWrapper
            return Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF282A2E),
                            Color(0xFF181A1D),
                            Color(0xFF101214),
                          ]
                        : const [
                            Color(0xFFEBE8E0),
                            Color(0xFFDCD8CE),
                            Color(0xFFE5E2DA),
                          ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: PhoneFrameWrapper(
                          isDark: isDark,
                          onToggleTheme: () => _toggleTheme(themeMode),
                          child: content,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFrameTogglePill(isDark),
                          const SizedBox(width: 10),
                          ToggleThemeButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFrameTogglePill(bool isDark) {
    final label = _usePhoneFrameOnWideScreens ? 'Full Screen' : 'Phone Frame';
    return Semantics(
      button: true,
      label: _usePhoneFrameOnWideScreens
          ? 'Switch to full screen layout'
          : 'Switch to phone frame layout',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _usePhoneFrameOnWideScreens = !_usePhoneFrameOnWideScreens;
            });
          },
          borderRadius: BorderRadius.circular(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _usePhoneFrameOnWideScreens
                        ? Icons.fullscreen_rounded
                        : Icons.smartphone_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
