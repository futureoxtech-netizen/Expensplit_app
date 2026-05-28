import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../errors/failure.dart';
import '../storage/token_storage.dart';

class DioClient {
  DioClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiV1,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
        responseType: ResponseType.json,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    _dio.interceptors.add(_AuthInterceptor(_dio, () => _onAuthFailure?.call()));
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }
  }

  late final Dio _dio;
  static final DioClient instance = DioClient._();
  Dio get raw => _dio;

  /// Invoked when refresh fails — the session is no longer recoverable
  /// and the app should drop to the sign-in screen. Wire from the auth
  /// layer (see AuthNotifier).
  static void Function()? _onAuthFailure;
  static void setOnAuthFailure(void Function() handler) {
    _onAuthFailure = handler;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get(path, queryParameters: query);
    return _unwrap(res);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body, Map<String, dynamic>? query}) async {
    final res = await _dio.post(path, data: body, queryParameters: query);
    return _unwrap(res);
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    final res = await _dio.patch(path, data: body);
    return _unwrap(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await _dio.delete(path);
    return _unwrap(res);
  }

  Map<String, dynamic> _unwrap(Response res) {
    final data = res.data;
    if (data is Map<String, dynamic>) {
      if (data['ok'] == true) return data;
      throw Failure(
        (data['message'] ?? 'Request failed').toString(),
        code: data['code']?.toString(),
        statusCode: res.statusCode,
      );
    }
    throw Failure('Unexpected response', statusCode: res.statusCode);
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio, this._notifyAuthFailure);

  final Dio _dio;
  final void Function() _notifyAuthFailure;
  bool _refreshing = false;
  Future<bool>? _pendingRefresh;
  bool _failureNotified = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['skipAuth'] != true) {
      final token = await TokenStorage.instance.readAccess();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.statusCode == 401 && response.requestOptions.extra['retried'] != true) {
      // Auth-endpoint 401s mean wrong credentials, not an expired session — never refresh those.
      final path = response.requestOptions.path;
      final isAuthEndpoint = path.startsWith('/auth/login') ||
          path.startsWith('/auth/register') ||
          path.startsWith('/auth/refresh') ||
          path.startsWith('/auth/google') ||
          path.startsWith('/auth/forgot-password');
      if (!isAuthEndpoint) {
        final refreshed = await _attemptRefresh();
        if (refreshed) {
          _failureNotified = false;
          final req = response.requestOptions;
          req.extra['retried'] = true;
          final token = await TokenStorage.instance.readAccess();
          if (token != null) req.headers['Authorization'] = 'Bearer $token';
          try {
            final clone = await _dio.fetch(req);
            return handler.resolve(clone);
          } catch (_) {
            return handler.next(response);
          }
        } else {
          // Refresh failed — session is unrecoverable. Trigger a single
          // force-logout; subsequent 401s in the same burst should not
          // re-fire the handler.
          if (!_failureNotified) {
            _failureNotified = true;
            _notifyAuthFailure();
          }
        }
      }
    }
    handler.next(response);
  }

  // If a refresh is already in flight, wait for it instead of making a
  // second request.  This prevents the race where two concurrent 401s both
  // try to refresh simultaneously and one incorrectly returns false.
  Future<bool> _attemptRefresh() async {
    if (_refreshing) return await (_pendingRefresh ?? Future.value(false));
    _refreshing = true;
    _pendingRefresh = _doRefresh();
    try {
      return await _pendingRefresh!;
    } finally {
      _refreshing = false;
      _pendingRefresh = null;
    }
  }

  Future<bool> _doRefresh() async {
    try {
      final refresh = await TokenStorage.instance.readRefresh();
      if (refresh == null) return false;
      final res = await Dio(BaseOptions(baseUrl: ApiConstants.apiV1)).post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = res.data;
      if (data is Map && data['ok'] == true) {
        final tokens = data['data'];
        await TokenStorage.instance.save(
          access: tokens['accessToken'] as String,
          refresh: tokens['refreshToken'] as String,
        );
        return true;
      }
    } catch (_) {
      // fall through
    }
    return false;
  }
}
