import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../features/groups/providers/group_providers.dart';
import '../db/local_store.dart';
import '../services/in_app_banner.dart';
import '../sync/sync_engine.dart';
import 'socket_service.dart';

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
      // Socket rooms are keyed by the *server* id (`group:<serverId>`). The
      // group's local id is a uuid for anything created on this device, so we
      // must join by server id or we'd sit in a room nobody broadcasts to and
      // never receive `expense:*` / `settlement:*` events (no live updates).
      final ids = await LocalStore.instance.allGroupServerIds();
      for (final id in ids) {
        if (_joinedGroups.add(id)) {
          SocketService.instance.joinGroup(id);
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

  /// After every sync pull, re-check the group set. A group created offline
  /// only gets a server id once its create has been pushed; this picks it up
  /// and joins its room so realtime starts flowing without waiting for the
  /// next reconnect.
  void _onSyncRevision() => _joinAllUserGroups();

  void _wire() {
    _wired = true;
    SyncEngine.instance.revision.addListener(_onSyncRevision);
    final s = SocketService.instance;

    // Re-join all known groups whenever the socket reconnects.
    s.onConnect(() {
      _rejoinCachedGroups();
      // Also refresh the groups list in case the server has new entries
      // we haven't been listening to yet.
      _joinAllUserGroups();
      SyncEngine.instance.kick();
    });

    // Data events: a single sync pull merges the change into the local DB, and
    // every screen (Drift streams + syncRevision-driven paged lists) updates
    // reactively from there. No manual provider invalidation needed.
    s.on('expense:created', (_) => SyncEngine.instance.kick());
    s.on('expense:updated', (_) => SyncEngine.instance.kick());
    s.on('expense:deleted', (_) => SyncEngine.instance.kick());
    s.on('settlement:created', (_) => SyncEngine.instance.kick());

    // A reaction was added / switched / removed on an expense or settlement.
    // Patch the affected row in place (keeps scroll position) rather than
    // re-fetching the whole list. The payload carries the new summary, and
    // because it has no per-viewer `mine` flag every client renders correctly.
    s.on('reaction:changed', (data) {
      if (data is! Map) return;
      final targetType = data['targetType']?.toString() ?? 'expense';
      final targetId = data['targetId']?.toString();
      if (targetId == null) return;
      // Persist the authoritative summary locally → the detail screen (Drift
      // stream) updates live, and paged lists reload on the revision bump.
      LocalStore.instance
          .applyReactionsJson(targetType, targetId, data['reactions'])
          .then((_) => SyncEngine.instance.bumpRevision())
          .catchError((_) {});
    });

    s.on('group:updated', (data) {
      SyncEngine.instance.kick();
      // Pending invitations are an online-only list (not in the offline set).
      _ref.invalidate(myInvitesProvider);
    });

    s.on('group:deleted', (data) {
      SyncEngine.instance.kick();
      _ref.invalidate(myInvitesProvider);
    });

    s.on('activity:new', (data) {
      SyncEngine.instance.kick();
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
      // recipient may not be a member of the group yet; invitations are an
      // online-only list, so refresh it (the rest syncs via the delta pull).
      if (type != null && type.startsWith('group.invite')) {
        _ref.invalidate(myInvitesProvider);
        SyncEngine.instance.kick();
        _showBanner(data);
        return;
      }

      // Make sure we're in this group's room going forward.
      if (groupId != null && _joinedGroups.add(groupId)) {
        SocketService.instance.joinGroup(groupId);
      }
      // Pull the change into the local DB — every screen updates reactively.
      SyncEngine.instance.kick();
      if (type != null && type.startsWith('group.')) {
        _ref.invalidate(myInvitesProvider);
      }

      // Surface a transient in-app banner so users see something happened
      // even when the OS push is suppressed (the socket is live, so push
      // is muted by [PushNotificationsService] to avoid double-notifying).
      _showBanner(data);
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

  /// Join a group's realtime room. Accepts a local or server id and resolves to
  /// the server id the room is keyed by (no-op if the group hasn't synced yet —
  /// the post-sync revision listener will join it then).
  Future<void> joinGroup(String localOrServerId) async {
    final sid =
        await LocalStore.instance.serverIdFor('group', localOrServerId);
    final id = (sid != null && sid.isNotEmpty) ? sid : localOrServerId;
    if (_joinedGroups.add(id)) SocketService.instance.joinGroup(id);
  }

  void disconnect() {
    _joinedGroups.clear();
    if (_wired) SyncEngine.instance.revision.removeListener(_onSyncRevision);
    _wired = false;
    SocketService.instance.disconnect();
  }
}

final realtimeBridgeProvider =
    Provider<RealtimeBridge>((ref) => RealtimeBridge(ref));
