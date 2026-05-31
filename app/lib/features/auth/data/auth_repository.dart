import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as p;

import '../../../core/errors/failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import 'user_model.dart';

// Web: no serverClientId → signIn() returns accessToken via GIS token client
// Mobile: serverClientId set → signIn() returns idToken via server auth code flow
final _googleSignIn = kIsWeb
    ? GoogleSignIn(scopes: ['email', 'profile', 'openid'])
    : GoogleSignIn(
        serverClientId:
            '382556398073-8qkv4r3fdn3dqqil13mgme341r8uuskh.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

class AuthRepository {
  AuthRepository(this._client);

  final DioClient _client;

  static final _skipAuth = Options(extra: const {'skipAuth': true});

  /// Throws [Failure] with the server's code/message when [ok] is false.
  static void _checkOkOrThrow(dynamic responseData, {int? statusCode}) {
    if (responseData is Map && responseData['ok'] != true) {
      throw Failure(
        (responseData['message'] ?? 'Request failed').toString(),
        code: responseData['code']?.toString(),
        statusCode: statusCode,
      );
    }
  }

  Future<void> sendOtp(String email) async {
    final res = await _client.raw.post(
      '/auth/send-otp',
      data: {'email': email},
      options: _skipAuth,
    );
    _checkOkOrThrow(res.data, statusCode: res.statusCode);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String otp,
    String currency = 'PKR',
  }) async {
    final res = await _client.raw.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password, 'currency': currency, 'otp': otp},
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

  Future<UserModel> googleSignIn() async {
    GoogleSignInAccount? account;

    if (kIsWeb) {
      // 1. Try One Tap (signInSilently) first — returns idToken if user already signed in
      account = await _googleSignIn.signInSilently();
      // 2. Fall back to popup — returns accessToken on web via GIS token client
      account ??= await _googleSignIn.signIn();
    } else {
      account = await _googleSignIn.signIn();
    }

    if (account == null) throw Exception('Google sign-in cancelled');
    final auth = await account.authentication;

    // On web: signInSilently returns idToken (One Tap credential)
    //         signIn() popup returns accessToken (GIS token client)
    // On mobile: signIn() returns idToken (server auth code flow)
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;

    if (idToken == null && accessToken == null) {
      throw Exception('Google authentication failed: no token received');
    }

    final res = await _client.raw.post(
      '/auth/google',
      data: {
        if (idToken != null) 'idToken': idToken,
        if (idToken == null && accessToken != null) 'accessToken': accessToken,
      },
      options: _skipAuth,
    );
    return _persistFromResponse(res.data);
  }

  Future<void> googleSignOut() async {
    await _googleSignIn.signOut();
  }

  Future<void> sendForgotOtp(String email) async {
    final res = await _client.raw.post(
      '/auth/forgot-password/send-otp',
      data: {'email': email},
      options: _skipAuth,
    );
    _checkOkOrThrow(res.data, statusCode: res.statusCode);
  }

  /// Validates the reset OTP without consuming it. The reset call still
  /// re-verifies and deletes the OTP atomically — this exists so the
  /// verify-code screen can fail fast and show errors inline instead of
  /// letting a bad code through to the new-password screen.
  Future<void> verifyResetOtp({required String email, required String otp}) async {
    final res = await _client.raw.post(
      '/auth/forgot-password/verify-otp',
      data: {'email': email, 'otp': otp},
      options: _skipAuth,
    );
    _checkOkOrThrow(res.data, statusCode: res.statusCode);
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final res = await _client.raw.post(
      '/auth/forgot-password/reset',
      data: {'email': email, 'otp': otp, 'newPassword': newPassword},
      options: _skipAuth,
    );
    _checkOkOrThrow(res.data, statusCode: res.statusCode);
  }

  /// Change the password of the logged-in user. The server verifies
  /// [currentPassword] before applying [newPassword]; a wrong current
  /// password (or a Google-only account) surfaces as a [Failure].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _client.raw.patch(
      '/users/me/password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    _checkOkOrThrow(res.data, statusCode: res.statusCode);
  }

  Future<void> deleteAccount() async {
    final res = await _client.raw.delete('/users/me');
    _checkOkOrThrow(res.data, statusCode: res.statusCode);
    await TokenStorage.instance.clear();
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

  /// Upload a new avatar image. On web, [bytes] + [filename] are used
  /// (dart:io File is not available). On mobile, pass [file].
  Future<UserModel> uploadAvatar({File? file, Uint8List? bytes, String? filename}) async {
    MultipartFile multipart;
    if (kIsWeb) {
      if (bytes == null || filename == null) throw ArgumentError('bytes and filename required on web');
      multipart = MultipartFile.fromBytes(bytes, filename: filename);
    } else {
      if (file == null) throw ArgumentError('file required on mobile');
      multipart = await MultipartFile.fromFile(file.path, filename: p.basename(file.path));
    }
    final form = FormData.fromMap({'image': multipart});
    final res = await _client.raw.post('/users/me/avatar', data: form);
    if (res.data is Map && (res.data['ok'] as bool? ?? false)) {
      final data = res.data['data'] as Map<String, dynamic>;
      await TokenStorage.instance.saveUserJson(jsonEncode(data));
      return UserModel.fromJson(data);
    }
    throw Exception('Failed to upload avatar');
  }

  Future<UserModel> _persistFromResponse(dynamic raw) async {
    if (raw is! Map || raw['ok'] != true) {
      throw Failure(
        (raw is Map ? raw['message'] : null)?.toString() ?? 'Auth failed',
        code: (raw is Map ? raw['code'] : null)?.toString(),
      );
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
