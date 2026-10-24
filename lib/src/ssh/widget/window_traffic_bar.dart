import 'package:flutter/material.dart';

import '../../../core/common/entities/host.dart';
import '../../../core/res/style/theme_tokens.dart';

class WindowTrafficLightsBar extends StatelessWidget {
  final Host activeHost;
  final SentinelThemeTokens tokens;
  final bool isFullscreen;
  final VoidCallback onClose;
  final VoidCallback onToggleFullscreen;
  final Color? textColor;

  const WindowTrafficLightsBar({
    super.key,
    required this.activeHost,
    required this.tokens,
    required this.isFullscreen,
    required this.onClose,
    required this.onToggleFullscreen,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TrafficLightButton(
          color: tokens.redAccent,
          label: 'Close session',
          onTap: onClose,
        ),
        _TrafficLightButton(
          color: tokens.yellowAccent,
          label: 'Exit fullscreen',
          enabled: isFullscreen,
          onTap: () {
            if (isFullscreen) onToggleFullscreen();
          },
        ),
        _TrafficLightButton(
          color: tokens.greenAccent,
          label: isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen',
          onTap: onToggleFullscreen,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${activeHost.username}@${activeHost.ip}: ~',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor ?? tokens.textSecondary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

class _TrafficLightButton extends StatelessWidget {
  const _TrafficLightButton({
    required this.color,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
