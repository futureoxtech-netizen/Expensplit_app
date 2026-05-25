import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/activity/providers/activity_providers.dart';
import '../../features/expenses/providers/expense_providers.dart';
import '../../features/groups/providers/group_providers.dart';
import 'socket_service.dart';

/// Helpers that invalidate every parameterised provider for a family —
/// Riverpod does not expose a one-call API for this, so we drop the entire
/// family by invalidating the top-level provider object.
void _invalidateFriendCaches(Ref ref) {
  ref.invalidate(friendsSummaryProvider);
  ref.invalidate(friendDetailProvider);
}

/// Glue between the socket layer and Riverpod providers.
/// On any server event it invalidates the providers that displayed stale
/// data, so screens already on display refresh automatically.
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

  /// Re-join every cached group room. Socket.IO drops room membership on
  /// disconnect, so after the auto-reconnect we have to walk back through
  /// and ask the server to put us back in each `group:<id>` room.
  void _rejoinCachedGroups() {
    for (final id in _joinedGroups) {
      SocketService.instance.joinGroup(id);
    }
  }

  void _wire() {
    _wired = true;
    final s = SocketService.instance;

    // Re-join all known groups whenever the socket reconnects.
    s.onConnect(() {
      _rejoinCachedGroups();
      // Also refresh the groups list in case the server has new entries
      // we haven't been listening to yet.
      _joinAllUserGroups();
    });

    s.on('expense:created', (data) {
      final groupId = _gid(data);
      if (groupId != null) {
        _ref.invalidate(groupExpensesProvider(groupId));
        _ref.invalidate(groupBalancesProvider(groupId));
      }
      _ref.invalidate(expenseFeedProvider);
      _ref.invalidate(activityFeedProvider);
      _ref.invalidate(monthlyAnalyticsProvider);
      // A new expense changes pairwise balances with every sharer, so
      // friend summaries must refresh too.
      _invalidateFriendCaches(_ref);
    });

    s.on('expense:updated', (data) {
      final groupId = _gid(data);
      final expenseId = _eid(data);
      if (groupId != null) {
        _ref.invalidate(groupExpensesProvider(groupId));
        _ref.invalidate(groupBalancesProvider(groupId));
      }
      if (expenseId != null) {
        _ref.invalidate(expenseDetailProvider(expenseId));
      }
      _ref.invalidate(expenseFeedProvider);
      _ref.invalidate(activityFeedProvider);
      _ref.invalidate(monthlyAnalyticsProvider);
      _invalidateFriendCaches(_ref);
    });

    s.on('expense:deleted', (data) {
      final groupId = _gid(data);
      final expenseId = _eid(data);
      if (groupId != null) {
        _ref.invalidate(groupExpensesProvider(groupId));
        _ref.invalidate(groupBalancesProvider(groupId));
      }
      if (expenseId != null) {
        _ref.invalidate(expenseDetailProvider(expenseId));
      }
      _ref.invalidate(expenseFeedProvider);
      _ref.invalidate(activityFeedProvider);
      _ref.invalidate(monthlyAnalyticsProvider);
      _invalidateFriendCaches(_ref);
    });

    s.on('settlement:created', (data) {
      final groupId = _gid(data);
      if (groupId != null) {
        _ref.invalidate(groupBalancesProvider(groupId));
        _ref.invalidate(groupExpensesProvider(groupId));
      }
      _ref.invalidate(activityFeedProvider);
      // Settling up reduces the friend's net to/from us.
      _invalidateFriendCaches(_ref);
    });

    s.on('group:updated', (_) {
      _ref.invalidate(groupsListProvider);
      // New / removed members reshape the friend list.
      _invalidateFriendCaches(_ref);
    });

    s.on('activity:new', (data) {
      _ref.invalidate(activityFeedProvider);
      // Make sure we're in the originating group's room going forward so
      // follow-up `expense:*` / `settlement:*` events arrive without
      // waiting for the next bootstrap.
      final groupId = _gid(data);
      if (groupId != null && _joinedGroups.add(groupId)) {
        SocketService.instance.joinGroup(groupId);
      }
    });

    // Backstop for missed group-room events. The server's notification
    // service emits this to the user's personal room (`user:<id>`), so
    // every user who is meant to see the event receives it — even if
    // they're on Home and haven't joined the relevant `group:<id>` room
    // yet (e.g. they joined the group during this session).
    s.on('notification:new', (data) {
      final type = data is Map ? data['type']?.toString() : null;
      final inner = data is Map && data['data'] is Map ? data['data'] as Map : null;
      final groupId = inner?['groupId']?.toString();
      final expenseId = inner?['expenseId']?.toString();
      if (groupId != null) {
        // Make sure we're in this room going forward, then invalidate caches.
        if (_joinedGroups.add(groupId)) {
          SocketService.instance.joinGroup(groupId);
        }
        _ref.invalidate(groupExpensesProvider(groupId));
        _ref.invalidate(groupBalancesProvider(groupId));
      }
      if (expenseId != null) {
        _ref.invalidate(expenseDetailProvider(expenseId));
      }
      if (type == null) return;
      if (type.startsWith('expense.') || type.startsWith('settlement.')) {
        _ref.invalidate(expenseFeedProvider);
        _ref.invalidate(activityFeedProvider);
        _ref.invalidate(monthlyAnalyticsProvider);
        _invalidateFriendCaches(_ref);
      }
      if (type.startsWith('group.')) {
        _ref.invalidate(groupsListProvider);
        _ref.invalidate(activityFeedProvider);
        _invalidateFriendCaches(_ref);
      }
    });
  }

  String? _gid(dynamic data) {
    if (data is Map && data['groupId'] != null) return data['groupId'].toString();
    return null;
  }

  String? _eid(dynamic data) {
    if (data is Map && data['expenseId'] != null) return data['expenseId'].toString();
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
