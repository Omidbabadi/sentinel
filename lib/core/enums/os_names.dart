enum OsNames {
  ubuntu,
  debian,
  arch,
  cachyOS,
  centOS,
  fedora,
  rockyLinux,
  almaLinux,
  unknown;

  OsNames parseOsName(String id) {
    switch (id.toLowerCase()) {
      case 'ubuntu':
        return OsNames.ubuntu;
      case 'debian':
        return OsNames.debian;
      case 'arch':
        return OsNames.arch;
      case 'cachyos':
        return OsNames.cachyOS;
      case 'centos':
        return OsNames.centOS;
      case 'fedora':
        return OsNames.fedora;
      case 'rocky':
        return OsNames.rockyLinux;
      case 'almalinux':
        return OsNames.almaLinux;
      default:
        return OsNames.unknown;
    }
  }
}
