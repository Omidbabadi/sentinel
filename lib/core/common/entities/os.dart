import '../../enums/os_names.dart';

abstract class OS {
  const OS({required this.osName, required this.icon, required this.osVersion});

  final OsNames osName;
  final String osVersion;
  final String icon;

  OS.test() : icon = 'unknown', osName = OsNames.unknown, osVersion = '0';
}
