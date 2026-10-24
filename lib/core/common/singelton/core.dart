import 'package:flutter/material.dart';

class Cache {
  Cache._internal();

  static final Cache instance = Cache._internal();

  final themeModeNotifier = ValueNotifier(ThemeMode.dark);

  void setThemeMode(ThemeMode themeMode) {
    themeModeNotifier.value = themeMode;
  }
}
