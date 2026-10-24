import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/host_list_tile.dart';

class HostRow extends ConsumerWidget {
  const HostRow({
    super.key,
    required this.host,
    required this.tokens,
    required this.isDark,
    required this.onNavigate,
  });

  final Host host;
  final SentinelThemeTokens tokens;
  final bool isDark;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HostListTile(
      host: host,
      tokens: tokens,
      avatarSize: 32,
      verticalPadding: 2.5,
      showPingPill: true,
      onTap: () => onNavigate(SentinelRoutes.hosts),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'N/A',
            textAlign: TextAlign.right,
            style: TextStyle(color: tokens.textSecondary, fontSize: 11),
          ),
          const SizedBox(width: 6),
          ExcludeSemantics(
            child: Icon(
              Icons.chevron_right_rounded,
              size: 15,
              color: tokens.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
