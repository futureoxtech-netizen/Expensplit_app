import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/activity/providers/activity_providers.dart';
import '../../features/expenses/providers/expense_providers.dart';
import '../../features/groups/providers/group_providers.dart';
import 'socket_service.dart';

/// Glue between the socket layer and Riverpod providers.
/// On any server event it invalidates the providers that displayed stale data,
/// so screens already on display refresh automatically.
class RealtimeBridge {
  RealtimeBridge(this._ref);
  final Ref _ref;

  final _joinedGroups = <String>{};
  bool _wired = false;

  Future<void> bootstrap() async {
    await SocketService.instance.connect();
    if (!_wired) _wire();
    await _joinAllUserGroups();
  }

  Future<void> _joinAllUserGroups() async {
    try {
      final groups = await _ref.read(groupRepositoryProvider).list();
      for (final g in groups) {
        if (_joinedGroups.add(g.id)) {
          SocketService.instance.joinGroup(g.id);
        }
      }
    } catch (e) {
      debugPrint('Realtime: failed to join groups: $e');
    }
  }

  void _wire() {
    _wired = true;
    final s = SocketService.instance;

    s.on('expense:created', (data) {
      final groupId = _gid(data);
      if (groupId != null) {
        _ref.invalidate(groupExpensesProvider(groupId));
        _ref.invalidate(groupBalancesProvider(groupId));
      }
      _ref.invalidate(expenseFeedProvider);
      _ref.invalidate(activityFeedProvider);
      _ref.invalidate(monthlyAnalyticsProvider);
    });

    s.on('expense:updated', (data) {
      final groupId = _gid(data);
      if (groupId != null) {
        _ref.invalidate(groupExpensesProvider(groupId));
        _ref.invalidate(groupBalancesProvider(groupId));
      }
      _ref.invalidate(expenseFeedProvider);
    });

    s.on('expense:deleted', (data) {
      final groupId = _gid(data);
      if (groupId != null) {
        _ref.invalidate(groupExpensesProvider(groupId));
        _ref.invalidate(groupBalancesProvider(groupId));
      }
      _ref.invalidate(expenseFeedProvider);
      _ref.invalidate(activityFeedProvider);
    });

    s.on('settlement:created', (data) {
      final groupId = _gid(data);
      if (groupId != null) {
        _ref.invalidate(groupBalancesProvider(groupId));
        _ref.invalidate(groupExpensesProvider(groupId));
      }
      _ref.invalidate(activityFeedProvider);
    });

    s.on('group:updated', (_) {
      _ref.invalidate(groupsListProvider);
    });

    s.on('activity:new', (_) {
      _ref.invalidate(activityFeedProvider);
    });
  }

  String? _gid(dynamic data) {
    if (data is Map && data['groupId'] != null) return data['groupId'].toString();
    return null;
  }

  void joinGroup(String id) {
    if (_joinedGroups.add(id)) SocketService.instance.joinGroup(id);
  }

  void disconnect() {
    _joinedGroups.clear();
    _wired = false;
    SocketService.instance.disconnect();
  }
}

final realtimeBridgeProvider = Provider<RealtimeBridge>((ref) => RealtimeBridge(ref));
