import 'package:dartssh2/dartssh2.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;

class SftpEntry extends Equatable {
  const SftpEntry({
    required this.name,
    required this.fullPath,
    required this.isDirectory,
    required this.isSymbolicLink,
    this.size,
    this.modifiedAt,
    this.permissionsOctal,
  });

  final String name;
  final String fullPath;
  final bool isDirectory;
  final bool isSymbolicLink;
  final int? size;
  final DateTime? modifiedAt;
  final String? permissionsOctal;

  factory SftpEntry.fromSftpName(String parentDir, SftpName item) {
    final fullPath = p.posix.normalize(p.posix.join(parentDir, item.filename));
    final attr = item.attr;
    final mtime = attr.modifyTime;
    final modeVal = attr.mode?.value;
    final octal = modeVal != null
        ? (modeVal & 0x1FF).toRadixString(8).padLeft(3, '0')
        : null;

    return SftpEntry(
      name: item.filename,
      fullPath: fullPath,
      isDirectory: attr.isDirectory,
      isSymbolicLink: attr.isSymbolicLink,
      size: attr.size,
      modifiedAt: mtime != null
          ? DateTime.fromMillisecondsSinceEpoch(mtime * 1000)
          : null,
      permissionsOctal: octal,
    );
  }

  String get formattedSize {
    if (isDirectory) return 'Folder';
    final bytes = size;
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  @override
  List<Object?> get props => [
    name,
    fullPath,
    isDirectory,
    isSymbolicLink,
    size,
    modifiedAt,
    permissionsOctal,
  ];
}

class SftpTransferProgress extends Equatable {
  const SftpTransferProgress({
    required this.label,
    required this.isUpload,
    this.transferredBytes = 0,
    this.totalBytes,
  });

  final String label;
  final bool isUpload;
  final int transferredBytes;
  final int? totalBytes;

  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return (transferredBytes / total).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [label, isUpload, transferredBytes, totalBytes];
}
