import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  io.Socket? get socket => _socket;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;
    final token = await TokenStorage.instance.readAccess();
    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token ?? ''})
          .build(),
    );
    _socket!.onConnect((_) => debugPrint('socket connected'));
    _socket!.onDisconnect((_) => debugPrint('socket disconnected'));
    _socket!.onConnectError((e) => debugPrint('socket connect error: $e'));
    _socket!.connect();
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
