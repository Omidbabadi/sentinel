import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/enums/os_names.dart';
import 'package:sentinel/core/utils/typedefs.dart';
import 'package:sentinel/src/hosts/data/model/linux_os_model.dart';

import '../../../../core/enums/ssh_auth_type.dart';

class HostModel extends Host {
  const HostModel({
    super.id,
    required super.ip,
    required super.hostname,
    required super.port,
    required super.username,
    required super.authType,
    super.groupName,
    required super.createdAt,
    required super.updatedAt,
    super.os,
    super.ping,
  });

  HostModel.test() : super.test();

  factory HostModel.fromEntity(Host host) {
    return HostModel(
      id: host.id,
      ip: host.ip,
      hostname: host.hostname,
      port: host.port,
      username: host.username,
      authType: host.authType,
      groupName: host.groupName,
      createdAt: host.createdAt,
      updatedAt: host.updatedAt,
      os: host.os != null
          ? LinuxOsModel(
              osName: host.os!.osName,
              osVersion: host.os!.osVersion,
              icon: host.os!.icon,
            )
          : null,
      ping: host.ping,
    );
  }

  /// Use [clearPing: true] when a host goes offline so `ping` can be set to `null`.
  HostModel copyWith({
    int? id,
    String? ip,
    String? hostname,
    int? port,
    String? username,
    SshAuthType? authType,
    String? groupName,
    DateTime? createdAt,
    DateTime? updatedAt,
    LinuxOsModel? os,
    double? ping,
    bool clearPing = false,
  }) {
    return HostModel(
      id: id ?? this.id,
      ip: ip ?? this.ip,
      hostname: hostname ?? this.hostname,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      groupName: groupName ?? this.groupName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      os: os ?? (this.os as LinuxOsModel?),
      ping: clearPing ? null : (ping ?? this.ping),
    );
  }

  DataMap toMap() {
    return {
      'id': id,
      'ip': ip,
      'hostname': hostname,
      'port': port,
      'username': username,
      'auth_type': authType.value,
      'group_name': groupName,
      'os_name': os?.osName.name ?? OsNames.unknown.name,
      'os_version': os?.osVersion ?? '',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'ping': ping,
    };
  }

  factory HostModel.fromMap(DataMap map) {
    final osNameString = map['os_name'] as String? ?? 'unknown';
    final osName = OsNames.values.firstWhere(
      (value) => value.name == osNameString,
      orElse: () => OsNames.unknown,
    );

    final osVersion = map['os_version'] as String? ?? '';
    final rawPing = (map['ping'] as num?)?.toDouble();

    return HostModel(
      id: map['id'] as int,
      ip: map['ip'] as String,
      hostname: map['hostname'] as String,
      port: map['port'] as int,
      username: map['username'] as String,
      authType: SshAuthType.fromValue(map['auth_type'] as String),
      groupName: map['group_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      os: osName == OsNames.unknown
          ? null
          : LinuxOsModel(osName: osName, osVersion: osVersion, icon: ''),
      ping: (rawPing != null && rawPing > 0) ? rawPing : null,
    );
  }
}
