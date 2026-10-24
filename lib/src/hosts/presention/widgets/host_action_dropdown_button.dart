import 'package:flutter/material.dart';

import '../../../../core/enums/host_menu_items.dart';
import '../../../../core/res/style/theme_tokens.dart';
import '../../../../core/widgets/sentinel_botton.dart';
import 'glass_dropdown_route.dart';

class HostActionDropdownButton extends StatelessWidget {
  final SentinelThemeTokens tokens;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpenNewTerminal;
  final VoidCallback? onOpenSftp;
  final bool isConnected;

  const HostActionDropdownButton({
    super.key,
    required this.tokens,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.isConnected,
    this.onOpenNewTerminal,
    this.onOpenSftp,
  });

  Future<void> _showGlassDropdown(BuildContext context) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final buttonOffset = renderBox.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );
    final buttonSize = renderBox.size;
    final screenSize = overlay.size;

    final menuWidth = isConnected ? 182.0 : 164.0;
    final menuHeight = isConnected ? 96.0 : 140.0;

    double left = buttonOffset.dx + buttonSize.width - menuWidth;
    if (left < 12) left = 12;
    if (left + menuWidth > screenSize.width - 12) {
      left = screenSize.width - menuWidth - 12;
    }

    final openUpwards =
        (buttonOffset.dy + buttonSize.height + menuHeight + 90) >
        screenSize.height;
    final top = openUpwards
        ? buttonOffset.dy - menuHeight - 6
        : buttonOffset.dy + buttonSize.height + 6;

    final action = await Navigator.of(context).push<HostMenuAction>(
      GlassDropdownRoute(
        position: Offset(left, top),
        width: menuWidth,
        tokens: tokens,
        isDark: isDark,
        openUpwards: openUpwards,
        isConnected: isConnected,
      ),
    );

    switch (action) {
      case HostMenuAction.openNewTerminal:
        onOpenNewTerminal?.call();
      case HostMenuAction.openSftp:
        onOpenSftp?.call();
      case HostMenuAction.edit:
        onEdit();
      case HostMenuAction.delete:
        onDelete();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      child: Center(
        child: SentinelButton(
          isDark: isDark,
          tokens: tokens,
          height: 32,
          width: 32,
          semanticLabel: 'Host actions menu',
          tooltip: 'Host actions',
          onTap: () => _showGlassDropdown(context),
          child: Icon(
            Icons.more_vert_rounded,
            size: 16,
            color: isConnected ? tokens.greenTextAccent : tokens.textSecondary,
          ),
        ),
      ),
    );
  }
}
