import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/sync/sync_engine.dart';
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
    final pendingGiven = ref.watch(pendingGivenCountProvider);
    final pendingTaken = ref.watch(pendingTakenCountProvider);
    final currency = ref.watch(authProvider).user?.currency ?? 'PKR';
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khata Book', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Owe Me'),
                  if (pendingGiven > 0) ...[
                    const SizedBox(width: 6),
                    _Badge(count: pendingGiven),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('I Owe'),
                  if (pendingTaken > 0) ...[
                    const SizedBox(width: 6),
                    _Badge(count: pendingTaken),
                  ],
                ],
              ),
            ),
            Tab(text: 'History'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: cs.onSurface.withOpacity(0.55),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          indicator: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
          ),
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showAddLoan(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('New Entry',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
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
    final net = summary.net;
    final allSettled = summary.totalOweMe == 0 && summary.totalIOwe == 0;
    final netPositive = net >= 0;
    final caption = allSettled
        ? "You're all settled up"
        : netPositive
            ? 'Net balance · in your favour'
            : "Net balance · you owe overall";

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 15),
              const SizedBox(width: 6),
              Text(
                caption,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Money.format(net.abs(), code: currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: "You'll get",
                  value: Money.format(summary.totalOweMe, code: currency),
                  icon: Icons.south_west_rounded,
                  iconColor: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: "You'll give",
                  value: Money.format(summary.totalIOwe, code: currency),
                  icon: Icons.north_east_rounded,
                  iconColor: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Translucent stat pill used inside the gradient summary card.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 11),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
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

    // Pull-to-refresh drives a full sync cycle. The error/empty states are made
    // scrollable so the pull gesture works even when the list has no rows.
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => SyncEngine.instance.sync(),
      child: async_.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ScrollableCenter(
          child: _EmptyLoanState.error(),
        ),
        data: (loans) {
          if (loans.isEmpty) {
            return _ScrollableCenter(child: _EmptyLoanState(type: type, filter: filter));
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            itemCount: loans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _LoanCard(
              loan: loans[i],
              onTap: () => ctx.push('/loans/${loans[i].id}'),
            ),
          );
        },
      ),
    );
  }
}

/// Centers [child] inside an always-scrollable viewport so a [RefreshIndicator]
/// can still be pulled when the underlying list is empty or errored.
class _ScrollableCenter extends StatelessWidget {
  const _ScrollableCenter({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
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
    final showProgress = !loan.isSettled && !loan.isRejected && loan.amount > 0;
    final pct = (loan.progress * 100).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with a directional badge: incoming (you'll get) vs
                  // outgoing (you'll give) — a quick visual cue per the
                  // money-transfer apps' convention.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _ContactAvatar(
                        name: loan.counterpartyName,
                        isGuest: loan.isGuest,
                        avatarUrl: loan.counterpartyAvatar,
                        size: 46,
                      ),
                      Positioned(
                        bottom: -2,
                        right: -3,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: theme.cardTheme.color ?? Colors.white,
                                width: 2),
                          ),
                          child: Icon(
                            isGiven
                                ? Icons.south_west_rounded
                                : Icons.north_east_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _StatusChip(status: loan.status),
                            // Created/edited offline and not yet pushed — let
                            // the user know it's queued, not lost.
                            if (loan.serverId == null) ...[
                              const SizedBox(width: 4),
                              const _SyncPendingIcon(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isGiven ? 'You lent' : 'You borrowed',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                        if (loan.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            loan.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
                          fontSize: 16.5,
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
              if (showProgress) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: loan.progress,
                          backgroundColor: accent.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation(accent),
                          minHeight: 7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$pct% paid',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
                if (loan.dueDate != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _DueChip(loan: loan),
                  ),
                ],
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

// ── Due-date chip ───────────────────────────────────────────────────────────────

class _DueChip extends StatelessWidget {
  const _DueChip({required this.loan});
  final LoanModel loan;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final overdue = loan.isOverdue;
    final color = overdue ? AppColors.danger : cs.onSurface.withOpacity(0.6);
    final bg = overdue
        ? AppColors.danger.withOpacity(0.10)
        : cs.onSurface.withOpacity(0.05);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overdue ? Icons.warning_amber_rounded : Icons.event_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            _LoanCard._dueDateLabel(loan),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sync-pending indicator ──────────────────────────────────────────────────────

class _SyncPendingIcon extends StatelessWidget {
  const _SyncPendingIcon();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Waiting to sync',
      child: Icon(
        Icons.cloud_upload_outlined,
        size: 13,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
  const _EmptyLoanState({required this.type, required this.filter}) : isError = false;
  const _EmptyLoanState.error()
      : type = null,
        filter = null,
        isError = true;

  final String? type;
  final String? filter;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final isHistory = filter == 'settled';
    final IconData icon;
    final String title;
    final String subtitle;
    if (isError) {
      icon = Icons.cloud_off_rounded;
      title = "Couldn't load your khata";
      subtitle = 'Pull down to retry once you\'re back online.';
    } else if (isHistory) {
      icon = Icons.history_rounded;
      title = 'No settled loans yet';
      subtitle = 'Settled and rejected loans appear here.';
    } else {
      icon = Icons.handshake_outlined;
      title = type == 'given' ? 'No one owes you' : 'You don\'t owe anyone';
      subtitle = 'Tap + to record a new loan entry.';
    }
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: (isError ? AppColors.danger : AppColors.primary).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)),
            textAlign: TextAlign.center,
          ),
        ],
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
