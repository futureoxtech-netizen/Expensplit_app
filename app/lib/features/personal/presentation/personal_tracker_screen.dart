import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/pagination/paged_sliver_list.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/personal_expense_model.dart';
import '../data/personal_expense_repository.dart';
import '../providers/personal_providers.dart';

// ─── Category helpers ─────────────────────────────────────────────────────────

const _categories = [
  'food',
  'transport',
  'shopping',
  'entertainment',
  'health',
  'bills',
  'education',
  'other',
];

IconData _categoryIcon(String cat) {
  switch (cat) {
    case 'food':
      return Icons.restaurant_rounded;
    case 'transport':
      return Icons.directions_car_rounded;
    case 'shopping':
      return Icons.shopping_bag_rounded;
    case 'entertainment':
      return Icons.movie_rounded;
    case 'health':
      return Icons.favorite_rounded;
    case 'bills':
      return Icons.receipt_long_rounded;
    case 'education':
      return Icons.school_rounded;
    default:
      return Icons.category_rounded;
  }
}

Color _categoryColor(String cat) {
  switch (cat) {
    case 'food':
      return Colors.orange;
    case 'transport':
      return Colors.blue;
    case 'shopping':
      return Colors.pink;
    case 'entertainment':
      return Colors.purple;
    case 'health':
      return Colors.red;
    case 'bills':
      return Colors.teal;
    case 'education':
      return Colors.indigo;
    default:
      return AppColors.primary;
  }
}

// ─── View mode ────────────────────────────────────────────────────────────────

enum _Mode { daily, weekly, monthly, custom }

// ─── Screen ───────────────────────────────────────────────────────────────────

class PersonalTrackerScreen extends ConsumerStatefulWidget {
  const PersonalTrackerScreen({super.key});

  @override
  ConsumerState<PersonalTrackerScreen> createState() =>
      _PersonalTrackerScreenState();
}

class _PersonalTrackerScreenState extends ConsumerState<PersonalTrackerScreen> {
  _Mode _mode = _Mode.daily;
  DateTime _anchor = DateTime.now();
  DateTimeRange? _customRange;
  final _scrollCtrl = ScrollController();
  PaginatedScrollListener? _scrollListener;
  (DateTime, DateTime)? _lastRangeKey;

