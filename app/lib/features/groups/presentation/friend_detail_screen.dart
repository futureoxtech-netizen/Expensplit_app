import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settlements/providers/settlement_providers.dart';
import '../data/friend_summary_model.dart';
import '../providers/group_providers.dart';

class FriendDetailScreen extends ConsumerWidget {
  const FriendDetailScreen({
    super.key,
    required this.friend,
    required this.friendId,
  });

  final FriendSummary friend;
  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(friendDetailProvider(friendId));
    final user = ref.watch(authProvider).user;
    final currency = user?.currency ?? 'USD';

    final net = friend.net;
    final isOwed = net > 0;
    final isSettled = net.abs() < 0.005;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      Avatar(
                          name: friend.user.name,
                          imageUrl: friend.user.avatarUrl,
                          size: 64),
                      const SizedBox(height: 12),
                      Text(friend.user.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        isSettled
                            ? 'You are settled up'
                            : isOwed
                                ? '${friend.user.name} owes you ${Money.format(net.abs(), code: currency)}'
                                : 'You owe ${friend.user.name} ${Money.format(net.abs(), code: currency)}',
                        style: TextStyle(
                            color: isSettled
                                ? Colors.white70
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Action buttons ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showSettleUp(context, ref,
                          currency: currency, net: net),
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 18),
                      label: const Text('Settle up'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Transaction list ─────────────────────────────────────────
          detailAsync.when(
            loading: () => const SliverFillRemaining(child: ShimmerLoader()),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text(e.toString())),
            ),
            data: (detail) {
              if (detail.transactions.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No shared transactions yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              // Group transactions by month
              final grouped = <String, List<FriendTransaction>>{};
              for (final t in detail.transactions) {
                final key =
                    '${_monthName(t.date.month)} ${t.date.year}';
                grouped.putIfAbsent(key, () => []).add(t);
              }

              final keys = grouped.keys.toList();
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final month = keys[i];
                      final txns = grouped[month]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              month,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5)),
                            ),
                          ),
                          for (final t in txns)
                            _TxnRow(
                              txn: t,
                              currency: currency,
                              friendName: friend.user.name,
                            ),
                        ],
                      );
                    },
                    childCount: keys.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSettleUp(BuildContext context, WidgetRef ref,
      {required String currency, required double net}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SettleUpSheet(
        friend: friend,
        net: net,
        currency: currency,
        ref: ref,
      ),
    );
  }

  static String _monthName(int m) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[m];
  }
}

// ─── Transaction row ──────────────────────────────────────────────────────────

class _TxnRow extends StatelessWidget {
  const _TxnRow({
    required this.txn,
    required this.currency,
    required this.friendName,
  });
  final FriendTransaction txn;
  final String currency;
  final String friendName;

  @override
  Widget build(BuildContext context) {
    final isPayment = txn.type == 'settlement';
    final isOwedToMe = txn.net > 0;
    final amtColor = isOwedToMe ? AppColors.primary : Colors.orange;

    Color groupColor;
    try {
      groupColor = Color(
          int.parse(txn.groupColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      groupColor = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date column
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Text(
                  txn.date.day.toString().padLeft(2, '0'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  _shortMonth(txn.date.month),
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: isPayment
                    ? Colors.grey.shade200
                    : groupColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(
              isPayment
                  ? Icons.payments_outlined
                  : Icons.receipt_long_outlined,
              size: 20,
              color: isPayment ? Colors.grey : groupColor,
            ),
          ),
          const SizedBox(width: 10),
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.description,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(txn.groupName,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isOwedToMe ? 'you are owed' : 'you owe',
                style: TextStyle(
                    fontSize: 10, color: amtColor.withOpacity(0.8)),
              ),
              Text(
                Money.format(txn.net.abs(), code: currency),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: amtColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _shortMonth(int m) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[m];
  }
}

// ─── Settle-up bottom sheet ───────────────────────────────────────────────────

class _SettleUpSheet extends StatefulWidget {
  const _SettleUpSheet({
    required this.friend,
    required this.net,
    required this.currency,
    required this.ref,
  });
  final FriendSummary friend;
  final double net;
  final String currency;
  final WidgetRef ref;

  @override
  State<_SettleUpSheet> createState() => _SettleUpSheetState();
}

class _SettleUpSheetState extends State<_SettleUpSheet> {
  String? _selectedGroupId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.friend.groups.isNotEmpty) {
      _selectedGroupId = widget.friend.groups.first.groupId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.friend.groups;
    final net = widget.net;
    final isOwed = net > 0;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Settle up',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isOwed
                ? '${widget.friend.user.name} owes you ${Money.format(net.abs(), code: widget.currency)}'
                : 'You owe ${widget.friend.user.name} ${Money.format(net.abs(), code: widget.currency)}',
            style: TextStyle(
                color: isOwed ? AppColors.primary : Colors.orange,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (groups.length > 1) ...[
            const Text('Select group',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedGroupId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              items: groups
                  .map((g) => DropdownMenuItem(
                        value: g.groupId,
                        child: Text(g.groupName),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedGroupId = v),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _settle,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm settlement',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _settle() async {
    if (_selectedGroupId == null) return;
    setState(() => _loading = true);
    try {
      final net = widget.net;
      final repo = widget.ref.read(settlementRepositoryProvider);
      final from = net < 0
          ? widget.ref.read(authProvider).user!.id
          : widget.friend.userId;
      final to = net < 0
          ? widget.friend.userId
          : widget.ref.read(authProvider).user!.id;
      await repo.create(
        groupId: _selectedGroupId!,
        from: from,
        to: to,
        amount: net.abs(),
        currency: widget.currency,
      );
      widget.ref.invalidate(friendsSummaryProvider);
      widget.ref.invalidate(friendDetailProvider(widget.friend.userId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
