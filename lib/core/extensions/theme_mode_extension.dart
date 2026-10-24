import 'package:flutter/material.dart';

extension ThemeModeExt on ThemeMode {
  String get themeStringValue {
    switch (this) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case _:
        return 'system';
    }
  }
}
