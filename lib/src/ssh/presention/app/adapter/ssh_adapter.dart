import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/common/application/riverpod/internet_connectivity_controller.dart';
import 'package:sentinel/core/common/application/riverpod/user_prefs.dart';
import 'package:sentinel/core/common/internet_conectivity.dart';
import 'package:sentinel/core/services/injection_container.dart';
import 'package:sentinel/src/ssh/widget/terminal_modifier_controller.dart';
import 'package:xterm2/core.dart';

import '../../../../../core/common/entities/host.dart';
import '../../../domain/usecase/connect.dart';

part 'ssh_adapter.g.dart';

part 'ssh_state.dart';

@Riverpod(keepAlive: true)
class SshAdapter extends _$SshAdapter {
  AppLifecycleListener? _lifecycleListener;

  @override
  Map<int, SshState> build() {
    _connect = sl<Connect>();

    _lifecycleListener?.dispose();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        unawaited(_handleAppResumed());
      },
    );

    ref.listen<AsyncValue<bool>>(internetConnectivityControllerProvider, (
      previous,
      next,
    ) {
      final wasConnected = previous?.value;
      final isNowConnected = next.value;
      if (wasConnected == isNowConnected || isNowConnected == null) return;

      if (!isNowConnected) {
        unawaited(_handleNetworkLost());
      } else {
        unawaited(_handleNetworkRestored());
      }
    });

    ref.onDispose(() {
      _lifecycleListener?.dispose();
      _lifecycleListener = null;
      for (final connection in state.values) {
        if (connection is SshConnected) {
          unawaited(_disposeConnection(connection));
        }
      }
    });

    return {};
  }

  late Connect _connect;

  bool get _isAppInForeground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  Future<void> _handleAppResumed() async {
    final hasNet = await sl<NetworkInfo>().checkConnectivity();
    if (!hasNet) return;

    // Verify existing connections and auto-reconnect any session that the OS
    // closed while the app was backgrounded.
    final autoReconnect = ref.read(userPrefsProvider).autoReconnectSsh;
    final openTabs = ref.read(activeHostTabControllerProvider).tabs;

    for (final tab in openTabs) {
      final current = stateFor(tab.id);
      if (current is SshConnected) {
        if (current.client.isClosed) {
          await _disposeConnection(current);
          _setStateFor(tab.id, const SshDisconnected('Session closed'));
          if (autoReconnect) {
            unawaited(connect(ConnectParams(host: tab.host)));
          }
        }
      } else if (autoReconnect &&
          (current is SshDisconnected || current is SshError)) {
        unawaited(connect(ConnectParams(host: tab.host)));
      }
    }
  }

  Future<void> _handleNetworkLost() async {
    // Ignore spurious Android network-lost callbacks fired when backgrounding
    if (!_isAppInForeground) return;

    final toDispose = <SshConnected>[];
    final updated = <int, SshState>{...state};

    for (final entry in state.entries) {
      final conn = entry.value;
      if (conn is SshConnected) {
        toDispose.add(conn);
        updated[entry.key] = const SshDisconnected(
          'Disconnected: No internet connection.',
        );
      } else if (conn is SshConnecting) {
        updated[entry.key] = const SshError(
          'No internet connection. Waiting for network...',
        );
      }
    }

    // Update state synchronously before awaiting disposal to prevent a race
    // condition if _handleNetworkRestored fires immediately afterward.
    state = updated;

    for (final conn in toDispose) {
      await _disposeConnection(conn);
    }
  }

  Future<void> _handleNetworkRestored() async {
    final autoReconnect = ref.read(userPrefsProvider).autoReconnectSsh;
    if (!autoReconnect) return;

    final openTabs = ref.read(activeHostTabControllerProvider).tabs;
    for (final tab in openTabs) {
      final current = stateFor(tab.id);
      if (current is SshDisconnected || current is SshError) {
        unawaited(connect(ConnectParams(host: tab.host)));
      }
    }
  }

  void _setStateFor(int hostId, SshState connection) {
    state = {...state, hostId: connection};
  }

  void _setErrorIfCurrent(int hostId, SSHClient client, String message) {
    final current = stateFor(hostId);

    if (current is SshConnected && identical(current.client, client)) {
      _setStateFor(hostId, SshError(message));
    }
  }

  int _hostIdForConnection(SshConnected connection) {
    return state.entries
        .firstWhere((entry) => identical(entry.value, connection))
        .key;
  }

  Future<void> _disposeConnection(SshConnected connection) async {
    await connection.stdoutSubscription.cancel();
    await connection.stderrSubscription.cancel();
    connection.client.close();
  }

  SshState stateFor(int hostId) {
    return state[hostId] ?? const SshInitial();
  }

  Future<void> connect(ConnectParams params) async {
    if (params.host.id == null) return;
    final current = stateFor(params.host.id!);
    if (current is SshConnected || current is SshConnecting) {
      return;
    }
    state = {...state, params.host.id!: const SshConnecting()};

    final result = await _connect(params);

    result.fold(
      (l) {
        state = {...state, params.host.id!: SshError(l.message)};
        return;
      },
      (r) async {
        final session = await r.shell();
        final terminal = Terminal(maxLines: 10000);
        terminal.onOutput = (data) {
          final transformed = TerminalModifierController.applyAndConsume(data);
          session.write(utf8.encode(transformed));
        };
        unawaited(
          session.done.then((_) {
            final current = stateFor(params.host.id!);
            if (current is SshConnected &&
                identical(current.session, session)) {
              _setStateFor(
                params.host.id!,
                const SshDisconnected('Session closed'),
              );
            }
          }),
        );

        final stdoutSubscription = session.stdout.listen(
          (data) {
            terminal.write(utf8.decode(data, allowMalformed: true));
          },
          onError: (Object error) {
            _setErrorIfCurrent(params.host.id!, r, 'SSH output error: $error');
          },
        );

        final stderrSubscription = session.stderr.listen(
          (data) {
            terminal.write(utf8.decode(data, allowMalformed: true));
          },
          onError: (Object error) {
            _setErrorIfCurrent(params.host.id!, r, 'SSH error output: $error');
          },
        );
        _setStateFor(
          params.host.id!,
          SshConnected(
            host: params.host,
            client: r,
            session: session,
            terminal: terminal,
            stdoutSubscription: stdoutSubscription,
            stderrSubscription: stderrSubscription,
          ),
        );
      },
    );
  }

  Future<void> disconnect(int hostId) async {
    final connection = stateFor(hostId);

    if (connection is SshConnected) {
      await _disposeConnection(connection);
    }

    _setStateFor(hostId, const SshDisconnected());
  }

  Future<void> disconnectAll() async {
    final connections = state.values.whereType<SshConnected>().toList();

    for (final connection in connections) {
      await _disposeConnection(connection);
      _setStateFor(_hostIdForConnection(connection), const SshDisconnected());
    }
  }
}
