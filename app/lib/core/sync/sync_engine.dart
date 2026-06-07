import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../db/local_store.dart';
import '../errors/failure.dart';
import '../network/connectivity_service.dart';
import '../network/dio_client.dart';

/// Coordinates offline → server synchronisation.
///
///  • **push** replays the queued local mutations (FIFO), resolving local ids to
///    server ids, and is idempotent (each create carries a `clientOpId`).
///  • **pull** fetches the delta from `/sync?since=` and merges it locally.
///
/// Runs are serialized (one at a time) and coalesced. Triggered on: start,
/// connectivity regained, queue changes, app resume, and socket events.
class SyncEngine {
  SyncEngine._();
  static final SyncEngine instance = SyncEngine._();

  final _store = LocalStore.instance;
  final _dio = DioClient.instance;

  /// Bumped after every successful pull so paged/derived providers can reload
  /// from the freshly-merged local data.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  bool _running = false;
  bool _rerun = false;
  bool _started = false;
  StreamSubscription? _connSub;
  StreamSubscription? _queueSub;
  Timer? _debounce;

  static const _lastSyncKey = 'lastSyncAt';

  /// Wire up automatic triggers. Call once after login/bootstrap.
  void start() {
    if (_started) return;
    _started = true;
    _connSub = ConnectivityService.instance.onStatusChange.listen((online) {
      if (online) kick();
    });
    // Any change to the queue (a new local write) kicks a debounced sync.
    _queueSub = AppDatabase.instance.select(AppDatabase.instance.syncQueue).watch().listen((_) {
      kick();
    });
    kick();
  }

  void stop() {
    _connSub?.cancel();
    _queueSub?.cancel();
    _debounce?.cancel();
    _started = false;
  }

  /// Signal a UI refresh for derived/paged providers without a network round
  /// trip — used when a realtime payload already mutated the local DB directly.
  void bumpRevision() => revision.value++;

