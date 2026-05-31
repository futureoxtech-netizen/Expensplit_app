import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import '../data/expense_model.dart';
import '../data/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(DioClient.instance),
);

/// Single-page providers (kept for the dashboard preview which only renders
/// the first 5 items and doesn't paginate).
final groupExpensesProvider = FutureProvider.autoDispose
    .family<ExpensePage, String>((ref, groupId) async {
  return ref.watch(expenseRepositoryProvider).listByGroup(groupId);
});

final expenseFeedProvider =
    FutureProvider.autoDispose<ExpensePage>((ref) async {
  return ref.watch(expenseRepositoryProvider).feed();
});

/// Infinite-scroll provider for the group detail "Expenses" tab. Returns a
/// merged stream of expenses *and* settlement records (see [GroupTxn]) so
/// recorded payments show up inline, the way Splitwise does it.
final groupExpensesPagedProvider = StateNotifierProvider.autoDispose
    .family<PagedListNotifier<GroupTxn>, PagedListState<GroupTxn>, String>(
        (ref, groupId) {
  final repo = ref.watch(expenseRepositoryProvider);
  return PagedListNotifier<GroupTxn>(
    fetcher: (page, limit) => repo.groupTransactionsPaged(
      groupId,
      page: page,
      limit: limit,
    ),
    limit: 30,
  );
});

final expenseFeedPagedProvider = StateNotifierProvider.autoDispose<
    PagedListNotifier<ExpenseModel>, PagedListState<ExpenseModel>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return PagedListNotifier<ExpenseModel>(
    fetcher: (page, limit) => repo.feedPaged(page: page, limit: limit),
    limit: 30,
  );
});

final monthlyAnalyticsProvider =
    FutureProvider.autoDispose<List<MonthlyCategoryTotal>>((ref) async {
  return ref.watch(expenseRepositoryProvider).analytics(months: 6);
});

final expenseDetailProvider =
    FutureProvider.autoDispose.family<ExpenseModel, String>((ref, id) async {
  return ref.watch(expenseRepositoryProvider).getById(id);
});
