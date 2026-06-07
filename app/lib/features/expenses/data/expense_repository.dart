import '../../../core/db/local_store.dart';
import '../../../core/sync/sync_engine.dart';
import 'expense_model.dart';

/// Offline-first expense writes. Reads are served by Drift streams in the
/// providers; here we only handle the mutations — they apply to the local DB
/// immediately and queue a sync op (the [SyncEngine] owns all server I/O).
class ExpenseRepository {
  ExpenseRepository();
  final _store = LocalStore.instance;

  Future<ExpenseModel> create({
    required String groupId,
    required String description,
    required double amount,
    required String splitMode,
    required String paidBy,
    required List<Map<String, dynamic>> splits,
    List<Map<String, dynamic>>? payers,
    String? notes,
    String? category,
    String? currency,
    double tax = 0,
    double tip = 0,
    DateTime? spentAt,
    String? receiptUrl,
  }) async {
    final id = await _store.createExpenseLocal(
      groupId: groupId,
      description: description,
      amount: amount,
      splitMode: splitMode,
      paidBy: paidBy,
      splits: splits,
      payers: payers ?? const [],
      category: category ?? 'other',
      notes: notes ?? '',
      currency: currency ?? 'PKR',
      tax: tax,
      tip: tip,
      spentAt: spentAt,
      receiptUrl: receiptUrl,
    );
    SyncEngine.instance.kick();
    return ExpenseModel.fromJson((await _store.watchExpenseJson(id).first)!);
  }

  Future<ExpenseModel> update(
    String id, {
    String? description,
    double? amount,
    String? splitMode,
    String? paidBy,
    List<Map<String, dynamic>>? splits,
    List<Map<String, dynamic>>? payers,
    String? category,
    String? notes,
    String? currency,
    DateTime? spentAt,
    String? receiptUrl,
  }) async {
    await _store.updateExpenseLocal(
      id,
      description: description ?? '',
      amount: amount ?? 0,
      splitMode: splitMode ?? 'equal',
      paidBy: paidBy ?? '',
      splits: splits ?? const [],
      payers: payers ?? const [],
      category: category ?? 'other',
      notes: notes ?? '',
      tax: 0,
      tip: 0,
      receiptUrl: receiptUrl,
    );
    SyncEngine.instance.kick();
    return ExpenseModel.fromJson((await _store.watchExpenseJson(id).first)!);
  }

  Future<void> delete(String id) async {
    await _store.deleteExpenseLocal(id);
    SyncEngine.instance.kick();
  }
}