  /// Request a sync soon (debounced). Safe to call frequently.
  void kick() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => sync());
  }

  /// Run a full push-then-pull cycle now. Returns when done.
  Future<void> sync() async {
    if (!ConnectivityService.instance.isOnline) return;
    if (_running) {
      _rerun = true;
      return;
    }
    _running = true;
    try {
      await _push();
      await _pull();
    } catch (_) {
      // Swallow — individual steps already classify/record their errors.
    } finally {
      _running = false;
      if (_rerun) {
        _rerun = false;
        kick();
      }
    }
  }

  // ── PUSH ────────────────────────────────────────────────────────────────────
  Future<void> _push() async {
    final ops = await _store.pendingOps();
    for (final op in ops) {
      if (op.status == 'failed') continue; // needs manual resolution
      try {
        final handled = await _pushOne(op);
        if (handled == _PushOutcome.done) {
          await _store.deleteOp(op.opId);
        } else if (handled == _PushOutcome.defer) {
          // A dependency isn't synced yet — stop here, preserve FIFO order, retry
          // on the next cycle once the parent create has completed.
          break;
        }
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        // Network drop or transient server error (5xx) → stop and retry later.
        // Only genuine client errors (4xx) are permanent.
        if (_isNetwork(e) || (status != null && status >= 500)) break;
        await _store.markOpFailed(op.opId, e.message ?? 'request failed', op.attempts + 1);
      } on Failure catch (e) {
        // Server rejected it (validation/permission). Permanent → mark failed.
        await _store.markOpFailed(op.opId, e.message, op.attempts + 1);
      } catch (e) {
        await _store.bumpOpAttempt(op.opId, e.toString(), op.attempts + 1);
        break;
      }
    }
  }

  Future<_PushOutcome> _pushOne(SyncQueueData op) async {
    final payload = Map<String, dynamic>.from(jsonDecodeSafe(op.payloadJson));
    final localId = op.entityLocalId;

    switch ('${op.entityType}:${op.opType}') {
      case 'group:create':
        final res = await _dio.post('/groups', body: payload);
        await _store.applyServerId('group', localId!, _idOf(res['data']));
        return _PushOutcome.done;

      case 'group:update':
        final gid0 = await _store.serverIdFor('group', localId!);
        if (gid0 == null) return _PushOutcome.defer;
        await _dio.patch('/groups/$gid0', body: payload);
        await _store.clearDirty('group', localId);
        return _PushOutcome.done;

      case 'groupNotes:update':
        final gid = await _store.serverIdFor('group', localId!);
        if (gid == null) return _PushOutcome.defer;
        await _dio.patch('/groups/$gid/notes', body: payload);
        await _store.clearDirty('group', localId);
        return _PushOutcome.done;

      case 'expense:create':
        final gid = await _store.serverIdFor('group', payload['groupId'].toString());
        if (gid == null) return _PushOutcome.defer;
        payload['groupId'] = gid;
        final res = await _dio.post('/expenses', body: payload);
        await _store.applyServerId('expense', localId!, _idOf(res['data']));
        return _PushOutcome.done;

      case 'expense:update':
        final id = await _store.serverIdFor('expense', localId!);
        if (id == null) return _PushOutcome.defer;
        await _dio.patch('/expenses/$id', body: payload);
        await _store.clearDirty('expense', localId);
        return _PushOutcome.done;

      case 'expense:delete':
        final id = await _store.serverIdFor('expense', localId!);
        if (id != null) await _dio.delete('/expenses/$id');
        await _store.hardDeleteAfterSync('expense', localId);
        return _PushOutcome.done;

      case 'settlement:create':
        final gid = await _store.serverIdFor('group', payload['groupId'].toString());
        if (gid == null) return _PushOutcome.defer;
        payload['groupId'] = gid;
        final res = await _dio.post('/settlements', body: payload);
        await _store.applyServerId('settlement', localId!, _idOf(res['data']));
        return _PushOutcome.done;

      case 'personal:create':
        final res = await _dio.post('/personal-expenses', body: payload);
        await _store.applyServerId('personal', localId!, _idOf(res['data']));
        return _PushOutcome.done;

      case 'personal:update':
        final id = await _store.serverIdFor('personal', localId!);
        if (id == null) return _PushOutcome.defer;
        await _dio.patch('/personal-expenses/$id', body: payload);
        await _store.clearDirty('personal', localId);
        return _PushOutcome.done;

      case 'personal:delete':
        final id = await _store.serverIdFor('personal', localId!);
        if (id != null) await _dio.delete('/personal-expenses/$id');
        await _store.hardDeleteAfterSync('personal', localId);
        return _PushOutcome.done;

      case 'goal:create':
        final res = await _dio.post('/goals', body: payload);
        await _store.applyServerId('goal', localId!, _idOf(res['data']));
        return _PushOutcome.done;

      case 'goal:update':
        final id = await _store.serverIdFor('goal', localId!);
        if (id == null) return _PushOutcome.defer;
        await _dio.patch('/goals/$id', body: payload);
        await _store.clearDirty('goal', localId);
        return _PushOutcome.done;

      case 'goal:delete':
        final id = await _store.serverIdFor('goal', localId!);
        if (id != null) await _dio.delete('/goals/$id');
        await _store.hardDeleteAfterSync('goal', localId);
        return _PushOutcome.done;
    }
    return _PushOutcome.done; // unknown op — drop it
  }

  // ── PULL ────────────────────────────────────────────────────────────────────
  /// Pulls the delta in pages so a fresh login (e.g. on a new device) streams
  /// data into the local DB progressively instead of one huge response. Each
  /// page bumps [revision], so screens fill in as the data arrives.
  Future<void> _pull() async {
    var cursor = await _store.db.metaGet(_lastSyncKey);
    // Safety bound so a pathological cursor can never loop forever.
    for (var i = 0; i < 500; i++) {
      final res = await _dio.get('/sync', query: {if (cursor != null) 'since': cursor});
      final data = res['data'] as Map<String, dynamic>;
      final changed = await _store.applyPull(data);
      // Only signal a UI refresh on real changes — an empty delta must not
      // wake providers that would re-kick the sync (infinite-loop guard).
      if (changed) revision.value++;

      final hasMore = data['hasMore'] == true;
      final nextSince = data['nextSince']?.toString();
      if (hasMore && nextSince != null && nextSince != cursor) {
        cursor = nextSince;
        continue; // keep paginating
      }
      final serverTime = data['serverTime']?.toString();
      if (serverTime != null) await _store.db.metaSet(_lastSyncKey, serverTime);
      break;
    }
  }

  bool _isNetwork(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.error is Exception && e.response == null;

  String _idOf(dynamic data) {
    if (data is Map) return (data['_id'] ?? data['id']).toString();
    return data.toString();
  }
}

enum _PushOutcome { done, defer }

// A tolerant JSON decode that never throws (a corrupt op payload becomes {}).
Map<String, dynamic> jsonDecodeSafe(String s) {
  try {
    final v = jsonDecode(s);
    return v is Map<String, dynamic> ? v : <String, dynamic>{};
  } catch (_) {
    return <String, dynamic>{};
  }
}
