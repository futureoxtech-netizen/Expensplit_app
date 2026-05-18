import '../../auth/data/user_model.dart';

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
    this.notes = '',
    this.tax = 0,
    this.tip = 0,
    this.receiptUrl,
    this.groupName,
    this.groupColor,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> j) {
    final group = j['group'];
    final paid = j['paidBy'];
    return ExpenseModel(
      id: (j['_id'] ?? j['id']).toString(),
      groupId: group is Map<String, dynamic>
          ? (group['_id'] ?? group['id']).toString()
          : group.toString(),
      groupName: group is Map<String, dynamic> ? group['name'] as String? : null,
      groupColor: group is Map<String, dynamic> ? group['coverColor'] as String? : null,
      description: j['description'] ?? '',
      notes: j['notes'] ?? '',
      amount: (j['amount'] as num).toDouble(),
      currency: j['currency'] ?? 'USD',
      category: j['category'] ?? 'other',
      splitMode: j['splitMode'] ?? 'equal',
      paidBy: paid is Map<String, dynamic>
          ? UserModel.fromJson(paid)
          : UserModel(id: paid.toString(), name: '', email: ''),
      shares: ((j['shares'] ?? []) as List)
          .map((s) => ExpenseShare.fromJson(s as Map<String, dynamic>))
          .toList(),
      tax: ((j['tax'] ?? 0) as num).toDouble(),
      tip: ((j['tip'] ?? 0) as num).toDouble(),
      receiptUrl: j['receiptUrl'] as String?,
      spentAt: DateTime.tryParse(j['spentAt']?.toString() ?? '') ?? DateTime.now(),
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
  final double tax;
  final double tip;
  final String? receiptUrl;
  final DateTime spentAt;
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
  factory MonthlyCategoryTotal.fromJson(Map<String, dynamic> j) => MonthlyCategoryTotal(
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
