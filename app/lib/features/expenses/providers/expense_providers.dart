import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/local_store.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/expense_model.dart';
import '../data/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(),
);

// ── Offline-first reads (stream from the local DB) ──────────────────────────

final groupExpensesProvider =
    StreamProvider.autoDispose.family<ExpensePage, String>((ref, groupId) {
  SyncEngine.instance.kick();
  // Preview stream (dashboard / group header) — only the most recent rows.
  return LocalStore.instance.watchGroupExpensesJson(groupId, limit: 20).map((list) =>
      ExpensePage(
          items: list.map((j) => ExpenseModel.fromJson(j)).toList(),
          hasMore: false,
          page: 1));
});

final expenseFeedProvider = StreamProvider.autoDispose<ExpensePage>((ref) {
  SyncEngine.instance.kick();
  return LocalStore.instance.watchFeedJson(limit: 20).map((list) => ExpensePage(
      items: list.map((j) => ExpenseModel.fromJson(j)).toList(),
      hasMore: false,
      page: 1));
});

/// Merged expenses + settlements for the group detail "Expenses" tab. Backed by
/// the local DB; reloads after each server pull (via [syncRevisionProvider]) and
/// on local writes (screens invalidate it after creating/editing).
final groupExpensesPagedProvider = StateNotifierProvider.autoDispose
    .family<PagedListNotifier<GroupTxn>, PagedListState<GroupTxn>, String>(
        (ref, groupId) {
  ref.watch(syncRevisionProvider);
  SyncEngine.instance.kick();
  return PagedListNotifier<GroupTxn>(
    fetcher: (page, limit) async {
      final list = await LocalStore.instance
          .groupTransactionsPage(groupId, limit: limit, offset: (page - 1) * limit);
      return PagedResult(items: list.map(parseGroupTxn).toList(), hasMore: list.length == limit);
    },
    limit: 30,
  );
});

final expenseFeedPagedProvider = StateNotifierProvider.autoDispose<
    PagedListNotifier<ExpenseModel>, PagedListState<ExpenseModel>>((ref) {
  ref.watch(syncRevisionProvider);
  SyncEngine.instance.kick();
  return PagedListNotifier<ExpenseModel>(
    fetcher: (page, limit) async {
      final list = await LocalStore.instance.feedPage(limit: limit, offset: (page - 1) * limit);
      return PagedResult(
          items: list.map((j) => ExpenseModel.fromJson(j)).toList(), hasMore: list.length == limit);
    },
    limit: 30,
  );
});

final monthlyAnalyticsProvider =
    StreamProvider.autoDispose<List<MonthlyCategoryTotal>>((ref) {
  final myId = ref.watch(authProvider.select((s) => s.user?.id));
  if (myId == null) return Stream.value(const <MonthlyCategoryTotal>[]);
  return LocalStore.instance.watchMonthlyAnalyticsJson(myId).map(
      (list) => list.map((j) => MonthlyCategoryTotal.fromJson(j)).toList());
});

final expenseDetailProvider =
    StreamProvider.autoDispose.family<ExpenseModel, String>((ref, id) {
  SyncEngine.instance.kick();
  return LocalStore.instance.watchExpenseJson(id).map((j) {
    if (j == null) throw StateError('Expense not found');
    return ExpenseModel.fromJson(j);
  });
});
