import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/local_store.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/realtime.dart';
import '../../../core/services/push_notifications_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/sync/sync_engine.dart';
import '../data/auth_repository.dart';
import '../data/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(DioClient.instance),
);

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user, this.error});

  final AuthStatus status;
  final UserModel? user;
  final String? error;

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error, bool clearError = false}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, this._realtime) : super(const AuthState()) {
    _bootstrap();
  }

  final AuthRepository _repo;
  final RealtimeBridge _realtime;

  Future<void> _bootstrap() async {
    final cached = await _repo.currentUserFromCache();
    if (cached == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    state = state.copyWith(status: AuthStatus.authenticated, user: cached);
    // Refresh in background; don't block
    _repo.fetchMe().then((u) {
      if (u != null) state = state.copyWith(user: u);
    }).catchError((_) {});
    _realtime.bootstrap();
    PushNotificationsService.instance.loginUser(cached.id);
    _onAuthenticated(cached);
  }

  /// Record the signed-in user for the offline layer and start syncing.
  void _onAuthenticated(UserModel user) {
    LocalStore.instance.setCurrentUser({
      '_id': user.id,
      'name': user.name,
      'email': user.email,
      'avatarUrl': user.avatarUrl,
    });
    SyncEngine.instance.start();
  }

  Future<void> sendOtp(String email) async {
    await _repo.sendOtp(email);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(clearError: true);
    try {
      final user = await _repo.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _realtime.bootstrap();
      await PushNotificationsService.instance.requestPermission();
      await PushNotificationsService.instance.loginUser(user.id);
      _onAuthenticated(user);
    } catch (e) {
      state = state.copyWith(error: _errorMessage(e));
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String otp,
    String currency = 'PKR',
  }) async {
    state = state.copyWith(clearError: true);
    try {
      final user = await _repo.register(
        name: name,
        email: email,
        password: password,
        currency: currency,
        otp: otp,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _realtime.bootstrap();
      await PushNotificationsService.instance.requestPermission();
      await PushNotificationsService.instance.loginUser(user.id);
      _onAuthenticated(user);
    } catch (e) {
      state = state.copyWith(error: _errorMessage(e));
      rethrow;
    }
  }

  Future<void> googleSignIn() async {
    state = state.copyWith(clearError: true);
    try {
      final user = await _repo.googleSignIn();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _realtime.bootstrap();
      await PushNotificationsService.instance.requestPermission();
      await PushNotificationsService.instance.loginUser(user.id);
      _onAuthenticated(user);
    } catch (e) {
      state = state.copyWith(error: _errorMessage(e));
      rethrow;
    }
  }

  Future<void> logout() async {
    // Best-effort flush of pending offline writes while we're still
    // authenticated, so a user who edited offline then logs out doesn't lose
    // those changes. Ignored if offline.
    try {
      await SyncEngine.instance.sync();
    } catch (_) {}
    await _repo.logout();
    _realtime.disconnect();
    await PushNotificationsService.instance.logoutUser();
    await _teardownOffline();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Stop syncing and clear the local DB so the next account starts clean.
  Future<void> _teardownOffline() async {
    SyncEngine.instance.stop();
    await LocalStore.instance.wipe();
  }

  /// Called by the network layer when refresh is no longer possible (refresh
  /// token revoked, expired, or rotated by another device). Clears local state
  /// without hitting the server — the server already considers us logged out.
  Future<void> forceLogout() async {
    if (state.status == AuthStatus.unauthenticated) return;
    _realtime.disconnect();
    await TokenStorage.instance.clear();
    await PushNotificationsService.instance.logoutUser();
    await _teardownOffline();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> sendForgotOtp(String email) async {
    await _repo.sendForgotOtp(email);
  }

  Future<void> verifyResetOtp({required String email, required String otp}) async {
    await _repo.verifyResetOtp(email: email, otp: otp);
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _repo.resetPassword(email: email, otp: otp, newPassword: newPassword);
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  Future<void> updateProfile({
    String? name,
    String? currency,
    String? bio,
    String? groupInvitePolicy,
  }) async {
    final updated = await _repo.updateProfile(
      name: name,
      currency: currency,
      bio: bio,
      groupInvitePolicy: groupInvitePolicy,
    );
    state = state.copyWith(user: updated);
  }

  /// Change the logged-in user's password. Throws if the current password
  /// is wrong or the account has no password (Google sign-in).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Pick & upload a new avatar. Pass [file] on mobile, [bytes]+[filename] on web.
  Future<void> uploadAvatar({File? file, Uint8List? bytes, String? filename}) async {
    final updated = await _repo.uploadAvatar(file: file, bytes: bytes, filename: filename);
    state = state.copyWith(user: updated);
  }

  Future<void> deleteAccount() async {
    await _repo.deleteAccount();
    await _repo.googleSignOut();
    _realtime.disconnect();
    await PushNotificationsService.instance.logoutUser();
    await _teardownOffline();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _errorMessage(Object e) => friendlyError(e);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(realtimeBridgeProvider),
  ),
);
