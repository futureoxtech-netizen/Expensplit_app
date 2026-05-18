import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
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
