import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/pagination/paged_sliver_list.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/activity_repository.dart';
import '../providers/activity_providers.dart';
import '../providers/unread_provider.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final _scrollCtrl = ScrollController();
  PaginatedScrollListener? _scrollListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unreadActivityProvider.notifier).markAllRead();
    });
    _scrollListener = PaginatedScrollListener(
      controller: _scrollCtrl,
      onLoadMore: () =>
          ref.read(activityFeedProvider.notifier).loadMore(),
    );
  }

  @override
  void dispose() {
    _scrollListener?.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityFeedProvider);
    final notifier = ref.read(activityFeedProvider.notifier);
    final meId = ref.watch(authProvider).user?.id;

    return GradientScaffold(
      padding: EdgeInsets.zero,
      child: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Activity',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            PagedSliverList<ActivityItem>(
              state: state,
              onLoadFirst: notifier.loadFirst,
              onRetryMore: notifier.loadMore,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              firstPageBuilder: (ctx, s) => s.error != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(friendlyError(s.error)),
                    )
                  : const ShimmerLoader(height: 72),
              emptyBuilder: (ctx) => const EmptyState(
                icon: Icons.history_toggle_off_rounded,
                title: 'Nothing yet',
                subtitle:
                    'When friends add expenses or settle up, it appears here.',
              ),
              itemBuilder: (ctx, item, _) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActivityTile(item: item, meId: meId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item, required this.meId});
  final ActivityItem item;
  final String? meId;

  bool get _isMe => meId != null && item.actorId == meId;

  String _displayName() => _isMe ? 'You' : (item.actorName ?? 'Someone');

  /// Rewrite messages so they read naturally with "You" instead of name.
  /// Some backend events embed the actor's own name into the message body
  /// (e.g. group.member_joined: "Arbaz joined via invite code"). Strip it
  /// so we don't get "You Arbaz joined…".
  String _displayMessage() {
    final m = item.message;
    if (!_isMe) return m;
    final name = item.actorName;
    if (name == null) return m;
    if (m.startsWith('$name ')) return m.substring(name.length + 1);
    return m;
  }

  /// Where tapping this activity should take the user. Group-less activities
  /// (loans/khata, personal tracker) have no `groupId`, so they're routed by
  /// type to their feature section — otherwise the row was dead (the bug where
  /// tapping a khata activity did nothing). Returns null when there's nowhere
  /// useful to go, so the row simply isn't tappable.
  VoidCallback? _onTap(BuildContext context) {
    final t = item.type;
    // Pending invites: the user isn't a full member yet, so opening the group
    // detail would 403. Send them to the Groups list (invite card lives there).
    if (t.startsWith('group.invite')) return () => context.go('/groups');
    // Khata/loan events → the loans list (deep-linking the exact loan from
    // history would need the loan id persisted locally; the live push/banner
    // already opens the specific loan via its route).
    if (t.startsWith('loan.')) return () => context.push('/loans');
    if (t.startsWith('personal.')) return () => context.push('/tracker');
    if (item.groupId != null) {
      return () => context.push('/groups/${item.groupId}');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _onTap(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Avatar(
                    name: _displayName(),
                    imageUrl: item.actorAvatar,
                    size: 40,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: _activityBadge(item.type),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _displayName(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ' ${_displayMessage()}'),
                          if (item.groupName != null) ...[
                            const TextSpan(text: ' · '),
                            TextSpan(
                              text: item.groupName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFmt.relative(item.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityBadge(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'expense.created':
        icon = Icons.add_rounded;
        color = Colors.green;
        break;
      case 'expense.updated':
        icon = Icons.edit_rounded;
        color = Colors.orange;
        break;
      case 'expense.deleted':
        icon = Icons.delete_rounded;
        color = Colors.red;
        break;
      case 'settlement.created':
        icon = Icons.handshake_rounded;
        color = Colors.blue;
        break;
      case 'personal.created':
        icon = Icons.account_balance_wallet_rounded;
        color = Colors.green;
        break;
      case 'personal.updated':
        icon = Icons.edit_rounded;
        color = Colors.orange;
        break;
      case 'personal.deleted':
        icon = Icons.delete_rounded;
        color = Colors.red;
        break;
      case 'reaction.added':
        icon = Icons.emoji_emotions_rounded;
        color = const Color(0xFFFFC857);
        break;
      case 'group.created':
        icon = Icons.group_add_rounded;
        color = const Color(0xFF6C5CE7);
        break;
      case 'group.member_added':
        icon = Icons.person_add_rounded;
        color = const Color(0xFF0984E3);
        break;
      case 'group.member_joined':
        icon = Icons.how_to_reg_rounded;
        color = const Color(0xFF00B894);
        break;
      case 'group.invite':
        icon = Icons.mark_email_unread_rounded;
        color = const Color(0xFF6C5CE7);
        break;
      case 'group.invite_declined':
        icon = Icons.cancel_rounded;
        color = Colors.red;
        break;
      case 'group.invite_cancelled':
        icon = Icons.remove_circle_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = Colors.grey;
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 11, color: Colors.white),
    );
  }
}
