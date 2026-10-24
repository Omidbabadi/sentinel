import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';

class SftpEditorHelper {
  const SftpEditorHelper._();

  /// Ordered list of terminal text editors to probe on the remote server.
  /// `nano` is preferred; if `nano` is not installed, falls back in order.
  static const List<String> candidateEditors = [
    'nano',
    'micro',
    'vim',
    'nvim',
    'vi',
    'emacs',
    'ee',
  ];

  /// Escapes characters that are special inside double quotes in POSIX shells.
  static String escapeDoubleQuotedPath(String remotePath) {
    return remotePath
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll(r'$', r'\$')
        .replaceAll('`', r'\`');
  }

  /// Builds the terminal command to open [remotePath] in [editor], e.g.:
  /// `nano "/path/to/file"`
  static String buildEditorCommand({
    required String editor,
    required String remotePath,
  }) {
    final escapedPath = escapeDoubleQuotedPath(remotePath);
    return '$editor "$escapedPath"';
  }

  /// Probes the remote server over [client] for `nano`, or the first installed
  /// fallback terminal text editor (`micro`, `vim`, `nvim`, `vi`, `emacs`, `ee`).
  static Future<String> detectInstalledEditor(SSHClient client) async {
    const probeCommand =
        'for ed in nano micro vim nvim vi emacs ee; do '
        'if command -v "\$ed" >/dev/null 2>&1; then echo "\$ed"; exit 0; fi; '
        'done';
    try {
      final result = await client
          .run(probeCommand)
          .timeout(const Duration(seconds: 4));
      final detected = utf8
          .decode(result, allowMalformed: true)
          .trim()
          .split(RegExp(r'\s+'))
          .first
          .trim();
      if (candidateEditors.contains(detected)) {
        return detected;
      }
    } catch (_) {
      // Fall back below if the probe command times out or fails
    }
    return 'vi';
  }
}
