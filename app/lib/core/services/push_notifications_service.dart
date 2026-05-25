import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../network/dio_client.dart';

/// Thin wrapper around the OneSignal SDK that:
///   • initialises OneSignal once on app boot
///   • requests notification permission on first launch
///   • ties the device to the backend user via `OneSignal.login(userId)`
///   • posts the device subscription id back to the API so we can debug
///     delivery problems server-side
///
/// The class is web-safe — on web the OneSignal Flutter SDK is a no-op so
/// every call short-circuits gracefully.
class PushNotificationsService {
  PushNotificationsService._();
  static final PushNotificationsService instance = PushNotificationsService._();

  static const _appId = 'f46f123a-8bb2-4871-909c-3549ad4f028d';

  bool _initialised = false;
  String? _loggedUserId;

  /// Optional callback supplied by the socket layer so the push service
  /// can check whether a live socket connection exists before suppressing
  /// foreground push banners.
  bool Function()? _isSocketConnected;

  /// Call this once after [init] to wire up the socket-connectivity check.
  // ignore: use_setters_to_change_properties
  void setSocketConnectedCheck(bool Function() check) {
    _isSocketConnected = check;
  }

  /// Routes that fired while no listener was attached (e.g. push tapped
  /// from a cold start before the router was built). The first router
  /// listener drains the buffer.
  final _pendingRoutes = <String>[];
  void Function(String route)? _routeListener;

  /// Register a router callback. Called immediately with any pending
  /// route that arrived before the listener was attached.
  void setRouteListener(void Function(String route) listener) {
    _routeListener = listener;
    for (final r in _pendingRoutes) {
      try {
        listener(r);
      } catch (_) {}
    }
    _pendingRoutes.clear();
  }

  void _dispatchRoute(String? route) {
    if (route == null || route.isEmpty) return;
    final l = _routeListener;
    if (l == null) {
      _pendingRoutes.add(route);
    } else {
      l(route);
    }
  }

  Future<void> init() async {
    if (_initialised || kIsWeb) return;
    _initialised = true;
    try {
      OneSignal.Debug.setLogLevel(
        kReleaseMode ? OSLogLevel.warn : OSLogLevel.info,
      );
      OneSignal.initialize(_appId);

      // Suppress the OS banner only when the socket is live — in that case
      // the in-app socket event has already refreshed the UI so a second
      // banner would be duplicate noise.
      // If the socket is disconnected (e.g. app just resumed from background
      // and reconnect hasn't finished yet) we let the push through so the
      // user isn't silently left without any notification at all.
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        if (_isSocketConnected != null && _isSocketConnected!()) {
          event.preventDefault();
        }
        // otherwise: show the system banner normally
      });

      OneSignal.Notifications.addClickListener((event) {
        final route = event.notification.additionalData?['route']?.toString();
        debugPrint('Push tapped → route=$route');
        _dispatchRoute(route);
      });

      OneSignal.User.pushSubscription.addObserver((_) {
        _syncSubscriptionId();
      });
    } catch (e) {
      debugPrint('OneSignal init failed: $e');
    }
  }

  /// Ask the OS for notification permission. Safe to call multiple times;
  /// the SDK only shows the prompt on the first call.
  Future<void> requestPermission() async {
    if (kIsWeb) return;
    try {
      await OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      debugPrint('OneSignal requestPermission failed: $e');
    }
  }

  /// Bind the current device to a backend user. Call after every successful
  /// sign-in (login, register, Google).
  Future<void> loginUser(String userId) async {
    if (kIsWeb) return;
    if (_loggedUserId == userId) return;
    try {
      await OneSignal.login(userId);
      _loggedUserId = userId;
      // The subscription id may already exist by the time we log in — push
      // it now in addition to the observer above.
      await _syncSubscriptionId();
    } catch (e) {
      debugPrint('OneSignal login failed: $e');
    }
  }

  Future<void> logoutUser() async {
    if (kIsWeb) return;
    _loggedUserId = null;
    try {
      await OneSignal.logout();
    } catch (e) {
      debugPrint('OneSignal logout failed: $e');
    }
  }

  Future<void> _syncSubscriptionId() async {
    if (kIsWeb) return;
    try {
      final id = OneSignal.User.pushSubscription.id;
      if (id == null || id.isEmpty) return;
      await DioClient.instance.raw.post(
        '/users/me/push-subscription',
        data: {'subscriptionId': id},
      );
    } catch (e) {
      // Non-fatal — backend can still target external_id directly.
      debugPrint('Failed to sync OneSignal subscription id: $e');
    }
  }

}
