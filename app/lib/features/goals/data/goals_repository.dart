import '../../../core/network/dio_client.dart';
import 'goal_model.dart';

class GoalsRepository {
  GoalsRepository(this._client);
  final DioClient _client;

  Future<GoalsPage> list({String? status, int page = 1, int limit = 20}) async {
    final params = <String, String>{'page': '$page', 'limit': '$limit'};
    if (status != null) params['status'] = status;
    final res = await _client.get('/goals', query: params);
    return GoalsPage.fromJson(res as Map<String, dynamic>);
  }

  Future<GoalModel> getById(String id) async {
    final res = await _client.get('/goals/$id');
    return GoalModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<GoalModel> create({
    required String title,
    String? description,
    String emoji = '🎯',
    String category = 'other',
    required double targetAmount,
    String currency = 'USD',
    DateTime? targetDate,
    String priority = 'medium',
    String color = '#6C5CE7',
    String notes = '',
  }) async {
    final res = await _client.post('/goals', body: {
      'title': title,
      if (description != null) 'description': description,
      'emoji': emoji,
      'category': category,
      'targetAmount': targetAmount,
      'currency': currency,
      if (targetDate != null) 'targetDate': targetDate.toIso8601String(),
      'priority': priority,
      'color': color,
      if (notes.isNotEmpty) 'notes': notes,
    });
    return GoalModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<GoalModel> update(
    String id, {
    String? title,
    String? description,
    String? emoji,
    String? category,
    double? targetAmount,
    String? currency,
    DateTime? targetDate,
    bool clearTargetDate = false,
    String? priority,
    String? color,
    String? notes,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (emoji != null) body['emoji'] = emoji;
    if (category != null) body['category'] = category;
    if (targetAmount != null) body['targetAmount'] = targetAmount;
    if (currency != null) body['currency'] = currency;
    if (clearTargetDate) body['targetDate'] = null;
    else if (targetDate != null) body['targetDate'] = targetDate.toIso8601String();
    if (priority != null) body['priority'] = priority;
    if (color != null) body['color'] = color;
    if (notes != null) body['notes'] = notes;
    if (status != null) body['status'] = status;

    final res = await _client.patch('/goals/$id', body: body);
    return GoalModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _client.delete('/goals/$id');

  Future<GoalModel> addContribution(
    String goalId, {
    required double amount,
    String note = '',
    DateTime? date,
  }) async {
    final res = await _client.post('/goals/$goalId/contributions', body: {
      'amount': amount,
      'note': note,
      if (date != null) 'date': date.toIso8601String(),
    });
    return GoalModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<GoalModel> updateContribution(
    String goalId,
    String contributionId, {
    double? amount,
    String? note,
    DateTime? date,
  }) async {
    final body = <String, dynamic>{};
    if (amount != null) body['amount'] = amount;
    if (note != null) body['note'] = note;
    if (date != null) body['date'] = date.toIso8601String();
    final res = await _client.patch(
        '/goals/$goalId/contributions/$contributionId',
        body: body);
    return GoalModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<GoalModel> removeContribution(
      String goalId, String contributionId) async {
    final res = await _client.delete(
        '/goals/$goalId/contributions/$contributionId');
    return GoalModel.fromJson(res['data'] as Map<String, dynamic>);
  }
}
