import '../../../core/db/local_store.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import '../../../core/sync/sync_engine.dart';
import 'goal_model.dart';

/// Offline-first goals. List/create/update/delete apply to the local DB and
/// queue a sync op. Contributions stay online (the server recomputes the saved
/// total) and the returned goal is merged back into the local DB.
class GoalsRepository {
  GoalsRepository(this._client);
  final DioClient _client;
  final _store = LocalStore.instance;

  Future<List<GoalModel>> _all() async {
    final list = await _store.watchGoalsJson().first;
    return list.map(GoalModel.fromJson).toList();
  }

  Future<GoalsPage> list({String? status, int page = 1, int limit = 20}) async {
    SyncEngine.instance.kick();
    var items = await _all();
    if (status != null) items = items.where((g) => g.status == status).toList();
    final totalSaved = items.fold<double>(0, (a, g) => a + g.savedAmount);
    final totalTarget = items.fold<double>(0, (a, g) => a + g.targetAmount);
    final completed = items.where((g) => g.status == 'completed').length;
    final active = items.where((g) => g.status == 'active').length;
    return GoalsPage(
      items: items,
      total: items.length,
      page: 1,
      pages: 1,
      totalSaved: totalSaved,
      totalTarget: totalTarget,
      completedCount: completed,
      activeCount: active,
    );
  }

  Future<PagedResult<GoalModel>> listPaged({String? status, int page = 1, int limit = 20}) async {
    final p = await list(status: status);
    return PagedResult(items: p.items, hasMore: false);
  }

  Future<GoalModel> getById(String id) async =>
      (await _all()).firstWhere((g) => g.id == id);

  Future<GoalModel> create({
    required String title,
    String? description,
    String emoji = '🎯',
    String category = 'other',
    required double targetAmount,
    String currency = 'PKR',
    DateTime? targetDate,
    String priority = 'medium',
    String color = '#6C5CE7',
    String notes = '',
  }) async {
    final id = await _store.createGoalLocal({
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
    SyncEngine.instance.kick();
    return (await _all()).firstWhere((g) => g.id == id);
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
    final fields = <String, dynamic>{};
    if (title != null) fields['title'] = title;
    if (description != null) fields['description'] = description;
    if (emoji != null) fields['emoji'] = emoji;
    if (category != null) fields['category'] = category;
    if (targetAmount != null) fields['targetAmount'] = targetAmount;
    if (currency != null) fields['currency'] = currency;
    if (clearTargetDate) fields['targetDate'] = null;
    else if (targetDate != null) fields['targetDate'] = targetDate.toIso8601String();
    if (priority != null) fields['priority'] = priority;
    if (color != null) fields['color'] = color;
    if (notes != null) fields['notes'] = notes;
    if (status != null) fields['status'] = status;
    await _store.updateGoalLocal(id, fields);
    SyncEngine.instance.kick();
    return (await _all()).firstWhere((g) => g.id == id);
  }

  Future<void> delete(String id) async {
    await _store.deleteGoalLocal(id);
    SyncEngine.instance.kick();
  }

  // ── Contributions stay online (server recomputes the saved total) ─────────
  Future<GoalModel> addContribution(
    String goalId, {
    required double amount,
    String note = '',
    DateTime? date,
  }) async {
    final gid = await SyncEngine.instance.requireServerId('goal', goalId);
    final res = await _client.post('/goals/$gid/contributions', body: {
      'amount': amount,
      'note': note,
      // UTC — contribution date read path does .toLocal(); see date convention.
      if (date != null) 'date': date.toUtc().toIso8601String(),
    });
    final json = res['data'] as Map<String, dynamic>;
    await _store.applyPull({'goals': [json]});
    return GoalModel.fromJson(json);
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
    if (date != null) body['date'] = date.toUtc().toIso8601String();
    final gid = await SyncEngine.instance.requireServerId('goal', goalId);
    final res = await _client.patch(
        '/goals/$gid/contributions/$contributionId',
        body: body);
    final json = res['data'] as Map<String, dynamic>;
    await _store.applyPull({'goals': [json]});
    return GoalModel.fromJson(json);
  }

  Future<GoalModel> removeContribution(String goalId, String contributionId) async {
    final gid = await SyncEngine.instance.requireServerId('goal', goalId);
    final res = await _client.delete('/goals/$gid/contributions/$contributionId');
    final json = res['data'] as Map<String, dynamic>;
    await _store.applyPull({'goals': [json]});
    return GoalModel.fromJson(json);
  }
}
