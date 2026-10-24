import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/application/riverpod/user_prefs.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/common/singelton/user_prefs.dart';
import 'package:sentinel/core/res/style/text.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/utils/core_utils.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/sentinel_state_view.dart';
import 'package:xterm2/core.dart';
import 'package:xterm2/ui.dart';

import '../presention/app/adapter/ssh_adapter.dart';
import 'terminal_theme.dart';

class TerminalSessionBody extends ConsumerStatefulWidget {
  final Host activeHost;
  final int activeHostId;
  final SshState sshState;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final VoidCallback onReconnect;
  final bool suppressSoftKeyboard;
  final VoidCallback? onTapTerminal;

  const TerminalSessionBody({
    super.key,
    required this.activeHost,
    required this.activeHostId,
    required this.sshState,
    required this.tokens,
    required this.isDark,
    required this.onReconnect,
    this.suppressSoftKeyboard = false,
    this.onTapTerminal,
  });

  @override
  ConsumerState<TerminalSessionBody> createState() =>
      _TerminalSessionBodyState();
}

class _TerminalSessionBodyState extends ConsumerState<TerminalSessionBody> {
  final GlobalKey<TerminalViewState> _terminalViewKey =
      GlobalKey<TerminalViewState>();
  final FocusNode _terminalFocusNode = FocusNode();
  final TerminalController _terminalController = TerminalController();

