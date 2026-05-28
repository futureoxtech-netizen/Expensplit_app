import '../../../core/network/dio_client.dart';
import '../../../core/pagination/paged_list_notifier.dart';

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
  ActivityRepository(this._client);
  final DioClient _client;

  Future<PagedResult<ActivityItem>> feed({int page = 1, int limit = 50}) async {
    final res = await _client.get('/activity/feed', query: {'page': page, 'limit': limit});
    final data = res['data'] as Map<String, dynamic>;
    final items = ((data['items'] ?? []) as List)
        .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return PagedResult(
      items: items,
      hasMore: (data['hasMore'] as bool?) ?? false,
    );
  }

  Future<PagedResult<ActivityItem>> byGroup(
    String groupId, {
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _client.get(
      '/activity/group/$groupId',
      query: {'page': page, 'limit': limit},
    );
    final data = res['data'] as Map<String, dynamic>;
    final items = ((data['items'] ?? []) as List)
        .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return PagedResult(
      items: items,
      hasMore: (data['hasMore'] as bool?) ?? false,
    );
  }
}
