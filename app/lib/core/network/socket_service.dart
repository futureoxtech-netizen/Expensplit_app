import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  io.Socket? get socket => _socket;

  /// Callbacks fired every time the socket reaches a connected state —
  /// including auto-reconnects. The realtime bridge uses this to put
  /// the user back into their group rooms after a transient disconnect.
  final List<VoidCallback> _connectCallbacks = [];

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;
    // Dispose stale socket before creating a fresh one to avoid resource
    // leaks and duplicate event-handler registrations.
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }
    final token = await TokenStorage.instance.readAccess();
    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          // websocket is preferred; polling is the fallback for mobile
          // networks that sit behind proxies blocking raw WebSocket upgrades.
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token ?? ''})
          .build(),
    );
    _socket!.onConnect((_) {
      debugPrint('socket connected');
      for (final cb in _connectCallbacks) {
        cb();
      }
    });
    _socket!.onDisconnect((_) => debugPrint('socket disconnected'));
    _socket!.onConnectError((e) => debugPrint('socket connect error: $e'));
    _socket!.connect();
  }

  /// Register a callback fired every time the socket transitions to
  /// connected. Idempotent — duplicate registrations are ignored.
  void onConnect(VoidCallback cb) {
    if (!_connectCallbacks.contains(cb)) _connectCallbacks.add(cb);
  }

  void joinGroup(String groupId) {
    _socket?.emit('group:join', {'groupId': groupId});
  }

  void leaveGroup(String groupId) {
    _socket?.emit('group:leave', {'groupId': groupId});
  }

  void on(String event, void Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
