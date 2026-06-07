import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/ad_banner_widget.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/friend_summary_model.dart';
import '../providers/group_providers.dart';

class FriendsSummaryScreen extends ConsumerStatefulWidget {
  const FriendsSummaryScreen({super.key});

  @override
  ConsumerState<FriendsSummaryScreen> createState() =>
      _FriendsSummaryScreenState();
}

class _FriendsSummaryScreenState extends ConsumerState<FriendsSummaryScreen> {
  bool _showSettled = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(friendsSummaryProvider);
    final user = ref.watch(authProvider).user;
    final currency = user?.currency ?? 'PKR';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(friendsSummaryProvider),
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: true,
              title: Text('Friends',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            async.when(
              loading: () =>
                  const SliverFillRemaining(child: ShimmerLoader()),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                    child: Text(friendlyError(e),
                        textAlign: TextAlign.center)),
              ),
              data: (friends) {
                final active =
                    friends.where((f) => f.net.abs() > 0.005).toList();
                final settled =
                    friends.where((f) => f.net.abs() <= 0.005).toList();
                final overallNet =
                    active.fold<double>(0, (a, f) => a + f.net);
                final visible =
                    _showSettled ? [...active, ...settled] : active;

                if (friends.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'No friends yet',
                      subtitle:
                          'Join a group with others to track balances here.',
                    ),
                  );
                }

                return SliverPadding(
                  // No FAB on this screen — bottom nav bar clearance only.
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),
                      _OverallBanner(net: overallNet, currency: currency),
                      const SizedBox(height: 16),
                      for (final f in visible)
                        _FriendRow(
                          summary: f,
                          currency: currency,
                          onTap: () => context.push(
                            '/friends/${f.userId}',
                            extra: f,
                          ),
                        ),
                      if (settled.isNotEmpty && !_showSettled) ...[
                        const SizedBox(height: 12),
                        _SettledHint(
                          count: settled.length,
                          onShow: () =>
                              setState(() => _showSettled = true),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const AdBannerWidget(),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OverallBanner extends StatelessWidget {
  const _OverallBanner({required this.net, required this.currency});
  final double net;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isSettled = net.abs() < 0.005;
    final isOwed = net > 0;
    final color = isSettled
        ? Colors.grey
        : (isOwed ? AppColors.accent : AppColors.danger);
    final label = isSettled
        ? 'You are all settled up'
        : isOwed
            ? 'Overall, you are owed ${Money.format(net.abs(), code: currency)}'
            : 'Overall, you owe ${Money.format(net.abs(), code: currency)}';

    return Text(label,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: color));
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.summary,
    required this.currency,
    required this.onTap,
  });
  final FriendSummary summary;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final net = summary.net;
    final settled = net.abs() < 0.005;
    final owedToMe = net > 0;

    final amtColor = settled
        ? Colors.grey
        : (owedToMe ? AppColors.accent : AppColors.danger);
    final amtLabel =
        settled ? 'settled up' : (owedToMe ? 'owes you' : 'you owe');
    final amtValue =
        settled ? '' : Money.format(net.abs(), code: currency);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Avatar(
                name: summary.user.name,
                imageUrl: summary.user.avatarUrl,
                size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Text(summary.user.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amtLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: amtColor.withOpacity(0.8))),
                if (amtValue.isNotEmpty)
                  Text(amtValue,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: amtColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettledHint extends StatelessWidget {
  const _SettledHint({required this.count, required this.onShow});
  final int count;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Hiding $count settled-up friend${count == 1 ? "" : "s"}',
          style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onShow,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Show $count settled-up friend${count == 1 ? "" : "s"}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
