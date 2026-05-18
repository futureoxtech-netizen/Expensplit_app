import '../../../core/network/dio_client.dart';
import 'group_model.dart';

class GroupRepository {
  GroupRepository(this._client);
  final DioClient _client;

  Future<List<GroupModel>> list() async {
    final res = await _client.get('/groups');
    final data = res['data'] as List;
    return data.map((j) => GroupModel.fromJson(j as Map<String, dynamic>)).toList();
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

  Future<GroupModel> addMember(String groupId, String email) async {
    final res = await _client.post('/groups/$groupId/members', body: {'email': email});
    return GroupModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> leave(String groupId) async {
    await _client.post('/groups/$groupId/leave');
  }

  Future<GroupBalances> balances(String groupId) async {
    final res = await _client.get('/groups/$groupId/balances');
    return GroupBalances.fromJson(res['data'] as Map<String, dynamic>);
  }
}
