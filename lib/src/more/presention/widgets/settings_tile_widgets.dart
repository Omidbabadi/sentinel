import 'package:flutter/material.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';

class SentinelSettingsSwitchTile extends StatelessWidget {
  const SentinelSettingsSwitchTile({
    super.key,
    required this.tokens,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.accentColor,
  });

  final SentinelThemeTokens tokens;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? tokens.greenAccent;

    return Semantics(
      toggled: value,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: tokens.innerPillSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: value
                            ? effectiveAccent.withValues(alpha: 0.35)
                            : tokens.innerPillBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 17,
                      color: value ? effectiveAccent : tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _GlassToggleSwitch(
                    tokens: tokens,
                    value: value,
                    activeColor: effectiveAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassToggleSwitch extends StatelessWidget {
  const _GlassToggleSwitch({
    required this.tokens,
    required this.value,
    required this.activeColor,
  });

  final SentinelThemeTokens tokens;
  final bool value;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 44,
      height: 25,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value
            ? activeColor.withValues(alpha: tokens.isDark ? 0.28 : 0.22)
            : tokens.innerPillSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? activeColor.withValues(alpha: 0.65)
              : tokens.innerPillBorder,
          width: 1.0,
        ),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 17,
          height: 17,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? activeColor : tokens.textSecondary,
            boxShadow: value
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class SentinelSettingsActionTile extends StatelessWidget {
  const SentinelSettingsActionTile({
    super.key,
    required this.tokens,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor,
    this.trailingBadge,
    this.isDestructive = false,
  });

  final SentinelThemeTokens tokens;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accentColor;
  final String? trailingBadge;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDestructive
        ? tokens.redAccent
        : (accentColor ?? tokens.greenAccent);
    final titleColor = isDestructive
        ? tokens.redTextAccent
        : tokens.textPrimary;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? tokens.redAccent.withValues(alpha: 0.12)
                          : tokens.innerPillSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDestructive
                            ? tokens.redAccent.withValues(alpha: 0.30)
                            : tokens.innerPillBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Icon(icon, size: 17, color: effectiveColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailingBadge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.innerPillSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: tokens.innerPillBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        trailingBadge!,
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 10.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: tokens.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SentinelSettingsOptionChips<T> extends StatelessWidget {
  const SentinelSettingsOptionChips({
    super.key,
    required this.tokens,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final SentinelThemeTokens tokens;
  final String label;
  final String subtitle;
  final IconData icon;
  final List<({T value, String label})> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tokens.innerPillSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.innerPillBorder, width: 0.8),
                ),
                child: Icon(icon, size: 17, color: tokens.blueAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < options.length; i++) ...[
                Expanded(
                  child: _OptionChipButton(
                    tokens: tokens,
                    label: options[i].label,
                    isSelected: options[i].value == selectedValue,
                    onTap: () => onSelected(options[i].value),
                  ),
                ),
                if (i < options.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionChipButton extends StatelessWidget {
  const _OptionChipButton({
    required this.tokens,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final SentinelThemeTokens tokens;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 36),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? tokens.greenAccent.withValues(
                      alpha: tokens.isDark ? 0.18 : 0.14,
                    )
                  : tokens.innerPillSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? tokens.greenAccent.withValues(alpha: 0.55)
                    : tokens.innerPillBorder,
                width: isSelected ? 1.1 : 0.8,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? tokens.greenTextAccent
                    : tokens.textSecondary,
                fontSize: 11.5,
                fontFamily: 'monospace',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
