import '../../auth/data/user_model.dart';

class FriendGroupBalance {
  FriendGroupBalance({
    required this.groupId,
    required this.groupName,
    required this.net,
  });

  factory FriendGroupBalance.fromJson(Map<String, dynamic> j) =>
      FriendGroupBalance(
        groupId: j['groupId'].toString(),
        groupName: j['groupName'].toString(),
        net: (j['net'] as num).toDouble(),
      );

  final String groupId;
  final String groupName;
  final double net;
}

class FriendSummary {
  FriendSummary({
    required this.userId,
    required this.user,
    required this.net,
    required this.groups,
  });

  factory FriendSummary.fromJson(Map<String, dynamic> j) => FriendSummary(
        userId: j['userId'].toString(),
        user: UserModel.fromJson(j['user'] as Map<String, dynamic>),
        net: (j['net'] as num).toDouble(),
        groups: ((j['groups'] ?? []) as List)
            .map((g) =>
                FriendGroupBalance.fromJson(g as Map<String, dynamic>))
            .toList(),
      );

  final String userId;
  final UserModel user;

  /// Positive = friend owes me, negative = I owe friend.
  final double net;

  final List<FriendGroupBalance> groups;
}

// ─── Friend transaction (for detail screen) ───────────────────────────────────

class FriendTransaction {
  FriendTransaction({
    required this.type,
    required this.id,
    required this.description,
    required this.groupId,
    required this.groupName,
    required this.groupColor,
    required this.category,
    required this.currency,
    required this.totalAmount,
    required this.net,
    required this.date,
  });

  factory FriendTransaction.fromJson(Map<String, dynamic> j) =>
      FriendTransaction(
        type: j['type'] as String,
        id: j['id'].toString(),
        description: j['description'] as String,
        groupId: j['groupId'].toString(),
        groupName: j['groupName'] as String,
        groupColor: j['groupColor'] as String? ?? '#6C5CE7',
        category: j['category'] as String,
        currency: j['currency'] as String,
        totalAmount: (j['totalAmount'] as num).toDouble(),
        net: (j['net'] as num).toDouble(),
        date: DateTime.parse(j['date'].toString()),
      );

  final String type; // 'expense' | 'settlement'
  final String id;
  final String description;
  final String groupId;
  final String groupName;
  final String groupColor;
  final String category;
  final String currency;
  final double totalAmount;

  /// Positive = friend owes me this amount. Negative = I owe friend.
  final double net;
  final DateTime date;
}

class FriendDetailData {
  FriendDetailData({required this.transactions, required this.groups});

  factory FriendDetailData.fromJson(Map<String, dynamic> j) =>
      FriendDetailData(
        transactions: ((j['transactions'] ?? []) as List)
            .map((t) => FriendTransaction.fromJson(t as Map<String, dynamic>))
            .toList(),
        groups: ((j['groups'] ?? []) as List)
            .map((g) => FriendGroupBalance.fromJson({
                  'groupId': (g['id'] ?? g['groupId']).toString(),
                  'groupName': g['name'] ?? g['groupName'] ?? '',
                  'net': 0,
                }))
            .toList(),
      );

  final List<FriendTransaction> transactions;
  final List<FriendGroupBalance> groups;
}
