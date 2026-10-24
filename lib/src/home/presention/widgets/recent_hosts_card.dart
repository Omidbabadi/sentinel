import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/core/common/entities/host.dart';
import 'package:sentinel/core/res/style/theme_tokens.dart';
import 'package:sentinel/core/services/router.dart';
import 'package:sentinel/core/widgets/glass_card.dart';

import 'host_row.dart';

class RecentHostsCard extends ConsumerWidget {
  const RecentHostsCard({
    super.key,
    required this.tokens,
    required this.isDark,
    required this.onNavigate,
    required this.hosts,
  });

  final SentinelThemeTokens tokens;
  final bool isDark;
  final ValueChanged<String> onNavigate;
  final List<Host> hosts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayHosts = hosts.take(4).toList();

    return GlassCard(
      tokens: tokens,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      borderRadius: 20,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Recent Hosts',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'View all hosts',
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => onNavigate(SentinelRoutes.hosts),
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 36),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'View all',
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: tokens.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < displayHosts.length; i++) ...[
            HostRow(
              host: displayHosts[i],
              tokens: tokens,
              isDark: isDark,
              onNavigate: onNavigate,
            ),
            if (i < displayHosts.length - 1)
              Divider(height: 14, thickness: 0.7, color: tokens.dividerColor),
          ],
        ],
      ),
    );
  }
}
