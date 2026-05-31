import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/pagination/paged_sliver_list.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/goal_model.dart';
import '../providers/goals_provider.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String? _statusFilter; // null = all
  final _scrollCtrl = ScrollController();
  PaginatedScrollListener? _scrollListener;
  String? _lastFilter;

  @override
  void initState() {
    super.initState();
    _attachScrollListener();
  }

  void _attachScrollListener() {
    _scrollListener?.dispose();
    _scrollListener = PaginatedScrollListener(
      controller: _scrollCtrl,
      onLoadMore: () => ref
          .read(goalsListPagedProvider(_statusFilter).notifier)
          .loadMore(),
    );
  }

  @override
  void dispose() {
    _scrollListener?.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(goalsListProvider(_statusFilter));
    await ref.read(goalsListPagedProvider(_statusFilter).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    // Re-bind the scroll listener whenever the filter changes — the family
    // notifier instance is keyed on `_statusFilter`.
    if (_lastFilter != _statusFilter) {
      _lastFilter = _statusFilter;
      _attachScrollListener();
    }

    final headerAsync = ref.watch(goalsListProvider(_statusFilter));
    final pagedState = ref.watch(goalsListPagedProvider(_statusFilter));
    final pagedNotifier =
        ref.read(goalsListPagedProvider(_statusFilter).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Stats header — comes from the legacy single-page provider so
            // we get accurate totals even before any list page loads.
            SliverToBoxAdapter(
              child: headerAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: ShimmerLoader(height: 120, count: 1),
                ),
                error: (e, _) => ErrorView(
                  error: e,
                  compact: true,
                  onRetry: () => ref.invalidate(goalsListProvider(_statusFilter)),
                ),
                data: (page) =>
                    page.items.isEmpty
                        ? const SizedBox.shrink()
                        : _StatsHeader(
                            page: page,
                            currency: ref.watch(authProvider).user?.currency ?? 'PKR',
                          ),
              ),
            ),
            SliverToBoxAdapter(
              child: _FilterChips(
                selected: _statusFilter,
                onChanged: (s) => setState(() => _statusFilter = s),
              ),
            ),
            PagedSliverList<GoalModel>(
              state: pagedState,
              onLoadFirst: pagedNotifier.loadFirst,
              onRetryMore: pagedNotifier.loadMore,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              firstPageBuilder: (ctx, s) => s.error != null
                  ? ErrorView(
                      error: s.error,
                      onRetry: pagedNotifier.loadFirst,
                    )
                  : const ShimmerLoader(),
              emptyBuilder: (ctx) => const Padding(
                padding: EdgeInsets.only(top: 60),
                child: EmptyState(
                  icon: Icons.flag_rounded,
                  title: 'No goals yet',
                  subtitle: 'Tap + to set your first savings goal.',
                ),
              ),
              separator: const SizedBox(height: 12),
              itemBuilder: (ctx, goal, _) => _GoalCard(
                goal: goal,
                onTap: () {
                  () async {
                    await context.push('/goals/${goal.id}');
                    await _refreshAll();
                  }();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => CreateGoalSheet(
        onCreated: () {
          _refreshAll();
        },
      ),
    );
  }
}

// ─── Stats header ─────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.page, required this.currency});
  final GoalsPage page;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final pct = page.totalTarget > 0
        ? (page.totalSaved / page.totalTarget).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Total saved',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${page.activeCount} active · ${page.completedCount} done',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            Money.format(page.totalSaved, code: currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'of ${Money.format(page.totalTarget, code: currency)} total target',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).toStringAsFixed(1)}% of target reached',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Filter chips ─────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  static const _filters = <String?, String>{
    null: 'All',
    'active': 'Active',
    'paused': 'Paused',
    'completed': 'Completed',
    'abandoned': 'Abandoned',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final e in _filters.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(e.value),
                selected: selected == e.key,
                onSelected: (_) => onChanged(e.key),
                selectedColor: AppColors.primary.withOpacity(0.18),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontWeight: selected == e.key ? FontWeight.w700 : FontWeight.w500,
                  color: selected == e.key ? AppColors.primary : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Goal card ────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.onTap});
  final GoalModel goal;
  final VoidCallback onTap;

  Color get _goalColor {
    try {
      return Color(int.parse(goal.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = _goalColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Emoji badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.withOpacity(isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(goal.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            GoalStatusBadge(status: goal.status),
                            const SizedBox(width: 8),
                            if (goal.targetDate != null)
                              Text(
                                _daysLabel(goal.targetDate!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Money.format(goal.savedAmount, code: goal.currency),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: c,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'of ${Money.format(goal.targetAmount, code: goal.currency)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  backgroundColor: c.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(c),
                  minHeight: 7,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${(goal.progress * 100).toStringAsFixed(1)}% saved',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${Money.format(goal.remaining, code: goal.currency)} left',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _daysLabel(DateTime target) {
    final days = target.difference(DateTime.now()).inDays;
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Due today';
    if (days == 1) return '1 day left';
    return '$days days left';
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class GoalStatusBadge extends StatelessWidget {
  const GoalStatusBadge({super.key, required this.status});
  final String status;

  static const _colors = {
    'active': Color(0xFF00B894),
    'completed': Color(0xFF6C5CE7),
    'paused': Color(0xFFFFC857),
    'abandoned': Color(0xFFFF6B6B),
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors[status] ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create / Edit Goal Sheet
// ─────────────────────────────────────────────────────────────────────────────

class CreateGoalSheet extends ConsumerStatefulWidget {
  const CreateGoalSheet({super.key, this.existing, required this.onCreated});
  final GoalModel? existing;
  final VoidCallback onCreated;

  @override
  ConsumerState<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends ConsumerState<CreateGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;

  String _emoji = '🎯';
  String _category = 'other';
  String _priority = 'medium';
  String _color = '#6C5CE7';
  DateTime? _targetDate;
  bool _loading = false;

  static const _categories = [
    ('house', '🏠', 'House'),
    ('car', '🚗', 'Car'),
    ('vacation', '✈️', 'Vacation'),
    ('emergency', '🛡️', 'Emergency'),
    ('education', '🎓', 'Education'),
    ('device', '📱', 'Device'),
    ('health', '❤️', 'Health'),
    ('wedding', '💍', 'Wedding'),
    ('business', '💼', 'Business'),
    ('other', '🎯', 'Other'),
  ];

  static const _colors = [
    '#6C5CE7', '#00B894', '#0984E3', '#E17055',
    '#FDCB6E', '#D63031', '#6D214F', '#2D3436',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl  = TextEditingController(text: e?.title ?? '');
    _descCtrl   = TextEditingController(text: e?.description ?? '');
    _amountCtrl = TextEditingController(text: e != null ? e.targetAmount.toStringAsFixed(2) : '');
    _notesCtrl  = TextEditingController(text: e?.notes ?? '');
    if (e != null) {
      _emoji = e.emoji;
      _category = e.category;
      _priority = e.priority;
      _color = e.color;
      _targetDate = e.targetDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(goalsRepositoryProvider);
      final amount = double.parse(_amountCtrl.text.replaceAll(',', ''));
      // Use the existing goal's currency on edit; on create, default to the
      // user's profile currency so new goals match every other amount the
      // user sees in the app.
      final userCurrency = ref.read(authProvider).user?.currency ?? 'PKR';
      final currency = widget.existing?.currency ?? userCurrency;
      if (widget.existing == null) {
        await repo.create(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          emoji: _emoji,
          category: _category,
          targetAmount: amount,
          currency: currency,
          targetDate: _targetDate,
          priority: _priority,
          color: _color,
          notes: _notesCtrl.text.trim(),
        );
      } else {
        await repo.update(
          widget.existing!.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          emoji: _emoji,
          category: _category,
          targetAmount: amount,
          currency: currency,
          targetDate: _targetDate,
          clearTargetDate: _targetDate == null,
          priority: _priority,
          color: _color,
          notes: _notesCtrl.text.trim(),
        );
      }
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;
    final currencyCode =
        widget.existing?.currency ?? ref.watch(authProvider).user?.currency ?? 'PKR';
    final currencySymbol = Money.symbolOf(currencyCode);

    return Padding(
      padding: EdgeInsets.zero,
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title row
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickEmoji,
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: _goalColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(_emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Goal' : 'New Goal',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Goal name
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Goal name *',
                  hintText: 'e.g. New MacBook Pro',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a goal name' : null,
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Why is this goal important to you?',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),

              // Target amount
              TextFormField(
                controller: _amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Target amount *',
                  hintText: '0.00',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      currencySymbol,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 20),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a target amount';
                  final n = double.tryParse(v.replaceAll(',', ''));
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Target date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded, color: AppColors.primary),
                title: Text(
                  _targetDate == null
                      ? 'No target date'
                      : 'By ${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _targetDate != null ? AppColors.primary : null,
                  ),
                ),
                subtitle: const Text('Helps calculate how much to save per day'),
                trailing: _targetDate != null
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _targetDate = null),
                      )
                    : null,
                onTap: _pickDate,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const Divider(),
              const SizedBox(height: 4),

              // Category
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _categories)
                    _CategoryChip(
                      emoji: c.$2,
                      label: c.$3,
                      selected: _category == c.$1,
                      onTap: () => setState(() {
                        _category = c.$1;
                        if (_emoji == '🎯' || _categories.any((x) => x.$2 == _emoji)) {
                          _emoji = c.$2;
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Priority
              const Text('Priority', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              _PrioritySelector(
                value: _priority,
                onChanged: (v) => setState(() => _priority = v),
              ),
              const SizedBox(height: 16),

              // Color
              const Text('Card color', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  for (final c in _colors)
                    _ColorDot(
                      hex: c,
                      selected: _color == c,
                      onTap: () => setState(() => _color = c),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Any extra details...',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isEdit ? 'Save Changes' : 'Create Goal',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _goalColor {
    try {
      return Color(int.parse(_color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _pickEmoji() async {
    const emojis = ['🎯', '🏠', '🚗', '✈️', '🎓', '📱', '💍', '💼',
                    '❤️', '🛡️', '⭐', '🌟', '💰', '🎮', '🏋️', '🎸',
                    '🌴', '🍕', '🎂', '🏆', '🎨', '📚', '🚀', '💡'];
    final picked = await showAppFixedSheet<String>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSheetHandle(),
            const Text('Choose emoji',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                for (final e in emojis)
                  GestureDetector(
                    onTap: () => Navigator.pop(context, e),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _emoji = picked);
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.emoji, required this.label,
    required this.selected, required this.onTap,
  });
  final String emoji, label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : null,
                )),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.hex, required this.selected, required this.onTap});
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Color(int.parse(hex.replaceFirst('#', '0xFF')));
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: selected ? 34 : 28,
        height: selected ? 34 : 28,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: selected
              ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
              : [],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  static const _options = <(String, String, IconData, Color)>[
    ('low', 'Low', Icons.arrow_downward_rounded, Color(0xFF44C4FF)),
    ('medium', 'Medium', Icons.remove_rounded, Color(0xFF00B894)),
    ('high', 'High', Icons.arrow_upward_rounded, Color(0xFFFF6B6B)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final o in _options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.$1),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: value == o.$1 ? o.$4 : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        o.$3,
                        size: 16,
                        color: value == o.$1 ? Colors.white : cs.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          o.$2,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: value == o.$1
                                ? Colors.white
                                : cs.onSurface.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
