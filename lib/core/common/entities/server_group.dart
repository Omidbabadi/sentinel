import 'package:equatable/equatable.dart';

class ServerGroup extends Equatable {
  const ServerGroup({
    this.id,
    required this.name,
    this.description,
    this.colorHex = '#10B981',
    this.iconName = 'folder',
    required this.createdAt,
    required this.updatedAt,
  });

  ServerGroup.test()
    : id = 1,
      name = 'Production Cluster',
      description = 'EU-Central primary nodes',
      colorHex = '#10B981',
      iconName = 'dns',
      createdAt = DateTime.now(),
      updatedAt = DateTime.now();

  final int? id;
  final String name;
  final String? description;
  final String colorHex;
  final String iconName;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    colorHex,
    iconName,
    createdAt,
    updatedAt,
  ];
}
