import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/network/realtime.dart';
import '../core/services/push_notifications_service.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/settings/settings_providers.dart';

class ExpenseApp extends ConsumerStatefulWidget {
  const ExpenseApp({super.key});

  @override
  ConsumerState<ExpenseApp> createState() => _ExpenseAppState();
}

class _ExpenseAppState extends ConsumerState<ExpenseApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Only mobile needs lifecycle-based reconnect; web handles it natively.
    if (!kIsWeb) WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if (!kIsWeb) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Reconnect the socket whenever the app returns to the foreground.
  /// On mobile the OS suspends the TCP connection while backgrounded, so
  /// socket.io's client-side auto-reconnect never fires — we must kick it
  /// manually here.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.authenticated) {
        ref.read(realtimeBridgeProvider).bootstrap();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Hand the router off to the push service so notification taps
    // deep-link to the right screen. Done in build (not initState) so
    // we always have the latest router instance.
    PushNotificationsService.instance.setRouteListener((route) {
      try {
        router.go(route);
      } catch (_) {}
    });

    return MaterialApp.router(
      title: 'Expensplit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
