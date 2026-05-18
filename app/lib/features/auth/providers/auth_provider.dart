import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_messages.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/realtime.dart';
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
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(clearError: true);
    try {
      final user = await _repo.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _realtime.bootstrap();
    } catch (e) {
      state = state.copyWith(error: _errorMessage(e));
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String currency = 'USD',
  }) async {
    state = state.copyWith(clearError: true);
    try {
      final user = await _repo.register(
        name: name,
        email: email,
        password: password,
        currency: currency,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _realtime.bootstrap();
    } catch (e) {
      state = state.copyWith(error: _errorMessage(e));
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _realtime.disconnect();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  Future<void> updateProfile({String? name, String? currency, String? bio}) async {
    final updated = await _repo.updateProfile(name: name, currency: currency, bio: bio);
    state = state.copyWith(user: updated);
  }

  String _errorMessage(Object e) => friendlyError(e);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(realtimeBridgeProvider),
  ),
);
