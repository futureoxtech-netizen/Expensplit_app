import '../../../core/db/local_store.dart';
import '../../../core/sync/sync_engine.dart';

/// Offline-first reaction writes. The caller (the UI) has already decided its
/// *desired* reaction (an emoji, or none) using WhatsApp toggle semantics; this
/// just makes it durable locally and lets the sync engine push it when online.
///
/// There is deliberately no network call here: writing to the local DB +
/// enqueuing a coalesced sync op means a reaction works with no connectivity,
/// shows instantly, survives navigation, and reconciles against the server's
/// authoritative `reaction:changed` broadcast once the push lands.
class ReactionRepository {
  ReactionRepository(this._store, this._sync);
  final LocalStore _store;
  final SyncEngine _sync;

  /// Set the caller's reaction on [localTargetId] to [desiredEmoji] (null/empty
  /// = remove it). Persists locally, queues the sync op, and refreshes the UI.
  Future<void> setReaction({
    required String targetType,
    required String localTargetId,
    required String? desiredEmoji,
    required String myId,
    String? myName,
    String? myAvatar,
  }) async {
    await _store.setMyReactionAndQueue(
      targetType: targetType,
      localTargetId: localTargetId,
      myId: myId,
      myName: myName,
      myAvatar: myAvatar,
      desiredEmoji: desiredEmoji,
    );
    // Refresh derived/paged lists from the local DB right away; the enqueue
    // itself already trips the sync engine's queue watcher to push when online.
    _sync.bumpRevision();
    _sync.kick();
  }
}
