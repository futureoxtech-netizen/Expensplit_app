/// Result of the `/app/version` check. Drives whether the app shows a soft
/// (dismissible) or forced (blocking) update prompt on launch.
class AppUpdateInfo {
  AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.updateAvailable,
    required this.forceUpdate,
    required this.storeUrl,
    required this.message,
    this.maintenance = false,
    this.maintenanceMessage = '',
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> j) => AppUpdateInfo(
        currentVersion: (j['currentVersion'] ?? '').toString(),
        latestVersion: (j['latestVersion'] ?? '').toString(),
        minSupportedVersion: (j['minSupportedVersion'] ?? '').toString(),
        updateAvailable: j['updateAvailable'] == true,
        forceUpdate: j['forceUpdate'] == true,
        storeUrl: (j['storeUrl'] ?? '').toString(),
        message: (j['message'] ?? '').toString(),
        maintenance: j['maintenance'] == true,
        maintenanceMessage: (j['maintenanceMessage'] ?? '').toString(),
      );

  final String currentVersion;
  final String latestVersion;
  final String minSupportedVersion;
  final bool updateAvailable;
  final bool forceUpdate;
  final String storeUrl;
  final String message;

  /// System maintenance — when true the whole app is blocked until disabled.
  final bool maintenance;
  final String maintenanceMessage;

  /// Whether any prompt (soft or forced) should be shown.
  bool get shouldPrompt => updateAvailable || forceUpdate;
}
