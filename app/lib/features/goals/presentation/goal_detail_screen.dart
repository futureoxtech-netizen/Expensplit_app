import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../data/goal_model.dart';
import '../providers/goals_provider.dart';
import 'goals_screen.dart' show CreateGoalSheet, GoalStatusBadge;

// ─── Goal Detail Screen ───────────────────────────────────────────────────────

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(goalDetailProvider(goalId));

    return async.when(
      loading: () => const Scaffold(body: Padding(padding: EdgeInsets.all(16), child: ShimmerLoader())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (goal) => _GoalDetailBody(goal: goal),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _GoalDetailBody extends ConsumerStatefulWidget {
  const _GoalDetailBody({required this.goal});
  final GoalModel goal;

  @override
  ConsumerState<_GoalDetailBody> createState() => _GoalDetailBodyState();
}

class _GoalDetailBodyState extends ConsumerState<_GoalDetailBody> {
  late GoalModel _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
  }

  Color get _goalColor {
    try {
      return Color(int.parse(_goal.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = _goalColor;
    final sortedContribs = [..._goal.contributions]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      floatingActionButton: (_goal.isActive || _goal.isPaused) && !_goal.isCompleted
          ? FloatingActionButton.extended(
              onPressed: () => _showAddContribution(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add money'),
              backgroundColor: c,
              foregroundColor: Colors.white,
            )
          : null,
      body: CustomScrollView(
      slivers: [
        // ── App bar ──────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c, c.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(_goal.emoji, style: const TextStyle(fontSize: 52)),
                    const SizedBox(height: 8),
                    Text(
                      _goal.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    GoalStatusBadge(status: _goal.status),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: () => _showEditSheet(context),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onSelected: (v) => _handleMenu(context, v),
              itemBuilder: (_) => [
                if (_goal.isActive)
                  const PopupMenuItem(value: 'pause', child: Text('Pause goal')),
                if (_goal.isPaused)
                  const PopupMenuItem(value: 'resume', child: Text('Resume goal')),
                if (!_goal.isAbandoned)
                  const PopupMenuItem(
                    value: 'abandon',
                    child: Text('Abandon goal', style: TextStyle(color: AppColors.danger)),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete goal', style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          ],
        ),

        // ── Progress ring card ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: _ProgressCard(goal: _goal, color: c),
          ),
        ),

        // ── Calculator card ───────────────────────────────────────────────────
        if (_goal.isActive && _goal.stats.dailyNeeded != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _CalculatorCard(goal: _goal),
            ),
          ),

        // ── Stats row ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _StatsRow(goal: _goal, color: c),
          ),
        ),

        // ── Contributions section ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                const Text('Contributions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  '${_goal.contributions.length} total',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (sortedContribs.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No contributions yet.\nTap + to add your first one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverList.separated(
              itemCount: sortedContribs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ContributionRow(
                contribution: sortedContribs[i],
                currency: _goal.currency,
                color: c,
                onDelete: () => _deleteContribution(context, sortedContribs[i].id),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    ), // end CustomScrollView
    ); // end Scaffold
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _showAddContribution(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddContributionSheet(
        goal: _goal,
        onAdded: (updated) => setState(() => _goal = updated),
      ),
    );
  }

  Future<void> _showEditSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => CreateGoalSheet(
        existing: _goal,
        onCreated: () async {
          final updated = await ref.read(goalsRepositoryProvider).getById(_goal.id);
          setState(() => _goal = updated);
        },
      ),
    );
  }

  Future<void> _handleMenu(BuildContext context, String action) async {
    final repo = ref.read(goalsRepositoryProvider);
    switch (action) {
      case 'pause':
        final g = await repo.update(_goal.id, status: 'paused');
        setState(() => _goal = g);
      case 'resume':
        final g = await repo.update(_goal.id, status: 'active');
        setState(() => _goal = g);
      case 'abandon':
        final ok = await _confirm(context, 'Abandon goal?',
            'You can still view this goal but won\'t be able to add contributions.');
        if (ok == true) {
          final g = await repo.update(_goal.id, status: 'abandoned');
          setState(() => _goal = g);
        }
      case 'delete':
        final ok = await _confirm(context, 'Delete goal?',
            'All contributions will be deleted. This cannot be undone.');
        if (ok == true && context.mounted) {
          await repo.delete(_goal.id);
          Navigator.pop(context);
        }
    }
  }

  Future<void> _deleteContribution(BuildContext context, String cId) async {
    final ok = await _confirm(context, 'Remove contribution?',
        'This contribution will be subtracted from your saved amount.');
    if (ok != true) return;
    try {
      final updated = await ref.read(goalsRepositoryProvider).removeContribution(_goal.id, cId);
      setState(() => _goal = updated);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<bool?> _confirm(BuildContext context, String title, String body) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );
}

// ─── Progress ring card ───────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.goal, required this.color});
  final GoalModel goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          // Progress ring
          SizedBox(
            width: 90,
            height: 90,
            child: CustomPaint(
              painter: _RingPainter(progress: goal.progress, color: color),
              child: Center(
                child: Text(
                  '${(goal.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AmountRow(label: 'Saved', value: goal.savedAmount, currency: goal.currency, color: color),
                const SizedBox(height: 8),
                _AmountRow(label: 'Target', value: goal.targetAmount, currency: goal.currency),
                const SizedBox(height: 8),
                _AmountRow(label: 'Remaining', value: goal.remaining, currency: goal.currency,
                    color: AppColors.danger),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value, required this.currency, this.color});
  final String label;
  final double value;
  final String currency;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        const Spacer(),
        Text(
          Money.format(value, code: currency),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius  = size.width / 2 - 6;
    final stroke  = 8.0;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Calculator card ──────────────────────────────────────────────────────────

class _CalculatorCard extends StatelessWidget {
  const _CalculatorCard({required this.goal});
  final GoalModel goal;

  @override
  Widget build(BuildContext context) {
    final s = goal.stats;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              const Text('Savings calculator',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
              if (goal.targetDate != null) ...[
                const Spacer(),
                Text(
                  '${s.daysLeft} days left',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (s.dailyNeeded != null)
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _CalcChip(label: 'Per day',   value: Money.format(s.dailyNeeded!, code: goal.currency)),
                _CalcChip(label: 'Per week',  value: Money.format(s.weeklyNeeded!, code: goal.currency)),
                _CalcChip(label: 'Per month', value: Money.format(s.monthlyNeeded!, code: goal.currency)),
              ],
            ),
          if (s.projectedCompletionDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'At current pace, done by ${_fmt(s.projectedCompletionDate!)}',
              style: const TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

class _CalcChip extends StatelessWidget {
  const _CalcChip({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.primary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.goal, required this.color});
  final GoalModel goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final created = goal.createdAt;
    final days = DateTime.now().difference(created).inDays;

    return Row(
      children: [
        _StatBox(
          theme: theme,
          icon: Icons.receipt_long_rounded,
          label: 'Contributions',
          value: '${goal.contributions.length}',
          color: color,
        ),
        const SizedBox(width: 10),
        _StatBox(
          theme: theme,
          icon: Icons.calendar_today_rounded,
          label: 'Days active',
          value: '$days',
          color: color,
        ),
        if (goal.targetDate != null) ...[
          const SizedBox(width: 10),
          _StatBox(
            theme: theme,
            icon: Icons.flag_rounded,
            label: 'Target date',
            value: '${goal.targetDate!.day}/${goal.targetDate!.month}/${goal.targetDate!.year}',
            color: color,
          ),
        ],
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.theme, required this.icon, required this.label,
    required this.value, required this.color,
  });
  final ThemeData theme;
  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            Text(label, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.55))),
          ],
        ),
      ),
    );
  }
}

// ─── Contribution row ─────────────────────────────────────────────────────────

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({
    required this.contribution, required this.currency,
    required this.color, required this.onDelete,
  });
  final ContributionModel contribution;
  final String currency;
  final Color color;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(contribution.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Remove contribution?'),
            content: Text('${Money.format(contribution.amount, code: currency)} will be removed from your saved amount.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.savings_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Money.format(contribution.amount, code: currency),
                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  ),
                  if (contribution.note.isNotEmpty)
                    Text(contribution.note,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Text(
              _fmtDate(contribution.date),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month]} ${d.day}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Contribution Sheet (floating action button on detail screen)
// ─────────────────────────────────────────────────────────────────────────────

class AddContributionSheet extends ConsumerStatefulWidget {
  const AddContributionSheet({
    super.key,
    required this.goal,
    required this.onAdded,
  });
  final GoalModel goal;
  final ValueChanged<GoalModel> onAdded;

  @override
  ConsumerState<AddContributionSheet> createState() => _AddContributionSheetState();
}

class _AddContributionSheetState extends ConsumerState<AddContributionSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  DateTime _date    = DateTime.now();
  bool _loading     = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final updated = await ref.read(goalsRepositoryProvider).addContribution(
            widget.goal.id,
            amount: amount,
            note: _noteCtrl.text.trim(),
            date: _date,
          );
      widget.onAdded(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color goalColor;
    try {
      goalColor = Color(int.parse(widget.goal.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      goalColor = AppColors.primary;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
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
                // Goal title row
                Row(
                  children: [
                    Text(widget.goal.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Add contribution',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          Text(widget.goal.title,
                              style: TextStyle(fontSize: 13, color: goalColor,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    // Quick remaining info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Money.format(widget.goal.remaining, code: widget.goal.currency),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: AppColors.danger, fontSize: 13),
                        ),
                        const Text('remaining', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Amount
                TextFormField(
                  controller: _amountCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Amount *',
                    prefixText: '${widget.goal.currency} ',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                ),
                const SizedBox(height: 12),

                // Note
                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'e.g. Birthday money',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),

                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: Text(
                    '${_date.day}/${_date.month}/${_date.year}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Contribution date'),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                ),
                const SizedBox(height: 16),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: goalColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Add Contribution',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
