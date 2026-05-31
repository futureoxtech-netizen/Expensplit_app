import '../../../core/network/dio_client.dart';
import 'group_model.dart';

/// Result of adding someone to a group. [status] is one of:
///   • `added`          — they're now a member
///   • `pending`        — an invitation was sent; they must accept first
///   • `already_member` — they were already in the group
class AddMemberOutcome {
  AddMemberOutcome({required this.group, required this.status});
  final GroupModel group;
  final String status;

  bool get isPending => status == 'pending';
}

class GroupRepository {
  GroupRepository(this._client);
  final DioClient _client;

  Future<List<GroupModel>> list() async {
    final res = await _client.get('/groups');
    final data = res['data'] as List;
    return data
        .map((j) => GroupModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<GroupModel> create({
    required String name,
    String description = '',
    String category = 'other',
    String? coverColor,
    String? currency,
    List<String> memberEmails = const [],
  }) async {
    final res = await _client.post('/groups', body: {
      'name': name,
      'description': description,
      'category': category,
      if (coverColor != null) 'coverColor': coverColor,
      if (currency != null) 'currency': currency,
      'memberEmails': memberEmails,
    });
    return GroupModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<GroupModel> getById(String id) async {
    final res = await _client.get('/groups/$id');
    return GroupModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<GroupModel> update(
    String id, {
    String? name,
    String? description,
    String? category,
    String? coverColor,
    String? currency,
  }) async {
    final res = await _client.patch('/groups/$id', body: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (coverColor != null) 'coverColor': coverColor,
      if (currency != null) 'currency': currency,
    });
    return GroupModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<GroupModel> joinByCode(String code) async {
    final res = await _client.post('/groups/join', body: {'code': code});
    return GroupModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<AddMemberOutcome> addMember(String groupId, String email) async {
    final res =
        await _client.post('/groups/$groupId/members', body: {'email': email});
    return AddMemberOutcome(
      group: GroupModel.fromJson(res['data'] as Map<String, dynamic>),
      status: (res['status'] ?? 'added').toString(),
    );
  }

  /// Group invitations the current user has received but not yet accepted.
  Future<List<GroupInvite>> listInvites() async {
    final res = await _client.get('/groups/invites');
    final data = (res['data'] ?? []) as List;
    return data
        .map((j) => GroupInvite.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Accept a pending invitation → become a member of the group.
  Future<GroupModel> acceptInvite(String groupId) async {
    final res = await _client.post('/groups/$groupId/invites/accept');
    return GroupModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// Decline a pending invitation → it's removed.
  Future<void> declineInvite(String groupId) async {
    await _client.post('/groups/$groupId/invites/decline');
  }

  /// Add a "guest" member (someone not on Expensplit) so expenses can be
  /// split with them. Returns the updated group with the new member.
  Future<GroupModel> addPlaceholder(String groupId, String name) async {
    final res = await _client.post(
      '/groups/$groupId/placeholders',
      body: {'name': name},
    );
    return GroupModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// Remove a member from the group. Used for guests added by mistake; the
  /// server rejects removal if the member already has expenses/settlements.
  Future<GroupModel> removeMember(String groupId, String memberId) async {
    final res = await _client.delete('/groups/$groupId/members/$memberId');
    return GroupModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// Leave a group. Returns true if leaving dissolved the group entirely
  /// (you were the last real member), false if it lives on without you.
  /// Throws if you still have an unsettled balance.
  Future<bool> leave(String groupId) async {
    final res = await _client.post('/groups/$groupId/leave');
    final data = res['data'];
    return data is Map && data['deleted'] == true;
  }

  /// Permanently delete a group for everyone. Owner-only on the server.
  Future<void> deleteGroup(String groupId) async {
    await _client.delete('/groups/$groupId');
  }

  Future<GroupBalances> balances(String groupId) async {
    final res = await _client.get('/groups/$groupId/balances');
    return GroupBalances.fromJson(res['data'] as Map<String, dynamic>);
  }
}
