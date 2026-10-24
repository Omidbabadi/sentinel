import 'package:flutter/material.dart';

import '../common/singelton/core.dart';

extension ContextExt on BuildContext {
  bool get isDarkMode {
    return switch (Cache.instance.themeModeNotifier.value) {
      ThemeMode.system =>
        MediaQuery.of(this).platformBrightness == Brightness.dark,
      ThemeMode.dark => true,
      _ => false,
    };
  }
}
