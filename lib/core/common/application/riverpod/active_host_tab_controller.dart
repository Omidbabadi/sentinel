import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentinel/src/hosts/presention/app/adapter/hosts_adapter.dart';
import 'package:sentinel/src/ssh/domain/usecase/connect.dart';
import 'package:sentinel/src/ssh/presention/app/adapter/ssh_adapter.dart';

import '../../entities/host.dart';

part 'active_host_tab_controller.g.dart';

typedef HostTab = ({Host host, int id});

class ActiveTabsState extends Equatable {
  const ActiveTabsState({
    this.tabs = const [],
    this.activeId,
    this.isFullscreen = false,
  });

  final List<HostTab> tabs;
  final int? activeId;
  final bool isFullscreen;

  Host? get activeHost {
    if (activeId == null) return null;
    for (final tab in tabs) {
      if (tab.id == activeId) return tab.host;
    }
    return tabs.isNotEmpty ? tabs.last.host : null;
  }

  ActiveTabsState copyWith({
    List<HostTab>? tabs,
    int? activeId,
    bool? isFullscreen,
    bool clearActive = false,
  }) {
    return ActiveTabsState(
      tabs: tabs ?? this.tabs,
      activeId: clearActive ? null : (activeId ?? this.activeId),
      isFullscreen: isFullscreen ?? this.isFullscreen,
    );
  }

  @override
  List<Object?> get props => [tabs, activeId, isFullscreen];
}

@Riverpod(keepAlive: true)
class ActiveHostTabController extends _$ActiveHostTabController {
  @override
  ActiveTabsState build() {
    // 1. When any SSH session transitions to SshConnected, refresh hosts from SQLite so the detected OS updates
    ref.listen(sshAdapterProvider, (previous, next) {
      for (final entry in next.entries) {
        final prev = previous?[entry.key];
        if (prev is! SshConnected && entry.value is SshConnected) {
          ref
              .read(hostsAdapterProvider.notifier)
              .getHostFromLocalBase(pingAfterLoad: false);
          break;
        }
      }
    });

    // 2. Keep tab Host entities synced when HostsAdapter reloads updated OS/ping data from SQLite
    ref.listen(hostsAdapterProvider, (previous, next) {
      if (next is HostsLoaded && state.tabs.isNotEmpty) {
        final updatedTabs = state.tabs.map((tab) {
          final match = next.hosts.where((h) => h.id == tab.id).firstOrNull;
          return match != null ? (host: match, id: tab.id) : tab;
        }).toList();
        state = state.copyWith(tabs: updatedTabs);
      }
    });

    return const ActiveTabsState();
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void setFullscreen(bool value) {
    if (state.isFullscreen == value) return;
    state = state.copyWith(isFullscreen: value);
  }

  /// Adds the host tab (if not already open), makes it active, and connects via SSH if needed.
  void openHost(Host host) {
    final hostId = host.id;
    if (hostId == null) return;

    final index = state.tabs.indexWhere((tab) => tab.id == hostId);
    final updatedTabs = index == -1
        ? [...state.tabs, (host: host, id: hostId)]
        : [
            for (final tab in state.tabs)
              if (tab.id == hostId) (host: host, id: hostId) else tab,
          ];

    state = state.copyWith(tabs: updatedTabs, activeId: hostId);
    _ensureConnected(host);
  }

  /// Switches the active tab and connects if not already connected.
  void selectTab(int hostId) {
    if (state.activeId == hostId) return;
    final tab = state.tabs.where((t) => t.id == hostId).firstOrNull;
    if (tab == null) return;

    state = state.copyWith(activeId: hostId);
    _ensureConnected(tab.host);
  }

  /// Forces a reconnect on the given host (or current active host).
  void reconnect([Host? targetHost]) {
    final host = targetHost ?? state.activeHost;
    if (host?.id == null) return;
    ref.read(sshAdapterProvider.notifier).connect(ConnectParams(host: host!));
  }

  /// Disconnects SSH, removes the tab, and activates the previous remaining tab.
  /// Returns `true` if there are still open tabs, or `false` if all tabs were closed.
  bool closeTab(int hostId) {
    ref.read(sshAdapterProvider.notifier).disconnect(hostId);
    final remaining = state.tabs.where((tab) => tab.id != hostId).toList();

    if (remaining.isEmpty) {
      state = const ActiveTabsState();
      return false;
    }

    if (state.activeId == hostId) {
      final nextTab = remaining.last;
      state = state.copyWith(tabs: remaining, activeId: nextTab.id);
      _ensureConnected(nextTab.host);
    } else {
      state = state.copyWith(tabs: remaining);
    }
    return true;
  }

  void clear() {
    for (final tab in state.tabs) {
      ref.read(sshAdapterProvider.notifier).disconnect(tab.id);
    }
    state = const ActiveTabsState();
  }

  void _ensureConnected(Host host) {
    final hostId = host.id;
    if (hostId == null) return;

    final current = ref.read(sshAdapterProvider.notifier).stateFor(hostId);
    if (current is! SshConnected && current is! SshConnecting) {
      ref.read(sshAdapterProvider.notifier).connect(ConnectParams(host: host));
    }
  }
}
