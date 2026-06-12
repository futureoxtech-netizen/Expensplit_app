import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/loan_model.dart';
import '../providers/loan_providers.dart';
import 'add_loan_screen.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(loanSummaryProvider);
    final pendingCount = ref.watch(pendingApprovalCountProvider);
    final currency = ref.watch(authProvider).user?.currency ?? 'PKR';
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khata Book', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Owe Me'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('I Owe'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    _Badge(count: pendingCount),
                  ],
                ],
              ),
            ),
            Tab(text: 'History'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: cs.onSurface.withOpacity(0.55),
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      body: Column(
        children: [
          _SummaryCard(summary: summary, currency: currency),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _LoanList(type: 'given', filter: null),
                _LoanList(type: 'taken', filter: null),
                _LoanList(type: null, filter: 'settled'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLoan(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Entry'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _showAddLoan(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddLoanSheet(),
    );
  }
}

// ── Summary header card ────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.currency});
  final LoanSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total owe you', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  Money.format(summary.totalOweMe, code: currency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 44, color: Colors.white24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You owe', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    Money.format(summary.totalIOwe, code: currency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loan list by type ──────────────────────────────────────────────────────────

class _LoanList extends ConsumerWidget {
  const _LoanList({required this.type, required this.filter});
  final String? type;
  final String? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<List<LoanModel>> async_;
    if (filter == 'settled') {
      async_ = ref.watch(loansProvider).whenData(
            (list) => list.where((l) => l.isSettled || l.isRejected).toList(),
          );
    } else if (type == 'given') {
      async_ = ref.watch(givenLoansProvider);
    } else {
      async_ = ref.watch(takenLoansProvider);
    }

    return async_.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (loans) {
        if (loans.isEmpty) {
          return _EmptyLoanState(type: type, filter: filter);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          itemCount: loans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _LoanCard(
            loan: loans[i],
            onTap: () => ctx.push('/loans/${loans[i].id}'),
          ),
        );
      },
    );
  }
}

// ── Individual loan card ───────────────────────────────────────────────────────

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan, required this.onTap});
  final LoanModel loan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isGiven = loan.loanType == 'given';
    final accent = isGiven ? AppColors.accent : AppColors.danger;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _ContactAvatar(
                    name: loan.counterpartyName,
                    isGuest: loan.isGuest,
                    avatarUrl: loan.counterpartyAvatar,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                loan.counterpartyName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _StatusChip(status: loan.status),
                          ],
                        ),
                        if (loan.description.isNotEmpty)
                          Text(
                            loan.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (loan.dueDate != null)
                          Text(
                            _dueDateLabel(loan),
                            style: TextStyle(
                              fontSize: 11,
                              color: loan.isOverdue ? AppColors.danger : cs.onSurface.withOpacity(0.5),
                              fontWeight: loan.isOverdue ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Money.format(loan.remaining, code: loan.currency),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'of ${Money.format(loan.amount, code: loan.currency)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!loan.isSettled && !loan.isRejected && loan.amount > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: loan.progress,
                    backgroundColor: accent.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation(accent),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _dueDateLabel(LoanModel loan) {
    final days = loan.daysUntilDue;
    if (days == null) return '';
    if (days < 0) return 'Overdue by ${(-days)} days';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }
}

// ── Status chip ────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  static const _map = {
    'pending_approval': (Color(0xFFFFC857), 'Pending'),
    'pending_sent': (Color(0xFFFFB300), 'Awaiting'),
    'active': (Color(0xFF00B894), 'Active'),
    'settled': (Color(0xFF6C5CE7), 'Settled'),
    'rejected': (Color(0xFFFF6B6B), 'Rejected'),
  };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _map[status] ?? (AppColors.primary, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ── Contact avatar ─────────────────────────────────────────────────────────────

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({
    required this.name,
    required this.isGuest,
    this.avatarUrl,
    this.size = 40,
  });
  final String name;
  final bool isGuest;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(avatarUrl!, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initials(initials, size)),
      );
    }
    return _initials(initials, size, guest: isGuest);
  }

  Widget _initials(String text, double s, {bool guest = false}) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: guest
              ? AppColors.warn.withOpacity(0.2)
              : AppColors.primary.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: s * 0.38,
              fontWeight: FontWeight.w800,
              color: guest ? AppColors.warn : AppColors.primary,
            ),
          ),
        ),
      );
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyLoanState extends StatelessWidget {
  const _EmptyLoanState({required this.type, required this.filter});
  final String? type;
  final String? filter;

  @override
  Widget build(BuildContext context) {
    final isHistory = filter == 'settled';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHistory ? Icons.history_rounded : Icons.handshake_outlined,
              size: 64,
              color: AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isHistory
                  ? 'No settled loans yet'
                  : type == 'given'
                      ? 'No one owes you'
                      : 'You don\'t owe anyone',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isHistory
                  ? 'Settled and rejected loans appear here.'
                  : 'Tap + to record a new loan entry.',
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge widget ───────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
        ),
      );
}

/// Public re-export of the contact avatar so it can be used in other screens.
class ContactAvatar extends StatelessWidget {
  const ContactAvatar({
    super.key,
    required this.name,
    required this.isGuest,
    this.avatarUrl,
    this.size = 40,
  });
  final String name;
  final bool isGuest;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) => _ContactAvatar(
        name: name,
        isGuest: isGuest,
        avatarUrl: avatarUrl,
        size: size,
      );
}

/// Public re-export of status chip.
class LoanStatusChip extends StatelessWidget {
  const LoanStatusChip({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => _StatusChip(status: status);
}
