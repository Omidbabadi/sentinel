import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class UserPrefs extends Equatable {
  static const double defaultFontSize = 11.0;
  static const double minFontSize = 7.0;
  static const double maxFontSize = 24.0;
  static const String defaultTerminalThemeId = 'sentinel_default';
  static const int defaultConnectionTimeoutSeconds = 15;
  static const int defaultKeepAliveSeconds = 15;

  final double terminalFontSize;
  final String terminalThemeId;
  final ThemeMode themeMode;
  final int sshConnectionTimeoutSeconds;
  final int sshKeepAliveSeconds;
  final bool autoPingOnStartup;
  final bool autoReconnectSsh;
  final bool strictHostKeyChecking;

  const UserPrefs({
    this.terminalFontSize = defaultFontSize,
    this.terminalThemeId = defaultTerminalThemeId,
    this.themeMode = ThemeMode.dark,
    this.sshConnectionTimeoutSeconds = defaultConnectionTimeoutSeconds,
    this.sshKeepAliveSeconds = defaultKeepAliveSeconds,
    this.autoPingOnStartup = true,
    this.autoReconnectSsh = true,
    this.strictHostKeyChecking = true,
  });

  UserPrefs copyWith({
    double? terminalFontSize,
    String? terminalThemeId,
    ThemeMode? themeMode,
    int? sshConnectionTimeoutSeconds,
    int? sshKeepAliveSeconds,
    bool? autoPingOnStartup,
    bool? autoReconnectSsh,
    bool? strictHostKeyChecking,
  }) {
    return UserPrefs(
      terminalFontSize: (terminalFontSize ?? this.terminalFontSize).clamp(
        minFontSize,
        maxFontSize,
      ),
      terminalThemeId: terminalThemeId ?? this.terminalThemeId,
      themeMode: themeMode ?? this.themeMode,
      sshConnectionTimeoutSeconds:
          (sshConnectionTimeoutSeconds ?? this.sshConnectionTimeoutSeconds)
              .clamp(5, 60),
      sshKeepAliveSeconds: (sshKeepAliveSeconds ?? this.sshKeepAliveSeconds)
          .clamp(0, 120),
      autoPingOnStartup: autoPingOnStartup ?? this.autoPingOnStartup,
      autoReconnectSsh: autoReconnectSsh ?? this.autoReconnectSsh,
      strictHostKeyChecking:
          strictHostKeyChecking ?? this.strictHostKeyChecking,
    );
  }

  @override
  List<Object?> get props => [
    terminalFontSize,
    terminalThemeId,
    themeMode,
    sshConnectionTimeoutSeconds,
    sshKeepAliveSeconds,
    autoPingOnStartup,
    autoReconnectSsh,
    strictHostKeyChecking,
  ];
}
