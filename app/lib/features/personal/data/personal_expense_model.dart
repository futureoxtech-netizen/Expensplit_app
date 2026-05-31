class PersonalExpenseModel {
  const PersonalExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    this.note = '',
  });

  final String id;
  final String description;
  final double amount;
  final String currency;
  final String category;
  final DateTime date;
  final String note;

  factory PersonalExpenseModel.fromJson(Map<String, dynamic> j) =>
      PersonalExpenseModel(
        id: j['_id'] as String,
        description: j['description'] as String,
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] as String? ?? 'PKR',
        category: j['category'] as String? ?? 'other',
        date: DateTime.parse(j['date'] as String),
        note: j['note'] as String? ?? '',
      );
}

class PersonalSummaryRow {
  const PersonalSummaryRow({
    required this.year,
    required this.month,
    required this.category,
    required this.total,
  });

  final int year;
  final int month;
  final String category;
  final double total;

  factory PersonalSummaryRow.fromJson(Map<String, dynamic> j) {
    final id = j['_id'] as Map<String, dynamic>;
    return PersonalSummaryRow(
      year: (id['year'] as num).toInt(),
      month: (id['month'] as num).toInt(),
      category: id['category'] as String,
      total: (j['total'] as num).toDouble(),
    );
  }
}
