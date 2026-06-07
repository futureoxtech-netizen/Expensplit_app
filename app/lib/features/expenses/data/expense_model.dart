import '../../auth/data/user_model.dart';
import '../../reactions/data/reaction_model.dart';

class ExpenseShare {
  ExpenseShare({required this.user, required this.amount});
  factory ExpenseShare.fromJson(Map<String, dynamic> j) {
    final raw = j['user'];
    final user = raw is Map<String, dynamic>
        ? UserModel.fromJson(raw)
        : UserModel(id: raw.toString(), name: '', email: '');
    return ExpenseShare(user: user, amount: (j['amount'] as num).toDouble());
  }

  final UserModel user;
  final double amount;
}

/// One contributor when an expense is paid by multiple people.
class ExpensePayer {
  ExpensePayer({required this.user, required this.amount});
  factory ExpensePayer.fromJson(Map<String, dynamic> j) {
    final raw = j['user'];
    final user = raw is Map<String, dynamic>
        ? UserModel.fromJson(raw)
        : UserModel(id: raw.toString(), name: '', email: '');
    return ExpensePayer(user: user, amount: (j['amount'] as num).toDouble());
  }

  final UserModel user;
  final double amount;
}

class ExpenseModel {
  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.splitMode,
    required this.paidBy,
    required this.shares,
    required this.spentAt,
    this.payers = const [],
    this.notes = '',
    this.tax = 0,
    this.tip = 0,
    this.receiptUrl,
    this.groupName,
    this.groupColor,
    this.reactions = const [],
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> j) {
    final group = j['group'];
    final paid = j['paidBy'];
    return ExpenseModel(
      id: (j['_id'] ?? j['id']).toString(),
      groupId: group is Map<String, dynamic>
          ? (group['_id'] ?? group['id']).toString()
          : group.toString(),
      groupName:
          group is Map<String, dynamic> ? group['name'] as String? : null,
      groupColor:
          group is Map<String, dynamic> ? group['coverColor'] as String? : null,
      description: j['description'] ?? '',
      notes: j['notes'] ?? '',
      amount: (j['amount'] as num).toDouble(),
      currency: j['currency'] ?? 'PKR',
      category: j['category'] ?? 'other',
      splitMode: j['splitMode'] ?? 'equal',
      paidBy: paid is Map<String, dynamic>
          ? UserModel.fromJson(paid)
          : UserModel(id: paid.toString(), name: '', email: ''),
      shares: ((j['shares'] ?? []) as List)
          .map((s) => ExpenseShare.fromJson(s as Map<String, dynamic>))
          .toList(),
      payers: ((j['payers'] ?? []) as List)
          .map((p) => ExpensePayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      tax: ((j['tax'] ?? 0) as num).toDouble(),
      tip: ((j['tip'] ?? 0) as num).toDouble(),
      receiptUrl: j['receiptUrl'] as String?,
      spentAt:
          DateTime.tryParse(j['spentAt']?.toString() ?? '') ?? DateTime.now(),
      reactions: parseReactions(j['reactions']),
    );
  }

  final String id;
  final String groupId;
  final String? groupName;
  final String? groupColor;
  final String description;
  final String notes;
  final double amount;
  final String currency;
  final String category;
  final String splitMode;
  final UserModel paidBy;
  final List<ExpenseShare> shares;

  /// Populated only when the expense was paid by more than one person.
  /// Empty for single-payer expenses (use [paidBy] + [amount] then).
  final List<ExpensePayer> payers;

  /// True when the expense has a multi-payer breakdown.
  bool get hasMultiplePayers => payers.length > 1;

  final double tax;
  final double tip;
  final String? receiptUrl;
  final DateTime spentAt;

  /// Per-emoji reaction summaries for this expense. Empty when nobody has
  /// reacted. Updated in place by the realtime bridge so the feed stays live.
  final List<ReactionSummary> reactions;

  ExpenseModel copyWith({List<ReactionSummary>? reactions}) => ExpenseModel(
        id: id,
        groupId: groupId,
        groupName: groupName,
        groupColor: groupColor,
        description: description,
        notes: notes,
        amount: amount,
        currency: currency,
        category: category,
        splitMode: splitMode,
        paidBy: paidBy,
        shares: shares,
        payers: payers,
        tax: tax,
        tip: tip,
        receiptUrl: receiptUrl,
        spentAt: spentAt,
        reactions: reactions ?? this.reactions,
      );
}

/// A single entry in a group's activity stream. The group-detail Expenses
/// tab shows expenses and settlement ("X paid Y") records merged together,
/// so the list is a mix of these two shapes.
sealed class GroupTxn {
  DateTime get date;
}

class ExpenseTxn extends GroupTxn {
  ExpenseTxn(this.expense);
  final ExpenseModel expense;

  @override
  DateTime get date => expense.spentAt;
}

class SettlementTxn extends GroupTxn {
  SettlementTxn({
    required this.id,
    required this.groupId,
    required this.from,
    required this.to,
    required this.amount,
    required this.currency,
    required this.note,
    required this.date,
    this.reactions = const [],
  });

  factory SettlementTxn.fromJson(Map<String, dynamic> j) {
    UserModel? parseUser(dynamic raw) =>
        raw is Map<String, dynamic> ? UserModel.fromJson(raw) : null;
    return SettlementTxn(
      id: (j['id'] ?? j['_id']).toString(),
      groupId: (j['groupId'] ?? '').toString(),
      from: parseUser(j['from']),
      to: parseUser(j['to']),
      amount: (j['amount'] as num).toDouble(),
      currency: j['currency'] ?? 'PKR',
      note: j['note'] ?? '',
      date:
          DateTime.tryParse(j['settledAt']?.toString() ?? '') ?? DateTime.now(),
      reactions: parseReactions(j['reactions']),
    );
  }

  final String id;
  final String groupId;
  final UserModel? from;
  final UserModel? to;
  final double amount;
  final String currency;
  final String note;
  @override
  final DateTime date;

  /// Per-emoji reaction summaries for this settlement record.
  final List<ReactionSummary> reactions;

  SettlementTxn copyWith({List<ReactionSummary>? reactions}) => SettlementTxn(
        id: id,
        groupId: groupId,
        from: from,
        to: to,
        amount: amount,
        currency: currency,
        note: note,
        date: date,
        reactions: reactions ?? this.reactions,
      );
}

/// Parse one transaction item from the merged group-transactions endpoint,
/// discriminating on the `type` field the backend sets.
GroupTxn parseGroupTxn(Map<String, dynamic> j) {
  if (j['type'] == 'settlement') return SettlementTxn.fromJson(j);
  return ExpenseTxn(ExpenseModel.fromJson(j));
}

class ExpensePage {
  ExpensePage({required this.items, required this.hasMore, required this.page});
  factory ExpensePage.fromJson(Map<String, dynamic> j) => ExpensePage(
        items: ((j['items'] ?? []) as List)
            .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: (j['hasMore'] ?? false) as bool,
        page: (j['page'] ?? 1) as int,
      );

  final List<ExpenseModel> items;
  final bool hasMore;
  final int page;
}

class MonthlyCategoryTotal {
  MonthlyCategoryTotal({
    required this.year,
    required this.month,
    required this.category,
    required this.total,
  });
  factory MonthlyCategoryTotal.fromJson(Map<String, dynamic> j) =>
      MonthlyCategoryTotal(
        year: (j['year'] as num).toInt(),
        month: (j['month'] as num).toInt(),
        category: j['category'].toString(),
        total: (j['total'] as num).toDouble(),
      );

  final int year;
  final int month;
  final String category;
  final double total;
}
