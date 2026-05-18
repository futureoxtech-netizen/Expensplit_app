import '../../../core/network/dio_client.dart';

class SettlementRepository {
  SettlementRepository(this._client);
  final DioClient _client;

  Future<void> create({
    required String groupId,
    required String from,
    required String to,
    required double amount,
    String? currency,
    String method = 'cash',
    String? note,
  }) async {
    await _client.post('/settlements', body: {
      'groupId': groupId,
      'from': from,
      'to': to,
      'amount': amount,
      if (currency != null) 'currency': currency,
      'method': method,
      if (note != null) 'note': note,
    });
  }

  Future<List<Map<String, dynamic>>> listByGroup(String groupId) async {
    final res = await _client.get('/settlements/group/$groupId');
    final data = res['data'] as Map<String, dynamic>;
    return ((data['items'] ?? []) as List).cast<Map<String, dynamic>>();
  }
}
