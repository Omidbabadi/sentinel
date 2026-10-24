import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentinel/core/common/application/riverpod/current_theme_controller.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/enums/ssh_auth_type.dart';
import 'package:sentinel/core/handler/host_key_prompts_handler.dart';
import 'package:sentinel/core/res/style/colors.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/security/credential_store.dart';
import 'package:sentinel/core/services/injection_container.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/utils/core_utils.dart';
import 'package:sentinel/core/widgets/back_button.dart';
import 'package:sentinel/core/widgets/sentinel_botton.dart';
import 'package:sentinel/core/widgets/sentinel_form_section_card.dart';
import 'package:sentinel/core/widgets/sentinel_glass_field.dart';
import 'package:sentinel/core/widgets/sentinel_primary_button.dart';
import 'package:sentinel/src/groups/presention/app/adapter/groups_adapter.dart';
import 'package:sentinel/src/groups/presention/widgets/group_style_helpers.dart';
import 'package:sentinel/src/hosts/data/model/host_model.dart';
import 'package:sentinel/src/hosts/presention/app/adapter/hosts_adapter.dart';

class EditHostView extends ConsumerStatefulWidget {
  const EditHostView({super.key, this.host});

  static const addPath = '/home/hosts/add';
  static String editPath(Host host) =>
      '/home/host/edit/${host.id}/${Uri.encodeComponent(host.ip)}';

  final Host? host;

  bool get isEditing => host != null;

  @override
  ConsumerState<EditHostView> createState() => _EditHostViewState();
}

enum _PrivateKeyInputMode { pastePem, filePath }

