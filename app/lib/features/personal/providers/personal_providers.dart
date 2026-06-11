import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pagination/paged_list_notifier.dart';
import '../../../core/sync/sync_providers.dart';
import '../data/personal_expense_model.dart';
import '../data/personal_expense_repository.dart';

final personalExpenseRepositoryProvider =
    Provider<PersonalExpenseRepository>(
  (ref) => PersonalExpenseRepository(),
);

/// Aggregating provider — walks all pages and returns the full set for the
/// date range. Used by the dashboard spending card and the reports module,
/// which need totals rather than scroll-driven UI.
final personalExpenseListProvider = FutureProvider.family<
    List<PersonalExpenseModel>, (DateTime from, DateTime to)>(
  (ref, range) async {
    ref.watch(syncRevisionProvider); // reload after each server pull
    final repo = ref.read(personalExpenseRepositoryProvider);
    return repo.list(from: range.$1, to: range.$2);
  },
);

/// Infinite-scroll provider for the Personal tracker screen. Key includes
/// the date range so changing the period (daily/weekly/monthly) creates a
/// fresh notifier instance with a fresh scroll cursor.
final personalExpensesPagedProvider = StateNotifierProvider.autoDispose.family<
    PagedListNotifier<PersonalExpenseModel>,
    PagedListState<PersonalExpenseModel>,
    (DateTime, DateTime)>((ref, range) {
  final repo = ref.watch(personalExpenseRepositoryProvider);
  final notifier = PagedListNotifier<PersonalExpenseModel>(
    fetcher: (page, limit) => repo.listPaged(
      from: range.$1,
      to: range.$2,
      page: page,
      limit: limit,
    ),
    limit: 30,
  );
  ref.listen(syncRevisionProvider, (_, __) => notifier.softRefresh());
  return notifier;
});

// Summary for chart
final personalSummaryProvider =
    FutureProvider<List<PersonalSummaryRow>>((ref) async {
  ref.watch(syncRevisionProvider);
  final repo = ref.read(personalExpenseRepositoryProvider);
  return repo.summary(months: 3);
});
