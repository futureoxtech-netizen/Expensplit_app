import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/utils/formatters.dart';
import '../data/loan_model.dart';
import '../providers/loan_providers.dart';
import 'add_payment_sheet.dart';
import 'loans_screen.dart';

class LoanDetailScreen extends ConsumerStatefulWidget {
  const LoanDetailScreen({super.key, required this.loanId});
  final String loanId;

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  // True once we've forced a sync for a loan that wasn't on this device yet
  // (e.g. opened from a push notification before the delta pull arrived). We
  // only show "not found" *after* that sync has had a chance to fetch it.
  bool _syncAttempted = false;

  @override
  Widget build(BuildContext context) {
    final loanAsync = ref.watch(loanDetailProvider(widget.loanId));

    return loanAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (loan) {
        if (loan == null) {
          if (!_syncAttempted) {
            // Pull from the server once, then re-evaluate. If the loan exists
            // (a deep link from a notification), the provider's stream will emit
            // it and rebuild this screen automatically; otherwise we fall
            // through to the friendly "not found" state below.
            _syncAttempted = true;
            SyncEngine.instance.sync().whenComplete(() {
              if (mounted) setState(() {});
            });
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 56, color: Theme.of(context).disabledColor),
                    const SizedBox(height: 12),
                    const Text('Loan not found',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 6),
                    Text(
                      "It may have been deleted, or it hasn't synced to this device yet.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.canPop() ? context.pop() : context.go('/loans'),
                      child: const Text('Back to loans'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return _LoanDetailBody(loan: loan);
      },
    );
  }
}

class _LoanDetailBody extends ConsumerWidget {
  const _LoanDetailBody({required this.loan});
  final LoanModel loan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 'pending_approval' on this device means the *other* party created the
    // loan and I'm the one who must confirm it (whether I'm lender or borrower).
    final canApprove = loan.isPendingApproval;
    final isActive = loan.isActive;
    final cs = Theme.of(context).colorScheme;
    final accent = loan.loanType == 'given' ? AppColors.accent : AppColors.danger;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loan.counterpartyName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          PopupMenuButton<_Action>(
            itemBuilder: (_) => [
              if (isActive)
                const PopupMenuItem(
                  value: _Action.markSettled,
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline_rounded),
                    title: Text('Mark as settled'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: _Action.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  title: Text('Delete loan', style: TextStyle(color: AppColors.danger)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (a) => _onAction(context, ref, a),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _HeaderCard(loan: loan, accent: accent),
          ),
          // Approval banner
          if (canApprove)
            SliverToBoxAdapter(
              child: _ApprovalBanner(
                loan: loan,
                onApprove: () => _approve(context, ref),
                onReject: () => _reject(context, ref),
              ),
            ),
          // Pending banner for the creator awaiting the other party's decision
          if (loan.isPendingSent)
            SliverToBoxAdapter(
              child: _PendingLenderBanner(counterpartyName: loan.counterpartyName),
            ),
          // Rejected banner
          if (loan.isRejected)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel_outlined, color: AppColors.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${loan.counterpartyName} rejected this loan request.',
                        style: const TextStyle(
                            color: AppColors.danger, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Payment history header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Payment History',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    '${loan.payments.length} record${loan.payments.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ),
          // Payments list
          if (loan.payments.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 48, color: AppColors.primary.withOpacity(0.25)),
                    const SizedBox(height: 12),
                    Text(
                      'No payments recorded yet',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.55)),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList.separated(
              separatorBuilder: (_, __) => Divider(
                  height: 1, indent: 68, color: Theme.of(context).dividerColor),
              itemCount: loan.payments.length,
              itemBuilder: (ctx, i) {
                // Reverse so newest at top.
                final p = loan.payments[loan.payments.length - 1 - i];
                return _PaymentRow(
                  payment: p,
                  currency: loan.currency,
                  accent: accent,
                  onDelete: () => _deletePayment(ctx, ref, p.id),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: (isActive && !loan.isSettled)
          ? FloatingActionButton.extended(
              onPressed: () => _showAddPayment(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Record Payment'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Future<void> _onAction(BuildContext context, WidgetRef ref, _Action action) async {
    switch (action) {
      case _Action.markSettled:
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Mark as settled?'),
            content: const Text(
                'This will mark the loan as fully settled. You can still view it in history.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true), child: const Text('Settle')),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          try {
            await ref.read(loanRepositoryProvider).addPayment(
                  loanId: loan.id,
                  amount: loan.remaining,
                  note: 'Marked as settled',
                );
          } catch (e) {
            if (context.mounted) showErrorSnack(context, e);
          }
        }
        break;
      case _Action.delete:
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete loan?'),
            content: const Text('This will permanently delete this loan and all its payments.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          // Leave the detail screen FIRST, then delete. The delete soft-removes
          // the loan locally, which makes loanDetailProvider emit null — if we
          // were still on this screen it would flash "Loan not found". Capture
          // the repo before popping so we don't read a disposed ref afterward.
          final repo = ref.read(loanRepositoryProvider);
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/loans');
          }
          try {
            await repo.deleteLoan(loan.id);
          } catch (_) {
            // Local delete + queued sync rarely fails; the screen is already
            // gone so there's no context to surface an error on.
          }
        }
        break;
    }
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(loanRepositoryProvider).approveLoan(loan.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loan confirmed!')));
      }
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject loan?'),
        content: const Text('Are you sure you want to reject this loan request?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await ref.read(loanRepositoryProvider).rejectLoan(loan.id);
      } catch (e) {
        if (context.mounted) showErrorSnack(context, e);
      }
    }
  }

  Future<void> _showAddPayment(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPaymentSheet(
        loan: loan,
        onAdded: () {},
      ),
    );
  }

  Future<void> _deletePayment(BuildContext context, WidgetRef ref, String paymentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete payment?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await ref.read(loanRepositoryProvider).deletePayment(paymentId, loan.id);
      } catch (e) {
        if (context.mounted) showErrorSnack(context, e);
      }
    }
  }
}

// ── Header card ────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.loan, required this.accent});
  final LoanModel loan;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accent.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ContactAvatar(
                name: loan.counterpartyName,
                isGuest: loan.isGuest,
                avatarUrl: loan.counterpartyAvatar,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.counterpartyName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      loan.loanType == 'given' ? 'Owes you' : 'You owe',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              LoanStatusChip(status: loan.status),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Remaining', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      Money.format(loan.remaining, code: loan.currency),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    Money.format(loan.amount, code: loan.currency),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  const Text('Paid', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    Money.format(loan.paidAmount, code: loan.currency),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: loan.progress,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${(loan.progress * 100).toStringAsFixed(1)}% paid back',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const Spacer(),
              if (loan.dueDate != null)
                Text(
                  loan.isOverdue
                      ? 'Overdue!'
                      : 'Due ${loan.dueDate!.day}/${loan.dueDate!.month}/${loan.dueDate!.year}',
                  style: TextStyle(
                    color: loan.isOverdue
                        ? const Color(0xFFFFCDD2)
                        : Colors.white70,
                    fontSize: 11,
                    fontWeight: loan.isOverdue ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
            ],
          ),
          if (loan.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              loan.description,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Approval banner (borrower) ─────────────────────────────────────────────────

class _ApprovalBanner extends StatelessWidget {
  const _ApprovalBanner({
    required this.loan,
    required this.onApprove,
    required this.onReject,
  });
  final LoanModel loan;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warn.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warn.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending_outlined, color: AppColors.warn),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    // loanType is from *my* perspective: 'taken' → the lender
                    // created it claiming I borrowed; 'given' → the borrower
                    // created it claiming they borrowed from me.
                    loan.loanType == 'taken'
                        ? '${loan.counterpartyName} says you borrowed ${Money.format(loan.amount, code: loan.currency)}'
                        : '${loan.counterpartyName} says they borrowed ${Money.format(loan.amount, code: loan.currency)} from you',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (loan.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Reason: ${loan.description}',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Confirm',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

// ── Pending banner (lender) ────────────────────────────────────────────────────

class _PendingLenderBanner extends StatelessWidget {
  const _PendingLenderBanner({required this.counterpartyName});
  final String counterpartyName;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warn.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warn.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: AppColors.warn, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Waiting for $counterpartyName to confirm this loan.',
                style: const TextStyle(color: AppColors.warn, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}

// ── Payment row ────────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.currency,
    required this.accent,
    required this.onDelete,
  });
  final LoanPaymentModel payment;
  final String currency;
  final Color accent;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(_methodIcon(payment.method), color: accent, size: 20),
      ),
      title: Text(
        Money.format(payment.amount, code: currency),
        style: TextStyle(fontWeight: FontWeight.w700, color: accent),
      ),
      subtitle: Text(
        '${_formatDate(payment.paidAt)}${payment.note.isNotEmpty ? ' · ${payment.note}' : ''}',
        style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.55)),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline_rounded, size: 18),
        color: AppColors.danger.withOpacity(0.6),
        onPressed: onDelete,
        tooltip: 'Delete payment',
      ),
    );
  }

  static IconData _methodIcon(String method) {
    switch (method) {
      case 'bank':
        return Icons.account_balance_rounded;
      case 'upi':
        return Icons.qr_code_scanner_rounded;
      case 'other':
        return Icons.attach_money_rounded;
      default:
        return Icons.payments_outlined;
    }
  }

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }
}

enum _Action { markSettled, delete }
