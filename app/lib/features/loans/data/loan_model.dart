class LoanPaymentModel {
  LoanPaymentModel({
    required this.id,
    required this.loanId,
    required this.amount,
    this.note = '',
    this.method = 'cash',
    required this.paidAt,
  });

  factory LoanPaymentModel.fromJson(Map<String, dynamic> j) => LoanPaymentModel(
        id: (j['_id'] ?? j['id']).toString(),
        loanId: j['loanId']?.toString() ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        note: j['note']?.toString() ?? '',
        method: j['method']?.toString() ?? 'cash',
        paidAt: j['paidAt'] != null ? DateTime.parse(j['paidAt'].toString()) : DateTime.now(),
      );

  final String id;
  final String loanId;
  final double amount;
  final String note;
  final String method;
  final DateTime paidAt;
}

class LoanModel {
  LoanModel({
    required this.id,
    this.serverId,
    required this.counterpartyId,
    required this.counterpartyType,
    required this.counterpartyName,
    this.counterpartyAvatar,
    required this.loanType,
    required this.amount,
    required this.paidAmount,
    required this.currency,
    this.description = '',
    this.notes = '',
    this.dueDate,
    required this.status,
    required this.createdAt,
    this.payments = const [],
  });

  factory LoanModel.fromJson(Map<String, dynamic> j) => LoanModel(
        id: (j['_id'] ?? j['id']).toString(),
        serverId: j['serverId']?.toString(),
        counterpartyId: j['counterpartyId']?.toString() ?? '',
        counterpartyType: j['counterpartyType']?.toString() ?? 'guest',
        counterpartyName: j['counterpartyName']?.toString() ?? '',
        counterpartyAvatar: j['counterpartyAvatar']?.toString(),
        loanType: j['loanType']?.toString() ?? 'given',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        paidAmount: (j['paidAmount'] as num?)?.toDouble() ?? 0,
        currency: j['currency']?.toString() ?? 'PKR',
        description: j['description']?.toString() ?? '',
        notes: j['notes']?.toString() ?? '',
        dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate'].toString()) : null,
        status: j['status']?.toString() ?? 'active',
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        payments: (j['payments'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(LoanPaymentModel.fromJson)
            .toList(),
      );

  final String id;
  final String? serverId;
  final String counterpartyId;
  final String counterpartyType;
  final String counterpartyName;
  final String? counterpartyAvatar;

  /// 'given' = I lent money  |  'taken' = I borrowed money
  final String loanType;

  final double amount;
  final double paidAmount;
  final String currency;
  final String description;
  final String notes;
  final DateTime? dueDate;

  /// 'pending_approval' | 'active' | 'settled' | 'rejected'
  final String status;
  final DateTime createdAt;
  final List<LoanPaymentModel> payments;

  double get remaining => (amount - paidAmount).clamp(0, amount);
  double get progress => amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0.0;

  /// The counterparty must approve/reject this loan (it was created by them).
  bool get isPendingApproval => status == 'pending_approval';

  /// I created this loan and am awaiting the counterparty's confirmation.
  bool get isPendingSent => status == 'pending_sent';

  /// Either side of the approval handshake — used to gate payments etc.
  bool get isPending => isPendingApproval || isPendingSent;

  bool get isActive => status == 'active';
  bool get isSettled => status == 'settled';
  bool get isRejected => status == 'rejected';
  bool get isGuest => counterpartyType == 'guest';

  bool get isOverdue =>
      isActive && dueDate != null && DateTime.now().isAfter(dueDate!);

  /// How many days until due (negative = overdue).
  int? get daysUntilDue => dueDate?.difference(DateTime.now()).inDays;
}
