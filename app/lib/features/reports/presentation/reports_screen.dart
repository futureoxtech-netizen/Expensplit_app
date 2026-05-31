import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../personal/data/personal_expense_model.dart';
import '../../personal/providers/personal_providers.dart';
import '../data/report_exporter.dart';
import '../data/report_model.dart';
import '../providers/report_providers.dart';

enum _ReportSource { groups, personal, combined }

enum ReportPeriod { day, week, month, year, custom }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.month;
  _ReportSource _source = _ReportSource.groups;
  DateTime _customFrom = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
      .subtract(const Duration(days: 30));
  DateTime _customTo =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59);
  bool _exporting = false;

  // Cached so the Riverpod query key stays stable between rebuilds.
  late (DateTime, DateTime, String) _cachedRange = _computeRange();

  @override
  void didUpdateWidget(covariant ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _setPeriod(ReportPeriod p) {
    setState(() {
      _period = p;
      _cachedRange = _computeRange();
    });
  }

  (DateTime, DateTime, String) _computeRange() {
    final now = DateTime.now();
    // Snap "now" to the end of today so the key is stable across rebuilds.
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_period) {
      case ReportPeriod.day:
        return (DateTime(now.year, now.month, now.day), endOfToday, 'Today');
      case ReportPeriod.week:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        return (start, endOfToday, 'This week');
      case ReportPeriod.month:
        return (DateTime(now.year, now.month, 1), endOfToday, 'This month');
      case ReportPeriod.year:
        return (DateTime(now.year, 1, 1), endOfToday, 'Year to date');
      case ReportPeriod.custom:
        final df = DateFormat('MMM d');
        return (_customFrom, _customTo, '${df.format(_customFrom)} – ${df.format(_customTo)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final currency = user?.currency ?? 'PKR';
    final (from, to, label) = _cachedRange;
    final groupAsync = ref.watch(reportProvider(ReportQuery(from: from, to: to)));
    final personalAsync = (_source != _ReportSource.groups)
        ? ref.watch(personalExpenseListProvider((from, to)))
        : const AsyncValue<List<PersonalExpenseModel>>.data([]);

    // Resolve the correct AsyncValue<ReportData> based on the selected source
    final AsyncValue<ReportData> async;
    switch (_source) {
      case _ReportSource.groups:
        async = groupAsync;
      case _ReportSource.personal:
        async = personalAsync.when(
          data: (items) => AsyncValue.data(_buildPersonalData(items, from, to)),
          loading: () => const AsyncValue.loading(),
          error: (e, s) => AsyncValue.error(e, s),
        );
      case _ReportSource.combined:
        if (groupAsync.isLoading || personalAsync.isLoading) {
          async = const AsyncValue.loading();
        } else if (groupAsync.hasError) {
          async = AsyncValue.error(groupAsync.error!, groupAsync.stackTrace!);
        } else if (personalAsync.hasError) {
          async = AsyncValue.error(personalAsync.error!, personalAsync.stackTrace!);
        } else {
          async = AsyncValue.data(
            _mergeData(groupAsync.value!, _buildPersonalData(personalAsync.value!, from, to)),
          );
        }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _cachedRange = _computeRange());
            ref.invalidate(reportProvider(ReportQuery(from: from, to: to)));
            ref.invalidate(personalExpenseListProvider((from, to)));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _sourceChips(),
              const SizedBox(height: 10),
              _periodChips(),
              const SizedBox(height: 16),
              async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: ShimmerLoader(height: 120, count: 3),
                ),
                error: (e, _) => GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                      const SizedBox(width: 10),
                      Expanded(child: Text(friendlyError(e))),
                    ],
                  ),
                ),
                data: (data) => _content(context, data, currency, label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceChips() {
    const sources = [
      (_ReportSource.groups, 'Groups'),
      (_ReportSource.personal, 'Personal'),
      (_ReportSource.combined, 'Combined'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final s in sources) ...
            [
              ChoiceChip(
                label: Text(s.$2),
                selected: _source == s.$1,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _source == s.$1 ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _source = s.$1),
              ),
              const SizedBox(width: 8),
            ],
        ],
      ),
    );
  }

  Widget _periodChips() {
    final chips = [
      (ReportPeriod.day, 'Today'),
      (ReportPeriod.week, 'Week'),
      (ReportPeriod.month, 'Month'),
      (ReportPeriod.year, 'Year'),
      (ReportPeriod.custom, 'Custom'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in chips) ...[
            ChoiceChip(
              label: Text(c.$2),
              selected: _period == c.$1,
              onSelected: (_) async {
                if (c.$1 == ReportPeriod.custom) {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(DateTime.now().year - 5),
                    lastDate: DateTime.now(),
                    initialDateRange: DateTimeRange(start: _customFrom, end: _customTo),
                  );
                  if (picked != null) {
                    setState(() {
                      _customFrom = picked.start;
                      _customTo = DateTime(
                        picked.end.year,
                        picked.end.month,
                        picked.end.day,
                        23,
                        59,
                        59,
                      );
                      _period = ReportPeriod.custom;
                      _cachedRange = _computeRange();
                    });
                  }
                } else {
                  _setPeriod(c.$1);
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _content(BuildContext context, ReportData data, String currency, String label) {
    if (data.totals.count == 0) {
      return Column(
        children: const [
          SizedBox(height: 40),
          EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'No expenses in this period',
            subtitle: 'Pick a different range or add an expense to see your report.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _totalsCard(data, currency, label),
        const SizedBox(height: 14),
        _insightCallout(data, currency),
        const SizedBox(height: 14),
        _exportRow(data, currency, label),
        const SizedBox(height: 22),
        _sectionTitle('Spending by category'),
        const SizedBox(height: 10),
        _CategoryBreakdownCard(data: data, currency: currency),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _totalsCard(ReportData data, String currency, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            Money.format(data.totals.total, code: currency),
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _kpi('Transactions', data.totals.count.toString())),
              Expanded(child: _kpi('Paid by you', Money.format(data.totals.paid, code: currency))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              )),
        ],
      );

  Widget _exportRow(ReportData data, String currency, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _exporting ? null : () => _exportPdf(data, currency, label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF9F43)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B6B).withOpacity(0.30),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Download PDF report',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (_exporting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              else
                const Icon(Icons.download_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf(ReportData data, String currency, String label) async {
    setState(() => _exporting = true);
    try {
      final userName = ref.read(authProvider).user?.name ?? 'You';
      final bytes = await ReportExporter.buildPdf(
        data: data,
        currency: currency,
        periodLabel: label,
        userName: userName,
      );
      final filename = 'expense-report-${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      await ReportExporter.savePdf(bytes: bytes, filename: filename);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e, fallback: 'Export failed');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _insightCallout(ReportData data, String currency) {
    if (data.byCategory.isEmpty) return const SizedBox.shrink();
    final top = data.byCategory.first;
    final pct = data.totals.total <= 0 ? 0 : (top.amount / data.totals.total * 100);
    final avg = data.byDay.isEmpty ? 0.0 : data.totals.total / data.byDay.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Top category · '),
                      TextSpan(
                        text: top.category,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' (${pct.toStringAsFixed(0)}%)'),
                    ],
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                if (avg > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Avg ${Money.format(avg, code: currency)} / day · ${data.totals.count} transactions',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) =>
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));

  // ── Personal data helpers ─────────────────────────────────────────────────

  ReportData _buildPersonalData(
      List<PersonalExpenseModel> items, DateTime from, DateTime to) {
    final total = items.fold<double>(0, (a, e) => a + e.amount);
    final count = items.length;

    final catMap = <String, double>{};
    final catCount = <String, int>{};
    for (final e in items) {
      catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
      catCount[e.category] = (catCount[e.category] ?? 0) + 1;
    }
    final byCategory = catMap.entries
        .map((e) =>
            CategoryAmount(category: e.key, amount: e.value, count: catCount[e.key]!))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final dayMap = <String, double>{};
    for (final e in items) {
      final k = DateFormat('yyyy-MM-dd').format(e.date);
      dayMap[k] = (dayMap[k] ?? 0) + e.amount;
    }
    final byDay = dayMap.entries
        .map((e) => DayAmount(date: DateTime.parse(e.key), amount: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Personal expenses have no group / payer — fall back to a friendly
    // "Personal" label so the Transactions table can render every row.
    final me = ref.read(authProvider).user;
    final reportItems = items
        .map((e) => ReportItem(
              id: e.id,
              description: e.description,
              amount: e.amount,
              currency: e.currency,
              category: e.category,
              paidBy: me?.name ?? 'You',
              groupName: 'Personal',
              spentAt: e.date,
            ))
        .toList()
      ..sort((a, b) => b.spentAt.compareTo(a.spentAt));

    return ReportData(
      from: from,
      to: to,
      totals: ReportTotals(total: total, count: count, paid: total),
      byCategory: byCategory,
      byDay: byDay,
      items: reportItems,
    );
  }

  ReportData _mergeData(ReportData groups, ReportData personal) {
    final total = groups.totals.total + personal.totals.total;
    final count = groups.totals.count + personal.totals.count;
    final paid = groups.totals.paid + personal.totals.paid;

    final catMap = <String, double>{};
    final catCount = <String, int>{};
    for (final c in [...groups.byCategory, ...personal.byCategory]) {
      catMap[c.category] = (catMap[c.category] ?? 0) + c.amount;
      catCount[c.category] = (catCount[c.category] ?? 0) + c.count;
    }
    final byCategory = catMap.entries
        .map((e) =>
            CategoryAmount(category: e.key, amount: e.value, count: catCount[e.key]!))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final dayMap = <String, double>{};
    for (final d in [...groups.byDay, ...personal.byDay]) {
      final k = DateFormat('yyyy-MM-dd').format(d.date);
      dayMap[k] = (dayMap[k] ?? 0) + d.amount;
    }
    final byDay = dayMap.entries
        .map((e) => DayAmount(date: DateTime.parse(e.key), amount: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final combinedItems = [...groups.items, ...personal.items]
      ..sort((a, b) => b.spentAt.compareTo(a.spentAt));

    return ReportData(
      from: groups.from,
      to: groups.to,
      totals: ReportTotals(total: total, count: count, paid: paid),
      byCategory: byCategory,
      byDay: byDay,
      items: combinedItems,
    );
  }

}

const _categoryPalette = <Color>[
  Color(0xFF6C5CE7),
  Color(0xFF00B894),
  Color(0xFFFF6B6B),
  Color(0xFFFFC857),
  Color(0xFF44C4FF),
  Color(0xFFFD79A8),
  Color(0xFFA29BFE),
  Color(0xFFE17055),
  Color(0xFF55EFC4),
  Color(0xFFFAB1A0),
];

class _CategoryBreakdownCard extends StatefulWidget {
  const _CategoryBreakdownCard({required this.data, required this.currency});
  final ReportData data;
  final String currency;

  @override
  State<_CategoryBreakdownCard> createState() => _CategoryBreakdownCardState();
}

class _CategoryBreakdownCardState extends State<_CategoryBreakdownCard> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final cats = widget.data.byCategory;
    if (cats.isEmpty) {
      return const GlassCard(child: Text('No expenses to chart yet.'));
    }
    final total = widget.data.totals.total;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 460;
        final donut = _Donut(
          cats: cats,
          total: total,
          currency: widget.currency,
          selected: _selected,
          onTap: (i) => setState(() => _selected = (_selected == i ? null : i)),
        );
        final legend = _Legend(
          cats: cats,
          total: total,
          currency: widget.currency,
          selected: _selected,
          onTap: (i) => setState(() => _selected = (_selected == i ? null : i)),
        );

        if (narrow) {
          return GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              children: [
                SizedBox(height: 220, child: donut),
                const SizedBox(height: 12),
                legend,
              ],
            ),
          );
        }
        return GlassCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 220, height: 240, child: donut),
              const SizedBox(width: 18),
              Expanded(child: legend),
            ],
          ),
        );
      },
    );
  }
}

