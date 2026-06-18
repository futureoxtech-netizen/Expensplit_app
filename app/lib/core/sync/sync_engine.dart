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
  // The currently-running push/pull cycle, exposed so callers can await an
  // already-in-progress run (see [sync]). Null when idle.
  Future<void>? _inFlight;
  StreamSubscription? _connSub;
  StreamSubscription? _queueSub;
  Timer? _debounce;

  static const _lastSyncKey = 'lastSyncAt';

  /// How many times a genuine (non-transient) client rejection is retried
  /// before the op is parked as 'failed'. Transient errors (network, 401,
  /// 408, 429, 5xx) never burn an attempt.
  static const _maxAttempts = 8;

  /// Wire up automatic triggers. Call once after login/bootstrap.
  void start() {
    if (_started) return;
    _started = true;
    _connSub = ConnectivityService.instance.onStatusChange.listen((online) {
      // Connectivity is a discrete recovery event: revive parked ops so an op
      // that failed while offline (or on a transient error) gets re-driven.
      if (online) _store.requeueFailedOps().whenComplete(kick);
    });
    // Any change to the queue (a new local write) kicks a debounced sync.
    _queueSub = AppDatabase.instance.select(AppDatabase.instance.syncQueue).watch().listen((_) {
      kick();
    });
    // Revive any ops a transient failure (or a past bug) parked as 'failed'.
    // The write trips the queue watcher above, which kicks a sync to re-drive
    // them with the smarter, attempt-bounded classification below.
    _store.requeueFailedOps().whenComplete(kick);
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

  /// Resolve a local entity id to the server id the backend knows it by.
  ///
  /// After the offline DB was introduced, every id surfaced to the UI is a
  /// *local* id (a uuid for anything created on this device, the server id for
  /// anything pulled). Operations that still talk to the server directly
  /// (invites, member changes, reactions, goal contributions) must translate
  /// that local id back to the server id — otherwise the server can't find the
  /// row and responds 404 ("We couldn't find what you were looking for").
  ///
  /// If the entity was created offline and hasn't been pushed yet, this flushes
  /// the pending queue first so the create gets its server id, then retries.
  /// Throws a friendly [StateError] if it still can't be resolved.
  Future<String> requireServerId(String entityType, String localId) async {
    var sid = await _store.serverIdFor(entityType, localId);
    if (sid != null && sid.isNotEmpty) return sid;
    // Not synced yet — revive anything a transient failure parked, then push
    // the pending create and look again. The revive is what lets this recover
    // without the user having to log out and back in.
    await _store.requeueFailedOps();
    await sync();
    sid = await _store.serverIdFor(entityType, localId);
    if (sid == null || sid.isEmpty) {
      throw StateError('This is still syncing — please try again in a moment.');
    }
    return sid;
  }

  /// Request a sync soon (debounced). Safe to call frequently.
  void kick() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => sync());
  }

  /// Run a full push-then-pull cycle now. Returns when the relevant work is
  /// done — including any cycle that was already in progress when called.
  ///
  /// Coalesced + awaitable: if a cycle is already running, we flag a rerun and
  /// return the in-flight future. That future does not complete until the rerun
  /// (which starts *after* this call) has also finished — so a caller like
  /// [requireServerId] that just queued a create and does `await sync()` is
  /// guaranteed its op got a push attempt before the await resolves. Returning
  /// early here was the root of spurious "still syncing" errors.
  Future<void> sync() {
    if (!ConnectivityService.instance.isOnline) return Future.value();
    if (_running) {
      _rerun = true;
      return _inFlight ?? Future.value();
    }
    return _inFlight = _runCycle();
  }

  Future<void> _runCycle() async {
    _running = true;
    try {
      await _push();
      await _pull();
    } catch (_) {
      // Swallow — individual steps already classify/record their errors.
    } finally {
      _running = false;
    }
    // Work requested mid-cycle → chain another cycle so anyone awaiting the
    // in-flight future still sees their newly-queued op flushed. Cleared
    // _running first so this re-enters cleanly; it converges once no new rerun
    // is requested (an empty pull bumps no revision, so nothing re-kicks).
    if (_rerun) {
      _rerun = false;
      await sync();
    } else {
      _inFlight = null;
    }
  }

  // ── PUSH ────────────────────────────────────────────────────────────────────
  Future<void> _push() async {
    final ops = await _store.pendingOps();
    for (final op in ops) {
      // Parked after _maxAttempts genuine rejections; skipped until a discrete
      // recovery event (start / connectivity / requireServerId) revives it.
      if (op.status == 'failed') continue;
      // Drop ops whose target row was hard-deleted out from under them (e.g. a
      // group tombstone cascade removed the expense this op edits). Otherwise
      // the op can never resolve a serverId, keeps deferring, and — since a
      // defer breaks this loop — stalls every op queued behind it forever.
      final localId = op.entityLocalId;
      if (localId != null && !await _store.entityRowExists(op.entityType, localId)) {
        await _store.deleteOp(op.opId);
        continue;
      }
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
        // Network drop or transient server error → stop and retry later without
        // burning an attempt or parking the op.
        if (_isNetwork(e) || _isTransientStatus(status)) break;
        await _failOrRetry(op, e.message ?? 'request failed');
      } on Failure catch (e) {
        // Responses with status < 500 surface here (DioClient validateStatus).
        // A 401 (token refresh raced), 408, 409 (conflict) or 429 (rate-limit)
        // is transient — retrying later usually succeeds, so don't park it.
        // Other 4xx (400/403/404/422) are genuine client errors.
        if (_isTransientStatus(e.statusCode)) break;
        await _failOrRetry(op, e.message);
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

      case 'loan:create':
        final res = await _dio.post('/loans', body: payload);
        await _store.applyServerId('loan', localId!, _idOf(res['data']));
        return _PushOutcome.done;

      case 'guestContact:create':
        final res = await _dio.post('/guest-contacts', body: payload);
        await _store.applyServerId('guestContact', localId!, _idOf(res['data']));
        return _PushOutcome.done;

      case 'guestContact:update':
        final gcServerId = await _store.serverIdFor('guestContact', localId!);
        if (gcServerId == null) return _PushOutcome.defer;
        await _dio.patch('/guest-contacts/$gcServerId', body: payload);
        await _store.clearDirty('guestContact', localId);
        return _PushOutcome.done;

      case 'guestContact:delete':
        final gcDelId = await _store.serverIdFor('guestContact', localId!);
        if (gcDelId != null) await _dio.delete('/guest-contacts/$gcDelId');
        await _store.hardDeleteAfterSync('guestContact', localId);
        return _PushOutcome.done;

      case 'loan:delete':
        final id = await _store.serverIdFor('loan', localId!);
        if (id != null) await _dio.delete('/loans/$id');
        await _store.hardDeleteAfterSync('loan', localId);
        return _PushOutcome.done;

      case 'loanPayment:create':
        // The parent loan must have a server id before we push the payment.
        final loanLocalId = payload['loanLocalId']?.toString();
        if (loanLocalId == null) return _PushOutcome.done;
        final loanServerId = await _store.serverIdFor('loan', loanLocalId);
        if (loanServerId == null) return _PushOutcome.defer;
        final res = await _dio.post('/loans/$loanServerId/payments', body: {
          'amount': payload['amount'],
          'note': payload['note'] ?? '',
          'method': payload['method'] ?? 'cash',
          if (payload['paidAt'] != null) 'paidAt': payload['paidAt'],
          'clientOpId': payload['clientOpId'],
        });
        // Store returned payment serverId on local row.
        final paymentServerId = _idOf(res['data']);
        await _store.db.customStatement(
          'UPDATE loan_payments SET server_id = ?, dirty = 0 WHERE id = ?',
          [paymentServerId, localId!],
        );
        return _PushOutcome.done;

      case 'loanPayment:delete':
        // Parent loan must be synced before its payment can be deleted server-side.
        final delLoanLocalId = payload['loanLocalId']?.toString();
        final delLoanServerId =
            delLoanLocalId != null ? await _store.serverIdFor('loan', delLoanLocalId) : null;
        final delPaymentServerId = payload['paymentServerId']?.toString();
        if (delLoanServerId == null) return _PushOutcome.defer;
        if (delPaymentServerId != null) {
          await _dio.delete('/loans/$delLoanServerId/payments/$delPaymentServerId');
        }
        await _store.hardDeleteAfterSync('loanPayment', localId!);
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
      if (hasMore) {
        if (nextSince != null && nextSince != cursor) {
          cursor = nextSince;
          continue; // advance the cursor and keep paginating
        }
        // The server still has more rows but the cursor can't advance (a
        // page-boundary timestamp tie). Stop WITHOUT moving the high-water mark
        // to serverTime — otherwise we'd mark ourselves caught-up past rows we
        // never fetched and they'd never load. The next sync re-pulls this
        // delta (idempotent upserts) and tries again.
        break;
      }
      // Fully drained — safe to commit the high-water mark.
      final serverTime = data['serverTime']?.toString();
      if (serverTime != null) await _store.db.metaSet(_lastSyncKey, serverTime);
      break;
    }
  }

  /// Park the op as 'failed' only after it has genuinely been rejected
  /// [_maxAttempts] times; otherwise just record the error and bump the
  /// counter so the next cycle retries. This keeps a flaky-but-recoverable op
  /// (a transient 4xx, a momentary conflict) from being abandoned forever.
  Future<void> _failOrRetry(SyncQueueData op, String message) async {
    final attempts = op.attempts + 1;
    if (attempts >= _maxAttempts) {
      await _store.markOpFailed(op.opId, message, attempts);
    } else {
      await _store.bumpOpAttempt(op.opId, message, attempts);
    }
  }

  /// HTTP statuses that are worth retrying rather than treating as permanent:
  /// 401 (auth refresh raced), 408 (timeout), 409 (conflict), 429 (rate limit),
  /// and any 5xx.
  bool _isTransientStatus(int? status) =>
      status == 401 ||
      status == 408 ||
      status == 409 ||
      status == 429 ||
      (status != null && status >= 500);

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
