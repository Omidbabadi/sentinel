import 'package:equatable/equatable.dart';
import 'package:sentinel/core/common/entities/os.dart';

import '../../enums/ssh_auth_type.dart';

class Host extends Equatable {
  const Host({
    this.id,
    required this.ip,
    required this.hostname,
    required this.port,
    required this.username,
    required this.authType,
    this.groupName,
    required this.createdAt,
    required this.updatedAt,
    this.os,
    this.ping,
  });

  final int? id;
  final String ip;
  final String hostname;
  final int port;
  final String username;
  final SshAuthType authType;
  final String? groupName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OS? os;
  final double? ping;

  /// Helper getter to quickly check if the last ping succeeded
  bool get isReachable => ping != null && ping! > 0;

  Host.test()
    : id = 1,
      ip = '192.168.1.100',
      hostname = 'test-server',
      port = 22,
      username = 'root',
      authType = SshAuthType.password,
      groupName = 'Default',
      createdAt = DateTime(2026, 6, 27),
      updatedAt = DateTime(2026, 6, 27),
      os = null,
      ping = null;

  @override
  List<Object?> get props => [
    id,
    ip,
    hostname,
    port,
    username,
    authType,
    groupName,
    createdAt,
    updatedAt,
    os,
    ping,
  ];
}
