import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/network/connectivity_service.dart';
import '../core/network/dio_client.dart';
import '../core/network/realtime.dart';
import '../core/services/ad_service.dart';
import '../core/services/in_app_banner.dart';
import '../core/services/push_notifications_service.dart';
import '../core/sync/sync_engine.dart';
import '../features/app_update/app_update_provider.dart';
import '../features/app_update/maintenance_provider.dart';
import '../features/app_update/presentation/maintenance_screen.dart';
import '../features/app_update/presentation/update_dialog.dart';
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
    // When the network layer can't refresh the session (refresh token
    // revoked/expired), force the app back to sign-in instead of leaving
    // the user stuck on an authenticated UI whose every request 401s.
    DioClient.setOnAuthFailure(() {
      if (!mounted) return;
      ref.read(authProvider.notifier).forceLogout();
    });
    // Check for app updates on launch and surface a soft/forced prompt.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  bool _updatePrompted = false;

  Future<void> _checkForUpdate() async {
    if (_updatePrompted) return;
    final info = await ref.read(appUpdateCheckProvider.future);
    if (!mounted || info == null || !info.shouldPrompt) return;
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;
    _updatePrompted = true;
    await showAppUpdateDialog(navContext, info);
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
        SyncEngine.instance.kick();
        // Show the App Open ad every time the app comes back to foreground.
        AdService.instance.showAppOpenAd();
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

    // Give the in-app banner overlay access to the root navigator so
    // socket events can show a transient toast from anywhere in the app.
    InAppBanner.instance.attach(rootNavigatorKey);

    return MaterialApp.router(
      title: 'Expensplit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => _AppGate(child: child),
    );
  }
}

/// Top-level gate wrapping the whole app: shows the blocking maintenance screen
/// when the backend switch is on, otherwise the app + offline banner.
class _AppGate extends ConsumerWidget {
  const _AppGate({required this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(maintenanceProvider).valueOrNull;
    if (info?.maintenance == true) {
      return MaintenanceScreen(message: info!.maintenanceMessage);
    }
    return _OfflineScaffold(child: child);
  }
}

/// Wraps the app with a slim "offline" banner pinned to the bottom that appears
/// whenever connectivity drops. Local writes keep working — they sync when the
/// connection returns.
class _OfflineScaffold extends ConsumerWidget {
  const _OfflineScaffold({required this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider).valueOrNull ?? true;
    return Stack(
      children: [
        if (child != null) child!,
        if (!online)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF2D2D3A),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 15, color: Colors.white70),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "You're offline — changes will sync automatically",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
