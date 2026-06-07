import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/network/socket_service.dart';
import 'core/services/ad_service.dart';
import 'core/services/push_notifications_service.dart';
import 'core/storage/hive_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await HiveSetup.init();
  // Initialize AdMob SDK (Android/iOS only; a no-op elsewhere). Never let an
  // ad init failure block app startup.
  try {
    await AdService.instance.init();
  } catch (_) {}
  // Fire-and-forget — OneSignal SDK init is cheap and we don't want to
  // block first frame waiting for the platform channels.
  unawaited(PushNotificationsService.instance.init());
  // Tell the push service how to check whether the socket is live so it
  // can decide whether to suppress foreground push banners.
  PushNotificationsService.instance.setSocketConnectedCheck(
    () => SocketService.instance.socket?.connected ?? false,
  );

  runApp(const ProviderScope(child: ExpenseApp()));
}
