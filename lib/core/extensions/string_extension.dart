import 'package:flutter/material.dart';

extension StringExt on String {
  ThemeMode get stringValueToTheme {
    return switch (toLowerCase()) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  bool? get stringValueToBool {
    return switch (toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => null,
    };
  }
}
