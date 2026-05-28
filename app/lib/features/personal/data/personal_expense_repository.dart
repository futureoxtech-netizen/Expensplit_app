import '../../../core/network/dio_client.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import 'personal_expense_model.dart';

class PersonalExpenseRepository {
  PersonalExpenseRepository(this._client);
  final DioClient _client;

  /// Fetch one page. The backend treats absent `page`/`limit` as page 1 /
  /// limit 30, but we pass them explicitly so the response shape stays stable.
  Future<PagedResult<PersonalExpenseModel>> listPaged({
    DateTime? from,
    DateTime? to,
    String? category,
    int page = 1,
    int limit = 30,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();
    if (category != null) params['category'] = category;

    final res = await _client.get('/personal-expenses', query: params);
    final data = res['data'] as Map<String, dynamic>;
    final items = (data['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(PersonalExpenseModel.fromJson)
        .toList();
    return PagedResult(
      items: items,
      hasMore: (data['hasMore'] as bool?) ?? false,
    );
  }

  /// Legacy whole-list variant — used by the report builders that aggregate
  /// across a date range and don't render the records individually.
  Future<List<PersonalExpenseModel>> list({
    DateTime? from,
    DateTime? to,
    String? category,
  }) async {
    final acc = <PersonalExpenseModel>[];
    var page = 1;
    while (true) {
      final res = await listPaged(
        from: from,
        to: to,
        category: category,
        page: page,
        limit: 100,
      );
      acc.addAll(res.items);
      if (!res.hasMore) break;
      page += 1;
      // Hard stop so an unexpectedly large dataset doesn't hang the report.
      if (page > 20) break;
    }
    return acc;
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

  Future<PersonalExpenseModel> update(
    String id, {
    String? description,
    double? amount,
    String? currency,
    String? category,
    DateTime? date,
    String? note,
  }) async {
    final body = <String, dynamic>{};
    if (description != null) body['description'] = description;
    if (amount != null) body['amount'] = amount;
    if (currency != null) body['currency'] = currency;
    if (category != null) body['category'] = category;
    if (date != null) body['date'] = date.toIso8601String();
    if (note != null) body['note'] = note;
    final res = await _client.patch('/personal-expenses/$id', body: body);
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
