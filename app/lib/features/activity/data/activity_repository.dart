import '../../../core/db/local_store.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import '../../../core/sync/sync_engine.dart';

class ActivityItem {
  ActivityItem({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.actorId,
    this.actorName,
    this.actorAvatar,
    this.groupName,
    this.groupColor,
    this.groupId,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> j) {
    final actor = j['actor'];
    final group = j['group'];
    return ActivityItem(
      id: (j['_id'] ?? j['id']).toString(),
      type: j['type']?.toString() ?? 'event',
      message: j['message']?.toString() ?? '',
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      actorId: actor is Map ? (actor['_id'] ?? actor['id'])?.toString() : null,
      actorName: actor is Map ? actor['name']?.toString() : null,
      actorAvatar: actor is Map ? actor['avatarUrl']?.toString() : null,
      groupId: group is Map ? (group['_id'] ?? group['id'])?.toString() : group?.toString(),
      groupName: group is Map ? group['name']?.toString() : null,
      groupColor: group is Map ? group['coverColor']?.toString() : null,
    );
  }

  final String id;
  final String type;
  final String message;
  final DateTime createdAt;
  final String? actorId;
  final String? actorName;
  final String? actorAvatar;
  final String? groupName;
  final String? groupColor;
  final String? groupId;
}

class ActivityRepository {
  ActivityRepository();
  final _store = LocalStore.instance;

  Future<PagedResult<ActivityItem>> feed({int page = 1, int limit = 50}) async {
    SyncEngine.instance.kick();
    final list = await _store.activityPage(limit: limit, offset: (page - 1) * limit);
    return PagedResult(
        items: list.map((j) => ActivityItem.fromJson(j)).toList(), hasMore: list.length == limit);
  }

  Future<PagedResult<ActivityItem>> byGroup(
    String groupId, {
    int page = 1,
    int limit = 50,
  }) async {
    final list =
        await _store.activityPage(groupId: groupId, limit: limit, offset: (page - 1) * limit);
    return PagedResult(
        items: list.map((j) => ActivityItem.fromJson(j)).toList(), hasMore: list.length == limit);
  }
}
