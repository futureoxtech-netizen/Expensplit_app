import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/personal_expense_model.dart';
import '../data/personal_expense_repository.dart';

final personalExpenseRepositoryProvider =
    Provider<PersonalExpenseRepository>(
  (ref) => PersonalExpenseRepository(DioClient.instance),
);

// List for a date range — key: (from, to)
final personalExpenseListProvider = FutureProvider.family<
    List<PersonalExpenseModel>, (DateTime from, DateTime to)>(
  (ref, range) async {
    final repo = ref.read(personalExpenseRepositoryProvider);
    return repo.list(from: range.$1, to: range.$2);
  },
);

// Summary for chart
final personalSummaryProvider =
    FutureProvider<List<PersonalSummaryRow>>((ref) async {
  final repo = ref.read(personalExpenseRepositoryProvider);
  return repo.summary(months: 3);
});
