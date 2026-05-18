import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // For Android emulator, host machine is 10.0.2.2. For web/desktop, use localhost.
  // Override at build time with: --dart-define=API_BASE_URL=http://192.168.x.x:4000
  static const _override = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:4000';
    // For physical Android devices, change to your machine LAN IP via --dart-define.
    return 'http://10.0.2.2:4000';
  }

  static String get apiV1 => '$baseUrl/api/v1';
  static String get socketUrl => baseUrl;

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const userJsonKey = 'auth_user';
}
