import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_setup.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/activity_repository.dart';
import 'activity_providers.dart';

const _kLastSeenKey = 'activity_last_seen_at';

DateTime _readLastSeen() {
  final box = Hive.box(HiveSetup.settingsBox);
  final iso = box.get(_kLastSeenKey) as String?;
  if (iso == null) return DateTime.fromMillisecondsSinceEpoch(0);
  return DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

Future<void> _writeLastSeen(DateTime when) async {
  final box = Hive.box(HiveSetup.settingsBox);
  await box.put(_kLastSeenKey, when.toIso8601String());
}

class UnreadActivityNotifier extends StateNotifier<int> {
  UnreadActivityNotifier(this._ref) : super(0) {
    _ref.listen(activityFeedProvider, (prev, next) {
      final items = next.items;
      if (items != null) {
        _recompute(items);
      } else if (!next.isLoadingFirst && next.error == null) {
        // Feed was invalidated (reset to initial state) by a socket event.
        // Kick off a background reload so the unread count stays accurate
        // without requiring the user to open the Activity screen first.
        _ref.read(activityFeedProvider.notifier).loadFirst();
      }
    });
    // Initial compute when feed already has data; otherwise kick off a load
    // so the badge is accurate on app open without first opening Activity.
    final state = _ref.read(activityFeedProvider);
    if (state.items != null) {
      _recompute(state.items!);
    } else if (!state.isLoadingFirst) {
      _ref.read(activityFeedProvider.notifier).loadFirst();
    }
  }

  final Ref _ref;

  void _recompute(List<ActivityItem> items) {
    final lastSeen = _readLastSeen();
    final myId = _ref.read(authProvider).user?.id;
    var count = 0;
    for (final a in items) {
      // Don't count the user's own actions as unread notifications.
      if (a.actorId != null && a.actorId == myId) continue;
      if (a.createdAt.isAfter(lastSeen)) count += 1;
    }
    state = count;
  }

  Future<void> markAllRead() async {
    await _writeLastSeen(DateTime.now());
    state = 0;
  }
}

final unreadActivityProvider =
    StateNotifierProvider<UnreadActivityNotifier, int>((ref) => UnreadActivityNotifier(ref));
