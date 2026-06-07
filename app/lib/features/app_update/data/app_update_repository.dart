import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/network/dio_client.dart';
import 'app_update_model.dart';

class AppUpdateRepository {
  AppUpdateRepository(this._client);
  final DioClient _client;

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  /// Reads the running app's version and asks the backend whether a soft or
  /// forced update is required. Returns null on any failure so a flaky network
  /// never blocks app launch.
  Future<AppUpdateInfo?> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final res = await _client.get('/app/version', query: {
        'platform': _platform,
        'version': info.version,
      });
      final data = res['data'];
      if (data is Map<String, dynamic>) return AppUpdateInfo.fromJson(data);
      return null;
    } catch (_) {
      return null;
    }
  }
}
