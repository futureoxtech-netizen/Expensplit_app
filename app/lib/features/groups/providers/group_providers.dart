import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/local_store.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/friend_summary_model.dart';
import '../data/group_model.dart';
import '../data/group_repository.dart';

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => GroupRepository(DioClient.instance),
);

// ── Offline-first reads (Drift is the source of truth) ──────────────────────
// Every read streams from the local DB and is reactive to both optimistic
// local writes and merged server pulls. We kick a sync on first subscribe so
// the data refreshes whenever a screen opens.

final groupsListProvider = StreamProvider.autoDispose<List<GroupModel>>((ref) {
  SyncEngine.instance.kick();
  return LocalStore.instance
      .watchGroupsJson()
      .map((list) => list.map((j) => GroupModel.fromJson(j)).toList());
});

/// Pending group invitations — still online (not part of the offline dataset).
final myInvitesProvider =
    FutureProvider.autoDispose<List<GroupInvite>>((ref) async {
  return ref.watch(groupRepositoryProvider).listInvites();
});

final groupDetailProvider =
    StreamProvider.autoDispose.family<GroupModel, String>((ref, id) {
  SyncEngine.instance.kick();
  return LocalStore.instance.watchGroupJson(id).map((j) {
    if (j == null) throw StateError('Group not found');
    return GroupModel.fromJson(j);
  });
});

final groupBalancesProvider =
    StreamProvider.autoDispose.family<GroupBalances, String>((ref, id) {
  return LocalStore.instance
      .watchGroupBalancesJson(id)
      .map((j) => GroupBalances.fromJson(j));
});

final friendsSummaryProvider =
    StreamProvider.autoDispose<List<FriendSummary>>((ref) {
  final myId = ref.watch(authProvider.select((s) => s.user?.id));
  if (myId == null) return Stream.value(const <FriendSummary>[]);
  SyncEngine.instance.kick();
  return LocalStore.instance.watchFriendsSummaryJson(myId).map(
      (list) => list.map((j) => FriendSummary.fromJson(j)).toList());
});

/// Friend detail (shared groups + transactions), computed offline.
final friendDetailProvider =
    StreamProvider.autoDispose.family<FriendDetailData, String>((ref, friendId) {
  final myId = ref.watch(authProvider.select((s) => s.user?.id));
  if (myId == null) return Stream.value(FriendDetailData(transactions: const [], groups: const []));
  SyncEngine.instance.kick();
  return LocalStore.instance
      .watchFriendDetailJson(myId, friendId)
      .map((j) => FriendDetailData.fromJson(j));
});

/// Full transaction list between the user and a friend (offline). Backed by the
/// local DB and reloaded after each sync; returned as one page (local data is
/// small, so there's nothing to paginate).
final friendTransactionsPagedProvider = StateNotifierProvider.autoDispose
    .family<PagedListNotifier<FriendTransaction>,
        PagedListState<FriendTransaction>, String>((ref, friendId) {
  final myId = ref.watch(authProvider.select((s) => s.user?.id));
  final notifier = PagedListNotifier<FriendTransaction>(
    fetcher: (page, limit) async {
      if (myId == null) return PagedResult(items: const [], hasMore: false);
      final list = await LocalStore.instance
          .friendTransactionsPage(myId, friendId, limit: limit, offset: (page - 1) * limit);
      final items = list.map((t) => FriendTransaction.fromJson(t)).toList();
      return PagedResult(items: items, hasMore: items.length == limit);
    },
    limit: 30,
  );
  ref.listen(syncRevisionProvider, (_, __) => notifier.softRefresh());
  return notifier;
});
