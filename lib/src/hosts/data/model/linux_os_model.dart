import 'package:sentinel/core/common/entities/os.dart';
import 'package:sentinel/core/enums/os_names.dart';

class LinuxOsModel extends OS {
  const LinuxOsModel({
    required super.osName,
    required super.icon,
    required super.osVersion,
  });

  /// Parses the contents of `/etc/os-release` into an [LinuxOsModel].
  ///
  /// Expected format (key=value, values may be quoted):
  /// ```
  /// ID=ubuntu
  /// VERSION_ID="22.04"
  /// PRETTY_NAME="Ubuntu 22.04.3 LTS"
  /// ```
  factory LinuxOsModel.fromOsRelease(String osReleaseContent) {
    final fields = <String, String>{};

    for (final line in osReleaseContent.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final separatorIndex = trimmed.indexOf('=');
      if (separatorIndex == -1) continue;

      final key = trimmed.substring(0, separatorIndex).trim();
      // Strip surrounding quotes from the value if present.
      var value = trimmed.substring(separatorIndex + 1).trim();
      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }

      fields[key] = value;
    }

    // ID holds the machine-readable distro identifier (e.g. "ubuntu", "arch").
    final id = fields['ID'] ?? '';
    final osName = OsNames.unknown.parseOsName(id);

    // VERSION_ID is the release number; fall back to VERSION or empty string.
    final osVersion = fields['VERSION_ID'] ?? fields['VERSION'] ?? '';

    final icon = _iconForOs(osName);

    return LinuxOsModel(osName: osName, icon: icon, osVersion: osVersion);
  }

  /// Returns an emoji/icon string for the given [OsNames] value.
  static String _iconForOs(OsNames name) => switch (name) {
    OsNames.ubuntu => '🐧',
    OsNames.debian => '🌀',
    OsNames.arch => '🏹',
    OsNames.cachyOS => '⚡',
    OsNames.centOS => '🎯',
    OsNames.fedora => '🎩',
    OsNames.rockyLinux => '🪨',
    OsNames.almaLinux => '🦋',
    OsNames.unknown => '🖥️',
  };

  LinuxOsModel copyWith({OsNames? osName, String? icon, String? osVersion}) =>
      LinuxOsModel(
        osName: osName ?? this.osName,
        icon: icon ?? this.icon,
        osVersion: osVersion ?? '',
      );
}
