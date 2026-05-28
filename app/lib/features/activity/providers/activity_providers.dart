import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import '../data/activity_repository.dart';

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(DioClient.instance),
);

/// Global activity feed. Uses [PagedListNotifier] for infinite scroll —
/// callers should `read(activityFeedProvider.notifier).loadFirst()` from
/// initState (the sliver does that automatically) and `loadMore()` from a
/// scroll listener.
final activityFeedProvider = StateNotifierProvider.autoDispose<
    PagedListNotifier<ActivityItem>, PagedListState<ActivityItem>>((ref) {
  final repo = ref.watch(activityRepositoryProvider);
  return PagedListNotifier<ActivityItem>(
    fetcher: (page, limit) => repo.feed(page: page, limit: limit),
    limit: 30,
  );
});

/// Per-group activity. Kept separate so dashboards / group screens can
/// scroll independently of the main feed.
final groupActivityProvider = StateNotifierProvider.autoDispose.family<
    PagedListNotifier<ActivityItem>, PagedListState<ActivityItem>, String>(
  (ref, gid) {
    final repo = ref.watch(activityRepositoryProvider);
    return PagedListNotifier<ActivityItem>(
      fetcher: (page, limit) => repo.byGroup(gid, page: page, limit: limit),
      limit: 30,
    );
  },
);
