import '../../../core/network/dio_client.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import 'expense_model.dart';

class ExpenseRepository {
  ExpenseRepository(this._client);
  final DioClient _client;

  Future<ExpenseModel> create({
    required String groupId,
    required String description,
    required double amount,
    required String splitMode,
    required String paidBy,
    required List<Map<String, dynamic>> splits,
    String? notes,
    String? category,
    String? currency,
    double tax = 0,
    double tip = 0,
    DateTime? spentAt,
  }) async {
    final res = await _client.post('/expenses', body: {
      'groupId': groupId,
      'description': description,
      'notes': notes ?? '',
      'amount': amount,
      'splitMode': splitMode,
      'paidBy': paidBy,
      'splits': splits,
      if (category != null) 'category': category,
      if (currency != null) 'currency': currency,
      'tax': tax,
      'tip': tip,
      if (spentAt != null) 'spentAt': spentAt.toIso8601String(),
    });
    return ExpenseModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<ExpensePage> listByGroup(String groupId,
      {int page = 1, int limit = 30}) async {
    final res = await _client.get(
      '/expenses/group/$groupId',
      query: {'page': page, 'limit': limit},
    );
    return ExpensePage.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// Bridge from [ExpensePage] to the generic [PagedResult] used by the
  /// shared list-notifier pattern.
  Future<PagedResult<ExpenseModel>> listByGroupPaged(
    String groupId, {
    int page = 1,
    int limit = 30,
  }) async {
    final p = await listByGroup(groupId, page: page, limit: limit);
    return PagedResult(items: p.items, hasMore: p.hasMore);
  }

  /// Merged group activity (expenses + settlement records) for the group
  /// detail Expenses tab, paginated. Settlements appear inline so a recorded
  /// payment shows up alongside expenses.
  Future<PagedResult<GroupTxn>> groupTransactionsPaged(
    String groupId, {
    int page = 1,
    int limit = 30,
  }) async {
    final res = await _client.get(
      '/expenses/group/$groupId/transactions',
      query: {'page': page, 'limit': limit},
    );
    final data = res['data'] as Map<String, dynamic>;
    final items = ((data['items'] ?? []) as List)
        .map((j) => parseGroupTxn(j as Map<String, dynamic>))
        .toList();
    return PagedResult(
        items: items, hasMore: (data['hasMore'] as bool?) ?? false);
  }

  Future<PagedResult<ExpenseModel>> feedPaged({
    int page = 1,
    int limit = 30,
  }) async {
    final p = await feed(page: page, limit: limit);
    return PagedResult(items: p.items, hasMore: p.hasMore);
  }

  Future<ExpenseModel> getById(String id) async {
    final res = await _client.get('/expenses/$id');
    return ExpenseModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<ExpenseModel> update(
    String id, {
    String? description,
    double? amount,
    String? splitMode,
    String? paidBy,
    List<Map<String, dynamic>>? splits,
    String? category,
    String? notes,
    String? currency,
    DateTime? spentAt,
  }) async {
    final body = <String, dynamic>{
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (splitMode != null) 'splitMode': splitMode,
      if (paidBy != null) 'paidBy': paidBy,
      if (splits != null) 'splits': splits,
      if (category != null) 'category': category,
      if (notes != null) 'notes': notes,
      if (currency != null) 'currency': currency,
      if (spentAt != null) 'spentAt': spentAt.toIso8601String(),
    };
    final res = await _client.patch('/expenses/$id', body: body);
    return ExpenseModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.delete('/expenses/$id');
  }

  Future<ExpensePage> feed({int page = 1, int limit = 30}) async {
    final res = await _client
        .get('/expenses/feed', query: {'page': page, 'limit': limit});
    return ExpensePage.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<List<MonthlyCategoryTotal>> analytics({int months = 6}) async {
    final res =
        await _client.get('/expenses/analytics', query: {'months': months});
    final data = res['data'] as List;
    return data
        .map((e) => MonthlyCategoryTotal.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
