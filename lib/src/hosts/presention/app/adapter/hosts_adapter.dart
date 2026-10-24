import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentinel/core/common/application/cache_helper.dart';
import 'package:sentinel/core/common/application/riverpod/internet_connectivity_controller.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/services/injection_container.dart';
import 'package:sentinel/src/hosts/domain/usecases/add_host.dart';
import 'package:sentinel/src/hosts/domain/usecases/delete_host.dart';
import 'package:sentinel/src/hosts/domain/usecases/get_hosts.dart';
import 'package:sentinel/src/hosts/domain/usecases/ping_a_hosts.dart';
import 'package:sentinel/src/hosts/domain/usecases/ping_al_host.dart';
import 'package:sentinel/src/hosts/domain/usecases/update_host.dart';

part 'hosts_adapter.g.dart';
part 'hosts_state.dart';

@Riverpod(keepAlive: true)
class HostsAdapter extends _$HostsAdapter {
  late final GetHosts _getHostFromLocalBase;
  late final AddHost _addHost;
  late final UpdateHost _updateHost;
  late final DeleteHost _deleteHost;
  late final PingAllHost _pingAlHost;
  late final PingHost _pingHost;

  @override
  HostsState build() {
    _getHostFromLocalBase = sl<GetHosts>();
    _addHost = sl<AddHost>();
    _updateHost = sl<UpdateHost>();
    _deleteHost = sl<DeleteHost>();
    _pingAlHost = sl<PingAllHost>();
    _pingHost = sl<PingHost>();

    ref.listen<AsyncValue<bool>>(internetConnectivityControllerProvider, (
      previous,
      next,
    ) {
      final wasConnected = previous?.value;
      final isNowConnected = next.value;

      if (wasConnected != isNowConnected && isNowConnected != null) {
        final currentState = state;
        if (currentState is HostsLoaded) {
          if (currentState.hosts.isNotEmpty) {
            pingAllHosts(params: PingAlHostParams(host: currentState.hosts));
          }
        } else if (currentState is! HostsLoading) {
          getHostFromLocalBase();
        }
      }
    });

    return const HostsInitial();
  }

  Future<List<Host>> pingAllHosts({required PingAlHostParams params}) async {
    final results = await _pingAlHost.call(params);
    List<Host> hosts = [];

    results.fold((l) => state = HostsError(l.message), (r) {
      hosts = r;
      state = HostsLoaded(r);
    });

    return hosts;
  }

  Future<Host?> pingSingleHost({required Host host}) async {
    final result = await _pingHost.call(host);
    Host? updatedHost;

    result.fold((l) => state = HostsError(l.message), (r) {
      updatedHost = r;
      final currentState = state;
      if (currentState is HostsLoaded) {
        final updatedList = currentState.hosts.map((h) {
          return h.id == r.id ? r : h;
        }).toList();
        state = HostsLoaded(updatedList);
      }
    });

    return updatedHost;
  }

  Future<void> getHostFromLocalBase({bool? pingAfterLoad}) async {
    state = const HostsLoading();
    final result = await _getHostFromLocalBase.call();
    final shouldPing =
        pingAfterLoad ?? sl<CacheHelper>().getAutoPingOnStartup();
    result.fold((l) => state = HostsError(l.message), (r) {
      state = HostsLoaded(r);
      if (shouldPing && r.isNotEmpty) {
        pingAllHosts(params: PingAlHostParams(host: r));
      }
    });
  }

  Future<void> addHost({
    required Host host,
    required String secret,
    String? passphrase,
  }) async {
    state = const HostsLoading();
    final result = await _addHost.call(
      AddHostParams(host: host, secret: secret, passphrase: passphrase),
    );
    await result.fold(
      (l) async => state = HostsError(l.message),
      (r) async => await getHostFromLocalBase(),
    );
  }

  Future<void> updateHost({
    required Host host,
    String? secret,
    String? passphrase,
  }) async {
    state = const HostsLoading();
    final result = await _updateHost.call(
      UpdateHostParams(host: host, secret: secret, passphrase: passphrase),
    );
    await result.fold(
      (l) async => state = HostsError(l.message),
      (r) async => await getHostFromLocalBase(),
    );
  }

  Future<void> deleteHost(int id) async {
    final result = await _deleteHost.call(id);
    await result.fold(
      (l) async => state = HostsError(l.message),
      (r) async => await getHostFromLocalBase(),
    );
  }
}
