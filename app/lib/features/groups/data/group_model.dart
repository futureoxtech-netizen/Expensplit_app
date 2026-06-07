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

/// Someone invited to the group whose privacy setting requires approval. They
/// are not a member yet — shown as "pending" until they accept.
class PendingMember {
  PendingMember({required this.user, this.invitedBy, this.invitedAt});

  factory PendingMember.fromJson(Map<String, dynamic> j) {
    final raw = j['user'];
    final user = raw is Map<String, dynamic>
        ? UserModel.fromJson(raw)
        : UserModel(id: raw.toString(), name: '', email: '');
    final inv = j['invitedBy'];
    return PendingMember(
      user: user,
      invitedBy: inv is Map<String, dynamic> ? UserModel.fromJson(inv) : null,
      invitedAt: j['invitedAt'] != null
          ? DateTime.tryParse(j['invitedAt'].toString())
          : null,
    );
  }

  final UserModel user;
  final UserModel? invitedBy;
  final DateTime? invitedAt;
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
    this.notes = '',
    this.pendingMembers = const [],
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
        notes: j['notes'] ?? '',
        inviteCode: j['inviteCode'] ?? '',
        members: ((j['members'] ?? []) as List)
            .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
            .toList(),
        pendingMembers: ((j['pendingMembers'] ?? []) as List)
            .map((m) => PendingMember.fromJson(m as Map<String, dynamic>))
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
  final String notes;
  final String inviteCode;
  final List<GroupMember> members;
  final List<PendingMember> pendingMembers;
  final DateTime? createdAt;
}

/// A pending invitation the current user has received — surfaced as a banner on
/// the Groups screen with Accept / Decline actions.
class GroupInvite {
  GroupInvite({
    required this.groupId,
    required this.name,
    required this.coverColor,
    required this.memberCount,
    this.invitedBy,
    this.invitedAt,
  });

  factory GroupInvite.fromJson(Map<String, dynamic> j) => GroupInvite(
        groupId: (j['groupId'] ?? j['_id'] ?? j['id']).toString(),
        name: j['name'] ?? '',
        coverColor: j['coverColor'] ?? '#6C5CE7',
        memberCount: (j['memberCount'] as num?)?.toInt() ?? 0,
        invitedBy: j['invitedBy'] is Map<String, dynamic>
            ? UserModel.fromJson(j['invitedBy'] as Map<String, dynamic>)
            : null,
        invitedAt: j['invitedAt'] != null
            ? DateTime.tryParse(j['invitedAt'].toString())
            : null,
      );

  final String groupId;
  final String name;
  final String coverColor;
  final int memberCount;
  final UserModel? invitedBy;
  final DateTime? invitedAt;
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
