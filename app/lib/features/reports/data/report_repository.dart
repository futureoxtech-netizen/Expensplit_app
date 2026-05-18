import '../../../core/network/dio_client.dart';
import 'report_model.dart';

class ReportRepository {
  ReportRepository(this._client);
  final DioClient _client;

  Future<ReportData> fetch({
    required DateTime from,
    required DateTime to,
    String? groupId,
  }) async {
    final res = await _client.get('/expenses/report', query: {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
      if (groupId != null) 'groupId': groupId,
    });
    return ReportData.fromJson(res['data'] as Map<String, dynamic>);
  }
}
