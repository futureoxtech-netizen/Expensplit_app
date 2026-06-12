import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../core/db/local_store.dart';
import '../data/guest_contact_model.dart';
import '../data/loan_model.dart';
import '../data/loan_repository.dart';

final loanRepositoryProvider = Provider<LoanRepository>(
  (ref) => LoanRepository(DioClient.instance),
);

/// All non-deleted loans for the current user, ordered by created date desc.
final loansProvider = StreamProvider.autoDispose<List<LoanModel>>((ref) {
  ref.watch(syncRevisionProvider);
  SyncEngine.instance.kick();
  return ref.read(loanRepositoryProvider).watchLoans();
});

/// Outstanding loans where I gave money (loanType == 'given'). Settled and
/// rejected loans move to the History tab, so they're excluded here.
final givenLoansProvider = StreamProvider.autoDispose<List<LoanModel>>((ref) {
  return ref.watch(loansProvider).whenData((list) {
    return list.where((l) => l.loanType == 'given' && !l.isRejected && !l.isSettled).toList();
  }).when(
    data: (d) => Stream.value(d),
    loading: () => const Stream.empty(),
    error: (e, s) => Stream.error(e, s),
  );
});

/// Outstanding loans where I took money (loanType == 'taken'). Settled and
/// rejected loans move to the History tab, so they're excluded here.
final takenLoansProvider = StreamProvider.autoDispose<List<LoanModel>>((ref) {
  return ref.watch(loansProvider).whenData((list) {
    return list.where((l) => l.loanType == 'taken' && !l.isRejected && !l.isSettled).toList();
  }).when(
    data: (d) => Stream.value(d),
    loading: () => const Stream.empty(),
    error: (e, s) => Stream.error(e, s),
  );
});

/// Loans awaiting my approval — the counterparty (other party) created them and
/// I must confirm or reject, regardless of whether I'm the lender or borrower.
final pendingApprovalLoansProvider = StreamProvider.autoDispose<List<LoanModel>>((ref) {
  return ref.watch(loansProvider).whenData((list) {
    return list.where((l) => l.isPendingApproval).toList();
  }).when(
    data: (d) => Stream.value(d),
    loading: () => const Stream.empty(),
    error: (e, s) => Stream.error(e, s),
  );
});

/// Count of loans needing my approval — drives badge in navigation.
final pendingApprovalCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(pendingApprovalLoansProvider).maybeWhen(
        data: (list) => list.length,
        orElse: () => 0,
      );
});

/// Summary totals across all loans.
final loanSummaryProvider = Provider.autoDispose<LoanSummary>((ref) {
  final all = ref.watch(loansProvider).valueOrNull ?? [];
  double totalGiven = 0;
  double totalTaken = 0;
  double totalGivenPaid = 0;
  double totalTakenPaid = 0;
  for (final l in all) {
    // Only confirmed, in-progress debts count toward the headline totals.
    // Pending (unconfirmed) and settled loans are excluded — a claim the other
    // party hasn't agreed to shouldn't inflate what you owe or are owed.
    if (!l.isActive) continue;
    if (l.loanType == 'given') {
      totalGiven += l.amount;
      totalGivenPaid += l.paidAmount;
    } else {
      totalTaken += l.amount;
      totalTakenPaid += l.paidAmount;
    }
  }
  return LoanSummary(
    totalOweMe: totalGiven - totalGivenPaid,
    totalIOwe: totalTaken - totalTakenPaid,
  );
});

/// Single loan detail stream.
final loanDetailProvider = StreamProvider.autoDispose.family<LoanModel?, String>((ref, id) {
  ref.watch(syncRevisionProvider);
  SyncEngine.instance.kick();
  return ref.read(loanRepositoryProvider).watchLoan(id);
});

/// All guest contacts (local only).
final guestContactsProvider = StreamProvider.autoDispose<List<GuestContactModel>>((ref) {
  return ref.read(loanRepositoryProvider).watchGuestContacts();
});

/// All app users cached in local DB (for contact picker), excluding the
/// current user (you can't owe a loan to yourself) and placeholder users.
final appUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final myId = LocalStore.instance.currentUser?['_id']?.toString();
  final rows = await LocalStore.instance.db.select(LocalStore.instance.db.users).get();
  return rows
      .where((u) => !u.isPlaceholder && u.id != myId)
      .map((u) => {
            '_id': u.id,
            'name': u.name,
            'email': u.email,
            'avatarUrl': u.avatarUrl,
            'isGuest': false,
          })
      .toList();
});

class LoanSummary {
  const LoanSummary({required this.totalOweMe, required this.totalIOwe});
  final double totalOweMe;
  final double totalIOwe;
  double get net => totalOweMe - totalIOwe;
}
