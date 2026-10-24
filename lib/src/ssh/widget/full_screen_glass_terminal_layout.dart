import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/application/riverpod/active_host_tab_controller.dart';
import 'package:sentinel/core/common/application/riverpod/user_prefs.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/common/singelton/user_prefs.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/widgets/glass_card.dart';
import 'package:sentinel/core/widgets/sentinel_botton.dart';
import 'package:sentinel/src/ssh/presention/app/adapter/ssh_adapter.dart';
import 'package:sentinel/src/ssh/widget/full_screen_glass_topbar.dart';
import 'package:sentinel/src/ssh/widget/glass_terminal_accessory_bar.dart';
import 'package:sentinel/src/ssh/widget/terminal_session_body.dart';
import 'package:sentinel/src/ssh/widget/terminal_theme.dart';
import 'package:sentinel/src/ssh/widget/window_traffic_bar.dart';
import 'package:xterm2/xterm.dart';

enum TerminalBottomPanelMode { none, keypadGrid, appearance }

class FullscreenGlassTerminalLayout extends ConsumerStatefulWidget {
  final Host activeHost;
  final int activeHostId;
  final List<HostTab> allTabs;
  final SshState sshState;
  final Map<int, SshState> sshStateMap;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final VoidCallback onExitFullscreen;
  final VoidCallback onAddHost;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<int> onCloseTab;
  final VoidCallback onReconnect;
  final VoidCallback? onOpenSftp;

  const FullscreenGlassTerminalLayout({
    super.key,
    required this.activeHost,
    required this.activeHostId,
    required this.allTabs,
    required this.sshState,
    required this.sshStateMap,
    required this.tokens,
    required this.isDark,
    required this.onExitFullscreen,
    required this.onAddHost,
    required this.onSelectTab,
    required this.onCloseTab,
    required this.onReconnect,
    this.onOpenSftp,
  });

  @override
  ConsumerState<FullscreenGlassTerminalLayout> createState() =>
      _FullscreenGlassTerminalLayoutState();
}

