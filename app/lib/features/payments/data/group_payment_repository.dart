import '../../../core/network/dio_client.dart';
import '../../../core/sync/sync_engine.dart';
import 'payment_method_model.dart';

/// Online-only repository for payment info shared inside a group. Unlike the
/// offline-first expense/balance data, payment info is fetched on demand —
/// sending someone money requires being online anyway, and it never needs to
/// participate in the local relational sync schema.
class GroupPaymentRepository {
  GroupPaymentRepository(this._client);
  final DioClient _client;

  /// Resolve the server id for a group that may have been created offline.
  Future<String> _gid(String groupId) =>
      SyncEngine.instance.requireServerId('group', groupId);

  List<PaymentMethodModel> _parse(dynamic data) => ((data ?? const []) as List)
      .whereType<Map>()
      .map((j) => PaymentMethodModel.fromJson(Map<String, dynamic>.from(j)))
      .toList();

  Future<List<PaymentMethodModel>> list(String groupId) async {
    final gid = await _gid(groupId);
    final res = await _client.get('/groups/$gid/payment-infos');
    return _parse(res['data']);
  }

  Future<List<PaymentMethodModel>> add(String groupId, Map<String, dynamic> input) async {
    final gid = await _gid(groupId);
    final res = await _client.post('/groups/$gid/payment-infos', body: input);
    return _parse(res['data']);
  }

  Future<List<PaymentMethodModel>> update(
      String groupId, String infoId, Map<String, dynamic> input) async {
    final gid = await _gid(groupId);
    final res = await _client.patch('/groups/$gid/payment-infos/$infoId', body: input);
    return _parse(res['data']);
  }

  Future<List<PaymentMethodModel>> remove(String groupId, String infoId) async {
    final gid = await _gid(groupId);
    final res = await _client.delete('/groups/$gid/payment-infos/$infoId');
    return _parse(res['data']);
  }
}
