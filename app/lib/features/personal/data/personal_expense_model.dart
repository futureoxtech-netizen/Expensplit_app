class PersonalExpenseModel {
  const PersonalExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    this.note = '',
    this.receiptUrl = '',
  });

  final String id;
  final String description;
  final double amount;
  final String currency;
  final String category;
  final DateTime date;
  final String note;
  final String receiptUrl;

  factory PersonalExpenseModel.fromJson(Map<String, dynamic> j) =>
      PersonalExpenseModel(
        id: j['_id'] as String,
        description: j['description'] as String,
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] as String? ?? 'PKR',
        category: j['category'] as String? ?? 'other',
        // Dates are stored/transported as UTC; convert to local so the screen
        // groups them under the calendar day the user actually picked (a UTC
        // instant would bucket a midnight entry under the previous day east of
        // GMT, e.g. PKT +5).
        date: DateTime.parse(j['date'] as String).toLocal(),
        note: j['note'] as String? ?? '',
        receiptUrl: j['receiptUrl'] as String? ?? '',
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