  final Map<int, Offset> _activePointers = <int, Offset>{};
  double? _initialPinchDistance;
  double? _baseFontSizeOnPinchStart;
  bool _gestureHadMultiTouch = false;
  bool _hadSelectionOnPointerDown = false;
  bool _keyboardEnabled = false;
  bool _wasKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _terminalController.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    // When user long-presses to select text, prevent soft keyboard from popping up
    if (_terminalController.selection != null && _keyboardEnabled && mounted) {
      setState(() => _keyboardEnabled = false);
      _terminalViewKey.currentState?.closeKeyboard();
    }
  }

  @override
  void didUpdateWidget(covariant TerminalSessionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suppressSoftKeyboard && !oldWidget.suppressSoftKeyboard) {
      _keyboardEnabled = false;
      _terminalViewKey.currentState?.closeKeyboard();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    } else if (!widget.suppressSoftKeyboard && oldWidget.suppressSoftKeyboard) {
      _keyboardEnabled = true;
      _openSoftKeyboard();
    }
    if (oldWidget.activeHostId != widget.activeHostId) {
      _terminalController.clearSelection();
    }
  }

  @override
  void dispose() {
    _terminalController.removeListener(_onSelectionChanged);
    _terminalController.dispose();
    _terminalFocusNode.dispose();
    super.dispose();
  }

  double _currentTwoFingerDistance() {
    final pts = _activePointers.values.toList(growable: false);
    if (pts.length < 2) return 0;
    return (pts[0] - pts[1]).distance;
  }

  void _onPointerDown(PointerDownEvent event, double currentFontSize) {
    if (_activePointers.isEmpty) {
      _hadSelectionOnPointerDown = _terminalController.selection != null;
    }
    _activePointers[event.pointer] = event.position;

    if (_activePointers.length >= 2) {
      final wasMultiTouch = _gestureHadMultiTouch;
      _gestureHadMultiTouch = true;
      final dist = _currentTwoFingerDistance();
      if (dist > 0) {
        _initialPinchDistance = dist;
        _baseFontSizeOnPinchStart = currentFontSize;
      }
      if (_keyboardEnabled || !wasMultiTouch) {
        setState(() => _keyboardEnabled = false);
      }
      _terminalViewKey.currentState?.closeKeyboard();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_activePointers.containsKey(event.pointer)) return;
    _activePointers[event.pointer] = event.position;

    if (_activePointers.length >= 2) {
      final initialDist = _initialPinchDistance;
      final baseSize = _baseFontSizeOnPinchStart;
      final currentDist = _currentTwoFingerDistance();
      if (initialDist != null &&
          initialDist > 12 &&
          baseSize != null &&
          currentDist > 0) {
        final scale = currentDist / initialDist;
        final targetSize = (baseSize * scale).clamp(
          UserPrefs.minFontSize,
          UserPrefs.maxFontSize,
        );
        ref.read(userPrefsProvider.notifier).setTerminalFontSize(targetSize);
      }
    }
  }

  void _onPointerUpOrCancel(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2) {
      _initialPinchDistance = null;
      _baseFontSizeOnPinchStart = null;
    }
    if (_activePointers.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _gestureHadMultiTouch) {
          setState(() => _gestureHadMultiTouch = false);
        }
        _hadSelectionOnPointerDown = false;
      });
    }
  }

  void _openSoftKeyboard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.suppressSoftKeyboard || _gestureHadMultiTouch) {
        return;
      }
      if (!_terminalFocusNode.hasFocus) {
        _terminalFocusNode.requestFocus();
        Future.microtask(() {
          if (mounted &&
              !widget.suppressSoftKeyboard &&
              !_gestureHadMultiTouch) {
            _terminalViewKey.currentState?.requestKeyboard();
            SystemChannels.textInput.invokeMethod('TextInput.show');
          }
        });
      } else {
        _terminalViewKey.currentState?.requestKeyboard();
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  void _handleSingleTapTerminal() {
    if (_gestureHadMultiTouch) return;

    // If text was selected when the tap started, let the tap just clear selection
    if (_hadSelectionOnPointerDown || _terminalController.selection != null) {
      _terminalController.clearSelection();
      return;
    }

    widget.onTapTerminal?.call();

    if (!_keyboardEnabled) {
      setState(() => _keyboardEnabled = true);
    }
    _openSoftKeyboard();
  }

  Future<void> _copySelection(Terminal terminal) async {
    final selection = _terminalController.selectionFor(terminal.buffer);
    if (selection == null) return;

    final text = terminal.buffer.getText(selection, true);
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    _terminalController.clearSelection();
    CoreUtils.showSnackBar('Copied to clipboard');
  }

  Future<void> _pasteClipboard(Terminal terminal) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      terminal.paste(text);
    }
    _terminalController.clearSelection();
  }

  void _selectAll(Terminal terminal) {
    _terminalController.setSelection(
      terminal.buffer.createAnchor(0, 0),
      terminal.buffer.createAnchor(
        terminal.viewWidth,
        terminal.buffer.height - 1,
      ),
      mode: SelectionMode.line,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 20;
    if (_wasKeyboardVisible && !isKeyboardVisible && _keyboardEnabled) {
      // User dismissed soft keyboard with system Back button; lock until next single tap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _keyboardEnabled) {
          setState(() => _keyboardEnabled = false);
        }
      });
    }
    _wasKeyboardVisible = isKeyboardVisible;

    final prefs = ref.watch(userPrefsProvider);
    final tokens = widget.tokens;
    final activeTerminalTheme = terminalPresetThemes(
      tokens,
      widget.isDark,
      themeId: prefs.terminalThemeId,
    );

    final shouldBlockSoftKeyboard =
        widget.suppressSoftKeyboard ||
        !_keyboardEnabled ||
        _gestureHadMultiTouch;

    return switch (widget.sshState) {
      SshInitial() || SshConnecting() => Semantics(
        container: true,
        liveRegion: true,
        label: 'Connecting to ${widget.activeHost.hostname}',
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: tokens.greenAccent,
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 14),
              Text(
                'Connecting to ${widget.activeHost.hostname}...',
                style: TextStyle(color: tokens.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      SshConnected(:final terminal) => Stack(
        children: [
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) => _onPointerDown(e, prefs.terminalFontSize),
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUpOrCancel,
            onPointerCancel: _onPointerUpOrCancel,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: TerminalView(
                terminal,
                key: _terminalViewKey,
                controller: _terminalController,
                focusNode: _terminalFocusNode,
                autofocus: false,
                hardwareKeyboardOnly: false,
                readOnly: shouldBlockSoftKeyboard,
                onTapUp: (_, _) => _handleSingleTapTerminal(),
                backgroundOpacity: 0.0,
                theme: activeTerminalTheme,
                textStyle: TerminalStyle.fromTextStyle(
                  TextStyles.paragraphRegular.copyWith(
                    fontSize: prefs.terminalFontSize,
                  ),
                ),
              ),
            ),
          ),

          // Floating Selection Action Bar (Copy / Paste / All / Clear)
          Positioned(
            top: 6,
            right: 6,
            child: ListenableBuilder(
              listenable: _terminalController,
              builder: (context, _) {
                final hasSelection =
                    _terminalController.selectionFor(terminal.buffer) != null;
                if (!hasSelection) return const SizedBox.shrink();

                return GlassCard(
                  tokens: tokens,
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SelectionActionChip(
                        icon: Icons.copy_rounded,
                        label: 'Copy',
                        color: tokens.greenTextAccent,
                        onTap: () => _copySelection(terminal),
                      ),
                      Container(
                        width: 1,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: tokens.dividerColor,
                      ),
                      _SelectionActionChip(
                        icon: Icons.content_paste_rounded,
                        label: 'Paste',
                        color: tokens.textPrimary,
                        onTap: () => _pasteClipboard(terminal),
                      ),
                      Container(
                        width: 1,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: tokens.dividerColor,
                      ),
                      _SelectionActionChip(
                        icon: Icons.select_all_rounded,
                        label: 'All',
                        color: tokens.textSecondary,
                        onTap: () => _selectAll(terminal),
                      ),
                      const SizedBox(width: 2),
                      InkWell(
                        onTap: _terminalController.clearSelection,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      SshError(:final message) => SentinelStateView(
        tokens: tokens,
        icon: Icons.error_outline_rounded,
        accentColor: tokens.redAccent,
        title: 'Connection Failed',
        subtitle: message,
        actionLabel: 'Try Again',
        actionIcon: Icons.refresh_rounded,
        onAction: widget.onReconnect,
        isLiveRegion: true,
      ),
      SshDisconnected(:final message) => SentinelStateView(
        tokens: tokens,
        icon: Icons.power_off_rounded,
        accentColor: tokens.textSecondary,
        title: 'Disconnected',
        subtitle: message ?? 'Session was terminated.',
        actionLabel: 'Reconnect',
        actionIcon: Icons.refresh_rounded,
        onAction: widget.onReconnect,
        isLiveRegion: true,
      ),
    };
  }
}

class _SelectionActionChip extends StatelessWidget {
  const _SelectionActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label terminal text',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13.5, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
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
