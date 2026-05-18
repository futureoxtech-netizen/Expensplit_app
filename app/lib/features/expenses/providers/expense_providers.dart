import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/expense_model.dart';
import '../data/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(DioClient.instance),
);

final groupExpensesProvider =
    FutureProvider.autoDispose.family<ExpensePage, String>((ref, groupId) async {
  return ref.watch(expenseRepositoryProvider).listByGroup(groupId);
});

final expenseFeedProvider = FutureProvider.autoDispose<ExpensePage>((ref) async {
  return ref.watch(expenseRepositoryProvider).feed();
});

final monthlyAnalyticsProvider =
    FutureProvider.autoDispose<List<MonthlyCategoryTotal>>((ref) async {
  return ref.watch(expenseRepositoryProvider).analytics(months: 6);
});

final expenseDetailProvider =
    FutureProvider.autoDispose.family<ExpenseModel, String>((ref, id) async {
  return ref.watch(expenseRepositoryProvider).getById(id);
});
