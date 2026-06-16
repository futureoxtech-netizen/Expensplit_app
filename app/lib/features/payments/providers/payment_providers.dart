import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/group_payment_repository.dart';
import '../data/payment_method_model.dart';

final groupPaymentRepositoryProvider = Provider<GroupPaymentRepository>(
  (ref) => GroupPaymentRepository(DioClient.instance),
);

/// All payment info shared inside a group. Online-only; refresh by invalidating.
final groupPaymentInfosProvider = FutureProvider.autoDispose
    .family<List<PaymentMethodModel>, String>((ref, groupId) async {
  return ref.watch(groupPaymentRepositoryProvider).list(groupId);
});
