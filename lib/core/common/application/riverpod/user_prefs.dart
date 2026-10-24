import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/application/cache_helper.dart';
import 'package:sentinel/core/services/injection_container.dart';

import '../../singelton/user_prefs.dart';

final userPrefsProvider = NotifierProvider<UserPrefsController, UserPrefs>(
  UserPrefsController.new,
);

class UserPrefsController extends Notifier<UserPrefs> {
  late final CacheHelper _cacheHelper;

  @override
  UserPrefs build() {
    _cacheHelper = sl<CacheHelper>();
    return _cacheHelper.getUserPrefs();
  }

  Future<void> setTerminalFontSize(double size) async {
    final clamped = double.parse(
      size
          .clamp(UserPrefs.minFontSize, UserPrefs.maxFontSize)
          .toStringAsFixed(1),
    );
    if (state.terminalFontSize == clamped) return;
    state = state.copyWith(terminalFontSize: clamped);
    await _cacheHelper.cacheTerminalFontSize(clamped);
  }

  Future<void> incrementFontSize([double step = 1.0]) async {
    await setTerminalFontSize(state.terminalFontSize + step);
  }

  Future<void> decrementFontSize([double step = 1.0]) async {
    await setTerminalFontSize(state.terminalFontSize - step);
  }

  Future<void> setTerminalThemeId(String themeId) async {
    if (state.terminalThemeId == themeId) return;
    state = state.copyWith(terminalThemeId: themeId);
    await _cacheHelper.cacheTerminalThemeId(themeId);
  }

  Future<void> setSshConnectionTimeout(int seconds) async {
    final clamped = seconds.clamp(5, 60);
    if (state.sshConnectionTimeoutSeconds == clamped) return;
    state = state.copyWith(sshConnectionTimeoutSeconds: clamped);
    await _cacheHelper.cacheSshConnectionTimeout(clamped);
  }

  Future<void> setSshKeepAlive(int seconds) async {
    final clamped = seconds.clamp(0, 120);
    if (state.sshKeepAliveSeconds == clamped) return;
    state = state.copyWith(sshKeepAliveSeconds: clamped);
    await _cacheHelper.cacheSshKeepAlive(clamped);
  }

  Future<void> setAutoPingOnStartup(bool enabled) async {
    if (state.autoPingOnStartup == enabled) return;
    state = state.copyWith(autoPingOnStartup: enabled);
    await _cacheHelper.cacheAutoPingOnStartup(enabled);
  }

  Future<void> setAutoReconnectSsh(bool enabled) async {
    if (state.autoReconnectSsh == enabled) return;
    state = state.copyWith(autoReconnectSsh: enabled);
    await _cacheHelper.cacheAutoReconnectSsh(enabled);
  }

  Future<void> setStrictHostKeyChecking(bool enabled) async {
    if (state.strictHostKeyChecking == enabled) return;
    state = state.copyWith(strictHostKeyChecking: enabled);
    await _cacheHelper.cacheStrictHostKeyChecking(enabled);
  }

  Future<void> resetToDefaults() async {
    state = await _cacheHelper.resetUserPrefs();
  }
}
