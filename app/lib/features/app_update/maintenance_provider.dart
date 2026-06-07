import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_update_provider.dart';
import 'data/app_update_model.dart';

/// Polls the version/config endpoint so the app can react to the backend
/// maintenance switch. While maintenance is on the app is blocked; the poll
/// keeps running so the block lifts automatically once it's turned off.
final maintenanceProvider = StreamProvider<AppUpdateInfo?>((ref) async* {
  final repo = ref.read(appUpdateRepositoryProvider);
  while (true) {
    AppUpdateInfo? info;
    try {
      info = await repo.check();
    } catch (_) {
      info = null;
    }
    yield info;
    // Poll faster while under maintenance so recovery is snappy; relax otherwise.
    final delay = (info?.maintenance ?? false)
        ? const Duration(seconds: 12)
        : const Duration(minutes: 5);
    await Future<void>.delayed(delay);
  }
});

/// Convenience: just the boolean "is the app under maintenance right now".
final isUnderMaintenanceProvider = Provider<bool>((ref) {
  return ref.watch(maintenanceProvider).valueOrNull?.maintenance ?? false;
});
