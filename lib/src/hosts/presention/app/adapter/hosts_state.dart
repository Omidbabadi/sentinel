part of 'hosts_adapter.dart';

sealed class HostsState extends Equatable {
  const HostsState();

  @override
  List<Object?> get props => [];
}

final class HostsInitial extends HostsState {
  const HostsInitial();
}

final class HostsLoading extends HostsState {
  const HostsLoading();
}

final class HostsLoaded extends HostsState {
  const HostsLoaded(this.hosts);

  final List<Host> hosts;

  @override
  List<Object?> get props => [hosts];
}

final class HostsError extends HostsState {
  const HostsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
