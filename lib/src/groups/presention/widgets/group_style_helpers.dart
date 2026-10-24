import 'package:flutter/material.dart';

class GroupColorOption {
  const GroupColorOption({
    required this.hex,
    required this.label,
    required this.color,
  });

  final String hex;
  final String label;
  final Color color;
}

class GroupIconOption {
  const GroupIconOption({
    required this.name,
    required this.label,
    required this.icon,
  });

  final String name;
  final String label;
  final IconData icon;
}

abstract final class GroupStyleHelpers {
  static const List<GroupColorOption> colorOptions = [
    GroupColorOption(
      hex: '#10B981',
      label: 'Emerald',
      color: Color(0xFF10B981),
    ),
    GroupColorOption(
      hex: '#3B82F6',
      label: 'Cyber Blue',
      color: Color(0xFF3B82F6),
    ),
    GroupColorOption(
      hex: '#8B5CF6',
      label: 'Violet',
      color: Color(0xFF8B5CF6),
    ),
    GroupColorOption(
      hex: '#F59E0B',
      label: 'Amber',
      color: Color(0xFFF59E0B),
    ),
    GroupColorOption(
      hex: '#EC4899',
      label: 'Rose',
      color: Color(0xFFEC4899),
    ),
    GroupColorOption(
      hex: '#06B6D4',
      label: 'Cyan',
      color: Color(0xFF06B6D4),
    ),
  ];

  static const List<GroupIconOption> iconOptions = [
    GroupIconOption(
      name: 'folder',
      label: 'Folder',
      icon: Icons.folder_rounded,
    ),
    GroupIconOption(
      name: 'dns',
      label: 'Cluster',
      icon: Icons.dns_rounded,
    ),
    GroupIconOption(
      name: 'cloud',
      label: 'Cloud',
      icon: Icons.cloud_outlined,
    ),
    GroupIconOption(
      name: 'shield',
      label: 'Bastion',
      icon: Icons.shield_outlined,
    ),
    GroupIconOption(
      name: 'memory',
      label: 'Compute',
      icon: Icons.memory_rounded,
    ),
    GroupIconOption(
      name: 'hub',
      label: 'Mesh',
      icon: Icons.hub_outlined,
    ),
  ];

  static Color parseColor(String hex) {
    final cleaned = hex.trim().replaceFirst('#', '');
    if (cleaned.length == 6) {
      final parsed = int.tryParse('FF$cleaned', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return const Color(0xFF10B981);
  }

  static IconData resolveIcon(String iconName) {
    for (final option in iconOptions) {
      if (option.name == iconName) return option.icon;
    }
    return Icons.folder_rounded;
  }
}
