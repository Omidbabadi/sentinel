import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';

enum SentinelToastType { success, error, warning, info }

class SentinelToastController {
  SentinelToastController._();

  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;
  static GlobalKey<_SentinelToastOverlayState>? _activeKey;

  static void show({
    required OverlayState overlay,
    required String message,
    String? title,
    SentinelToastType type = SentinelToastType.success,
    Duration duration = const Duration(milliseconds: 3200),
    required bool isDark,
  }) {
    _dismissTimer?.cancel();
    _activeEntry?.remove();
    _activeEntry = null;

    final key = GlobalKey<_SentinelToastOverlayState>();
    _activeKey = key;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _SentinelToastOverlay(
        key: key,
        message: message,
        title: title,
        type: type,
        isDark: isDark,
        onDismissed: () {
          if (_activeEntry == entry) {
            entry.remove();
            _activeEntry = null;
            _activeKey = null;
          }
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_activeKey == key) {
        key.currentState?.dismiss();
      }
    });
  }
}

class _SentinelToastOverlay extends StatefulWidget {
  const _SentinelToastOverlay({
    super.key,
    required this.message,
    this.title,
    required this.type,
    required this.isDark,
    required this.onDismissed,
  });

  final String message;
  final String? title;
  final SentinelToastType type;
  final bool isDark;
  final VoidCallback onDismissed;

  @override
  State<_SentinelToastOverlay> createState() => _SentinelToastOverlayState();
}

class _SentinelToastOverlayState extends State<_SentinelToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _scale = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  Future<void> dismiss() async {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    await _controller.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = SentinelThemeTokens(widget.isDark);
    final topPadding = MediaQuery.paddingOf(context).top;

    final (accentColor, textAccentColor, icon, defaultTitle) = switch (
      widget.type
    ) {
      SentinelToastType.success => (
        tokens.greenAccent,
        tokens.greenTextAccent,
        Icons.check_circle_rounded,
        'Success',
      ),
      SentinelToastType.error => (
        tokens.redAccent,
        tokens.redTextAccent,
        Icons.error_outline_rounded,
        'Error',
      ),
      SentinelToastType.warning => (
        tokens.yellowAccent,
        tokens.yellowTextAccent,
        Icons.warning_amber_rounded,
        'Warning',
      ),
      SentinelToastType.info => (
        tokens.blueAccent,
        tokens.blueTextAccent,
        Icons.info_outline_rounded,
        'Notice',
      ),
    };

    final effectiveTitle = widget.title ?? defaultTitle;

    return Positioned(
      top: topPadding + 14,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(
              scale: _scale,
              child: FadeTransition(
                opacity: _opacity,
                child: Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.up,
                  onDismissed: (_) => widget.onDismissed(),
                  child: Material(
                    color: Colors.transparent,
                    child: Semantics(
                      container: true,
                      liveRegion: true,
                      label: '$effectiveTitle: ${widget.message}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  tokens.isDark
                                      ? const Color(0xEB1C1F26)
                                      : const Color(0xF5FFFFFF),
                                  tokens.isDark
                                      ? const Color(0xE014171D)
                                      : const Color(0xEBFAFBFD),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: accentColor.withValues(
                                  alpha: tokens.isDark ? 0.45 : 0.40,
                                ),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: tokens.isDark ? 0.45 : 0.10,
                                  ),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: accentColor.withValues(
                                    alpha: tokens.isDark ? 0.14 : 0.08,
                                  ),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accentColor.withValues(alpha: 0.16),
                                    border: Border.all(
                                      color: accentColor.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 0.8,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 18,
                                    color: accentColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        effectiveTitle,
                                        style: TextStyle(
                                          color: textAccentColor,
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.message,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: tokens.textPrimary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Semantics(
                                  button: true,
                                  label: 'Dismiss notification',
                                  child: InkWell(
                                    onTap: dismiss,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: tokens.textSecondary,
                                      ),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
