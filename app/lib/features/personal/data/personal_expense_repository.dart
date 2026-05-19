import '../../../core/network/dio_client.dart';
import 'personal_expense_model.dart';

class PersonalExpenseRepository {
  PersonalExpenseRepository(this._client);
  final DioClient _client;

  Future<List<PersonalExpenseModel>> list({
    DateTime? from,
    DateTime? to,
    String? category,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();
    if (category != null) params['category'] = category;

    final res = await _client.get('/personal-expenses', query: params);
    final items = (res['data']['items'] as List).cast<Map<String, dynamic>>();
    return items.map(PersonalExpenseModel.fromJson).toList();
  }

  Future<PersonalExpenseModel> create({
    required String description,
    required double amount,
    required String currency,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final res = await _client.post('/personal-expenses', body: {
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category,
      'date': date.toIso8601String(),
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return PersonalExpenseModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.delete('/personal-expenses/$id');
  }

  Future<List<PersonalSummaryRow>> summary({int months = 3}) async {
    final res = await _client.get('/personal-expenses/summary',
        query: {'months': '$months'});
    final rows = (res['data']['rows'] as List).cast<Map<String, dynamic>>();
    return rows.map(PersonalSummaryRow.fromJson).toList();
  }
}
