import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/injection_container.dart';
import '../../singelton/core.dart';
import '../cache_helper.dart';

part 'current_theme_controller.g.dart';

@Riverpod(keepAlive: true)
class CurrentTheme extends _$CurrentTheme {
  final ValueNotifier<ThemeMode> _notifier = Cache.instance.themeModeNotifier;

  @override
  ThemeMode build() {
    final initialThemeMode = sl<CacheHelper>().getThemeMode();

    _notifier.addListener(_onThemeChanged);

    ref.onDispose(() {
      _notifier.removeListener(_onThemeChanged);
    });

    return initialThemeMode;
  }

  void _onThemeChanged() {
    if (state != _notifier.value) {
      state = _notifier.value;
    }
  }

  void toggleTheme(ThemeMode theme) {
    state = theme;
    sl<CacheHelper>().cacheThemeMode(theme);
  }

  /// Alias in case any widget calls `changeTheme`
  void changeTheme(ThemeMode theme) => toggleTheme(theme);

  /// Cycles: light -> dark -> system -> light
  void cycleTheme() {
    final nextMode = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    toggleTheme(nextMode);
  }
}
