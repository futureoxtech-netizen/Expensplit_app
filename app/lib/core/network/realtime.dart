import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../features/activity/providers/activity_providers.dart';
import '../../features/expenses/data/expense_model.dart';
import '../../features/expenses/providers/expense_providers.dart';
import '../../features/groups/providers/group_providers.dart';
import '../../features/reactions/data/reaction_model.dart';
import '../services/in_app_banner.dart';
import 'socket_service.dart';

/// Helpers that invalidate every parameterised provider for a family —
/// Riverpod does not expose a one-call API for this, so we drop the entire
/// family by invalidating the top-level provider object.
void _invalidateFriendCaches(Ref ref) {
  ref.invalidate(friendsSummaryProvider);
  ref.invalidate(friendDetailProvider);
  ref.invalidate(friendTransactionsPagedProvider);
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
        _ref.invalidate(groupExpensesPagedProvider(groupId));
        _ref.invalidate(groupBalancesProvider(groupId));
      }
      _ref.invalidate(expenseFeedProvider);
      _ref.invalidate(expenseFeedPagedProvider);
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
        _ref.invalidate(groupExpensesPagedProvider(groupId));
        _ref.invalidate(groupBalancesProvider(groupId));
      }
      if (expenseId != null) {
        _ref.invalidate(expenseDetailProvider(expenseId));
      }
      _ref.invalidate(expenseFeedProvider);
      _ref.invalidate(expenseFeedPagedProvider);
      _ref.invalidate(activityFeedProvider);
      _ref.invalidate(monthlyAnalyticsProvider);
      _invalidateFriendCaches(_ref);
    });

    s.on('expense:deleted', (data) {
      final groupId = _gid(data);
      final expenseId = _eid(data);
      if (groupId != null) {
        _ref.invalidate(groupExpensesProvider(groupId));
        _ref.invalidate(groupExpensesPagedProvider(groupId));
        _ref.invalidate(groupBalancesProvider(groupId));
      }
      if (expenseId != null) {
        _ref.invalidate(expenseDetailProvider(expenseId));
      }
      _ref.invalidate(expenseFeedProvider);
      _ref.invalidate(expenseFeedPagedProvider);
      _ref.invalidate(activityFeedProvider);
      _ref.invalidate(monthlyAnalyticsProvider);
      _invalidateFriendCaches(_ref);
    });

    s.on('settlement:created', (data) {
      final groupId = _gid(data);
      if (groupId != null) {
        _ref.invalidate(groupBalancesProvider(groupId));
        _ref.invalidate(groupExpensesProvider(groupId));
        _ref.invalidate(groupExpensesPagedProvider(groupId));
      }
      _ref.invalidate(activityFeedProvider);
      // Settling up reduces the friend's net to/from us.
      _invalidateFriendCaches(_ref);
    });

    // A reaction was added / switched / removed on an expense or settlement.
    // Patch the affected row in place (keeps scroll position) rather than
    // re-fetching the whole list. The payload carries the new summary, and
    // because it has no per-viewer `mine` flag every client renders correctly.
    s.on('reaction:changed', (data) {
      if (data is! Map) return;
      final groupId = data['groupId']?.toString();
      final targetType = data['targetType']?.toString();
      final targetId = data['targetId']?.toString();
      if (targetId == null) return;
      final reactions = parseReactions(data['reactions']);

      // Detail screen — cheap single fetch, just refetch.
      if (targetType == 'expense') {
        _ref.invalidate(expenseDetailProvider(targetId));
      }

      // Group activity tab (mixed expenses + settlements).
      if (groupId != null) {
        _ref.read(groupExpensesPagedProvider(groupId).notifier).mapWhere(
          (t) =>
              (t is ExpenseTxn && t.expense.id == targetId) ||
              (t is SettlementTxn && t.id == targetId),
          (t) => switch (t) {
            ExpenseTxn(:final expense) =>
              ExpenseTxn(expense.copyWith(reactions: reactions)),
            SettlementTxn s => s.copyWith(reactions: reactions),
          },
        );
      }

      // Global "all groups" feed.
      if (targetType == 'expense') {
        _ref.read(expenseFeedPagedProvider.notifier).mapWhere(
              (e) => e.id == targetId,
              (e) => e.copyWith(reactions: reactions),
            );
      }
    });

    s.on('group:updated', (data) {
      _ref.invalidate(groupsListProvider);
      // Membership / pending-invite changes may concern the current user too.
      _ref.invalidate(myInvitesProvider);
      // Refresh the affected group's detail so the Members tab (incl. pending
      // invitations) and balances update live.
      final groupId = _gid(data);
      if (groupId != null) {
        _ref.invalidate(groupDetailProvider(groupId));
        _ref.invalidate(groupBalancesProvider(groupId));
      }
      // New / removed members reshape the friend list.
      _invalidateFriendCaches(_ref);
    });

    s.on('group:deleted', (data) {
      final groupId = _gid(data);
      _ref.invalidate(groupsListProvider);
      if (groupId != null) {
        _ref.invalidate(groupDetailProvider(groupId));
        _ref.invalidate(groupBalancesProvider(groupId));
        _ref.invalidate(groupExpensesPagedProvider(groupId));
      }
      // The group's expenses vanish everywhere they were aggregated.
      _ref.invalidate(expenseFeedProvider);
      _ref.invalidate(expenseFeedPagedProvider);
      _ref.invalidate(monthlyAnalyticsProvider);
      _ref.invalidate(activityFeedProvider);
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
      final inner =
          data is Map && data['data'] is Map ? data['data'] as Map : null;
      final groupId = inner?['groupId']?.toString();
      final expenseId = inner?['expenseId']?.toString();

      // Reaction notices are handled by the `reaction:changed` event, which
      // patches the affected row in place. Re-fetching here would needlessly
      // reset the list scroll — so just surface the banner and stop.
      if (type != null && type.startsWith('reaction.')) {
        if (groupId != null && _joinedGroups.add(groupId)) {
          SocketService.instance.joinGroup(groupId);
        }
        _showBanner(data);
        return;
      }

      // Group invitation lifecycle (received / declined / cancelled). The
      // recipient may not be a member of the group yet, so don't touch the
      // group caches — just refresh the invitations banner + groups list.
      // Also invalidate the activity feed: the backend now logs a group.invite
      // activity entry that pending members can see in their feed.
      if (type != null && type.startsWith('group.invite')) {
        _ref.invalidate(myInvitesProvider);
        _ref.invalidate(groupsListProvider);
        _ref.invalidate(activityFeedProvider);
        // The inviter receives group.invite_declined which also starts with
        // group.invite — their pending-member list must clear immediately.
        if (groupId != null) {
          _ref.invalidate(groupDetailProvider(groupId));
        }
        _showBanner(data);
        return;
      }

      if (groupId != null) {
        // Make sure we're in this room going forward, then invalidate caches.
        if (_joinedGroups.add(groupId)) {
          SocketService.instance.joinGroup(groupId);
        }
        _ref.invalidate(groupExpensesProvider(groupId));
        _ref.invalidate(groupExpensesPagedProvider(groupId));
        _ref.invalidate(groupBalancesProvider(groupId));
      }
      if (expenseId != null) {
        _ref.invalidate(expenseDetailProvider(expenseId));
      }

      // Surface a transient in-app banner so users see something happened
      // even when the OS push is suppressed (the socket is live, so push
      // is muted by [PushNotificationsService] to avoid double-notifying).
      _showBanner(data);

      if (type == null) return;
      if (type.startsWith('expense.') || type.startsWith('settlement.')) {
        _ref.invalidate(expenseFeedProvider);
        _ref.invalidate(expenseFeedPagedProvider);
        _ref.invalidate(activityFeedProvider);
        _ref.invalidate(monthlyAnalyticsProvider);
        _invalidateFriendCaches(_ref);
      }
      if (type.startsWith('group.')) {
        _ref.invalidate(groupsListProvider);
        _ref.invalidate(activityFeedProvider);
        // Refresh the group detail so membership changes (pending → member,
        // new member added, etc.) reflect immediately on the inviter's screen.
        if (groupId != null) {
          _ref.invalidate(groupDetailProvider(groupId));
        }
        _invalidateFriendCaches(_ref);
      }
    });
  }

  /// Translate a `notification:new` payload into a banner. Tapping the
  /// banner deep-links via the same `route` field the push handler uses.
  void _showBanner(dynamic data) {
    if (data is! Map) return;
    final title = data['title']?.toString();
    final message = data['message']?.toString();
    if (title == null || message == null || title.isEmpty || message.isEmpty) {
      return;
    }
    final type = data['type']?.toString() ?? '';
    final inner = data['data'] is Map ? data['data'] as Map : const {};
    final groupId = inner['groupId']?.toString();
    final expenseId = inner['expenseId']?.toString();
    final route = inner['route']?.toString() ??
        (expenseId != null
            ? '/expenses/$expenseId'
            : (groupId != null ? '/groups/$groupId' : null));

    IconData icon;
    Color accent;
    if (type.startsWith('group.invite')) {
      icon = Icons.mark_email_unread_rounded;
      accent = const Color(0xFF6C5CE7);
    } else if (type.startsWith('reaction.')) {
      icon = Icons.emoji_emotions_rounded;
      accent = const Color(0xFFFFC857);
    } else if (type.startsWith('settlement.')) {
      icon = Icons.payments_rounded;
      accent = const Color(0xFF00B894);
    } else if (type.startsWith('expense.')) {
      icon = Icons.receipt_long_rounded;
      accent = const Color(0xFF6C5CE7);
    } else if (type.startsWith('group.')) {
      icon = Icons.group_rounded;
      accent = const Color(0xFF0984E3);
    } else {
      icon = Icons.notifications_active_rounded;
      accent = const Color(0xFF6C5CE7);
    }

    InAppBanner.instance.show(
      title: title,
      message: message,
      icon: icon,
      accent: accent,
      onTap: route == null
          ? null
          : () {
              final ctx = rootNavigatorKey.currentContext;
              if (ctx == null) return;
              try {
                GoRouter.of(ctx).go(route);
              } catch (_) {
                /* router not ready */
              }
            },
    );
  }

  String? _gid(dynamic data) {
    if (data is Map && data['groupId'] != null)
      return data['groupId'].toString();
    return null;
  }

  String? _eid(dynamic data) {
    if (data is Map && data['expenseId'] != null)
      return data['expenseId'].toString();
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

final realtimeBridgeProvider =
    Provider<RealtimeBridge>((ref) => RealtimeBridge(ref));
