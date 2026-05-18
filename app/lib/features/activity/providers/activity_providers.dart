import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/activity_repository.dart';

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(DioClient.instance),
);

final activityFeedProvider = FutureProvider.autoDispose<List<ActivityItem>>((ref) async {
  return ref.watch(activityRepositoryProvider).feed();
});

final groupActivityProvider =
    FutureProvider.autoDispose.family<List<ActivityItem>, String>((ref, gid) async {
  return ref.watch(activityRepositoryProvider).byGroup(gid);
});
