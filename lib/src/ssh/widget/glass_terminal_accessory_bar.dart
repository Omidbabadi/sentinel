import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:xterm2/core.dart';

import 'glass_shortcut_icon_key.dart';
import 'glass_shortcut_key.dart';
import 'terminal_modifier_controller.dart';

class GlassTerminalAccessoryBar extends StatelessWidget {
  final Terminal terminal;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final VoidCallback? onOpenAppearance;
  final VoidCallback? onOpenKeypadGrid;

  const GlassTerminalAccessoryBar({
    super.key,
    required this.terminal,
    required this.tokens,
    required this.isDark,
    this.onOpenAppearance,
    this.onOpenKeypadGrid,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TerminalModifierState>(
      valueListenable: TerminalModifierController.notifier,
      builder: (context, modState, _) {
        return GlassCard(
          tokens: tokens,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 34),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  if (onOpenAppearance != null) ...[
                    GlassShortcutIconKey(
                      icon: Icons.palette_outlined,
                      tokens: tokens,
                      accentColor: tokens.greenAccent,
                      semanticLabel: 'Terminal appearance settings',
                      onTap: onOpenAppearance!,
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (onOpenKeypadGrid != null) ...[
                    GlassShortcutIconKey(
                      icon: Icons.grid_view_rounded,
                      tokens: tokens,
                      accentColor: tokens.blueAccent,
                      semanticLabel: 'Extended keypad grid',
                      onTap: onOpenKeypadGrid!,
                    ),
                    const SizedBox(width: 6),
                  ],
                  GlassShortcutKey(
                    label: 'esc',
                    semanticLabel: 'Escape',
                    tokens: tokens,
                    isHighlighted: true,
                    onTap: () {
                      TerminalModifierController.reset();
                      terminal.keyInput(TerminalKey.escape);
                    },
                  ),
                  const SizedBox(width: 6),
                  GlassShortcutKey(
                    label: 'tab',
                    semanticLabel: 'Tab',
                    tokens: tokens,
                    onTap: () {
                      TerminalModifierController.reset();
                      terminal.keyInput(TerminalKey.tab);
                    },
                  ),
                  const SizedBox(width: 6),
                  GlassShortcutKey(
                    label: modState.ctrl ? 'ctrl •' : 'ctrl',
                    semanticLabel:
                        'Control modifier key. Tap then type any key on keyboard',
                    tokens: tokens,
                    isHighlighted: true,
                    isActive: modState.ctrl,
                    onTap: TerminalModifierController.toggleCtrl,
                  ),
                  const SizedBox(width: 6),
                  GlassShortcutKey(
                    label: modState.alt ? 'alt •' : 'alt',
                    semanticLabel:
                        'Alt modifier key. Tap then type any key on keyboard',
                    tokens: tokens,
                    isHighlighted: true,
                    isActive: modState.alt,
                    onTap: TerminalModifierController.toggleAlt,
                  ),
                  const SizedBox(width: 6),
                  GlassShortcutKey(
                    label: 'ctrl+x',
                    semanticLabel: 'Control X',
                    tokens: tokens,
                    isHighlighted: true,
                    onTap: () {
                      TerminalModifierController.reset();
                      terminal.charInput(0x78, ctrl: true);
                    },
                  ),
                  const SizedBox(width: 6),
                  GlassShortcutKey(
                    label: 'ctrl+o',
                    semanticLabel: 'Control O',
                    tokens: tokens,
                    isHighlighted: true,
                    onTap: () {
                      TerminalModifierController.reset();
                      terminal.charInput(0x6F, ctrl: true);
                    },
                  ),
                  const SizedBox(width: 6),
                  GlassShortcutKey(
                    label: 'ctrl+c',
                    semanticLabel: 'Control C',
                    tokens: tokens,
                    isHighlighted: true,
                    onTap: () {
                      TerminalModifierController.reset();
                      terminal.charInput(0x63, ctrl: true);
                    },
                  ),
                  const SizedBox(width: 6),
                  GlassShortcutKey(
                    label: '-',
                    semanticLabel: 'Minus',
                    tokens: tokens,
                    onTap: () => terminal.textInput('-'),
                  ),
                  const SizedBox(width: 6),
                  GlassShortcutKey(
                    label: '/',
                    semanticLabel: 'Slash',
                    tokens: tokens,
                    onTap: () => terminal.textInput('/'),
                  ),
                  const SizedBox(width: 6),
                  GlassShortcutKey(
                    label: '|',
                    semanticLabel: 'Pipe',
                    tokens: tokens,
                    onTap: () => terminal.textInput('|'),
                  ),
                  const SizedBox(width: 6),
                  GlassShortcutIconKey(
                    icon: Icons.arrow_back_rounded,
                    tokens: tokens,
                    semanticLabel: 'Left arrow',
                    onTap: () => terminal.keyInput(TerminalKey.arrowLeft),
                  ),
                  const SizedBox(width: 6),
                  GlassShortcutIconKey(
                    icon: Icons.arrow_upward_rounded,
                    tokens: tokens,
                    semanticLabel: 'Up arrow',
                    onTap: () => terminal.keyInput(TerminalKey.arrowUp),
                  ),
                  const SizedBox(width: 6),
                  GlassShortcutIconKey(
                    icon: Icons.arrow_downward_rounded,
                    tokens: tokens,
                    semanticLabel: 'Down arrow',
                    onTap: () => terminal.keyInput(TerminalKey.arrowDown),
                  ),
                  const SizedBox(width: 6),
                  GlassShortcutIconKey(
                    icon: Icons.arrow_forward_rounded,
                    tokens: tokens,
                    semanticLabel: 'Right arrow',
                    onTap: () => terminal.keyInput(TerminalKey.arrowRight),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
