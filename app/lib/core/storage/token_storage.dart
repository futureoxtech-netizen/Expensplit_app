import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

/// Cross-platform token storage. Uses secure storage on mobile/desktop,
/// falls back to SharedPreferences on web (web has no keystore).
class TokenStorage {
  TokenStorage._();
  static final instance = TokenStorage._();

  final _secure = const FlutterSecureStorage();

  Future<void> save({required String access, required String refresh}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConstants.accessTokenKey, access);
      await prefs.setString(ApiConstants.refreshTokenKey, refresh);
    } else {
      await _secure.write(key: ApiConstants.accessTokenKey, value: access);
      await _secure.write(key: ApiConstants.refreshTokenKey, value: refresh);
    }
  }

  Future<String?> readAccess() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(ApiConstants.accessTokenKey);
    }
    return _secure.read(key: ApiConstants.accessTokenKey);
  }

  Future<String?> readRefresh() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(ApiConstants.refreshTokenKey);
    }
    return _secure.read(key: ApiConstants.refreshTokenKey);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ApiConstants.accessTokenKey);
      await prefs.remove(ApiConstants.refreshTokenKey);
      await prefs.remove(ApiConstants.userJsonKey);
    } else {
      await _secure.delete(key: ApiConstants.accessTokenKey);
      await _secure.delete(key: ApiConstants.refreshTokenKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ApiConstants.userJsonKey);
    }
  }

  Future<void> saveUserJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.userJsonKey, json);
  }

  Future<String?> readUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.userJsonKey);
  }
}
