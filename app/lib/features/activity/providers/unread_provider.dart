import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_setup.dart';
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
    _ref.listen(activityFeedProvider, (_, next) {
      final items = next.items;
      if (items != null) _recompute(items);
    });
    // Initial compute when feed already has data.
    final items = _ref.read(activityFeedProvider).items;
    if (items != null) _recompute(items);
  }

  final Ref _ref;

  void _recompute(List<ActivityItem> items) {
    final lastSeen = _readLastSeen();
    var count = 0;
    for (final a in items) {
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
