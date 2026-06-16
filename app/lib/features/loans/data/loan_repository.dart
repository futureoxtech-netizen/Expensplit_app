import '../../../core/db/local_store.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/sync/sync_engine.dart';
import 'guest_contact_model.dart';
import 'loan_model.dart';

class LoanRepository {
  LoanRepository(this._dio);

  final DioClient _dio;
  final _store = LocalStore.instance;

  // ── Guest Contacts ─────────────────────────────────────────────────────────
  Future<String> addGuestContact({
    required String name,
    String? phone,
    String? email,
    String? avatarColor,
  }) =>
      _store.createGuestContactLocal(
        name: name,
        phone: phone,
        email: email,
        avatarColor: avatarColor,
      );

  Future<void> updateGuestContact(String id, {String? name, String? phone, String? email}) =>
      _store.updateGuestContactLocal(id, name: name, phone: phone, email: email);

  Future<void> deleteGuestContact(String id) => _store.deleteGuestContactLocal(id);

  Stream<List<GuestContactModel>> watchGuestContacts() =>
      _store.watchGuestContactsJson().map(
            (list) => list.map(GuestContactModel.fromJson).toList(),
          );

  /// Search registered Expensplit users by name OR email via the server.
  /// Returns contact maps shaped like the picker expects. Online-only; returns
  /// an empty list on any failure so the picker degrades gracefully offline.
  Future<List<Map<String, dynamic>>> searchAppUsers(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];
    try {
      final res = await _dio.get('/users/search', query: {'q': q});
      final data = (res['data'] ?? const []) as List;
      return data.whereType<Map>().map((u) {
        return <String, dynamic>{
          '_id': (u['id'] ?? u['_id']).toString(),
          'name': (u['name'] ?? '').toString(),
          'email': (u['email'] ?? '').toString(),
          'avatarUrl': u['avatarUrl']?.toString(),
          'isGuest': false,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Loans ──────────────────────────────────────────────────────────────────
  Stream<List<LoanModel>> watchLoans() =>
      _store.watchLoansJson().map(
            (list) => list.map(LoanModel.fromJson).toList(),
          );

  Stream<LoanModel?> watchLoan(String id) =>
      _store.watchLoanJson(id).map(
            (j) => j == null ? null : LoanModel.fromJson(j),
          );

  Future<String> createLoan({
    required String counterpartyId,
    required String counterpartyType,
    required String counterpartyName,
    String? counterpartyAvatar,
    required String loanType,
    required double amount,
    required String currency,
    String description = '',
    String notes = '',
    DateTime? dueDate,
  }) async {
    final id = await _store.createLoanLocal(
      counterpartyId: counterpartyId,
      counterpartyType: counterpartyType,
      counterpartyName: counterpartyName,
      counterpartyAvatar: counterpartyAvatar,
      loanType: loanType,
      amount: amount,
      currency: currency,
      description: description,
      notes: notes,
      dueDate: dueDate,
    );
    SyncEngine.instance.kick();
    return id;
  }

  /// Approve a pending loan (borrower calling this).
  Future<void> approveLoan(String loanId) async {
    // Optimistic update immediately.
    await _store.updateLoanStatusLocal(loanId, 'active');
    try {
      final sid = await SyncEngine.instance.requireServerId('loan', loanId);
      await _dio.post('/loans/$sid/approve', body: {});
    } catch (_) {
      // Rollback optimistic update on failure.
      await _store.updateLoanStatusLocal(loanId, 'pending_approval');
      rethrow;
    }
    SyncEngine.instance.kick();
  }

  /// Reject a pending loan (borrower calling this).
  Future<void> rejectLoan(String loanId) async {
    await _store.updateLoanStatusLocal(loanId, 'rejected');
    try {
      final sid = await SyncEngine.instance.requireServerId('loan', loanId);
      await _dio.post('/loans/$sid/reject', body: {});
    } catch (_) {
      await _store.updateLoanStatusLocal(loanId, 'pending_approval');
      rethrow;
    }
    SyncEngine.instance.kick();
  }

  Future<void> deleteLoan(String id) async {
    await _store.deleteLoanLocal(id);
    SyncEngine.instance.kick();
  }

  // ── Payments ───────────────────────────────────────────────────────────────
  Future<String> addPayment({
    required String loanId,
    required double amount,
    String note = '',
    String method = 'cash',
    DateTime? paidAt,
  }) async {
    final id = await _store.createLoanPaymentLocal(
      loanId: loanId,
      amount: amount,
      note: note,
      method: method,
      paidAt: paidAt,
    );
    SyncEngine.instance.kick();
    return id;
  }

  Future<void> deletePayment(String paymentId, String loanId) async {
    await _store.deleteLoanPaymentLocal(paymentId, loanId);
    SyncEngine.instance.kick();
  }
}
