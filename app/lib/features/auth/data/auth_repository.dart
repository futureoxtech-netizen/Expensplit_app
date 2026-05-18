import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import 'user_model.dart';

class AuthRepository {
  AuthRepository(this._client);

  final DioClient _client;

  static final _skipAuth = Options(extra: const {'skipAuth': true});

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String currency = 'USD',
  }) async {
    final res = await _client.raw.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password, 'currency': currency},
      options: _skipAuth,
    );
    return _persistFromResponse(res.data);
  }

  Future<UserModel> login({required String email, required String password}) async {
    final res = await _client.raw.post(
      '/auth/login',
      data: {'email': email, 'password': password},
      options: _skipAuth,
    );
    return _persistFromResponse(res.data);
  }

  Future<void> logout() async {
    try {
      final refresh = await TokenStorage.instance.readRefresh();
      if (refresh != null) {
        await _client.raw.post('/auth/logout', data: {'refreshToken': refresh});
      }
    } catch (_) {
      // ignore — clearing is the important part
    }
    await TokenStorage.instance.clear();
  }

  Future<UserModel?> currentUserFromCache() async {
    final json = await TokenStorage.instance.readUserJson();
    if (json == null) return null;
    return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<UserModel?> fetchMe() async {
    final access = await TokenStorage.instance.readAccess();
    if (access == null) return null;
    final res = await _client.raw.get('/auth/me');
    if (res.data is Map && (res.data['ok'] as bool? ?? false)) {
      final data = res.data['data'];
      if (data is Map<String, dynamic>) {
        await TokenStorage.instance.saveUserJson(jsonEncode(data));
        return UserModel.fromJson(data);
      }
    }
    return null;
  }

  Future<UserModel> updateProfile({String? name, String? currency, String? bio}) async {
    final res = await _client.raw.patch(
      '/users/me',
      data: {
        if (name != null) 'name': name,
        if (currency != null) 'currency': currency,
        if (bio != null) 'bio': bio,
      },
    );
    if (res.data is Map && (res.data['ok'] as bool? ?? false)) {
      final data = res.data['data'] as Map<String, dynamic>;
      await TokenStorage.instance.saveUserJson(jsonEncode(data));
      return UserModel.fromJson(data);
    }
    throw Exception('Failed to update profile');
  }

  Future<UserModel> _persistFromResponse(dynamic raw) async {
    if (raw is! Map || raw['ok'] != true) {
      final msg = (raw is Map ? raw['message'] : null)?.toString() ?? 'Auth failed';
      throw Exception(msg);
    }
    final data = raw['data'] as Map<String, dynamic>;
    await TokenStorage.instance.save(
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await TokenStorage.instance.saveUserJson(jsonEncode(user.toJson()));
    return user;
  }
}
