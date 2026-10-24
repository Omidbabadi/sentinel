import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sentinel/core/enums/host_menu_items.dart';
import 'package:sentinel/core/res/style/colors.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/src/hosts/presention/widgets/glass_menu_item.dart';

class GlassDropdownRoute extends PopupRoute<HostMenuAction> {
  final Offset position;
  final double width;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final bool openUpwards;
  final bool isConnected;

  GlassDropdownRoute({
    required this.position,
    required this.width,
    required this.tokens,
    required this.isDark,
    required this.openUpwards,
    this.isConnected = false,
  });

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss host menu';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: position.dx,
            top: position.dy,
            width: width,
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
                alignment: openUpwards
                    ? Alignment.bottomRight
                    : Alignment.topRight,
                child: Semantics(
                  scopesRoute: true,
                  namesRoute: true,
                  label: 'Host actions menu',
                  explicitChildNodes: true,
                  child: FocusScope(
                    autofocus: true,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C2027).withValues(alpha: 0.88)
                                : Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: tokens.cardBorder,
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.45 : 0.12,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: isConnected
                                ? [
                                    GlassMenuItem(
                                      autofocus: true,
                                      icon: Icons.terminal_rounded,
                                      label: 'Open Terminal',
                                      color: tokens.textPrimary,
                                      iconColor: tokens.greenAccent,
                                      hoverColor: tokens.greenAccent.withValues(
                                        alpha: 0.12,
                                      ),
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pop(HostMenuAction.openNewTerminal),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      child: Divider(
                                        height: 1,
                                        thickness: 0.7,
                                        color: tokens.dividerColor,
                                      ),
                                    ),
                                    GlassMenuItem(
                                      icon: Icons.folder_open_rounded,
                                      label: 'Open SFTP',
                                      color: tokens.textPrimary,
                                      iconColor: tokens.blueAccent,
                                      hoverColor: tokens.blueAccent.withValues(
                                        alpha: 0.12,
                                      ),
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pop(HostMenuAction.openSftp),
                                    ),
                                  ]
                                : [
                                    GlassMenuItem(
                                      autofocus: true,
                                      icon: Icons.folder_open_rounded,
                                      label: 'Open SFTP',
                                      color: tokens.textPrimary,
                                      iconColor: tokens.blueAccent,
                                      hoverColor: tokens.blueAccent.withValues(
                                        alpha: 0.12,
                                      ),
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pop(HostMenuAction.openSftp),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      child: Divider(
                                        height: 1,
                                        thickness: 0.7,
                                        color: tokens.dividerColor,
                                      ),
                                    ),
                                    GlassMenuItem(
                                      icon: Icons.edit_outlined,
                                      label: 'Edit Host',
                                      color: tokens.textPrimary,
                                      iconColor: tokens.greenAccent,
                                      hoverColor: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.05),
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pop(HostMenuAction.edit),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      child: Divider(
                                        height: 1,
                                        thickness: 0.7,
                                        color: tokens.dividerColor,
                                      ),
                                    ),
                                    GlassMenuItem(
                                      icon: Icons.delete_outline_rounded,
                                      label: 'Delete Host',
                                      color: tokens.redTextAccent,
                                      iconColor: Pallet.criticalRose,
                                      hoverColor: Pallet.criticalRose.withValues(
                                        alpha: 0.12,
                                      ),
                                      onTap: () => Navigator.of(
                                        context,
                                      ).pop(HostMenuAction.delete),
                                    ),
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
