import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/common/entities/server_group.dart';
import 'package:sentinel/core/enums/os_names.dart';
import 'package:sentinel/core/res/style/colors.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/utils/core_utils.dart';
import 'package:sentinel/core/widgets/distro_avatar.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/sentinel_botton.dart';
import 'package:sentinel/core/widgets/sentinel_glass_field.dart';
import 'package:sentinel/core/widgets/sentinel_primary_button.dart';
import 'package:sentinel/src/groups/data/model/server_group_model.dart';
import 'package:sentinel/src/groups/presention/app/adapter/groups_adapter.dart';
import 'package:sentinel/src/groups/presention/widgets/group_style_helpers.dart';
import 'package:sentinel/src/hosts/presention/app/adapter/hosts_adapter.dart';

class EditGroupSheet extends ConsumerStatefulWidget {
  const EditGroupSheet({
    super.key,
    required this.isDark,
    this.existingGroup,
  });

  final bool isDark;
  final ServerGroup? existingGroup;

  bool get isEditing => existingGroup != null;

  static Future<bool?> show(
    BuildContext context, {
    required bool isDark,
    ServerGroup? existingGroup,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => EditGroupSheet(
        isDark: isDark,
        existingGroup: existingGroup,
      ),
    );
  }

  @override
  ConsumerState<EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends ConsumerState<EditGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  late String _selectedColorHex;
  late String _selectedIconName;
  late final Set<int> _selectedHostIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingGroup;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _selectedColorHex = existing?.colorHex ?? '#10B981';
    _selectedIconName = existing?.iconName ?? 'folder';

