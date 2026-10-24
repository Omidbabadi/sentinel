import 'package:sentinel/core/common/entities/server_group.dart';
import 'package:sentinel/core/utils/typedefs.dart';

class ServerGroupModel extends ServerGroup {
  const ServerGroupModel({
    super.id,
    required super.name,
    super.description,
    super.colorHex = '#10B981',
    super.iconName = 'folder',
    required super.createdAt,
    required super.updatedAt,
  });

  ServerGroupModel.test() : super.test();

  factory ServerGroupModel.fromEntity(ServerGroup group) {
    return ServerGroupModel(
      id: group.id,
      name: group.name,
      description: group.description,
      colorHex: group.colorHex,
      iconName: group.iconName,
      createdAt: group.createdAt,
      updatedAt: group.updatedAt,
    );
  }

  ServerGroupModel copyWith({
    int? id,
    String? name,
    String? description,
    bool clearDescription = false,
    String? colorHex,
    String? iconName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServerGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  DataMap toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color_hex': colorHex,
      'icon_name': iconName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ServerGroupModel.fromMap(DataMap map) {
    return ServerGroupModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      colorHex: (map['color_hex'] as String?) ?? '#10B981',
      iconName: (map['icon_name'] as String?) ?? 'folder',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
