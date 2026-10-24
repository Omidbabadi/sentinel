import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/common/application/riverpod/current_theme_controller.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/utils/core_utils.dart';
import 'package:sentinel/core/widgets/back_button.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/sentinel_botton.dart';
import 'package:sentinel/core/widgets/sentinel_state_view.dart';
import 'package:sentinel/src/home/presention/widgets/open_terminal_host_sheet.dart';
import 'package:sentinel/src/sftp/domain/entities/sftp_entry.dart';
import 'package:sentinel/src/sftp/presention/adapter/sftp_editor_helper.dart';
import 'package:sentinel/src/ssh/presention/app/adapter/ssh_adapter.dart';

class SentinelSftpView extends ConsumerStatefulWidget {
  const SentinelSftpView({
    super.key,
    this.host,
    this.onNavigate,
  });

  final Host? host;
  final ValueChanged<String>? onNavigate;

  @override
  ConsumerState<SentinelSftpView> createState() => _SentinelSftpViewState();
}

class _SentinelSftpViewState extends ConsumerState<SentinelSftpView> {
  final TextEditingController _searchController = TextEditingController();

  Host? _activeHost;
  SftpClient? _sftp;
  SSHClient? _attachedClient;
  String _currentPath = '/';
  List<SftpEntry> _entries = const [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showHidden = false;
  String _searchQuery = '';
  SftpTransferProgress? _transferProgress;

  @override
  void initState() {
    super.initState();
    _activeHost = widget.host;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSftp();
    });
  }

  @override
  void didUpdateWidget(covariant SentinelSftpView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.host != null && widget.host?.id != _activeHost?.id) {
      _activeHost = widget.host;
      _initializeSftp();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sftp?.close();
    super.dispose();
  }

  Host? _resolveHost() {
    if (_activeHost != null) return _activeHost;
    if (widget.host != null) return widget.host;
    return ref.read(activeHostTabControllerProvider).activeHost;
  }

  void _closeView() {
    if (context.canPop()) {
      context.pop();
    } else if (widget.onNavigate != null) {
      widget.onNavigate!(SentinelRoutes.hosts);
    } else {
      context.go(SentinelRoutes.hosts);
    }
  }

  Future<void> _switchHost(SentinelThemeTokens tokens, bool isDark) async {
    final picked = await OpenTerminalHostSheet.pickHost(
      context: context,
      tokens: tokens,
      isDark: isDark,
    );
    if (picked != null && mounted) {
      setState(() {
        _activeHost = picked;
      });
      await _initializeSftp();
    }
  }

  Future<void> _initializeSftp() async {
    if (!mounted) return;

    final host = _resolveHost();
    if (host == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    _activeHost = host;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final hostId = host.id;
    if (hostId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Host does not have a valid ID.';
      });
      return;
    }

    // Ensure the host tab and SSH connection are active
    ref.read(activeHostTabControllerProvider.notifier).openHost(host);

    SshState sshState = ref.read(sshAdapterProvider.notifier).stateFor(hostId);
    if (sshState is! SshConnected) {
      final completer = Completer<SshState>();
      final sub = ref.listenManual<Map<int, SshState>>(sshAdapterProvider, (
        prev,
        next,
      ) {
        final current = next[hostId];
        if (current is SshConnected || current is SshError) {
          if (!completer.isCompleted) {
            completer.complete(current!);
          }
        }
      });

      try {
        sshState = await completer.future.timeout(
          const Duration(seconds: 20),
          onTimeout: () => const SshError('Timed out waiting for SSH session.'),
        );
      } finally {
        sub.close();
      }
    }

    if (!mounted) return;

    if (sshState case SshError(:final message)) {
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
      return;
    }

    if (sshState is! SshConnected) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'SSH session is not connected.';
      });
      return;
    }

    try {
      _sftp?.close();
      _attachedClient = sshState.client;
      final sftp = await sshState.client.sftp();
      _sftp = sftp;
      final homePath = await sftp.absolute('.');
      await _loadDirectory(homePath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to open SFTP subsystem: $e';
      });
    }
  }

  Future<void> _loadDirectory(String targetPath) async {
    final sftp = _sftp;
    if (sftp == null) {
      await _initializeSftp();
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final normalized = p.posix.normalize(
        targetPath.isEmpty ? '/' : targetPath,
      );
      final rawItems = await sftp.listdir(normalized);
      final parsed = <SftpEntry>[];

      for (final item in rawItems) {
        if (item.filename == '.' || item.filename == '..') continue;
        parsed.add(SftpEntry.fromSftpName(normalized, item));
      }

      parsed.sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      if (!mounted) return;
      setState(() {
        _currentPath = normalized;
        _entries = parsed;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to read directory "$targetPath": $e';
      });
    }
  }

  void _navigateUp() {
    if (_currentPath == '/' || _currentPath.isEmpty) return;
    final parent = p.posix.dirname(_currentPath);
    _loadDirectory(parent);
  }

  Future<void> _downloadFile(SftpEntry entry) async {
    final sftp = _sftp;
    if (sftp == null || entry.isDirectory) return;

    try {
      final dirPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select folder to save ${entry.name}',
      );
      if (dirPath == null || dirPath.trim().isEmpty) return;
      final savePath = p.join(dirPath, entry.name);

      if (!mounted) return;
      setState(() {
        _transferProgress = SftpTransferProgress(
          label: 'Downloading ${entry.name}...',
          isUpload: false,
          transferredBytes: 0,
          totalBytes: entry.size,
        );
      });

      final remoteFile = await sftp.open(
        entry.fullPath,
        mode: SftpFileOpenMode.read,
      );
      final localFile = File(savePath);
      await localFile.parent.create(recursive: true);
      final sink = localFile.openWrite();

      try {
        await remoteFile.downloadTo(
          sink,
          closeDestination: true,
          onProgress: (bytesRead) {
            if (!mounted) return;
            setState(() {
              _transferProgress = SftpTransferProgress(
                label: 'Downloading ${entry.name}...',
                isUpload: false,
                transferredBytes: bytesRead,
                totalBytes: entry.size,
              );
            });
          },
        );
      } finally {
        await remoteFile.close();
      }

      if (!mounted) return;
      setState(() => _transferProgress = null);
      CoreUtils.showSnackBar('Downloaded "${entry.name}" to $savePath');
    } catch (e) {
      if (!mounted) return;
      setState(() => _transferProgress = null);
      CoreUtils.showSnackBar(
        'Failed to download "${entry.name}": $e',
        isError: true,
      );
    }
  }

  Future<void> _uploadFiles() async {
    final sftp = _sftp;
    if (sftp == null) return;

    try {
      final pickedFiles = await FilePicker.pickFiles(
        dialogTitle: 'Select file(s) to upload to $_currentPath',
      );
      if (pickedFiles.isEmpty) return;

      for (final picked in pickedFiles) {
        final localPath = picked.path;
        if (localPath == null) continue;

        final localFile = File(localPath);
        if (!await localFile.exists()) continue;

        final fileName = p.basename(localPath);
        final remoteTarget = p.posix.join(_currentPath, fileName);
        final totalBytes = await localFile.length();

        await _uploadSingleLocalFile(
          sftp: sftp,
          localFile: localFile,
          remotePath: remoteTarget,
          displayLabel: 'Uploading $fileName...',
          totalBytes: totalBytes,
        );
      }

      if (!mounted) return;
      setState(() => _transferProgress = null);
      CoreUtils.showSnackBar(
        pickedFiles.length == 1
            ? 'Uploaded "${pickedFiles.first.name}"'
            : 'Uploaded ${pickedFiles.length} files',
      );
      await _loadDirectory(_currentPath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _transferProgress = null);
      CoreUtils.showSnackBar('File upload failed: $e', isError: true);
    }
  }

  Future<void> _uploadFolder() async {
    final sftp = _sftp;
    if (sftp == null) return;

    try {
      final dirPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select folder to upload to $_currentPath',
      );
      if (dirPath == null || dirPath.trim().isEmpty) return;

      final rootDir = Directory(dirPath);
      if (!await rootDir.exists()) return;

      final rootFolderName = p.basename(p.normalize(rootDir.absolute.path));
      final remoteBaseDir = p.posix.join(_currentPath, rootFolderName);

      if (!mounted) return;
      setState(() {
        _transferProgress = SftpTransferProgress(
          label: 'Preparing folder "$rootFolderName"...',
          isUpload: true,
        );
      });

      await _ensureRemoteDirectory(sftp, remoteBaseDir);

      final allEntities = await rootDir
          .list(recursive: true, followLinks: false)
          .toList();
      final directories = allEntities.whereType<Directory>().toList();
      final files = allEntities.whereType<File>().toList();

      for (final subDir in directories) {
        final rel = p.relative(subDir.path, from: rootDir.path);
        final relSegments = p.split(rel);
        final remoteSubDir = p.posix.joinAll([remoteBaseDir, ...relSegments]);
        await _ensureRemoteDirectory(sftp, remoteSubDir);
      }

      var uploadedCount = 0;
      for (final file in files) {
        uploadedCount++;
        final rel = p.relative(file.path, from: rootDir.path);
        final relSegments = p.split(rel);
        final remoteFilePath = p.posix.joinAll([remoteBaseDir, ...relSegments]);
        final totalBytes = await file.length();
        final shortName = p.basename(file.path);

        await _uploadSingleLocalFile(
          sftp: sftp,
          localFile: file,
          remotePath: remoteFilePath,
          displayLabel:
              'Uploading ($uploadedCount/${files.length}) $shortName...',
          totalBytes: totalBytes,
        );
      }

      if (!mounted) return;
      setState(() => _transferProgress = null);
      CoreUtils.showSnackBar(
        'Uploaded folder "$rootFolderName" ($uploadedCount files)',
      );
      await _loadDirectory(_currentPath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _transferProgress = null);
      CoreUtils.showSnackBar('Folder upload failed: $e', isError: true);
    }
  }

  Future<void> _ensureRemoteDirectory(
    SftpClient sftp,
    String remoteDirPath,
  ) async {
    try {
      final stat = await sftp.stat(remoteDirPath);
      if (stat.isDirectory) return;
    } catch (_) {
      // Directory does not exist yet; create it below
    }
    try {
      await sftp.mkdir(remoteDirPath);
    } catch (_) {
      // Ignore if created concurrently or already exists
    }
  }

  Future<void> _uploadSingleLocalFile({
    required SftpClient sftp,
    required File localFile,
    required String remotePath,
    required String displayLabel,
    required int totalBytes,
  }) async {
    if (mounted) {
      setState(() {
        _transferProgress = SftpTransferProgress(
          label: displayLabel,
          isUpload: true,
          transferredBytes: 0,
          totalBytes: totalBytes,
        );
      });
    }

    final remoteFile = await sftp.open(
      remotePath,
      mode:
          SftpFileOpenMode.create |
          SftpFileOpenMode.truncate |
          SftpFileOpenMode.write,
    );

    try {
      final stream = localFile.openRead().map(Uint8List.fromList);
      final writer = remoteFile.write(
        stream,
        onProgress: (written) {
          if (!mounted) return;
          setState(() {
            _transferProgress = SftpTransferProgress(
              label: displayLabel,
              isUpload: true,
              transferredBytes: written,
              totalBytes: totalBytes,
            );
          });
        },
      );
      await writer.done;
    } finally {
      await remoteFile.close();
    }
  }

  Future<void> _editFileInTerminal(SftpEntry entry) async {
    if (entry.isDirectory) return;
    final host = _resolveHost();
    final hostId = host?.id;
    if (host == null || hostId == null) return;

    final sshState = ref.read(sshAdapterProvider.notifier).stateFor(hostId);
    if (sshState is! SshConnected) {
      CoreUtils.showSnackBar(
        'SSH terminal is not connected yet.',
        isError: true,
      );
      return;
    }

    setState(() {
      _transferProgress = SftpTransferProgress(
        label: 'Opening ${entry.name} in terminal editor...',
        isUpload: false,
      );
    });

    final editor = await SftpEditorHelper.detectInstalledEditor(
      sshState.client,
    );
    final command = SftpEditorHelper.buildEditorCommand(
      editor: editor,
      remotePath: entry.fullPath,
    );

    if (!mounted) return;
    setState(() => _transferProgress = null);

    if (editor != 'nano') {
      CoreUtils.showSnackBar(
        'nano is not installed on server — opening with $editor',
      );
    }

    // Activate this host tab in FULLSCREEN mode and send the editor command to the interactive shell
    final tabNotifier = ref.read(activeHostTabControllerProvider.notifier);
    tabNotifier.openHost(host);
    tabNotifier.setFullscreen(true);
    sshState.session.write(utf8.encode('$command\r'));

    final targetRoute = SentinelRoutes.hostTerminal(host.hostname, host.ip);
    if (widget.onNavigate != null) {
      widget.onNavigate!(targetRoute);
    } else {
      context.go(targetRoute);
    }
  }

  Future<void> _promptCreateFolder(
    SentinelThemeTokens tokens,
    bool isDark,
  ) async {
    final sftp = _sftp;
    if (sftp == null) return;

    final controller = TextEditingController();
    final folderName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1E24) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: tokens.cardBorder),
          ),
          title: Text(
            'New Folder',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: tokens.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Folder name',
              hintStyle: TextStyle(color: tokens.textMuted),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.innerPillBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.greenAccent),
              ),
            ),
            onSubmitted: (val) => Navigator.of(dialogContext).pop(val.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.greenAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (folderName == null || folderName.isEmpty) return;
    try {
      final newDirPath = p.posix.join(_currentPath, folderName);
      await sftp.mkdir(newDirPath);
      CoreUtils.showSnackBar('Created folder "$folderName"');
      await _loadDirectory(_currentPath);
    } catch (e) {
      CoreUtils.showSnackBar('Failed to create folder: $e', isError: true);
    }
  }

  Future<void> _deleteEntry(
    SftpEntry entry,
    SentinelThemeTokens tokens,
    bool isDark,
  ) async {
    final sftp = _sftp;
    if (sftp == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1E24) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: tokens.cardBorder),
          ),
          title: Text(
            'Delete ${entry.isDirectory ? "Folder" : "File"}?',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${entry.name}" from the server?',
            style: TextStyle(color: tokens.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      if (entry.isDirectory) {
        try {
          await sftp.rmdir(entry.fullPath);
        } catch (_) {
          // If non-empty, remove recursively via SSH shell
          final client = _attachedClient;
          if (client != null) {
            final escaped = SftpEditorHelper.escapeDoubleQuotedPath(
              entry.fullPath,
            );
            await client.run('rm -rf "$escaped"');
          } else {
            rethrow;
          }
        }
      } else {
        await sftp.remove(entry.fullPath);
      }
      CoreUtils.showSnackBar('Deleted "${entry.name}"');
      await _loadDirectory(_currentPath);
    } catch (e) {
      CoreUtils.showSnackBar(
        'Failed to delete "${entry.name}": $e',
        isError: true,
      );
    }
  }

  List<SftpEntry> _filteredEntries() {
    final query = _searchQuery.trim().toLowerCase();
    return _entries.where((entry) {
      if (!_showHidden && entry.name.startsWith('.')) {
        return false;
      }
      if (query.isEmpty) return true;
      return entry.name.toLowerCase().contains(query);
    }).toList();
  }

  List<({String label, String path})> _buildBreadcrumbs() {
    final segments = p.posix
        .split(_currentPath)
        .where((s) => s.isNotEmpty && s != '/')
        .toList();
    final crumbs = <({String label, String path})>[
      (label: '/', path: '/'),
    ];
    var accum = '/';
    for (final seg in segments) {
      accum = p.posix.join(accum, seg);
      crumbs.add((label: seg, path: accum));
    }
    return crumbs;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(currentThemeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final tokens = SentinelThemeTokens(isDark);
    final host = _resolveHost();

    if (host == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 98),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MyBackButton(onPop: _closeView),
                const SizedBox(width: 12),
                Text(
                  'SFTP Browser',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SentinelStateView(
                tokens: tokens,
                icon: Icons.folder_open_rounded,
                accentColor: tokens.blueAccent,
                title: 'No Host Selected',
                subtitle: 'Choose a server to browse its files via SFTP.',
                actionLabel: 'Select Host',
                actionIcon: Icons.dns_outlined,
                onAction: () => _switchHost(tokens, isDark),
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredEntries();
    final breadcrumbs = _buildBreadcrumbs();
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 10;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        isKeyboardOpen ? 10 : 96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Fullscreen View Header Row
          Row(
            children: [
              MyBackButton(onPop: _closeView),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'SFTP • ${host.hostname}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'sftp://${host.username}@${host.ip}:${host.port}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              SentinelButton(
                tokens: tokens,
                isDark: isDark,
                width: 36,
                height: 36,
                borderRadius: 11,
                semanticLabel: _showHidden
                    ? 'Hide dotfiles'
                    : 'Show dotfiles',
                tooltip: _showHidden
                    ? 'Hide hidden files'
                    : 'Show hidden files',
                onTap: () => setState(() => _showHidden = !_showHidden),
                child: Icon(
                  _showHidden
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_outlined,
                  size: 17,
                  color: _showHidden
                      ? tokens.greenAccent
                      : tokens.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              SentinelButton(
                tokens: tokens,
                isDark: isDark,
                width: 36,
                height: 36,
                borderRadius: 11,
                semanticLabel: 'New folder',
                tooltip: 'New folder',
                onTap: () => _promptCreateFolder(tokens, isDark),
                child: Icon(
                  Icons.create_new_folder_outlined,
                  size: 17,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              SentinelButton(
                tokens: tokens,
                isDark: isDark,
                width: 36,
                height: 36,
                borderRadius: 11,
                semanticLabel: 'Refresh directory',
                tooltip: 'Refresh',
                onTap: () => _loadDirectory(_currentPath),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 17,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              SentinelButton(
                tokens: tokens,
                isDark: isDark,
                width: 36,
                height: 36,
                borderRadius: 11,
                semanticLabel: 'Switch SFTP host',
                tooltip: 'Switch host',
                onTap: () => _switchHost(tokens, isDark),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: tokens.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Main Frosted Glass Card Container
          Expanded(
            child: GlassCard(
              tokens: tokens,
              borderRadius: 22,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Upload File / Upload Folder Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SentinelButton(
                          tokens: tokens,
                          isDark: isDark,
                          width: null,
                          height: 40,
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          semanticLabel: 'Upload file to server',
                          onTap: _transferProgress == null
                              ? _uploadFiles
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_file_rounded,
                                size: 16,
                                color: tokens.greenAccent,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Upload File',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: tokens.textPrimary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SentinelButton(
                          tokens: tokens,
                          isDark: isDark,
                          width: null,
                          height: 40,
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          semanticLabel: 'Upload folder to server',
                          onTap: _transferProgress == null
                              ? _uploadFolder
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.drive_folder_upload_rounded,
                                size: 16,
                                color: tokens.blueAccent,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Upload Folder',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: tokens.textPrimary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Breadcrumb Path & Up Button
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: tokens.innerPillSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tokens.innerPillBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _currentPath != '/' ? _navigateUp : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: _currentPath != '/'
                                  ? tokens.greenAccent
                                  : tokens.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: breadcrumbs.length,
                            separatorBuilder: (_, _) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Center(
                                child: Text(
                                  '›',
                                  style: TextStyle(
                                    color: tokens.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            itemBuilder: (context, index) {
                              final crumb = breadcrumbs[index];
                              final isLast = index == breadcrumbs.length - 1;
                              return Center(
                                child: InkWell(
                                  onTap: isLast
                                      ? null
                                      : () => _loadDirectory(crumb.path),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 3,
                                    ),
                                    child: Text(
                                      crumb.label,
                                      style: TextStyle(
                                        color: isLast
                                            ? tokens.greenTextAccent
                                            : tokens.textSecondary,
                                        fontSize: 11.5,
                                        fontFamily: 'monospace',
                                        fontWeight: isLast
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Filter Input
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: tokens.innerPillSurface,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: tokens.innerPillBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 15,
                          color: tokens.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 12,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Filter files in current folder...',
                              hintStyle: TextStyle(
                                color: tokens.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: tokens.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Active Transfer Progress Indicator
                  if (_transferProgress != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.greenAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: tokens.greenAccent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: tokens.greenAccent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _transferProgress!.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: tokens.textPrimary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_transferProgress!.fraction != null)
                                Text(
                                  '${(_transferProgress!.fraction! * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: tokens.greenTextAccent,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          if (_transferProgress!.fraction != null) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _transferProgress!.fraction,
                                minHeight: 4,
                                backgroundColor: tokens.innerPillSurface,
                                color: tokens.greenAccent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Directory Contents
                  Expanded(
                    child: _buildBody(tokens, isDark, filtered),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    SentinelThemeTokens tokens,
    bool isDark,
    List<SftpEntry> filtered,
  ) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: tokens.greenAccent,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 12),
            Text(
              'Loading remote files...',
              style: TextStyle(color: tokens.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SentinelStateView(
          tokens: tokens,
          icon: Icons.error_outline_rounded,
          accentColor: tokens.redAccent,
          title: 'SFTP Error',
          subtitle: _errorMessage!,
          actionLabel: 'Retry',
          actionIcon: Icons.refresh_rounded,
          onAction: () => _loadDirectory(_currentPath),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: SentinelStateView(
          tokens: tokens,
          icon: Icons.folder_off_outlined,
          accentColor: tokens.textSecondary,
          title: 'Folder is Empty',
          subtitle: _searchQuery.isNotEmpty
              ? 'No files match "$_searchQuery".'
              : 'Upload a file or folder, or toggle hidden files.',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.innerPillSurface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.innerPillBorder, width: 0.8),
      ),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => Divider(
          height: 8,
          thickness: 0.6,
          color: tokens.dividerColor,
        ),
        itemBuilder: (context, index) {
          final entry = filtered[index];
          return _SftpEntryTile(
            entry: entry,
            tokens: tokens,
            onOpenDirectory: entry.isDirectory
                ? () => _loadDirectory(entry.fullPath)
                : null,
            onEdit: !entry.isDirectory
                ? () => _editFileInTerminal(entry)
                : null,
            onDownload: !entry.isDirectory ? () => _downloadFile(entry) : null,
            onDelete: () => _deleteEntry(entry, tokens, isDark),
          );
        },
      ),
    );
  }
}

class _SftpEntryTile extends StatelessWidget {
  const _SftpEntryTile({
    required this.entry,
    required this.tokens,
    this.onOpenDirectory,
    this.onEdit,
    this.onDownload,
    required this.onDelete,
  });

  final SftpEntry entry;
  final SentinelThemeTokens tokens;
  final VoidCallback? onOpenDirectory;
  final VoidCallback? onEdit;
  final VoidCallback? onDownload;
  final VoidCallback onDelete;

  IconData _iconForEntry() {
    if (entry.isDirectory) return Icons.folder_rounded;
    final ext = p.posix.extension(entry.name).toLowerCase();
    return switch (ext) {
      '.sh' || '.bash' || '.zsh' || '.py' || '.js' || '.ts' || '.dart' =>
        Icons.code_rounded,
      '.json' ||
      '.yaml' ||
      '.yml' ||
      '.toml' ||
      '.conf' ||
      '.ini' ||
      '.env' => Icons.settings_ethernet_rounded,
      '.zip' || '.tar' || '.gz' || '.tgz' || '.bz2' || '.xz' =>
        Icons.folder_zip_outlined,
      '.log' || '.txt' || '.md' => Icons.description_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = entry.isDirectory
        ? tokens.yellowAccent
        : tokens.blueAccent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: entry.isDirectory ? onOpenDirectory : onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.32),
                    width: 0.8,
                  ),
                ),
                child: Icon(_iconForEntry(), size: 17, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.permissionsOctal != null
                          ? '${entry.formattedSize} • ${entry.permissionsOctal}'
                          : entry.formattedSize,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 10.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              if (!entry.isDirectory) ...[
                // Edit in Fullscreen Terminal (nano / fallback editor)
                Semantics(
                  button: true,
                  label: 'Edit ${entry.name} in fullscreen terminal',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: tokens.greenAccent.withValues(alpha: 0.40),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 14,
                            color: tokens.greenTextAccent,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: tokens.greenTextAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Download File
                Semantics(
                  button: true,
                  label: 'Download ${entry.name}',
                  child: Tooltip(
                    message: 'Download ${entry.name}',
                    child: InkWell(
                      onTap: onDownload,
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: tokens.blueAccent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: tokens.blueAccent.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.download_rounded,
                          size: 15,
                          color: tokens.blueAccent,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              // Delete Entry
              Semantics(
                button: true,
                label: 'Delete ${entry.name}',
                child: Tooltip(
                  message: 'Delete ${entry.name}',
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(9),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
