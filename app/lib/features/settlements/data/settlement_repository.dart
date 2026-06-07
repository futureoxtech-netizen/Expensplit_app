import '../../../core/db/local_store.dart';
import '../../../core/sync/sync_engine.dart';

/// Offline-first settlements. A recorded payment applies locally (adjusting
/// balances instantly) and queues a sync op.
class SettlementRepository {
  SettlementRepository();
  final _store = LocalStore.instance;

  Future<void> create({
    required String groupId,
    required String from,
    required String to,
    required double amount,
    String? currency,
    String method = 'cash',
    String? note,
  }) async {
    await _store.createSettlementLocal(
      groupId: groupId,
      from: from,
      to: to,
      amount: amount,
      currency: currency ?? 'PKR',
      method: method,
      note: note ?? '',
    );
    SyncEngine.instance.kick();
  }

  Future<List<Map<String, dynamic>>> listByGroup(String groupId) async {
    final rows = await _store.groupSettlements(groupId);
    return [
      for (final s in rows)
        {
          '_id': s.id,
          'groupId': groupId,
          'from': s.fromUserId,
          'to': s.toUserId,
          'amount': s.amount,
          'currency': s.currency,
          'method': s.method,
          'note': s.note,
          'settledAt': s.settledAt?.toIso8601String(),
        }
    ];
  }
}
