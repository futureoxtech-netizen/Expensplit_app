import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/providers/auth_provider.dart';
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
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(expenseFeedProvider);
    final user = ref.watch(authProvider).user;
    final currency = user?.currency ?? 'USD';
    final userId = user?.id ?? '';

    return GradientScaffold(
      padding: EdgeInsets.zero,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(expenseFeedProvider),
        child: CustomScrollView(
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
                  onChanged: (c) =>
                      setState(() => _selectedCategory = c),
                ),
              ),
            ),
            feedAsync.when(
              loading: () => const SliverFillRemaining(
                child: ShimmerLoader(),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text(friendlyError(e))),
              ),
              data: (page) {
                final filtered = _selectedCategory == 'all'
                    ? page.items
                    : page.items
                        .where((e) => e.category == _selectedCategory)
                        .toList();

                if (filtered.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No expenses',
                      subtitle:
                          'No expenses found for this category.',
                    ),
                  );
                }

                // Compute my total share for filtered expenses
                final myTotal = filtered.fold<double>(0, (acc, e) {
                  return acc +
                      e.shares
                          .where((s) => s.user.id == userId)
                          .fold<double>(0, (a, s) => a + s.amount);
                });

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 12),
                      // Summary hero card
                      _SummaryCard(
                        total: myTotal,
                        count: filtered.length,
                        currency: currency,
                      ),
                      const SizedBox(height: 16),
                      for (final expense in filtered)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ExpenseTile(
                            expense: expense,
                            userId: userId,
                            currency: currency,
                          ),
                        ),
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

// ─── Category chips ───────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips(
      {required this.selected, required this.onChanged});

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
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.normal,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        [if (groupLabel.isNotEmpty) groupLabel, paidByName]
            .join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }
}