class _FullscreenGlassTerminalLayoutState
    extends ConsumerState<FullscreenGlassTerminalLayout> {
  final ValueNotifier<TerminalBottomPanelMode> _panelMode = ValueNotifier(
    TerminalBottomPanelMode.none,
  );

  @override
  void dispose() {
    _panelMode.dispose();
    super.dispose();
  }

  void _toggleBottomToolPanel() {
    if (_panelMode.value == TerminalBottomPanelMode.none) {
      FocusManager.instance.primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      _panelMode.value = TerminalBottomPanelMode.keypadGrid;
    } else {
      _panelMode.value = TerminalBottomPanelMode.none;
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  void _selectPanelTab(TerminalBottomPanelMode mode) {
    if (mode == TerminalBottomPanelMode.none) {
      _panelMode.value = TerminalBottomPanelMode.none;
      SystemChannels.textInput.invokeMethod('TextInput.show');
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      _panelMode.value = mode;
    }
  }

  void _exitFullscreen() {
    _panelMode.value = TerminalBottomPanelMode.none;
    widget.onExitFullscreen();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(userPrefsProvider);
    final isDefaultTerminalTheme =
        prefs.terminalThemeId == UserPrefs.defaultTerminalThemeId;
    final activeTerminalTheme = terminalPresetThemes(
      widget.tokens,
      widget.isDark,
      themeId: prefs.terminalThemeId,
    );
    final cardBg = isDefaultTerminalTheme
        ? widget.tokens.cardSurface
        : activeTerminalTheme.background.withValues(alpha: 0.90);
    final headerTextColor = isDefaultTerminalTheme
        ? widget.tokens.textSecondary
        : activeTerminalTheme.foreground.withValues(alpha: 0.72);

    return ValueListenableBuilder<TerminalBottomPanelMode>(
      valueListenable: _panelMode,
      builder: (context, panelMode, _) {
        final isPanelOpen = panelMode != TerminalBottomPanelMode.none;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Control Bar: [ < ]  [ Host Tab Pill ]  [ + ]  [ ⊞ / ⌨ ]
                FullscreenGlassTopBar(
                  allTabs: widget.allTabs,
                  activeHostId: widget.activeHostId,
                  sshStateMap: widget.sshStateMap,
                  tokens: widget.tokens,
                  isDark: widget.isDark,
                  isPanelOpen: isPanelOpen,
                  onExitFullscreen: _exitFullscreen,
                  onAddHost: () {
                    _panelMode.value = TerminalBottomPanelMode.none;
                    widget.onAddHost();
                  },
                  onSelectTab: widget.onSelectTab,
                  onCloseTab: widget.onCloseTab,
                  onTogglePanel: _toggleBottomToolPanel,
                  onOpenSftp: widget.onOpenSftp,
                ),
                const SizedBox(height: 8),

                // 2. Full-Height Frosted Glass Terminal Card
                Expanded(
                  child: GlassCard(
                    tokens: widget.tokens,
                    backgroundColor: cardBg,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WindowTrafficLightsBar(
                          activeHost: widget.activeHost,
                          tokens: widget.tokens,
                          isFullscreen: true,
                          textColor: headerTextColor,
                          onClose: () => widget.onCloseTab(widget.activeHostId),
                          onToggleFullscreen: _exitFullscreen,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: TerminalSessionBody(
                              activeHost: widget.activeHost,
                              activeHostId: widget.activeHostId,
                              sshState: widget.sshState,
                              tokens: widget.tokens,
                              isDark: widget.isDark,
                              onReconnect: widget.onReconnect,
                              suppressSoftKeyboard: isPanelOpen,
                              onTapTerminal: isPanelOpen
                                  ? () => _selectPanelTab(
                                      TerminalBottomPanelMode.none,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Compact Quick-Keys Strip (when custom panel is closed)
                if (widget.sshState is SshConnected && !isPanelOpen) ...[
                  const SizedBox(height: 8),
                  GlassTerminalAccessoryBar(
                    terminal: (widget.sshState as SshConnected).terminal,
                    tokens: widget.tokens,
                    isDark: widget.isDark,
                    onOpenAppearance: () =>
                        _selectPanelTab(TerminalBottomPanelMode.appearance),
                    onOpenKeypadGrid: () =>
                        _selectPanelTab(TerminalBottomPanelMode.keypadGrid),
                  ),
                ],

                // 4. Expandable Bottom Drawer (Extended Keypad Grid OR Theme/Font Picker)
                if (isPanelOpen) ...[
                  const SizedBox(height: 8),
                  _FullscreenBottomToolSheet(
                    mode: panelMode,
                    sshState: widget.sshState,
                    tokens: widget.tokens,
                    isDark: widget.isDark,
                    onSelectMode: _selectPanelTab,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FullscreenBottomToolSheet extends StatelessWidget {
  final TerminalBottomPanelMode mode;
  final SshState sshState;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final ValueChanged<TerminalBottomPanelMode> onSelectMode;

  const _FullscreenBottomToolSheet({
    required this.mode,
    required this.sshState,
    required this.tokens,
    required this.isDark,
    required this.onSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    final terminal = sshState is SshConnected
        ? (sshState as SshConnected).terminal
        : null;

    return GlassCard(
      tokens: tokens,
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
      child: SizedBox(
        height: 295,
        child: Column(
          children: [
            Expanded(
              child: mode == TerminalBottomPanelMode.appearance
                  ? _TerminalAppearanceSheetContent(
                      tokens: tokens,
                      isDark: isDark,
                    )
                  : _TerminalExtendedKeypadGrid(
                      terminal: terminal,
                      tokens: tokens,
                      isDark: isDark,
                    ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, thickness: 0.7, color: tokens.dividerColor),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SheetNavTabButton(
                  icon: Icons.grid_view_rounded,
                  label: 'Keys',
                  isSelected: mode == TerminalBottomPanelMode.keypadGrid,
                  tokens: tokens,
                  onTap: () => onSelectMode(TerminalBottomPanelMode.keypadGrid),
                ),
                _SheetNavTabButton(
                  icon: Icons.palette_outlined,
                  label: 'Appearance',
                  isSelected: mode == TerminalBottomPanelMode.appearance,
                  tokens: tokens,
                  onTap: () => onSelectMode(TerminalBottomPanelMode.appearance),
                ),
                Container(width: 1, height: 22, color: tokens.dividerColor),
                _SheetNavTabButton(
                  icon: Icons.keyboard_hide_rounded,
                  label: 'Keyboard',
                  isSelected: false,
                  tokens: tokens,
                  onTap: () => onSelectMode(TerminalBottomPanelMode.none),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetNavTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final SentinelThemeTokens tokens;
  final VoidCallback onTap;

  const _SheetNavTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = tokens.greenTextAccent;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? tokens.greenAccent.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: tokens.greenAccent.withValues(alpha: 0.35),
                      width: 0.8,
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? activeColor : tokens.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? activeColor : tokens.textSecondary,
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

class _TerminalAppearanceSheetContent extends ConsumerWidget {
  final SentinelThemeTokens tokens;
  final bool isDark;

  const _TerminalAppearanceSheetContent({
    required this.tokens,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPrefsProvider);
    final prefsNotifier = ref.read(userPrefsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SentinelButton(
              tokens: tokens,
              width: 40,
              height: 36,
              borderRadius: 11,
              semanticLabel: 'Decrease font size',
              tooltip: 'Decrease font size',
              onTap: () => prefsNotifier.decrementFontSize(1.0),
              child: Icon(
                Icons.remove_rounded,
                size: 18,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            SentinelButton(
              tokens: tokens,
              width: 52,
              height: 36,
              borderRadius: 11,
              semanticLabel:
                  'Terminal font size ${prefs.terminalFontSize.toStringAsFixed(0)}',
              child: Text(
                prefs.terminalFontSize.toStringAsFixed(0),
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 13.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            SentinelButton(
              tokens: tokens,
              width: 40,
              height: 36,
              borderRadius: 11,
              semanticLabel: 'Increase font size',
              tooltip: 'Increase font size',
              onTap: () => prefsNotifier.incrementFontSize(1.0),
              child: Icon(
                Icons.add_rounded,
                size: 18,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SentinelButton(
                tokens: tokens,
                width: null,
                height: 36,
                borderRadius: 11,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                semanticLabel: 'Font family: JetBrains Mono, supports pinch zoom',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'JetBrains Mono • Pinch Zoom',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Icon(
                      Icons.pinch_outlined,
                      size: 15,
                      color: tokens.greenAccent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.22,
            ),
            itemCount: kSentinelTerminalThemePresets.length,
            itemBuilder: (context, index) {
              final preset = kSentinelTerminalThemePresets[index];
              final isSelected = preset.id == prefs.terminalThemeId;
              return _TerminalThemePreviewCard(
                preset: preset,
                isSelected: isSelected,
                tokens: tokens,
                isDark: isDark,
                onTap: () => prefsNotifier.setTerminalThemeId(preset.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TerminalThemePreviewCard extends StatelessWidget {
  final SentinelTerminalThemePreset preset;
  final bool isSelected;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final VoidCallback onTap;

  const _TerminalThemePreviewCard({
    required this.preset,
    required this.isSelected,
    required this.tokens,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = preset.effectivePreviewBg(isDark);
    final primary = preset.effectivePreviewPrimary(isDark);
    final secondary = preset.effectivePreviewSecondary(isDark);
    final accent = preset.effectivePreviewAccent(isDark);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${preset.name} terminal theme',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? tokens.greenAccent
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.14)
                                : Colors.black.withValues(alpha: 0.12)),
                      width: isSelected ? 1.8 : 0.9,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        height: 5,
                        width: 68,
                        decoration: BoxDecoration(
                          color: secondary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            height: 5,
                            width: 18,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            height: 5,
                            width: 14,
                            decoration: BoxDecoration(
                              color: primary.withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            height: 7,
                            width: 3,
                            color: primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                preset.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? tokens.greenTextAccent
                      : tokens.textSecondary,
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TerminalExtendedKeypadGrid extends StatelessWidget {
  final Terminal? terminal;
  final SentinelThemeTokens tokens;
  final bool isDark;

  const _TerminalExtendedKeypadGrid({
    required this.terminal,
    required this.tokens,
    required this.isDark,
  });

  void _sendKey(VoidCallback action) {
    if (terminal != null) action();
  }

  @override
  Widget build(BuildContext context) {
    final t = terminal;

    final rows = <List<({String label, VoidCallback onTap})>>[
      [
        (
          label: 'esc',
          onTap: () => _sendKey(() => t!.keyInput(TerminalKey.escape)),
        ),
        (
          label: 'tab',
          onTap: () => _sendKey(() => t!.keyInput(TerminalKey.tab)),
        ),
        (
          label: 'ctrl+c',
          onTap: () => _sendKey(() => t!.charInput(0x63, ctrl: true)),
        ),
        (
          label: 'ctrl+z',
          onTap: () => _sendKey(() => t!.charInput(0x7A, ctrl: true)),
        ),
        (
          label: '←',
          onTap: () => _sendKey(() => t!.keyInput(TerminalKey.arrowLeft)),
        ),
        (
          label: '↑',
          onTap: () => _sendKey(() => t!.keyInput(TerminalKey.arrowUp)),
        ),
        (
          label: '↓',
          onTap: () => _sendKey(() => t!.keyInput(TerminalKey.arrowDown)),
        ),
        (
          label: '→',
          onTap: () => _sendKey(() => t!.keyInput(TerminalKey.arrowRight)),
        ),
      ],
      [
        (
          label: 'ins',
          onTap: () => _sendKey(() => t!.keyInput(TerminalKey.insert)),
        ),
        (
          label: 'del',
          onTap: () => _sendKey(() => t!.keyInput(TerminalKey.delete)),
        ),
        (
          label: 'home',
          onTap: () => _sendKey(() => t!.keyInput(TerminalKey.home)),
        ),
        (
          label: 'end',
          onTap: () => _sendKey(() => t!.keyInput(TerminalKey.end)),
        ),
        (
          label: 'pgUp',
          onTap: () => _sendKey(() => t!.keyInput(TerminalKey.pageUp)),
        ),
        (
          label: 'pgDn',
          onTap: () => _sendKey(() => t!.keyInput(TerminalKey.pageDown)),
        ),
        (
          label: 'ctrl+l',
          onTap: () => _sendKey(() => t!.charInput(0x6C, ctrl: true)),
        ),
        (
          label: 'ctrl+d',
          onTap: () => _sendKey(() => t!.charInput(0x64, ctrl: true)),
        ),
      ],
      [
        (label: '~', onTap: () => _sendKey(() => t!.textInput('~'))),
        (label: '/', onTap: () => _sendKey(() => t!.textInput('/'))),
        (label: '|', onTap: () => _sendKey(() => t!.textInput('|'))),
        (label: '-', onTap: () => _sendKey(() => t!.textInput('-'))),
        (label: '_', onTap: () => _sendKey(() => t!.textInput('_'))),
        (label: '*', onTap: () => _sendKey(() => t!.textInput('*'))),
        (label: '&', onTap: () => _sendKey(() => t!.textInput('&'))),
        (label: '\$', onTap: () => _sendKey(() => t!.textInput('\$'))),
      ],
      [
        (label: '[', onTap: () => _sendKey(() => t!.textInput('['))),
        (label: ']', onTap: () => _sendKey(() => t!.textInput(']'))),
        (label: '{', onTap: () => _sendKey(() => t!.textInput('{'))),
        (label: '}', onTap: () => _sendKey(() => t!.textInput('}'))),
        (label: '(', onTap: () => _sendKey(() => t!.textInput('('))),
        (label: ')', onTap: () => _sendKey(() => t!.textInput(')'))),
        (label: '<', onTap: () => _sendKey(() => t!.textInput('<'))),
        (label: '>', onTap: () => _sendKey(() => t!.textInput('>'))),
      ],
      [
        (label: 'F1', onTap: () => _sendKey(() => t!.keyInput(TerminalKey.f1))),
        (label: 'F2', onTap: () => _sendKey(() => t!.keyInput(TerminalKey.f2))),
        (label: 'F3', onTap: () => _sendKey(() => t!.keyInput(TerminalKey.f3))),
        (label: 'F4', onTap: () => _sendKey(() => t!.keyInput(TerminalKey.f4))),
        (label: 'F5', onTap: () => _sendKey(() => t!.keyInput(TerminalKey.f5))),
        (label: 'F6', onTap: () => _sendKey(() => t!.keyInput(TerminalKey.f6))),
        (label: 'F7', onTap: () => _sendKey(() => t!.keyInput(TerminalKey.f7))),
        (label: 'F8', onTap: () => _sendKey(() => t!.keyInput(TerminalKey.f8))),
      ],
      [
        (label: 'F9', onTap: () => _sendKey(() => t!.keyInput(TerminalKey.f9))),
        (
          label: 'F10',
          onTap: () => _sendKey(() => t!.keyInput(TerminalKey.f10)),
        ),
        (
          label: '^X',
          onTap: () => _sendKey(() => t!.charInput(0x78, ctrl: true)),
        ),
        (
          label: '^O',
          onTap: () => _sendKey(() => t!.charInput(0x6F, ctrl: true)),
        ),
        (
          label: '^W',
          onTap: () => _sendKey(() => t!.charInput(0x77, ctrl: true)),
        ),
        (
          label: '^K',
          onTap: () => _sendKey(() => t!.charInput(0x6B, ctrl: true)),
        ),
        (
          label: '^A',
          onTap: () => _sendKey(() => t!.charInput(0x61, ctrl: true)),
        ),
        (
          label: '^E',
          onTap: () => _sendKey(() => t!.charInput(0x65, ctrl: true)),
        ),
      ],
    ];

    return Column(
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          Expanded(
            child: Row(
              children: [
                for (int c = 0; c < rows[r].length; c++) ...[
                  Expanded(
                    child: _ExtendedGridKeyCell(
                      label: rows[r][c].label,
                      tokens: tokens,
                      onTap: rows[r][c].onTap,
                    ),
                  ),
                  if (c < rows[r].length - 1) const SizedBox(width: 5),
                ],
              ],
            ),
          ),
          if (r < rows.length - 1) const SizedBox(height: 5),
        ],
      ],
    );
  }
}

class _ExtendedGridKeyCell extends StatelessWidget {
  final String label;
  final SentinelThemeTokens tokens;
  final VoidCallback onTap;

  const _ExtendedGridKeyCell({
    required this.label,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isModifier =
        label.startsWith('ctrl') ||
        label.startsWith('^') ||
        label == 'esc' ||
        label == 'tab';

    return Semantics(
      button: true,
      label: 'Key $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.innerPillSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isModifier
                    ? tokens.greenAccent.withValues(alpha: 0.3)
                    : tokens.innerPillBorder,
                width: 0.8,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: isModifier ? tokens.greenTextAccent : tokens.textPrimary,
                fontSize: 10.5,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
