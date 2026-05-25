import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/socket_service.dart';

/// A single in-app notification, surfaced via the `notification:new`
/// socket event (the backend fires the same payload through both the
/// socket and OneSignal push — the client de-duplicates by [id]).
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.data = const {},
    this.read = false,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        createdAt: createdAt,
        data: data,
        read: read ?? this.read,
      );

  factory AppNotification.fromJson(Map raw) {
    final id = raw['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString();
    DateTime ts;
    try {
      ts = DateTime.parse(raw['createdAt']?.toString() ?? '').toLocal();
    } catch (_) {
      ts = DateTime.now();
    }
    final data = raw['data'];
    return AppNotification(
      id: id,
      type: raw['type']?.toString() ?? 'generic',
      title: raw['title']?.toString() ?? '',
      message: raw['message']?.toString() ?? '',
      createdAt: ts,
      data: data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }
}

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(const []) {
    _wire();
  }

  static const _maxKept = 100;
  final _seenIds = <String>{};

  void _wire() {
    SocketService.instance.on('notification:new', (data) {
      if (data is! Map) return;
      final n = AppNotification.fromJson(data);
      if (!_seenIds.add(n.id)) return; // de-dup against push
      final next = [n, ...state];
      if (next.length > _maxKept) next.removeRange(_maxKept, next.length);
      state = next;
    });
  }

  void markAllRead() {
    if (state.every((n) => n.read)) return;
    state = [for (final n in state) n.copyWith(read: true)];
  }

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(read: true) else n,
    ];
  }

  void clear() {
    _seenIds.clear();
    state = const [];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(),
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider);
  return list.where((n) => !n.read).length;
});
