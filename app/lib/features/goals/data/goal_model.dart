class ContributionModel {
  const ContributionModel({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });

  final String id;
  final double amount;
  final DateTime date;
  final String note;

  factory ContributionModel.fromJson(Map<String, dynamic> j) =>
      ContributionModel(
        id: j['_id'] as String,
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.parse(j['date'] as String).toLocal(),
        note: j['note'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'note': note,
        'date': date.toUtc().toIso8601String(),
      };
}

class GoalStats {
  const GoalStats({
    required this.remaining,
    required this.progress,
    this.daysLeft,
    this.dailyNeeded,
    this.weeklyNeeded,
    this.monthlyNeeded,
    this.projectedCompletionDate,
    this.reachedMilestone,
    this.nextMilestone,
  });

  final double remaining;
  final double progress;
  final int? daysLeft;
  final double? dailyNeeded;
  final double? weeklyNeeded;
  final double? monthlyNeeded;
  final DateTime? projectedCompletionDate;
  final double? reachedMilestone;
  final double? nextMilestone;

  factory GoalStats.fromJson(Map<String, dynamic> j) => GoalStats(
        remaining: (j['remaining'] as num?)?.toDouble() ?? 0,
        progress: (j['progress'] as num?)?.toDouble() ?? 0,
        daysLeft: (j['daysLeft'] as num?)?.toInt(),
        dailyNeeded: (j['dailyNeeded'] as num?)?.toDouble(),
        weeklyNeeded: (j['weeklyNeeded'] as num?)?.toDouble(),
        monthlyNeeded: (j['monthlyNeeded'] as num?)?.toDouble(),
        projectedCompletionDate: j['projectedCompletionDate'] != null
            ? DateTime.tryParse(j['projectedCompletionDate'] as String)
            : null,
        reachedMilestone: (j['reachedMilestone'] as num?)?.toDouble(),
        nextMilestone: (j['nextMilestone'] as num?)?.toDouble(),
      );

  static const GoalStats empty = GoalStats(remaining: 0, progress: 0);
}

class GoalModel {
  const GoalModel({
    required this.id,
    required this.title,
    required this.emoji,
    required this.category,
    required this.targetAmount,
    required this.savedAmount,
    required this.currency,
    required this.status,
    required this.priority,
    required this.color,
    required this.createdAt,
    this.description = '',
    this.notes = '',
    this.targetDate,
    this.completedAt,
    this.contributions = const [],
    this.stats = GoalStats.empty,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final String category;
  final double targetAmount;
  final double savedAmount;
  final String currency;
  final DateTime? targetDate;
  final String status;
  final String priority;
  final String color;
  final String notes;
  final List<ContributionModel> contributions;
  final DateTime? completedAt;
  final DateTime createdAt;
  final GoalStats stats;

  // Computed helpers
  double get progress => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;
  double get remaining => (targetAmount - savedAmount).clamp(0.0, double.infinity);
  bool get isCompleted => status == 'completed';
  bool get isPaused => status == 'paused';
  bool get isAbandoned => status == 'abandoned';
  bool get isActive => status == 'active';

  factory GoalModel.fromJson(Map<String, dynamic> j) => GoalModel(
        id: j['_id'] as String,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '🎯',
        category: j['category'] as String? ?? 'other',
        targetAmount: (j['targetAmount'] as num).toDouble(),
        savedAmount: (j['savedAmount'] as num?)?.toDouble() ?? 0,
        currency: j['currency'] as String? ?? 'PKR',
        targetDate: j['targetDate'] != null
            ? DateTime.tryParse(j['targetDate'] as String)
            : null,
        status: j['status'] as String? ?? 'active',
        priority: j['priority'] as String? ?? 'medium',
        color: j['color'] as String? ?? '#6C5CE7',
        notes: j['notes'] as String? ?? '',
        contributions: j['contributions'] != null
            ? (j['contributions'] as List)
                .cast<Map<String, dynamic>>()
                .map(ContributionModel.fromJson)
                .toList()
            : const [],
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'] as String)
            : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
        stats: j['stats'] != null
            ? GoalStats.fromJson(j['stats'] as Map<String, dynamic>)
            : GoalStats.empty,
      );
}

class GoalsPage {
  const GoalsPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
    required this.totalSaved,
    required this.totalTarget,
    required this.completedCount,
    required this.activeCount,
  });

  final List<GoalModel> items;
  final int total;
  final int page;
  final int pages;
  final double totalSaved;
  final double totalTarget;
  final int completedCount;
  final int activeCount;

  bool get hasMore => page < pages;

  factory GoalsPage.fromJson(Map<String, dynamic> j) {
    final data = j['data'] as Map<String, dynamic>;
    final items = (data['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(GoalModel.fromJson)
        .toList();
    final pagination = data['pagination'] as Map<String, dynamic>;
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    return GoalsPage(
      items: items,
      total: (pagination['total'] as num?)?.toInt() ?? 0,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      pages: (pagination['pages'] as num?)?.toInt() ?? 1,
      totalSaved: (stats['totalSaved'] as num?)?.toDouble() ?? 0,
      totalTarget: (stats['totalTarget'] as num?)?.toDouble() ?? 0,
      completedCount: (stats['completedCount'] as num?)?.toInt() ?? 0,
      activeCount: (stats['activeCount'] as num?)?.toInt() ?? 0,
    );
  }
}
