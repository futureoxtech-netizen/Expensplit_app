import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../../core/errors/error_messages.dart';
import '../../activity/providers/unread_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/data/expense_model.dart';
import '../../expenses/providers/expense_providers.dart';
import '../../groups/providers/group_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final feedAsync = ref.watch(expenseFeedProvider);
    final groupsAsync = ref.watch(groupsListProvider);
    final analyticsAsync = ref.watch(monthlyAnalyticsProvider);

    return GradientScaffold(
      padding: EdgeInsets.zero,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expenseFeedProvider);
          ref.invalidate(groupsListProvider);
          ref.invalidate(monthlyAnalyticsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Row(
              children: [
                Avatar(name: user?.name ?? 'You', imageUrl: user?.avatarUrl, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        user?.name.split(' ').first ?? 'Friend',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                _NotificationBell(
                  count: ref.watch(unreadActivityProvider),
                  onTap: () => context.go('/activity'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryHeroCard(feedAsync: feedAsync, currency: user?.currency ?? 'USD'),
            const SizedBox(height: 20),
            const _SectionTitle('This month'),
            const SizedBox(height: 12),
            analyticsAsync.when(
              data: (rows) => _SpendChart(rows: rows),
              loading: () => const SizedBox(height: 180, child: ShimmerLoader(height: 180, count: 1)),
              error: (e, _) => _ErrorCard(message: friendlyError(e)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: _SectionTitle('Your groups')),
                TextButton(onPressed: () => context.go('/groups'), child: const Text('See all')),
              ],
            ),
            const SizedBox(height: 8),
            groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: GlassCard(
                      child: Row(
                        children: [
                          const Icon(Icons.groups_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Start a group to split expenses with friends.'),
                          ),
                          TextButton(
                            onPressed: () => context.push('/groups/new'),
                            child: const Text('Create'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, i) {
                      final g = groups[i];
                      return _GroupCard(
                        name: g.name,
                        color: g.coverColor,
                        memberCount: g.members.length,
                        category: g.category,
                        onTap: () => context.push('/groups/${g.id}'),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: groups.length,
                  ),
                );
              },
              loading: () => const SizedBox(height: 140, child: ShimmerLoader(height: 140, count: 1)),
              error: (e, _) => _ErrorCard(message: friendlyError(e)),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Recent expenses'),
            const SizedBox(height: 8),
            feedAsync.when(
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No expenses yet',
                    subtitle: 'Add your first expense in a group to see it here.',
                  );
                }
                return Column(
                  children: [
                    for (final e in page.items.take(10))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ExpenseTile(expense: e),
                      ),
                  ],
                );
              },
              loading: () => const ShimmerLoader(),
              error: (e, _) => _ErrorCard(message: friendlyError(e)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700));
}

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({required this.feedAsync, required this.currency});
  final AsyncValue<ExpensePage> feedAsync;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final total = feedAsync.maybeWhen(
      data: (p) => p.items.fold<double>(0, (a, e) => a + e.amount),
      orElse: () => 0.0,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => GoRouter.of(context).push('/reports'),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total tracked',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                Money.format(total, code: currency),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  _Pill(icon: Icons.bar_chart_rounded, label: 'See reports'),
                  SizedBox(width: 8),
                  _Pill(icon: Icons.bolt_rounded, label: 'Live sync'),
                  Spacer(),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SpendChart extends StatelessWidget {
  const _SpendChart({required this.rows});
  final List<MonthlyCategoryTotal> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: const [
            Icon(Icons.insights_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(child: Text('Add expenses to start seeing your spending insights.')),
          ],
        ),
      );
    }
    // Aggregate by month
    final byMonth = <String, double>{};
    for (final r in rows) {
      final k = '${r.year}-${r.month.toString().padLeft(2, '0')}';
      byMonth[k] = (byMonth[k] ?? 0) + r.total;
    }
    final entries = byMonth.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxY = entries.fold<double>(1, (a, e) => e.value > a ? e.value : a);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.2,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                    final mm = entries[i].key.split('-').last;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(DateFmt.monthShort(int.parse(mm)),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < entries.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: entries[i].value,
                      width: 18,
                      borderRadius: BorderRadius.circular(8),
                      gradient: AppColors.brandGradient,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.name,
    required this.color,
    required this.memberCount,
    required this.category,
    required this.onTap,
  });

  final String name;
  final String color;
  final int memberCount;
  final String category;
  final VoidCallback onTap;

  Color _parse() {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _parse();
    return SizedBox(
      width: 180,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [c, c.withOpacity(0.72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: c.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$memberCount members · $category',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});
  final ExpenseModel expense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => GoRouter.of(context).push('/expenses/${expense.id}'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              CategoryIcon(category: expense.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.description,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      '${expense.paidBy.name} · ${expense.groupName ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Money.format(expense.amount, code: expense.currency),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFmt.relative(expense.spentAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(
            count > 0 ? Icons.notifications_active_rounded : Icons.notifications_outlined,
            color: count > 0
                ? AppColors.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (count > 0)
          Positioned(
            top: 6,
            right: 4,
            child: AnimatedScale(
              scale: 1,
              duration: const Duration(milliseconds: 220),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: count > 9 ? 5 : 4,
                  vertical: 2,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
