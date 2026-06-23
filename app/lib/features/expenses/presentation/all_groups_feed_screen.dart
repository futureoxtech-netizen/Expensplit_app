import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/pagination/paged_sliver_list.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reactions/presentation/reaction_editor.dart';
import '../data/expense_model.dart';
import '../providers/expense_providers.dart';

class AllGroupsFeedScreen extends ConsumerStatefulWidget {
  const AllGroupsFeedScreen({super.key});

  @override
  ConsumerState<AllGroupsFeedScreen> createState() =>
      _AllGroupsFeedScreenState();
}

class _AllGroupsFeedScreenState extends ConsumerState<AllGroupsFeedScreen> {
  String _selectedCategory = 'all';
  final _scrollCtrl = ScrollController();
  PaginatedScrollListener? _scrollListener;

  static const _categories = [
    'all',
    'food',
    'groceries',
    'transport',
    'shopping',
    'rent',
    'utilities',
    'entertainment',
    'travel',
    'health',
    'gifts',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _scrollListener = PaginatedScrollListener(
      controller: _scrollCtrl,
      onLoadMore: () => ref.read(expenseFeedPagedProvider.notifier).loadMore(),
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
    final state = ref.watch(expenseFeedPagedProvider);
    final notifier = ref.read(expenseFeedPagedProvider.notifier);
    final user = ref.watch(authProvider).user;
    final currency = user?.currency ?? 'PKR';
    final userId = user?.id ?? '';

    // Filter is applied client-side over whatever we've loaded so far.
    // Server-side category filtering for the global feed would be a backend
    // change; for now scrolling continues to surface more matches as new
    // pages arrive.
    final loaded = state.items ?? const <ExpenseModel>[];
    final filtered = _selectedCategory == 'all'
        ? loaded
        : loaded.where((e) => e.category == _selectedCategory).toList();
    final myTotal = filtered.fold<double>(0, (acc, e) {
      return acc +
          e.shares
              .where((s) => s.user.id == userId)
              .fold<double>(0, (a, s) => a + s.amount);
    });

    return GradientScaffold(
      padding: EdgeInsets.zero,
      child: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: const Text('All Groups'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _CategoryChips(
                  selected: _selectedCategory,
                  onChanged: (c) => setState(() => _selectedCategory = c),
                ),
              ),
            ),
            // Header — only shown once items are loaded.
            if (state.items != null && filtered.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: _SummaryCard(
                    total: myTotal,
                    count: filtered.length,
                    currency: currency,
                  ),
                ),
              ),
            PagedSliverList<ExpenseModel>(
              state: state,
              onLoadFirst: notifier.loadFirst,
              onRetryMore: notifier.loadMore,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              firstPageBuilder: (ctx, s) => s.error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(friendlyError(s.error))),
                    )
                  : const ShimmerLoader(),
              emptyBuilder: (ctx) => const SizedBox(
                height: 320,
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No expenses',
                  subtitle: 'Add an expense in any group to see it here.',
                ),
              ),
              // The filter is applied above, but PagedSliverList renders
              // `state.items` directly. To honor the filter we provide a
              // custom builder that skips non-matching items by returning
              // an empty widget. Items still load in chunks; matching ones
              // accumulate as the user scrolls.
              itemBuilder: (ctx, e, _) {
                if (_selectedCategory != 'all' &&
                    e.category != _selectedCategory) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  // Stable per-target key so each row's ReactionEditor State
                  // (which holds optimistic reaction state) stays bound to its
                  // expense across list reloads/reorders — otherwise an
                  // optimistic reaction can land on a different row.
                  key: ValueKey('feed-expense-${e.id}'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExpenseTile(
                    expense: e,
                    userId: userId,
                    currency: currency,
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

// ─── Category chips ───────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  static const _cats = [
    'all',
    'food',
    'groceries',
    'transport',
    'shopping',
    'rent',
    'utilities',
    'entertainment',
    'travel',
    'health',
    'gifts',
    'other',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _cats[i];
          final isSelected = cat == selected;
          return ChoiceChip(
            label: Text(cat == 'all' ? 'All' : cat),
            selected: isSelected,
            onSelected: (_) => onChanged(cat),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : null,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              fontSize: 13,
            ),
          );
        },
      ),
    );
  }
}

// ─── Summary hero card ────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.total, required this.count, required this.currency});
  final double total;
  final int count;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My share total',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  Money.format(total, code: currency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count item${count == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Expense tile ─────────────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.userId,
    required this.currency,
  });

  final ExpenseModel expense;
  final String userId;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final myShare = expense.shares
        .where((s) => s.user.id == userId)
        .fold<double>(0, (a, s) => a + s.amount);

    final groupLabel = expense.groupName ?? '';
    final paidByName = expense.paidBy.name.split(' ').first;
    final subtitle =
        [if (groupLabel.isNotEmpty) groupLabel, paidByName].join(' · ');

    return ReactionEditor(
      targetType: 'expense',
      targetId: expense.id,
      groupId: expense.groupId,
      reactions: expense.reactions,
      borderRadius: 16,
      onTap: () => context.push('/expenses/${expense.id}'),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category icon
              CategoryIcon(category: expense.category, size: 42),
              const SizedBox(width: 12),

              // Name + group/paidBy
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // My share + total (constrained to avoid overflow)
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Money.format(myShare, code: currency),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'of ${Money.format(expense.amount, code: currency)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.45),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}