    _selectedHostIds = <int>{};
    final hostsState = ref.read(hostsAdapterProvider);
    if (hostsState is HostsLoaded && existing != null) {
      for (final host in hostsState.hosts) {
        if (host.id != null &&
            host.groupName?.trim().toLowerCase() ==
                existing.name.trim().toLowerCase()) {
          _selectedHostIds.add(host.id!);
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(groupsAdapterProvider) is GroupsInitial) {
        ref.read(groupsAdapterProvider.notifier).getGroupsFromLocalBase();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final existing = widget.existingGroup;
      final groupModel = ServerGroupModel(
        id: existing?.id,
        name: _nameController.text.trim(),
        description: CoreUtils.nullIfEmpty(_descriptionController.text),
        colorHex: _selectedColorHex,
        iconName: _selectedIconName,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      final notifier = ref.read(groupsAdapterProvider.notifier);
      final bool ok;
      if (widget.isEditing) {
        ok = await notifier.updateGroup(
          group: groupModel,
          previousName: existing!.name,
          assignedHostIds: _selectedHostIds.toList(),
        );
      } else {
        ok = await notifier.addGroup(
          group: groupModel,
          assignedHostIds: _selectedHostIds.toList(),
        );
      }

      if (!mounted) return;
      if (ok) {
        CoreUtils.showSnackBar(
          widget.isEditing
              ? 'Group "${groupModel.name}" updated'
              : 'Group "${groupModel.name}" created',
        );
        Navigator.of(context).pop(true);
      } else {
        CoreUtils.showSnackBar('Failed to save server group', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteGroup() async {
    final existing = widget.existingGroup;
    if (existing?.id == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final ok = await ref
          .read(groupsAdapterProvider.notifier)
          .deleteGroup(id: existing!.id!, groupName: existing.name);
      if (!mounted) return;
      if (ok) {
        CoreUtils.showSnackBar('Group "${existing.name}" deleted');
        Navigator.of(context).pop(true);
      } else {
        CoreUtils.showSnackBar('Failed to delete group', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SentinelThemeTokens(widget.isDark);
    final hostsState = ref.watch(hostsAdapterProvider);
    final groupsState = ref.watch(groupsAdapterProvider);

    final allHosts = switch (hostsState) {
      HostsLoaded(:final hosts) => hosts,
      _ => const <Host>[],
    };
    final existingGroups = switch (groupsState) {
      GroupsLoaded(:final groups) => groups,
      _ => const <ServerGroup>[],
    };

    final accentColor = GroupStyleHelpers.parseColor(_selectedColorHex);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.86;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: bottomInset + 12,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight, maxWidth: 460),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                color: widget.isDark
                    ? const Color(0xFF101923).withValues(alpha: 0.90)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: tokens.cardBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: widget.isDark ? 0.55 : 0.14,
                    ),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: tokens.textSecondary.withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.40),
                              ),
                            ),
                            child: Icon(
                              GroupStyleHelpers.resolveIcon(_selectedIconName),
                              size: 20,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    widget.isEditing
                                        ? 'Edit Server Group'
                                        : 'New Server Group',
                                    style: TextStyle(
                                      color: tokens.textPrimary,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.isEditing
                                      ? 'Update group metadata & host membership'
                                      : 'Organize SSH hosts into logical clusters',
                                  style: TextStyle(
                                    color: tokens.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.isEditing) ...[
                            SentinelButton(
                              tokens: tokens,
                              isDark: widget.isDark,
                              width: 38,
                              height: 38,
                              borderRadius: 12,
                              isHighlighted: true,
                              accentColor: Pallet.criticalRose,
                              semanticLabel: 'Delete group',
                              tooltip: 'Delete group',
                              onTap: _isSaving ? null : _deleteGroup,
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 17,
                                color: Pallet.criticalRose,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          SentinelButton(
                            tokens: tokens,
                            isDark: widget.isDark,
                            width: 38,
                            height: 38,
                            borderRadius: 12,
                            semanticLabel: 'Close sheet',
                            tooltip: 'Close',
                            onTap: () => Navigator.of(context).pop(),
                            child: Icon(
                              Icons.close_rounded,
                              size: 17,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: tokens.dividerColor),

                    // Scrollable form body
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SentinelGlassField(
                              controller: _nameController,
                              tokens: tokens,
                              isDark: widget.isDark,
                              label: 'Group Name',
                              hint: 'e.g. Production Cluster, EU-Central',
                              prefixIcon: Icons.folder_open_rounded,
                              textInputAction: TextInputAction.next,
                              validator: (val) {
                                final trimmed = val?.trim() ?? '';
                                if (trimmed.isEmpty) {
                                  return 'Group name is required';
                                }
                                final duplicate = existingGroups.any(
                                  (g) =>
                                      g.id != widget.existingGroup?.id &&
                                      g.name.trim().toLowerCase() ==
                                          trimmed.toLowerCase(),
                                );
                                if (duplicate) {
                                  return 'A group with this name already exists';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            SentinelGlassField(
                              controller: _descriptionController,
                              tokens: tokens,
                              isDark: widget.isDark,
                              label: 'Description / Region (Optional)',
                              hint: 'e.g. Primary Frankfurt k8s nodes',
                              prefixIcon: Icons.notes_rounded,
                              textInputAction: TextInputAction.done,
                            ),
                            const SizedBox(height: 16),

                            // Color Picker
                            Text(
                              'Accent Color',
                              style: TextStyle(
                                color: tokens.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final option
                                    in GroupStyleHelpers.colorOptions)
                                  _buildColorChip(option, tokens),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Icon Picker
                            Text(
                              'Cluster Icon',
                              style: TextStyle(
                                color: tokens.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final option
                                    in GroupStyleHelpers.iconOptions)
                                  _buildIconChip(option, accentColor, tokens),
                              ],
                            ),

                            if (allHosts.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Assign Hosts (${_selectedHostIds.length}/${allHosts.length})',
                                    style: TextStyle(
                                      color: tokens.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_selectedHostIds.isNotEmpty)
                                    GestureDetector(
                                      onTap: () => setState(
                                        _selectedHostIds.clear,
                                      ),
                                      child: Text(
                                        'Clear selection',
                                        style: TextStyle(
                                          color: tokens.greenTextAccent,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              GlassCard(
                                tokens: tokens,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                borderRadius: 16,
                                child: Column(
                                  children: [
                                    for (var i = 0;
                                        i < allHosts.length;
                                        i++) ...[
                                      _buildHostAssignmentTile(
                                        allHosts[i],
                                        accentColor,
                                        tokens,
                                      ),
                                      if (i < allHosts.length - 1)
                                        Divider(
                                          height: 1,
                                          indent: 14,
                                          endIndent: 14,
                                          color: tokens.dividerColor,
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),
                            SentinelPrimaryButton(
                              tokens: tokens,
                              isFullWidth: true,
                              height: 48,
                              isLoading: _isSaving,
                              icon: widget.isEditing
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.add_circle_outline_rounded,
                              label: widget.isEditing
                                  ? 'Save Group Changes'
                                  : 'Create Server Group',
                              onPressed: _saveGroup,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorChip(
    GroupColorOption option,
    SentinelThemeTokens tokens,
  ) {
    final isSelected =
        _selectedColorHex.toLowerCase() == option.hex.toLowerCase();

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${option.label} color',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => setState(() => _selectedColorHex = option.hex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? option.color.withValues(alpha: 0.18)
                : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isSelected
                  ? option.color.withValues(alpha: 0.65)
                  : tokens.cardBorder,
              width: isSelected ? 1.3 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: option.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                option.label,
                style: TextStyle(
                  color: isSelected ? tokens.textPrimary : tokens.textSecondary,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconChip(
    GroupIconOption option,
    Color accentColor,
    SentinelThemeTokens tokens,
  ) {
    final isSelected = _selectedIconName == option.name;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${option.label} icon',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => setState(() => _selectedIconName = option.name),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.16)
                : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.65)
                  : tokens.cardBorder,
              width: isSelected ? 1.3 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                option.icon,
                size: 15,
                color: isSelected ? accentColor : tokens.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                option.label,
                style: TextStyle(
                  color: isSelected ? tokens.textPrimary : tokens.textSecondary,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHostAssignmentTile(
    Host host,
    Color accentColor,
    SentinelThemeTokens tokens,
  ) {
    final hostId = host.id;
    final isSelected = hostId != null && _selectedHostIds.contains(hostId);
    final currentGroup = host.groupName?.trim();
    final hasOtherGroup =
        currentGroup != null &&
        currentGroup.isNotEmpty &&
        currentGroup.toLowerCase() !=
            (widget.existingGroup?.name.trim().toLowerCase() ?? '');

    return Semantics(
      button: true,
      checked: isSelected,
      label: 'Assign ${host.hostname} (${host.ip})',
      excludeSemantics: true,
      child: InkWell(
        onTap: hostId == null
            ? null
            : () {
                setState(() {
                  if (isSelected) {
                    _selectedHostIds.remove(hostId);
                  } else {
                    _selectedHostIds.add(hostId);
                  }
                });
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              DistroAvatar(
                distro: host.os?.osName ?? OsNames.unknown,
                tokens: tokens,
                size: 32,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      host.hostname,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${host.username}@${host.ip}:${host.port}${hasOtherGroup ? ' • Currently in $currentGroup' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 10.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: isSelected ? accentColor : tokens.textSecondary,
                    width: 1.4,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
