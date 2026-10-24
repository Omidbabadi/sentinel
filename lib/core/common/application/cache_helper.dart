import 'package:flutter/material.dart';
import 'package:sentinel/core/common/singelton/core.dart';
import 'package:sentinel/core/extensions/string_extension.dart';
import 'package:sentinel/core/extensions/theme_mode_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../singelton/user_prefs.dart';

class CacheHelper {
  const CacheHelper(this._prefs);
  final SharedPreferences _prefs;

  static const _isFirstTimer = 'is_first_timer';
  static const _themeKey = 'theme_mode_key';
  static const _terminalFontSizeKey = 'terminal_font_size_key';
  static const _terminalThemeIdKey = 'terminal_theme_id_key';
  static const _sshTimeoutKey = 'ssh_connection_timeout_key';
  static const _sshKeepAliveKey = 'ssh_keep_alive_key';
  static const _autoPingKey = 'auto_ping_on_startup_key';
  static const _autoReconnectSshKey = 'auto_reconnect_ssh_key';
  static const _strictHostKeyKey = 'strict_host_key_checking_key';

  Future<void> saveFirstTimer(bool isFirstTimer) async {
    await _prefs.setBool(_isFirstTimer, isFirstTimer);
  }

  Future<void> cacheThemeMode(ThemeMode themeMode) async {
    await _prefs.setString(_themeKey, themeMode.themeStringValue);
    Cache.instance.setThemeMode(themeMode);
  }

  Future<void> cacheTerminalFontSize(double fontSize) async {
    final clamped = fontSize.clamp(
      UserPrefs.minFontSize,
      UserPrefs.maxFontSize,
    );
    await _prefs.setDouble(_terminalFontSizeKey, clamped);
  }

  Future<void> cacheTerminalThemeId(String themeId) async {
    await _prefs.setString(_terminalThemeIdKey, themeId);
  }

  Future<void> cacheSshConnectionTimeout(int seconds) async {
    await _prefs.setInt(_sshTimeoutKey, seconds.clamp(5, 60));
  }

  Future<void> cacheSshKeepAlive(int seconds) async {
    await _prefs.setInt(_sshKeepAliveKey, seconds.clamp(0, 120));
  }

  Future<void> cacheAutoPingOnStartup(bool enabled) async {
    await _prefs.setBool(_autoPingKey, enabled);
  }

  Future<void> cacheAutoReconnectSsh(bool enabled) async {
    await _prefs.setBool(_autoReconnectSshKey, enabled);
  }

  Future<void> cacheStrictHostKeyChecking(bool enabled) async {
    await _prefs.setBool(_strictHostKeyKey, enabled);
  }

  bool isFirstTime() => _prefs.getBool(_isFirstTimer) ?? true;

  ThemeMode getThemeMode() {
    final themeModeStringValue = _prefs.getString(_themeKey);
    final themeMode =
        themeModeStringValue?.stringValueToTheme ?? ThemeMode.dark;
    Cache.instance.setThemeMode(themeMode);
    return themeMode;
  }

  double getTerminalFontSize() {
    return (_prefs.getDouble(_terminalFontSizeKey) ?? UserPrefs.defaultFontSize)
        .clamp(UserPrefs.minFontSize, UserPrefs.maxFontSize);
  }

  String getTerminalThemeId() {
    return _prefs.getString(_terminalThemeIdKey) ??
        UserPrefs.defaultTerminalThemeId;
  }

  int getSshConnectionTimeout() {
    return (_prefs.getInt(_sshTimeoutKey) ??
            UserPrefs.defaultConnectionTimeoutSeconds)
        .clamp(5, 60);
  }

  int getSshKeepAlive() {
    return (_prefs.getInt(_sshKeepAliveKey) ??
            UserPrefs.defaultKeepAliveSeconds)
        .clamp(0, 120);
  }

  bool getAutoPingOnStartup() => _prefs.getBool(_autoPingKey) ?? true;

  bool getAutoReconnectSsh() => _prefs.getBool(_autoReconnectSshKey) ?? true;

  bool getStrictHostKeyChecking() => _prefs.getBool(_strictHostKeyKey) ?? true;

  UserPrefs getUserPrefs() {
    return UserPrefs(
      terminalFontSize: getTerminalFontSize(),
      terminalThemeId: getTerminalThemeId(),
      themeMode: getThemeMode(),
      sshConnectionTimeoutSeconds: getSshConnectionTimeout(),
      sshKeepAliveSeconds: getSshKeepAlive(),
      autoPingOnStartup: getAutoPingOnStartup(),
      autoReconnectSsh: getAutoReconnectSsh(),
      strictHostKeyChecking: getStrictHostKeyChecking(),
    );
  }

  Future<UserPrefs> resetUserPrefs() async {
    await _prefs.remove(_terminalFontSizeKey);
    await _prefs.remove(_terminalThemeIdKey);
    await _prefs.remove(_sshTimeoutKey);
    await _prefs.remove(_sshKeepAliveKey);
    await _prefs.remove(_autoPingKey);
    await _prefs.remove(_autoReconnectSshKey);
    await _prefs.remove(_strictHostKeyKey);
    await cacheThemeMode(ThemeMode.dark);
    return getUserPrefs();
  }
}
