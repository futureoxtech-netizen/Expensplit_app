import '../../auth/data/user_model.dart';

class GroupMember {
  GroupMember({required this.user, required this.role});

  factory GroupMember.fromJson(Map<String, dynamic> j) {
    final raw = j['user'];
    final user = raw is Map<String, dynamic>
        ? UserModel.fromJson(raw)
        : UserModel(id: raw.toString(), name: '', email: '');
    return GroupMember(user: user, role: (j['role'] ?? 'member').toString());
  }

  final UserModel user;
  final String role;
}

class GroupModel {
  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.coverColor,
    required this.icon,
    required this.currency,
    required this.inviteCode,
    required this.members,
    this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> j) => GroupModel(
        id: (j['_id'] ?? j['id']).toString(),
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        category: j['category'] ?? 'other',
        coverColor: j['coverColor'] ?? '#6C5CE7',
        icon: j['icon'] ?? 'group',
        currency: j['currency'] ?? 'PKR',
        inviteCode: j['inviteCode'] ?? '',
        members: ((j['members'] ?? []) as List)
            .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
            .toList(),
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      );

  final String id;
  final String name;
  final String description;
  final String category;
  final String coverColor;
  final String icon;
  final String currency;
  final String inviteCode;
  final List<GroupMember> members;
  final DateTime? createdAt;
}

class BalanceEntry {
  BalanceEntry({required this.userId, required this.user, required this.net});

  factory BalanceEntry.fromJson(Map<String, dynamic> j) => BalanceEntry(
        userId: j['userId'].toString(),
        user: j['user'] is Map<String, dynamic>
            ? UserModel.fromJson(j['user'] as Map<String, dynamic>)
            : null,
        net: (j['net'] as num).toDouble(),
      );

  final String userId;
  final UserModel? user;
  final double net;
}

class TransferEntry {
  TransferEntry({
    required this.from,
    required this.to,
    required this.amount,
    this.fromUser,
    this.toUser,
  });

  factory TransferEntry.fromJson(Map<String, dynamic> j) => TransferEntry(
        from: j['from'].toString(),
        to: j['to'].toString(),
        amount: (j['amount'] as num).toDouble(),
        fromUser: j['fromUser'] is Map<String, dynamic>
            ? UserModel.fromJson(j['fromUser'] as Map<String, dynamic>)
            : null,
        toUser: j['toUser'] is Map<String, dynamic>
            ? UserModel.fromJson(j['toUser'] as Map<String, dynamic>)
            : null,
      );

  final String from;
  final String to;
  final double amount;
  final UserModel? fromUser;
  final UserModel? toUser;
}

class GroupBalances {
  GroupBalances({required this.balances, required this.transfers});

  factory GroupBalances.fromJson(Map<String, dynamic> j) => GroupBalances(
        balances: ((j['balances'] ?? []) as List)
            .map((b) => BalanceEntry.fromJson(b as Map<String, dynamic>))
            .toList(),
        transfers: ((j['transfers'] ?? []) as List)
            .map((t) => TransferEntry.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  final List<BalanceEntry> balances;
  final List<TransferEntry> transfers;
}
