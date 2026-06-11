import '../../../core/db/local_store.dart';
import '../../../core/pagination/paged_list_notifier.dart';
import '../../../core/sync/sync_engine.dart';
import 'personal_expense_model.dart';

/// Offline-first personal expenses. Reads come from the local DB; writes apply
/// locally and queue a sync op.
class PersonalExpenseRepository {
  PersonalExpenseRepository();
  final _store = LocalStore.instance;

  Future<List<PersonalExpenseModel>> _all() async {
    final list = await _store.watchPersonalJson().first;
    return list.map(PersonalExpenseModel.fromJson).toList();
  }

  bool _inRange(PersonalExpenseModel e, DateTime? from, DateTime? to, String? category) {
    // Half-open interval [from, to) — matches personalPage so a midnight-dated
    // expense doesn't leak into the previous period (see LocalStore.personalPage).
    if (from != null && e.date.isBefore(from)) return false;
    if (to != null && !e.date.isBefore(to)) return false;
    if (category != null && e.category != category) return false;
    return true;
  }

  Future<PagedResult<PersonalExpenseModel>> listPaged({
    DateTime? from,
    DateTime? to,
    String? category,
    int page = 1,
    int limit = 30,
  }) async {
    SyncEngine.instance.kick();
    final rows = await _store.personalPage(
      from: from,
      to: to,
      category: category,
      limit: limit,
      offset: (page - 1) * limit,
    );
    return PagedResult(
      items: rows.map(PersonalExpenseModel.fromJson).toList(),
      hasMore: rows.length == limit,
    );
  }

  Future<List<PersonalExpenseModel>> list({
    DateTime? from,
    DateTime? to,
    String? category,
  }) async {
    return (await _all()).where((e) => _inRange(e, from, to, category)).toList();
  }

  Future<PersonalExpenseModel> create({
    required String description,
    required double amount,
    required String currency,
    required String category,
    required DateTime date,
    String? note,
    String? receiptUrl,
  }) async {
    final id = await _store.createPersonalLocal(
      description: description,
      amount: amount,
      currency: currency,
      category: category,
      date: date,
      note: note ?? '',
      receiptUrl: receiptUrl,
    );
    SyncEngine.instance.kick();
    final row = (await _store.watchPersonalJson().first).firstWhere((e) => e['_id'] == id);
    return PersonalExpenseModel.fromJson(row);
  }

  Future<PersonalExpenseModel> update(
    String id, {
    String? description,
    double? amount,
    String? currency,
    String? category,
    DateTime? date,
    String? note,
    String? receiptUrl,
  }) async {
    final fields = <String, dynamic>{};
    if (description != null) fields['description'] = description;
    if (amount != null) fields['amount'] = amount;
    if (currency != null) fields['currency'] = currency;
    if (category != null) fields['category'] = category;
    if (date != null) fields['date'] = date.toIso8601String();
    if (note != null) fields['note'] = note;
    if (receiptUrl != null) fields['receiptUrl'] = receiptUrl;
    await _store.updatePersonalLocal(id, fields);
    SyncEngine.instance.kick();
    final row = (await _store.watchPersonalJson().first).firstWhere((e) => e['_id'] == id);
    return PersonalExpenseModel.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _store.deletePersonalLocal(id);
    SyncEngine.instance.kick();
  }

  /// Monthly category totals for the chart, computed from local data.
  Future<List<PersonalSummaryRow>> summary({int months = 3}) async {
    final since = DateTime(DateTime.now().year, DateTime.now().month - (months - 1), 1);
    final all = await _all();
    final totals = <String, PersonalSummaryRow>{};
    for (final e in all) {
      if (e.date.isBefore(since)) continue;
      final key = '${e.date.year}-${e.date.month}-${e.category}';
      final prev = totals[key];
      totals[key] = PersonalSummaryRow(
        year: e.date.year,
        month: e.date.month,
        category: e.category,
        total: (prev?.total ?? 0) + e.amount,
      );
    }
    return totals.values.toList();
  }
}