class _Donut extends StatelessWidget {
  const _Donut({
    required this.cats,
    required this.total,
    required this.currency,
    required this.selected,
    required this.onTap,
  });

  final List<CategoryAmount> cats;
  final double total;
  final String currency;
  final int? selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final centerLabel = selected != null && selected! < cats.length
        ? cats[selected!].category
        : 'Total';
    final centerValue = selected != null && selected! < cats.length
        ? Money.format(cats[selected!].amount, code: currency)
        : Money.format(total, code: currency);
    final centerPct = selected != null && total > 0
        ? '${(cats[selected!].amount / total * 100).toStringAsFixed(0)}%'
        : '${cats.length} categories';

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 64,
            startDegreeOffset: -90,
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                if (!event.isInterestedForInteractions) return;
                final idx = response?.touchedSection?.touchedSectionIndex ?? -1;
                if (idx >= 0) onTap(idx);
              },
            ),
            sections: [
              for (var i = 0; i < cats.length; i++)
                PieChartSectionData(
                  value: cats[i].amount.clamp(0.0001, double.infinity),
                  color: _categoryPalette[i % _categoryPalette.length],
                  radius: selected == i ? 64 : 54,
                  title: total <= 0
                      ? ''
                      : (cats[i].amount / total >= 0.06
                          ? '${(cats[i].amount / total * 100).toStringAsFixed(0)}%'
                          : ''),
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              centerLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              centerValue,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              centerPct,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.cats,
    required this.total,
    required this.currency,
    required this.selected,
    required this.onTap,
  });

  final List<CategoryAmount> cats;
  final double total;
  final String currency;
  final int? selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cats.length; i++)
          _LegendRow(
            cat: cats[i],
            color: _categoryPalette[i % _categoryPalette.length],
            total: total,
            currency: currency,
            highlighted: selected == i,
            onTap: () => onTap(i),
          ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.cat,
    required this.color,
    required this.total,
    required this.currency,
    required this.highlighted,
    required this.onTap,
  });

  final CategoryAmount cat;
  final Color color;
  final double total;
  final String currency;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = total <= 0 ? 0.0 : (cat.amount / total).clamp(0.0, 1.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: highlighted ? color.withOpacity(0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlighted ? color.withOpacity(0.35) : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cat.category,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  Text(
                    Money.format(cat.amount, code: currency),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(pct * 100).toStringAsFixed(1)}% · ${cat.count} ${cat.count == 1 ? "expense" : "expenses"}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
