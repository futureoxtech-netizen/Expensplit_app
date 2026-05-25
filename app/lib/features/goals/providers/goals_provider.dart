import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/goal_model.dart';
import '../data/goals_repository.dart';

// ─── Repository provider ──────────────────────────────────────────────────────
final goalsRepositoryProvider = Provider<GoalsRepository>(
  (ref) => GoalsRepository(DioClient.instance),
);

// ─── Goals list provider ──────────────────────────────────────────────────────
final goalsListProvider = FutureProvider.family<GoalsPage, String?>(
  (ref, status) async {
    final repo = ref.read(goalsRepositoryProvider);
    return repo.list(status: status);
  },
);

// ─── Single goal provider ─────────────────────────────────────────────────────
final goalDetailProvider = FutureProvider.family<GoalModel, String>(
  (ref, id) async {
    final repo = ref.read(goalsRepositoryProvider);
    return repo.getById(id);
  },
);
