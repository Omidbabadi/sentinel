import 'package:flutter/foundation.dart';

class TerminalModifierState {
  const TerminalModifierState({
    this.ctrl = false,
    this.alt = false,
  });

  final bool ctrl;
  final bool alt;

  bool get isActive => ctrl || alt;

  TerminalModifierState copyWith({bool? ctrl, bool? alt}) {
    return TerminalModifierState(
      ctrl: ctrl ?? this.ctrl,
      alt: alt ?? this.alt,
    );
  }
}

/// Manages one-shot / sticky `Ctrl` and `Alt` modifier keys for soft keyboards,
/// allowing the user to tap `ctrl` and then type any character (e.g. `x`, `o`,
/// `w`, `k`, `c`, `[`, `\`, `_`) to send `Ctrl+<key>` or `Alt+<key>`.
class TerminalModifierController {
  TerminalModifierController._();

  static final ValueNotifier<TerminalModifierState> notifier =
      ValueNotifier<TerminalModifierState>(const TerminalModifierState());

  static TerminalModifierState get state => notifier.value;

  static void toggleCtrl() {
    notifier.value = notifier.value.copyWith(ctrl: !notifier.value.ctrl);
  }

  static void toggleAlt() {
    notifier.value = notifier.value.copyWith(alt: !notifier.value.alt);
  }

  static void reset() {
    if (notifier.value.isActive) {
      notifier.value = const TerminalModifierState();
    }
  }

  /// Transforms outgoing terminal [data] if `Ctrl` or `Alt` modifier is active,
  /// and automatically clears the one-shot modifier after applying it.
  static String applyAndConsume(String data) {
    final current = notifier.value;
    if (!current.isActive || data.isEmpty) {
      return data;
    }

    reset();
    return transformWithModifiers(
      data,
      ctrl: current.ctrl,
      alt: current.alt,
    );
  }

  /// Pure helper to transform [data] with [ctrl] and/or [alt] modifiers.
  static String transformWithModifiers(
    String data, {
    required bool ctrl,
    required bool alt,
  }) {
    if (data.isEmpty || (!ctrl && !alt)) return data;

    // Only transform single printable characters (not multi-byte escape sequences)
    if (data.length == 1) {
      final code = data.codeUnitAt(0);
      String result = data;

      if (ctrl) {
        final ctrlCode = controlCharCodeFor(code);
        if (ctrlCode != null) {
          result = String.fromCharCode(ctrlCode);
        }
      }

      if (alt) {
        result = '\x1b$result';
      }

      return result;
    }

    return data;
  }

  /// Maps an ASCII character code to its control character code (`0x00`..`0x1F` or `0x7F`).
  static int? controlCharCodeFor(int charCode) {
    // 'a'..'z' (97..122) -> 1..26 (Ctrl+A .. Ctrl+Z)
    if (charCode >= 97 && charCode <= 122) {
      return charCode - 97 + 1;
    }
    // 'A'..'Z' (65..90) -> 1..26 (Ctrl+A .. Ctrl+Z)
    if (charCode >= 65 && charCode <= 90) {
      return charCode - 65 + 1;
    }
    // Space (32), '@' (64), '`' (96), '2' (50) -> NUL (0)
    if (charCode == 32 || charCode == 64 || charCode == 96 || charCode == 50) {
      return 0;
    }
    // '[' (91) or '3' (51) -> ESC (27)
    if (charCode == 91 || charCode == 51) {
      return 27;
    }
    // '\' (92) or '4' (52) -> FS (28)
    if (charCode == 92 || charCode == 52) {
      return 28;
    }
    // ']' (93) or '5' (53) -> GS (29)
    if (charCode == 93 || charCode == 53) {
      return 29;
    }
    // '^' (94) or '6' (54) -> RS (30)
    if (charCode == 94 || charCode == 54) {
      return 30;
    }
    // '_' (95), '/' (47), or '7' (55) -> US (31)
    if (charCode == 95 || charCode == 47 || charCode == 55) {
      return 31;
    }
    // '?' (63) or '8' (56) -> DEL (127)
    if (charCode == 63 || charCode == 56) {
      return 127;
    }
    return null;
  }
}
