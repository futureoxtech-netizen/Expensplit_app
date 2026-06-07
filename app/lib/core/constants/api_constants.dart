class ApiConstants {
  ApiConstants._();

  // Override at build time: --dart-define=API_BASE_URL=https://...
  static const _override = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const _production = 'https://expensplitapi.futureoxtech.com';

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // Always use the production server — dev can still override via dart-define.
    return _production;
  }

  static String get apiV1 => '$baseUrl/api/v1';
  static String get socketUrl => baseUrl;

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const userJsonKey = 'auth_user';
}
