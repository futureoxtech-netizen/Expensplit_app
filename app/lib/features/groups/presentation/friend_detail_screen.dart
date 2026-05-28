import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/pagination/paged_sliver_list.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settlements/providers/settlement_providers.dart';
import '../data/friend_summary_model.dart';
import '../providers/group_providers.dart';

class FriendDetailScreen extends ConsumerStatefulWidget {
  const FriendDetailScreen({
    super.key,
    required this.friend,
    required this.friendId,
  });

  final FriendSummary friend;
  final String friendId;

  @override
  ConsumerState<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends ConsumerState<FriendDetailScreen> {
  final _scrollCtrl = ScrollController();
  PaginatedScrollListener? _scrollListener;

  @override
  void initState() {
    super.initState();
    _scrollListener = PaginatedScrollListener(
      controller: _scrollCtrl,
      onLoadMore: () => ref
          .read(friendTransactionsPagedProvider(widget.friendId).notifier)
          .loadMore(),
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
    final user = ref.watch(authProvider).user;
    final currency = user?.currency ?? 'USD';
    final txState =
        ref.watch(friendTransactionsPagedProvider(widget.friendId));
    final txNotifier =
        ref.read(friendTransactionsPagedProvider(widget.friendId).notifier);

    // Watch live summary so balance updates immediately after settlement
    final summaryAsync = ref.watch(friendsSummaryProvider);
    final net = summaryAsync.valueOrNull
            ?.firstWhere(
              (f) => f.userId == widget.friendId,
              orElse: () => widget.friend,
            )
            .net ??
        widget.friend.net;
    final isOwed = net > 0;
    final isSettled = net.abs() < 0.005;
    final friend = widget.friend;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollCtrl,
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

          // ── Transaction list (paginated) ────────────────────────────
          // We inject month headers inline by tracking the previous row's
          // month while scrolling. The paged notifier guarantees stable
          // descending-date ordering.
          PagedSliverList<FriendTransaction>(
            state: txState,
            onLoadFirst: txNotifier.loadFirst,
            onRetryMore: txNotifier.loadMore,
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
            firstPageBuilder: (ctx, s) => s.error != null
                ? ErrorView(
                    error: s.error,
                    onRetry: txNotifier.loadFirst,
                  )
                : const ShimmerLoader(),
            emptyBuilder: (ctx) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  'No shared transactions yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            itemBuilder: (ctx, t, i) {
              final items = txState.items!;
              final prev = i > 0 ? items[i - 1] : null;
              final showHeader = prev == null ||
                  prev.date.month != t.date.month ||
                  prev.date.year != t.date.year;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        '${_FriendDetailScreenState._monthName(t.date.month)} ${t.date.year}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                      ),
                    ),
                  _TxnRow(
                    txn: t,
                    currency: currency,
                    friendName: friend.user.name,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showSettleUp(BuildContext context, WidgetRef ref,
      {required String currency, required double net}) async {
    final settled = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SettleUpSheet(
        friend: widget.friend,
        net: net,
        currency: currency,
        ref: ref,
      ),
    );
    if (settled != null && context.mounted) {
      _showSettlementSuccess(
          context, settled, currency, widget.friend.user.name);
    }
  }

  static void _showSettlementSuccess(
      BuildContext context, double amount, String currency, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Settlement Recorded!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'You settled ${Money.format(amount, code: currency)} with $name',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.65)),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(modalCtx),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
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
    // For settlements `net > 0` means the current user was the payer (from=me);
    // for expenses it means the friend owes the current user. The label & color
    // differ between the two — a settlement is just a cash-flow record, not a
    // debt direction.
    final isOwedToMe = txn.net > 0;
    final Color amtColor;
    final String amtLabel;
    if (isPayment) {
      amtLabel = isOwedToMe ? 'you paid' : 'you received';
      amtColor = isOwedToMe ? Colors.orange : AppColors.primary;
    } else {
      amtLabel = isOwedToMe ? 'you are owed' : 'you owe';
      amtColor = isOwedToMe ? AppColors.primary : Colors.orange;
    }

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
                amtLabel,
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
  late TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.friend.groups.isNotEmpty) {
      _selectedGroupId = widget.friend.groups.first.groupId;
    }
    _amountCtrl = TextEditingController(
        text: widget.net.abs().toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
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
          // Editable amount
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '${widget.currency} ',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),
            ),
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
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No shared group — add this friend to a group first'),
        ),
      );
      return;
    }
    final enteredAmount = double.tryParse(_amountCtrl.text.trim());
    if (enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
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
        amount: enteredAmount,
        currency: widget.currency,
      );
      widget.ref.invalidate(friendsSummaryProvider);
      widget.ref.invalidate(friendDetailProvider(widget.friend.userId));
      widget.ref.invalidate(
          friendTransactionsPagedProvider(widget.friend.userId));
      if (mounted) Navigator.pop(context, enteredAmount);
    } catch (e) {
      if (mounted) showErrorSnack(context, e, fallback: 'Could not record settlement');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
