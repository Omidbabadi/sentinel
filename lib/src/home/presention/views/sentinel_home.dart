import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentinel/src/home/presention/widgets/bottom_split_cards.dart';
import 'package:sentinel/src/home/presention/widgets/greeting_section.dart';
import 'package:sentinel/src/home/presention/widgets/recent_hosts_card.dart';
import 'package:sentinel/src/home/presention/widgets/summary_row.dart';
import 'package:sentinel/src/hosts/presention/app/adapter/hosts_adapter.dart';

import '../../../../core/res/style/theme_tokens.dart';

class SentinelHomeView extends ConsumerWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final ValueChanged<String> onNavigate;

  const SentinelHomeView({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = SentinelThemeTokens(isDark);
    final state = ref.watch(hostsAdapterProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 104),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          GreetingSection(isDark: isDark, tokens: tokens),
          const SizedBox(height: 18),
          SummaryRow(tokens: tokens, onNavigate: onNavigate, state: state),
          const SizedBox(height: 12),
          BottomSplitCards(
            tokens: tokens,
            isDark: isDark,
            onNavigate: onNavigate,
          ),
          const SizedBox(height: 12),
          if (state is HostsLoaded)
            RecentHostsCard(
              tokens: tokens,
              isDark: isDark,
              onNavigate: onNavigate,
              hosts: state.hosts,
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
