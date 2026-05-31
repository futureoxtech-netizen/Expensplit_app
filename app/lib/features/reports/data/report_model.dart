class ReportTotals {
  ReportTotals({required this.total, required this.count, required this.paid});
  factory ReportTotals.fromJson(Map<String, dynamic> j) => ReportTotals(
        total: (j['total'] as num).toDouble(),
        count: (j['count'] as num).toInt(),
        paid: (j['paid'] as num? ?? 0).toDouble(),
      );
  final double total;
  final int count;
  final double paid;
}

class CategoryAmount {
  CategoryAmount({required this.category, required this.amount, required this.count});
  factory CategoryAmount.fromJson(Map<String, dynamic> j) => CategoryAmount(
        category: j['category']?.toString() ?? 'other',
        amount: (j['amount'] as num).toDouble(),
        count: (j['count'] as num? ?? 0).toInt(),
      );
  final String category;
  final double amount;
  final int count;
}

class DayAmount {
  DayAmount({required this.date, required this.amount});
  factory DayAmount.fromJson(Map<String, dynamic> j) => DayAmount(
        date: DateTime.parse(j['date'].toString()),
        amount: (j['amount'] as num).toDouble(),
      );
  final DateTime date;
  final double amount;
}

class ReportItem {
  ReportItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.paidBy,
    required this.groupName,
    required this.spentAt,
  });

  factory ReportItem.fromJson(Map<String, dynamic> j) {
    final paid = j['paidBy'];
    final group = j['group'];
    return ReportItem(
      id: (j['_id'] ?? j['id']).toString(),
      description: j['description']?.toString() ?? '',
      amount: (j['amount'] as num).toDouble(),
      currency: j['currency']?.toString() ?? 'PKR',
      category: j['category']?.toString() ?? 'other',
      paidBy: paid is Map ? paid['name']?.toString() ?? '' : '',
      groupName: group is Map ? group['name']?.toString() ?? '' : '',
      spentAt: DateTime.tryParse(j['spentAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String description;
  final double amount;
  final String currency;
  final String category;
  final String paidBy;
  final String groupName;
  final DateTime spentAt;
}

class ReportData {
  ReportData({
    required this.from,
    required this.to,
    required this.totals,
    required this.byCategory,
    required this.byDay,
    required this.items,
  });

  factory ReportData.fromJson(Map<String, dynamic> j) {
    final range = j['range'] as Map<String, dynamic>? ?? const {};
    return ReportData(
      from: DateTime.tryParse(range['from']?.toString() ?? '') ?? DateTime.now(),
      to: DateTime.tryParse(range['to']?.toString() ?? '') ?? DateTime.now(),
      totals: ReportTotals.fromJson(j['totals'] as Map<String, dynamic>? ?? const {'total': 0, 'count': 0}),
      byCategory: ((j['byCategory'] ?? []) as List)
          .map((e) => CategoryAmount.fromJson(e as Map<String, dynamic>))
          .toList(),
      byDay: ((j['byDay'] ?? []) as List)
          .map((e) => DayAmount.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: ((j['items'] ?? []) as List)
          .map((e) => ReportItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final DateTime from;
  final DateTime to;
  final ReportTotals totals;
  final List<CategoryAmount> byCategory;
  final List<DayAmount> byDay;
  final List<ReportItem> items;
}
