import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import '../data/goal_model.dart';
import '../data/goals_repository.dart';

// ─── Repository provider ──────────────────────────────────────────────────────
final goalsRepositoryProvider = Provider<GoalsRepository>(
  (ref) => GoalsRepository(DioClient.instance),
);

/// Single-page provider — still useful for the header/stats card which
/// renders `totalSaved` / `totalTarget` / counts from the first response.
final goalsListProvider = FutureProvider.family<GoalsPage, String?>(
  (ref, status) async {
    final repo = ref.read(goalsRepositoryProvider);
    return repo.list(status: status);
  },
);

/// Infinite-scroll goal list. The header on the goals screen still reads
/// [goalsListProvider] for the aggregate stats; the scrollable item list
/// reads this notifier for paged content.
final goalsListPagedProvider = StateNotifierProvider.autoDispose.family<
    PagedListNotifier<GoalModel>, PagedListState<GoalModel>, String?>(
  (ref, status) {
    final repo = ref.watch(goalsRepositoryProvider);
    return PagedListNotifier<GoalModel>(
      fetcher: (page, limit) =>
          repo.listPaged(status: status, page: page, limit: limit),
      limit: 20,
    );
  },
);

// ─── Single goal provider ─────────────────────────────────────────────────────
final goalDetailProvider = FutureProvider.family<GoalModel, String>(
  (ref, id) async {
    final repo = ref.read(goalsRepositoryProvider);
    return repo.getById(id);
  },
);
