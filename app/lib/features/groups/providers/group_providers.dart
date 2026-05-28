import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import '../data/friend_summary_model.dart';
import '../data/group_model.dart';
import '../data/group_repository.dart';

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => GroupRepository(DioClient.instance),
);

final groupsListProvider = FutureProvider.autoDispose<List<GroupModel>>((ref) async {
  return ref.watch(groupRepositoryProvider).list();
});

final groupDetailProvider =
    FutureProvider.autoDispose.family<GroupModel, String>((ref, id) async {
  return ref.watch(groupRepositoryProvider).getById(id);
});

final groupBalancesProvider =
    FutureProvider.autoDispose.family<GroupBalances, String>((ref, id) async {
  return ref.watch(groupRepositoryProvider).balances(id);
});

final friendsSummaryProvider =
    FutureProvider.autoDispose<List<FriendSummary>>((ref) async {
  final res = await DioClient.instance.get('/users/friends-summary');
  final data = res['data'] as List;
  return data
      .map((j) => FriendSummary.fromJson(j as Map<String, dynamic>))
      .toList();
});

/// Lightweight one-shot fetch — used for the "shared groups" header. Loads
/// page 1 only; for the scrollable transactions list, use
/// [friendTransactionsPagedProvider].
final friendDetailProvider =
    FutureProvider.autoDispose.family<FriendDetailData, String>((ref, friendId) async {
  final res = await DioClient.instance.get(
    '/users/friends/$friendId/transactions',
    query: {'page': '1', 'limit': '30'},
  );
  return FriendDetailData.fromJson(res['data'] as Map<String, dynamic>);
});

/// Paginated transactions stream. The friend detail screen uses this for
/// the scrollable list and watches [friendDetailProvider] separately for
/// the small shared-groups list.
final friendTransactionsPagedProvider = StateNotifierProvider.autoDispose
    .family<PagedListNotifier<FriendTransaction>,
        PagedListState<FriendTransaction>, String>((ref, friendId) {
  return PagedListNotifier<FriendTransaction>(
    fetcher: (page, limit) async {
      final res = await DioClient.instance.get(
        '/users/friends/$friendId/transactions',
        query: {'page': '$page', 'limit': '$limit'},
      );
      final data = res['data'] as Map<String, dynamic>;
      final items = ((data['transactions'] ?? []) as List)
          .map((e) => FriendTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
      return PagedResult(
        items: items,
        hasMore: (data['hasMore'] as bool?) ?? false,
      );
    },
    limit: 30,
  );
});
