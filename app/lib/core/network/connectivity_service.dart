import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the device currently has a network path. This is a coarse
/// signal (connectivity_plus reports the interface, not real reachability), so
/// the SyncEngine still treats network errors as "try again later" — but it's
/// enough to drive the offline banner and to kick a sync the moment Wi-Fi/data
/// comes back.
class ConnectivityService {
  ConnectivityService._() {
    _sub = Connectivity().onConnectivityChanged.listen(_onChange);
    _init();
  }

  static final ConnectivityService instance = ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  late final StreamSubscription _sub;
  bool _online = true;

  bool get isOnline => _online;
  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> _init() async {
    final result = await Connectivity().checkConnectivity();
    _onChange(result);
  }

  void _onChange(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _online) {
      _online = online;
      _controller.add(online);
    } else {
      _online = online;
    }
  }

  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}

/// `true` when the device appears to be online. Reactive — the offline banner
/// and any "online-only" affordances watch this.
final onlineProvider = StreamProvider<bool>((ref) async* {
  yield ConnectivityService.instance.isOnline;
  yield* ConnectivityService.instance.onStatusChange;
});