  @override
  void dispose() {
    _scrollListener?.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _ensureScrollListener((DateTime, DateTime) range) {
    if (_lastRangeKey == range) return;
    _lastRangeKey = range;
    _scrollListener?.dispose();
    _scrollListener = PaginatedScrollListener(
      controller: _scrollCtrl,
      onLoadMore: () =>
          ref.read(personalExpensesPagedProvider(range).notifier).loadMore(),
    );
  }

  String _periodKey(PersonalExpenseModel e) {
    switch (_mode) {
      case _Mode.daily:
        return 'all';
      case _Mode.weekly:
        return '${_dayName(e.date.weekday)}, ${e.date.day} ${_monthShort(e.date.month)}';
      case _Mode.monthly:
        final wk = ((e.date.day - 1) ~/ 7) + 1;
        return 'Week $wk';
      case _Mode.custom:
        return '${e.date.day} ${_monthShort(e.date.month)}';
    }
  }

  DateTimeRange get _range {
    if (_mode == _Mode.daily) {
      final d = DateTime(_anchor.year, _anchor.month, _anchor.day);
      return DateTimeRange(start: d, end: d.add(const Duration(days: 1)));
    } else if (_mode == _Mode.weekly) {
      final weekday = _anchor.weekday;
      final start = _anchor.subtract(Duration(days: weekday - 1));
      final s = DateTime(start.year, start.month, start.day);
      return DateTimeRange(start: s, end: s.add(const Duration(days: 7)));
    } else if (_mode == _Mode.monthly) {
      final s = DateTime(_anchor.year, _anchor.month, 1);
      return DateTimeRange(
          start: s, end: DateTime(_anchor.year, _anchor.month + 1, 1));
    } else {
      if (_customRange != null) return _customRange!;
      final d = DateTime.now();
      return DateTimeRange(
          start: DateTime(d.year, d.month, 1),
          end: DateTime(d.year, d.month + 1, 1));
    }
  }

  String get _rangeLabel {
    if (_mode == _Mode.daily) {
      final now = DateTime.now();
      if (_anchor.year == now.year &&
          _anchor.month == now.month &&
          _anchor.day == now.day) return 'Today';
      return '${_dayName(_anchor.weekday)}, ${_anchor.day} ${_monthShort(_anchor.month)}';
    } else if (_mode == _Mode.weekly) {
      final r = _range;
      final end = r.end.subtract(const Duration(days: 1));
      return '${r.start.day} ${_monthShort(r.start.month)} – ${end.day} ${_monthShort(end.month)}';
    } else if (_mode == _Mode.monthly) {
      return '${_monthShort(_anchor.month)} ${_anchor.year}';
    } else {
      if (_customRange == null) return 'Pick range';
      final s = _customRange!.start;
      final e = _customRange!.end;
      return '${s.day} ${_monthShort(s.month)} – ${e.day} ${_monthShort(e.month)}';
    }
  }

  void _prev() {
    if (_mode == _Mode.custom) return;
    setState(() {
      if (_mode == _Mode.daily) {
        _anchor = _anchor.subtract(const Duration(days: 1));
      } else if (_mode == _Mode.weekly) {
        _anchor = _anchor.subtract(const Duration(days: 7));
      } else if (_mode == _Mode.monthly) {
        _anchor = DateTime(_anchor.year, _anchor.month - 1, 1);
      }
    });
  }

  void _next() {
    if (_mode == _Mode.custom) return;
    setState(() {
      if (_mode == _Mode.daily) {
        _anchor = _anchor.add(const Duration(days: 1));
      } else if (_mode == _Mode.weekly) {
        _anchor = _anchor.add(const Duration(days: 7));
      } else if (_mode == _Mode.monthly) {
        _anchor = DateTime(_anchor.year, _anchor.month + 1, 1);
      }
    });
  }

  Future<void> _pickCustomRange(BuildContext ctx) async {
    final picked = await showDateRangePicker(
      context: ctx,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _customRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final currency = user?.currency ?? 'PKR';
    final r = _range;
    final rangeKey = (r.start, r.end);
    _ensureScrollListener(rangeKey);
    final pagedState = ref.watch(personalExpensesPagedProvider(rangeKey));
    final pagedNotifier =
        ref.read(personalExpensesPagedProvider(rangeKey).notifier);
    final theme = Theme.of(context);
    final loadedItems = pagedState.items ?? const <PersonalExpenseModel>[];
    final loadedTotal = loadedItems.fold<double>(0, (a, e) => a + e.amount);
    final byCategory = <String, double>{};
    for (final e in loadedItems) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Personal Tracker',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeBtn(
                            label: 'Daily',
                            selected: _mode == _Mode.daily,
                            onTap: () => setState(() {
                              _mode = _Mode.daily;
                              _anchor = DateTime.now();
                            }),
                          ),
                        ),
                        Expanded(
                          child: _ModeBtn(
                            label: 'Weekly',
                            selected: _mode == _Mode.weekly,
                            onTap: () => setState(() {
                              _mode = _Mode.weekly;
                              _anchor = DateTime.now();
                            }),
                          ),
                        ),
                        Expanded(
                          child: _ModeBtn(
                            label: 'Monthly',
                            selected: _mode == _Mode.monthly,
                            onTap: () => setState(() {
                              _mode = _Mode.monthly;
                              _anchor = DateTime.now();
                            }),
                          ),
                        ),
                        Expanded(
                          child: _ModeBtn(
                            label: 'Custom',
                            selected: _mode == _Mode.custom,
                            onTap: () async {
                              setState(() => _mode = _Mode.custom);
                              await _pickCustomRange(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_mode != _Mode.custom)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: _prev,
                          style: IconButton.styleFrom(
                              visualDensity: VisualDensity.compact),
                        ),
                        Text(_rangeLabel,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: _next,
                          style: IconButton.styleFrom(
                              visualDensity: VisualDensity.compact),
                        ),
                      ],
                    )
                  else
                    Center(
                      child: InkWell(
                        onTap: () => _pickCustomRange(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_month_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(_rangeLabel,
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              const Icon(Icons.expand_more_rounded,
                                  size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Header (total + category bar) — derived from items loaded so
          // far. While more pages remain, the figures reflect the loaded
          // portion; the spinner footer + "loaded N of M" feel makes the
          // partial state self-evident.
          if (pagedState.items != null && loadedItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TotalCard(total: loadedTotal, currency: currency),
                    const SizedBox(height: 16),
                    if (byCategory.isNotEmpty)
                      _CategoryBar(
                        byCategory: byCategory,
                        total: loadedTotal,
                        currency: currency,
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          PagedSliverList<PersonalExpenseModel>(
            state: pagedState,
            onLoadFirst: pagedNotifier.loadFirst,
            onRetryMore: pagedNotifier.loadMore,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            firstPageBuilder: (ctx, s) => s.error != null
                ? ErrorView(
                    error: s.error,
                    onRetry: pagedNotifier.loadFirst,
                  )
                : const ShimmerLoader(),
            emptyBuilder: (ctx) => Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 80),
              child: Column(
                children: [
                  _TotalCard(total: 0, currency: currency),
                  const SizedBox(height: 24),
                  const EmptyState(
                    icon: Icons.wallet_outlined,
                    title: 'No expenses',
                    subtitle: 'Tap + to add your first expense.',
                  ),
                ],
              ),
            ),
            itemBuilder: (ctx, e, i) {
              // Inline period header when the grouping key changes. Avoids
              // the up-front "group everything" pass that doesn't compose
              // with paged delivery.
              final prev = i > 0 ? loadedItems[i - 1] : null;
              final headerLabel = _periodKey(e);
              final prevHeader = prev != null ? _periodKey(prev) : null;
              final showHeader =
                  _mode != _Mode.daily && headerLabel != prevHeader;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader) ...[
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                      child: Text(
                        headerLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _ExpenseRow(
                    expense: e,
                    currency: currency,
                    onDelete: () async {
                      await ref
                          .read(personalExpenseRepositoryProvider)
                          .delete(e.id);
                      await pagedNotifier.refresh();
                      ref.invalidate(personalExpenseListProvider);
                    },
                    onTap: () => _showRowActions(context, currency, e),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, currency),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddSheet(BuildContext context, String currency,
      {PersonalExpenseModel? existing}) {
    final r = _range;
    showAppSheet(
      context: context,
      builder: (_) => _AddExpenseSheet(
        currency: currency,
        existing: existing,
        onSaved: () {
          ref.invalidate(personalExpenseListProvider);
          // Refresh the visible paged list so the new/edited record shows
          // immediately (the legacy provider is only consumed by reports).
          ref
              .read(personalExpensesPagedProvider((r.start, r.end)).notifier)
              .refresh();
        },
        ref: ref,
      ),
    );
  }

  /// Bottom sheet shown when a row is tapped — gives the user a discoverable
  /// way to edit or delete (swipe-to-delete alone was not obvious enough).
  void _showRowActions(
    BuildContext context,
    String currency,
    PersonalExpenseModel e,
  ) {
    showAppFixedSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(sheetCtx).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _categoryColor(e.category).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _categoryIcon(e.category),
                      size: 20,
                      color: _categoryColor(e.category),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          Money.format(e.amount, code: currency),
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(sheetCtx)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showAddSheet(context, currency, existing: e);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
              title: const Text('Delete',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(sheetCtx);
                // Use the dialog's own context for pop — using the outer
                // screen context can leave the dialog barrier visible if the
                // outer context is deactivated during the dialog animation.
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Delete expense?'),
                    content: Text('Remove "${e.description}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  try {
                    await ref
                        .read(personalExpenseRepositoryProvider)
                        .delete(e.id);
                    // Refresh the paged list shown on screen AND the
                    // dashboard aggregation provider.
                    final r = _range;
                    await ref
                        .read(personalExpensesPagedProvider((r.start, r.end))
                            .notifier)
                        .refresh();
                    ref.invalidate(personalExpenseListProvider);
                  } catch (err) {
                    if (context.mounted) {
                      showErrorSnack(context, err,
                          fallback: 'Could not delete expense');
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  static String _dayName(int d) {
    const n = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return n[d];
  }

  static String _monthShort(int m) {
    const n = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return n[m];
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _ModeBtn extends StatelessWidget {
  const _ModeBtn(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? Colors.white : null,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            )),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.currency});
  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total spent',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(Money.format(total, code: currency),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.wallet_rounded, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.byCategory,
    required this.total,
    required this.currency,
  });
  final Map<String, double> byCategory;
  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('By category',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 10),
        for (final entry in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _categoryColor(entry.key).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_categoryIcon(entry.key),
                      size: 16, color: _categoryColor(entry.key)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            entry.key[0].toUpperCase() + entry.key.substring(1),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            Money.format(entry.value, code: currency),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total > 0 ? entry.value / total : 0,
                          backgroundColor:
                              _categoryColor(entry.key).withOpacity(0.1),
                          valueColor:
                              AlwaysStoppedAnimation(_categoryColor(entry.key)),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.currency,
    required this.onDelete,
    required this.onTap,
  });
  final PersonalExpenseModel expense;
  final String currency;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Delete expense?'),
            content: Text('Remove "${expense.description}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, true),
                  child: const Text('Delete',
                      style: TextStyle(color: AppColors.danger))),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _categoryColor(expense.category).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_categoryIcon(expense.category),
                      size: 20, color: _categoryColor(expense.category)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.description,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                          expense.category[0].toUpperCase() +
                              expense.category.substring(1),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Text(Money.format(expense.amount, code: currency),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Add expense sheet ────────────────────────────────────────────────────────

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({
    required this.currency,
    required this.onSaved,
    required this.ref,
    this.existing,
  });
  final String currency;
  final VoidCallback onSaved;
  final WidgetRef ref;
  final PersonalExpenseModel? existing;

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amtCtrl;
  late String _category;
  late DateTime _date;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _amtCtrl = TextEditingController(
        text: e != null ? e.amount.toStringAsFixed(2) : '');
    _category = e?.category ?? 'food';
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_isEdit ? 'Edit Expense' : 'Add Expense',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: InputDecoration(
              labelText: 'Description',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount (${widget.currency})',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(
              labelText: 'Category',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: _categories
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(_categoryIcon(c),
                              size: 16, color: _categoryColor(c)),
                          const SizedBox(width: 8),
                          Text(c[0].toUpperCase() + c.substring(1)),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('${_date.day}/${_date.month}/${_date.year}',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(_isEdit ? 'Save changes' : 'Save',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final desc = _descCtrl.text.trim();
    final amt = double.tryParse(_amtCtrl.text.trim());
    if (desc.isEmpty || amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a valid description and amount')));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = widget.ref.read(personalExpenseRepositoryProvider);
      if (_isEdit) {
        await repo.update(
          widget.existing!.id,
          description: desc,
          amount: amt,
          currency: widget.currency,
          category: _category,
          date: _date,
        );
      } else {
        await repo.create(
          description: desc,
          amount: amt,
          currency: widget.currency,
          category: _category,
          date: _date,
        );
      }
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(_isEdit ? 'Changes saved!' : 'Expense recorded!'),
          ]),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
