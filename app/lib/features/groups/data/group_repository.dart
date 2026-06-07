import '../../../core/db/local_store.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/sync/sync_engine.dart';
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
  final _store = LocalStore.instance;

  Future<List<GroupModel>> list() async {
    final list = await _store.watchGroupsJson().first;
    return list.map((j) => GroupModel.fromJson(j)).toList();
  }

  Future<GroupModel> create({
    required String name,
    String description = '',
    String category = 'other',
    String? coverColor,
    String? currency,
    List<String> memberEmails = const [],
  }) async {
    final id = await _store.createGroupLocal(
      name: name,
      description: description,
      category: category,
      coverColor: coverColor,
      currency: currency,
      memberEmails: memberEmails,
    );
    SyncEngine.instance.kick();
    return GroupModel.fromJson((await _store.watchGroupJson(id).first)!);
  }

  Future<GroupModel> getById(String id) async =>
      GroupModel.fromJson((await _store.watchGroupJson(id).first)!);

  Future<GroupModel> update(
    String id, {
    String? name,
    String? description,
    String? category,
    String? coverColor,
    String? currency,
  }) async {
    await _store.updateGroupLocal(id, {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (coverColor != null) 'coverColor': coverColor,
      if (currency != null) 'currency': currency,
    });
    SyncEngine.instance.kick();
    return GroupModel.fromJson((await _store.watchGroupJson(id).first)!);
  }

  /// Update the group's shared notes (any member can edit) — offline-first.
  Future<GroupModel> updateNotes(String id, String notes) async {
    await _store.updateGroupNotesLocal(id, notes);
    SyncEngine.instance.kick();
    return GroupModel.fromJson((await _store.watchGroupJson(id).first)!);
  }

  // ── Online-only membership ops (need the server); they upsert the returned
  //    group into the local DB so screens reflect the change immediately. ──
  Future<GroupModel> joinByCode(String code) async {
    final res = await _client.post('/groups/join', body: {'code': code});
    final json = res['data'] as Map<String, dynamic>;
    await _store.applyPull({'groups': [json]});
    SyncEngine.instance.kick();
    return GroupModel.fromJson(json);
  }

  Future<AddMemberOutcome> addMember(String groupId, String email) async {
    final res =
        await _client.post('/groups/$groupId/members', body: {'email': email});
    final json = res['data'] as Map<String, dynamic>;
    await _store.applyPull({'groups': [json]});
    return AddMemberOutcome(
      group: GroupModel.fromJson(json),
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
    final json = res['data'] as Map<String, dynamic>;
    await _store.applyPull({'groups': [json]});
    return GroupModel.fromJson(json);
  }

  /// Remove a member from the group. Used for guests added by mistake; the
  /// server rejects removal if the member already has expenses/settlements.
  Future<GroupModel> removeMember(String groupId, String memberId) async {
    final res = await _client.delete('/groups/$groupId/members/$memberId');
    final json = res['data'] as Map<String, dynamic>;
    await _store.applyPull({'groups': [json]});
    return GroupModel.fromJson(json);
  }

  /// Leave a group. Returns true if leaving dissolved the group entirely
  /// (you were the last real member), false if it lives on without you.
  /// Throws if you still have an unsettled balance.
  Future<bool> leave(String groupId) async {
    final res = await _client.post('/groups/$groupId/leave');
    final data = res['data'];
    // Drop the group locally — we're no longer in it.
    await _store.applyPull({'deletions': [{'entityType': 'group', 'entityId': groupId}]});
    SyncEngine.instance.kick();
    return data is Map && data['deleted'] == true;
  }

  /// Permanently delete a group for everyone. Owner-only on the server.
  Future<void> deleteGroup(String groupId) async {
    await _client.delete('/groups/$groupId');
    await _store.applyPull({'deletions': [{'entityType': 'group', 'entityId': groupId}]});
    SyncEngine.instance.kick();
  }

  Future<GroupBalances> balances(String groupId) async {
    return GroupBalances.fromJson(await _store.watchGroupBalancesJson(groupId).first);
  }
}
