import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

abstract interface class NetworkInfo {
  bool get isConnected;
  Stream<bool> get onConnectivityChanged;
  Future<void> init();
  Future<bool> checkConnectivity();
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;
  bool _isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _offlineDebounceTimer;
  final _controller = StreamController<bool>.broadcast();

  bool get _isAppInForeground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  Future<void> init() async {
    await checkConnectivity();
    try {
      _subscription = _connectivity.onConnectivityChanged.listen(
        (results) {
          final connected = _hasActiveInterface(results);

          if (connected) {
            _offlineDebounceTimer?.cancel();
            _offlineDebounceTimer = null;
            if (!_isConnected) {
              _isConnected = true;
              if (!_controller.isClosed) {
                _controller.add(true);
              }
            }
          } else {
            // Android often emits spurious ConnectivityResult.none when the app
            // goes to background or is resuming. Ignore offline events while
            // backgrounded, and debounce in foreground to confirm real loss.
            if (!_isAppInForeground) return;

            _offlineDebounceTimer?.cancel();
            _offlineDebounceTimer = Timer(
              const Duration(milliseconds: 1500),
              () async {
                if (!_isAppInForeground) return;
                final stillConnected = await checkConnectivity();
                if (!stillConnected && _isConnected) {
                  _isConnected = false;
                  if (!_controller.isClosed) {
                    _controller.add(false);
                  }
                }
              },
            );
          }
        },
        onError: (Object e) {
          debugPrint('Connectivity stream error: $e');
        },
      );
    } on MissingPluginException catch (e) {
      debugPrint('Connectivity plugin not registered: $e');
    } on PlatformException catch (e) {
      debugPrint('Connectivity platform error: $e');
    }
  }

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream.distinct();

  @override
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final connected = _hasActiveInterface(results);

      // Do not flip to false while backgrounded due to OS background restrictions
      if (!connected && !_isAppInForeground) {
        return _isConnected;
      }

      if (_isConnected != connected) {
        _isConnected = connected;
        if (!_controller.isClosed) {
          _controller.add(_isConnected);
        }
      }
      return _isConnected;
    } on MissingPluginException catch (e) {
      debugPrint('Connectivity plugin missing (need full rebuild?): $e');
      return _isConnected;
    } on PlatformException catch (e) {
      debugPrint('Connectivity check failed: $e');
      return _isConnected;
    }
  }

  bool _hasActiveInterface(List<ConnectivityResult> results) {
    if (results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none)) {
      return false;
    }
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn ||
          r == ConnectivityResult.other,
    );
  }

  void dispose() {
    _offlineDebounceTimer?.cancel();
    _subscription?.cancel();
    _controller.close();
  }
}