class _EditHostViewState extends ConsumerState<EditHostView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hostnameController;
  late final TextEditingController _ipController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _groupNameController;
  late final TextEditingController _secretController;
  final TextEditingController _keyPathController = TextEditingController();
  late final TextEditingController _passphraseController;

  late final ValueNotifier<SshAuthType> _selectedAuthType;
  final ValueNotifier<_PrivateKeyInputMode> _privateKeyMode = ValueNotifier(
    _PrivateKeyInputMode.pastePem,
  );
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);
  final ValueNotifier<bool> _obscureSecret = ValueNotifier(true);
  final ValueNotifier<bool> _obscurePassphrase = ValueNotifier(true);

  List<ChangeNotifier> get _disposables => [
    _hostnameController,
    _ipController,
    _portController,
    _usernameController,
    _groupNameController,
    _secretController,
    _keyPathController,
    _passphraseController,
    _selectedAuthType,
    _privateKeyMode,
    _isSubmitting,
    _obscureSecret,
    _obscurePassphrase,
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.host;

    _hostnameController = TextEditingController(text: initial?.hostname ?? '');
    _ipController = TextEditingController(text: initial?.ip ?? '');
    _portController = TextEditingController(
      text: (initial?.port ?? 22).toString(),
    );
    _usernameController = TextEditingController(
      text: initial?.username ?? 'root',
    );
    _groupNameController = TextEditingController(
      text: initial?.groupName ?? '',
    );
    _secretController = TextEditingController();
    _passphraseController = TextEditingController();

    _selectedAuthType = ValueNotifier(
      initial?.authType ?? SshAuthType.password,
    );

    if (initial?.id != null && initial?.authType == SshAuthType.privateKey) {
      _loadSavedPrivateKeyMetadata(initial!.id!);
    }
  }

  Future<void> _loadSavedPrivateKeyMetadata(int hostId) async {
    try {
      final savedSecret = await sl<CredentialStore>().readSecret(hostId);
      if (!mounted || savedSecret == null || savedSecret.trim().isEmpty) return;
      final trimmed = savedSecret.trim();
      if (!trimmed.startsWith('-----BEGIN')) {
        _keyPathController.text = trimmed;
        _privateKeyMode.value = _PrivateKeyInputMode.filePath;
      }
    } catch (_) {}
  }

  String _expandTildePath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.startsWith('file://')) {
      return Uri.tryParse(trimmed)?.toFilePath() ?? trimmed;
    }
    if (trimmed == '~' || trimmed.startsWith('~/')) {
      final home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null && home.isNotEmpty) {
        return trimmed == '~' ? home : '$home${trimmed.substring(1)}';
      }
    }
    return trimmed;
  }

  Future<void> _verifyOrImportKeyPath({required bool importIntoPem}) async {
    final rawPath = _keyPathController.text.trim();
    if (rawPath.isEmpty) {
      CoreUtils.showSnackBar('Enter a private key file path first', isError: true);
      return;
    }

    final resolved = _expandTildePath(rawPath);
    final file = File(resolved);
    if (!await file.exists()) {
      CoreUtils.showSnackBar(
        'File not found at: $resolved',
        isError: true,
      );
      return;
    }

    try {
      final content = (await file.readAsString()).trim();
      if (content.isEmpty) {
        CoreUtils.showSnackBar('Key file is empty: $resolved', isError: true);
        return;
      }
      if (importIntoPem) {
        _secretController.text = content;
        _privateKeyMode.value = _PrivateKeyInputMode.pastePem;
        CoreUtils.showSnackBar('Private key loaded into PEM editor');
      } else {
        CoreUtils.showSnackBar('Verified readable key file at $resolved');
      }
    } catch (e) {
      CoreUtils.showSnackBar('Cannot read key file: $e', isError: true);
    }
  }

  Future<void> _pickKeyFileFromManager({bool importDirectlyToPem = false}) async {
    try {
      final pickedFile = await FilePicker.pickFile(
        dialogTitle: 'Select SSH Private Key',
        type: FileType.any,
      );
      if (pickedFile == null || !mounted) return;

      final selectedPath = pickedFile.path;
      String? fileContent;
      try {
        fileContent = (await pickedFile.xFile.readAsString()).trim();
      } catch (_) {
        if (selectedPath != null) {
          final f = File(selectedPath);
          if (await f.exists()) {
            fileContent = (await f.readAsString()).trim();
          }
        }
      }

      if (fileContent != null && fileContent.isEmpty) {
        CoreUtils.showSnackBar(
          'Selected file "${pickedFile.name}" is empty',
          isError: true,
        );
        return;
      }

      if (importDirectlyToPem || selectedPath == null || selectedPath.isEmpty) {
        if (fileContent != null && fileContent.isNotEmpty) {
          _secretController.text = fileContent;
          _privateKeyMode.value = _PrivateKeyInputMode.pastePem;
          CoreUtils.showSnackBar('Imported key "${pickedFile.name}"');
        }
        return;
      }

      _keyPathController.text = selectedPath;
      if (fileContent != null && fileContent.isNotEmpty) {
        _secretController.text = fileContent;
      }
      CoreUtils.showSnackBar('Selected key file: ${pickedFile.name}');
    } catch (e) {
      CoreUtils.showSnackBar('Failed to open file manager: $e', isError: true);
    }
  }

  @override
  void dispose() {
    for (final disposable in _disposables) {
      disposable.dispose();
    }
    super.dispose();
  }

  void _closeScreen() {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(SentinelRoutes.hosts);
    }
  }

  Future<void> _saveHost() async {
    if (!_formKey.currentState!.validate()) return;

    _isSubmitting.value = true;

    try {
      final now = DateTime.now();
      final existing = widget.host;
      final isKeyPathMode =
          _selectedAuthType.value == SshAuthType.privateKey &&
          _privateKeyMode.value == _PrivateKeyInputMode.filePath;
      final rawSecret = isKeyPathMode
          ? _keyPathController.text
          : _secretController.text;
      final secret = CoreUtils.nullIfEmpty(rawSecret);
      final passphrase = CoreUtils.nullIfEmpty(_passphraseController.text);

      final hostModel = HostModel(
        id: existing?.id,
        hostname: _hostnameController.text.trim(),
        ip: _ipController.text.trim(),
        port: int.tryParse(_portController.text.trim()) ?? 22,
        username: _usernameController.text.trim(),
        authType: _selectedAuthType.value,
        groupName: CoreUtils.nullIfEmpty(_groupNameController.text),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      final notifier = ref.read(hostsAdapterProvider.notifier);

      if (widget.isEditing) {
        await notifier.updateHost(
          host: hostModel,
          secret: secret,
          passphrase: passphrase,
        );
      } else {
        await notifier.addHost(
          host: hostModel,
          secret: secret ?? '',
          passphrase: passphrase,
        );
      }

      await ref
          .read(groupsAdapterProvider.notifier)
          .getGroupsFromLocalBase();

      if (mounted) {
        CoreUtils.showSnackBar(
          widget.isEditing
              ? 'Host updated successfully'
              : 'Host added successfully',
        );
        _closeScreen();
      }
    } catch (e) {
      CoreUtils.showSnackBar('Failed to save host: $e', isError: true);
    } finally {
      if (mounted) _isSubmitting.value = false;
    }
  }

  Future<void> _confirmDelete() async {
    final host = widget.host;
    if (host?.id == null) return;

    final confirmed = await PromptsHandlerImpl().confirmDeletion(host: host!);

    if (confirmed != true || !mounted) return;

    _isSubmitting.value = true;
    try {
      await ref.read(hostsAdapterProvider.notifier).deleteHost(host.id!);
      if (mounted) {
        CoreUtils.showSnackBar('Host deleted successfully');
        _closeScreen();
      }
    } catch (e) {
      CoreUtils.showSnackBar('Failed to delete host: $e', isError: true);
    } finally {
      if (mounted) _isSubmitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(currentThemeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final tokens = SentinelThemeTokens(isDark);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(tokens, isDark),
            const SizedBox(height: 20),

            // 1. General Identity Section
            SentinelFormSectionCard(
              tokens: tokens,
              icon: Icons.dns_outlined,
              title: 'General Identity',
              subtitle: 'Server label and optional group assignment',
              children: [
                SentinelGlassField(
                  controller: _hostnameController,
                  tokens: tokens,
                  isDark: isDark,
                  label: 'Host Label / Alias',
                  hint: 'e.g. Production Ubuntu',
                  prefixIcon: Icons.label_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Host label is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                SentinelGlassField(
                  controller: _groupNameController,
                  tokens: tokens,
                  isDark: isDark,
                  label: 'Group Name (Optional)',
                  hint: 'e.g. EU-West Cluster, Staging',
                  prefixIcon: Icons.folder_open_rounded,
                  textInputAction: TextInputAction.next,
                ),
                _buildSavedGroupsQuickChips(tokens, isDark),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Network Endpoint Section
            SentinelFormSectionCard(
              tokens: tokens,
              icon: Icons.lan_outlined,
              title: 'SSH Endpoint',
              subtitle: 'IPv4 / IPv6 address, domain, and SSH port',
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: SentinelGlassField(
                        controller: _ipController,
                        tokens: tokens,
                        isDark: isDark,
                        label: 'IP Address / Host',
                        hint: '192.168.1.100',
                        prefixIcon: Icons.language_rounded,
                        isMonospace: true,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'IP or domain is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: SentinelGlassField(
                        controller: _portController,
                        tokens: tokens,
                        isDark: isDark,
                        label: 'Port',
                        hint: '22',
                        isMonospace: true,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        validator: (val) {
                          final port = int.tryParse(val?.trim() ?? '');
                          if (port == null || port < 1 || port > 65535) {
                            return '1-65535';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Authentication & Credentials Section
            ValueListenableBuilder<SshAuthType>(
              valueListenable: _selectedAuthType,
              builder: (_, authType, _) {
                final isPassword = authType == SshAuthType.password;
                return SentinelFormSectionCard(
                  tokens: tokens,
                  icon: Icons.shield_outlined,
                  title: 'Authentication',
                  subtitle: 'Encrypted in hardware-backed secure storage',
                  children: [
                    SentinelGlassField(
                      controller: _usernameController,
                      tokens: tokens,
                      isDark: isDark,
                      label: 'Username',
                      hint: 'root',
                      prefixIcon: Icons.person_outline_rounded,
                      isMonospace: true,
                      textInputAction: TextInputAction.next,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Username is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Authentication Method',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AuthTypeSegmentedControl(
                      selected: authType,
                      tokens: tokens,
                      isDark: isDark,
                      onChanged: (next) => _selectedAuthType.value = next,
                    ),
                    const SizedBox(height: 16),
                    if (isPassword)
                      ValueListenableBuilder<bool>(
                        valueListenable: _obscureSecret,
                        builder: (_, obscure, _) => SentinelGlassField(
                          controller: _secretController,
                          tokens: tokens,
                          isDark: isDark,
                          label: widget.isEditing
                              ? 'New Password (leave blank to keep existing)'
                              : 'SSH Password',
                          hint: widget.isEditing
                              ? '••••••••••••'
                              : 'Enter server password',
                          prefixIcon: Icons.key_rounded,
                          obscureText: obscure,
                          suffixIcon: IconButton(
                            tooltip: obscure
                                ? 'Show password'
                                : 'Hide password',
                            splashRadius: 18,
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 17,
                              color: tokens.textSecondary,
                            ),
                            onPressed: () =>
                                _obscureSecret.value = !_obscureSecret.value,
                          ),
                          validator: (val) {
                            if (!widget.isEditing &&
                                (val == null || val.isEmpty)) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                      )
                    else ...[
                      ValueListenableBuilder<_PrivateKeyInputMode>(
                        valueListenable: _privateKeyMode,
                        builder: (_, keyMode, _) {
                          final isFilePath =
                              keyMode == _PrivateKeyInputMode.filePath;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Private Key Source',
                                style: TextStyle(
                                  color: tokens.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _PrivateKeySourceControl(
                                selected: keyMode,
                                tokens: tokens,
                                isDark: isDark,
                                onChanged: (next) =>
                                    _privateKeyMode.value = next,
                              ),
                              const SizedBox(height: 14),
                              if (!isFilePath)
                                SentinelGlassField(
                                  controller: _secretController,
                                  tokens: tokens,
                                  isDark: isDark,
                                  label: widget.isEditing
                                      ? 'Private Key PEM (leave blank to keep existing)'
                                      : 'Private Key (PEM / OpenSSH)',
                                  hint: '-----BEGIN OPENSSH PRIVATE KEY-----',
                                  prefixIcon: Icons.vpn_key_outlined,
                                  isMonospace: true,
                                  maxLines: 4,
                                  validator: (val) {
                                    if (!widget.isEditing &&
                                        (val == null || val.trim().isEmpty)) {
                                      return 'Private key PEM is required';
                                    }
                                    return null;
                                  },
                                )
                              else ...[
                                SentinelGlassField(
                                  controller: _keyPathController,
                                  tokens: tokens,
                                  isDark: isDark,
                                  label: widget.isEditing
                                      ? 'Private Key File Path (leave blank to keep existing)'
                                      : 'Private Key File Path',
                                  hint: '~/.ssh/id_ed25519 or /path/to/id_rsa',
                                  prefixIcon: Icons.folder_shared_outlined,
                                  isMonospace: true,
                                  textInputAction: TextInputAction.next,
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Browse file manager',
                                        splashRadius: 18,
                                        icon: Icon(
                                          Icons.folder_open_rounded,
                                          size: 18,
                                          color: tokens.greenTextAccent,
                                        ),
                                        onPressed: _pickKeyFileFromManager,
                                      ),
                                      IconButton(
                                        tooltip: 'Verify key file on disk',
                                        splashRadius: 18,
                                        icon: Icon(
                                          Icons.fact_check_outlined,
                                          size: 17,
                                          color: tokens.textSecondary,
                                        ),
                                        onPressed: () => _verifyOrImportKeyPath(
                                          importIntoPem: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                  validator: (val) {
                                    if (!widget.isEditing &&
                                        (val == null || val.trim().isEmpty)) {
                                      return 'Private key file path is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                SentinelButton(
                                  tokens: tokens,
                                  isDark: isDark,
                                  width: double.infinity,
                                  height: 40,
                                  borderRadius: 12,
                                  isHighlighted: true,
                                  accentColor: tokens.greenAccent,
                                  semanticLabel:
                                      'Open file manager to select SSH private key',
                                  onTap: _pickKeyFileFromManager,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.folder_open_rounded,
                                        size: 16,
                                        color: tokens.greenTextAccent,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Choose Key from File Manager',
                                        style: TextStyle(
                                          color: tokens.textPrimary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildKeyPathPresetsAndActions(tokens, isDark),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      ValueListenableBuilder<bool>(
                        valueListenable: _obscurePassphrase,
                        builder: (_, obscure, _) => SentinelGlassField(
                          controller: _passphraseController,
                          tokens: tokens,
                          isDark: isDark,
                          label: 'Key Passphrase (Optional)',
                          hint: 'Leave empty if unencrypted',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: obscure,
                          suffixIcon: IconButton(
                            tooltip: obscure
                                ? 'Show passphrase'
                                : 'Hide passphrase',
                            splashRadius: 18,
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 17,
                              color: tokens.textSecondary,
                            ),
                            onPressed: () => _obscurePassphrase.value =
                                !_obscurePassphrase.value,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 22),

            // 4. Primary Action Button
            ValueListenableBuilder<bool>(
              valueListenable: _isSubmitting,
              builder: (_, isSubmitting, _) => SentinelPrimaryButton(
                tokens: tokens,
                isFullWidth: true,
                height: 50,
                isLoading: isSubmitting,
                icon: widget.isEditing
                    ? Icons.check_circle_outline_rounded
                    : Icons.add_circle_outline_rounded,
                label: widget.isEditing
                    ? 'Save Host Changes'
                    : 'Create SSH Host',
                onPressed: _saveHost,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyPathPresetsAndActions(
    SentinelThemeTokens tokens,
    bool isDark,
  ) {
    const presets = [
      '~/.ssh/id_ed25519',
      '~/.ssh/id_rsa',
      '~/.ssh/id_ecdsa',
    ];

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _keyPathController,
      builder: (context, value, _) {
        final currentPath = value.text.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final preset in presets)
                  Builder(
                    builder: (context) {
                      final isSelected = currentPath == preset;
                      return Semantics(
                        button: true,
                        selected: isSelected,
                        label: 'Use key path $preset',
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => _keyPathController.text = preset,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? tokens.greenAccent.withValues(alpha: 0.16)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: isSelected
                                    ? tokens.greenAccent.withValues(alpha: 0.55)
                                    : tokens.cardBorder,
                              ),
                            ),
                            child: Text(
                              preset,
                              style: TextStyle(
                                color: isSelected
                                    ? tokens.greenTextAccent
                                    : tokens.textSecondary,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            if (currentPath.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Key file will be read from path on SSH connect',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SentinelButton(
                    tokens: tokens,
                    isDark: isDark,
                    width: null,
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    borderRadius: 9,
                    semanticLabel: 'Import key file contents into PEM editor',
                    tooltip: 'Load file contents into PEM editor',
                    onTap: () => _verifyOrImportKeyPath(importIntoPem: true),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.file_download_outlined,
                          size: 13.5,
                          color: tokens.greenTextAccent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Import PEM',
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSavedGroupsQuickChips(SentinelThemeTokens tokens, bool isDark) {
    final groupsState = ref.watch(groupsAdapterProvider);
    final groups = switch (groupsState) {
      GroupsLoaded(:final groups) => groups,
      _ => const [],
    };
    if (groups.isEmpty) return const SizedBox.shrink();

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _groupNameController,
      builder: (context, value, _) {
        final currentGroup = value.text.trim().toLowerCase();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final group in groups)
                Builder(
                  builder: (context) {
                    final isSelected =
                        group.name.trim().toLowerCase() == currentGroup;
                    final accentColor = GroupStyleHelpers.parseColor(
                      group.colorHex,
                    );
                    final icon = GroupStyleHelpers.resolveIcon(group.iconName);

                    return Semantics(
                      button: true,
                      selected: isSelected,
                      label: 'Assign group ${group.name}',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () {
                          _groupNameController.text = isSelected
                              ? ''
                              : group.name;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withValues(alpha: 0.18)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? accentColor.withValues(alpha: 0.65)
                                  : tokens.cardBorder,
                              width: isSelected ? 1.25 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 13.5,
                                color: isSelected
                                    ? accentColor
                                    : tokens.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                group.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? tokens.textPrimary
                                      : tokens.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(SentinelThemeTokens tokens, bool isDark) {
    return Row(
      children: [
        MyBackButton(onPop: () => context.pop()),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  widget.isEditing ? 'Edit Host' : 'New Host',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.isEditing
                    ? '${widget.host!.username}@${widget.host!.ip}:${widget.host!.port}'
                    : 'Configure SSH connection parameters',
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 11.5,
                  fontFamily: widget.isEditing ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
        if (widget.isEditing)
          ValueListenableBuilder<bool>(
            valueListenable: _isSubmitting,
            builder: (_, isSubmitting, _) => SentinelButton(
              tokens: tokens,
              isDark: isDark,
              width: 44,
              height: 44,
              borderRadius: 14,
              isHighlighted: true,
              accentColor: Pallet.criticalRose,
              semanticLabel: 'Delete host',
              tooltip: 'Delete host',
              onTap: isSubmitting ? null : _confirmDelete,
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Pallet.criticalRose,
              ),
            ),
          ),
      ],
    );
  }
}

class _AuthTypeSegmentedControl extends StatelessWidget {
  final SshAuthType selected;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final ValueChanged<SshAuthType> onChanged;

  const _AuthTypeSegmentedControl({
    required this.selected,
    required this.tokens,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.26)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegment(
              type: SshAuthType.password,
              icon: Icons.password_rounded,
              label: 'Password',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildSegment(
              type: SshAuthType.privateKey,
              icon: Icons.key_rounded,
              label: 'Private Key',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required SshAuthType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selected == type;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label authentication method',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(type),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.92))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: tokens.greenAccent.withValues(
                        alpha: isDark ? 0.45 : 0.35,
                      ),
                    )
                  : null,
              boxShadow: isSelected && !isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? tokens.greenTextAccent
                      : tokens.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? tokens.textPrimary
                        : tokens.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivateKeySourceControl extends StatelessWidget {
  final _PrivateKeyInputMode selected;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final ValueChanged<_PrivateKeyInputMode> onChanged;

  const _PrivateKeySourceControl({
    required this.selected,
    required this.tokens,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.26)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegment(
              mode: _PrivateKeyInputMode.pastePem,
              icon: Icons.paste_rounded,
              label: 'Paste Key (PEM)',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildSegment(
              mode: _PrivateKeyInputMode.filePath,
              icon: Icons.folder_open_rounded,
              label: 'Key File Path',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required _PrivateKeyInputMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selected == mode;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(mode),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.92))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: tokens.greenAccent.withValues(
                        alpha: isDark ? 0.45 : 0.35,
                      ),
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? tokens.greenTextAccent
                      : tokens.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? tokens.textPrimary
                        : tokens.textSecondary,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
