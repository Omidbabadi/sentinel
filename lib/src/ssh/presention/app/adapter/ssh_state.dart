part of 'ssh_adapter.dart';

sealed class SshState {
  const SshState();
}

final class SshInitial extends SshState {
  const SshInitial();
}

final class SshConnecting extends SshState {
  const SshConnecting();
}

final class SshConnected extends SshState {
  const SshConnected({
    required this.client,
    required this.session,
    required this.terminal,
    required this.host,
    required this.stdoutSubscription,
    required this.stderrSubscription,
  });

  final SSHClient client;
  final SSHSession session;
  final Terminal terminal;
  final Host host;

  final StreamSubscription<Uint8List> stdoutSubscription;
  final StreamSubscription<Uint8List> stderrSubscription;
}

final class SshDisconnected extends SshState {
  const SshDisconnected([this.message]);

  final String? message;
}

final class SshError extends SshState {
  const SshError(this.message);

  final String message;
}
