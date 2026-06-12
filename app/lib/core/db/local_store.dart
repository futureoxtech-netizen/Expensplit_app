import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../balances/balance_calculator.dart';
import '../balances/split_calculator.dart';
import 'app_database.dart';

/// The single data-access layer over the offline Drift DB. Repositories read
/// from here (reactive `watch*` streams that rebuild the app's existing model
/// objects) and write through here (optimistic local writes + a queued sync op).
/// The [SyncEngine] also uses it to apply server pull payloads.
class LocalStore {
  LocalStore(this.db);
  final AppDatabase db;

  static final LocalStore instance = LocalStore(AppDatabase.instance);
  static const _uuid = Uuid();

  /// The signed-in user, set on login/bootstrap. Used as the owner for groups
  /// created offline. `{_id, name, email, avatarUrl}`.
  Map<String, dynamic>? currentUser;
  void setCurrentUser(Map<String, dynamic> user) => currentUser = user;

  String newId() => _uuid.v4();

  DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  String? _iso(DateTime? d) => d?.toUtc().toIso8601String();

  // ───────────────────────────────────────────────────────────────────────────
  // PULL: apply a /sync payload into the local DB.
  // ───────────────────────────────────────────────────────────────────────────
  /// Applies a /sync payload. Returns `true` if it carried any data, so the
  /// caller only signals a UI refresh on real changes (an empty delta must not
  /// trigger a rebuild → re-kick → re-pull feedback loop).
  Future<bool> applyPull(Map<String, dynamic> data) async {
    bool nonEmpty(String k) => (data[k] is List) && (data[k] as List).isNotEmpty;
    final changed = nonEmpty('users') ||
        nonEmpty('groups') ||
        nonEmpty('expenses') ||
        nonEmpty('settlements') ||
        nonEmpty('personalExpenses') ||
        nonEmpty('goals') ||
        nonEmpty('activity') ||
        nonEmpty('loans') ||
        nonEmpty('deletions');
    final myId = currentUser?['_id']?.toString() ?? '';
    await db.transaction(() async {
      for (final u in (data['users'] as List? ?? [])) {
        await _upsertUser(u as Map<String, dynamic>);
      }
      for (final g in (data['groups'] as List? ?? [])) {
        await _upsertGroup(g as Map<String, dynamic>);
      }
      for (final e in (data['expenses'] as List? ?? [])) {
        await _upsertExpense(e as Map<String, dynamic>);
      }
      for (final s in (data['settlements'] as List? ?? [])) {
        await _upsertSettlement(s as Map<String, dynamic>);
      }
      for (final p in (data['personalExpenses'] as List? ?? [])) {
        await _upsertPersonal(p as Map<String, dynamic>);
      }
      for (final g in (data['goals'] as List? ?? [])) {
        await _upsertGoal(g as Map<String, dynamic>);
      }
      for (final a in (data['activity'] as List? ?? [])) {
        await _upsertActivity(a as Map<String, dynamic>);
      }
      for (final l in (data['loans'] as List? ?? [])) {
        await _upsertLoan(l as Map<String, dynamic>, myId);
      }
      for (final d in (data['deletions'] as List? ?? [])) {
        await _applyDeletion(d as Map<String, dynamic>);
      }
    });
    return changed;
  }

  Future<bool> _isDirty(TableInfo table, String localId) async {
    final q = db.customSelect(
      'SELECT dirty FROM ${table.actualTableName} WHERE id = ? LIMIT 1',
      variables: [Variable.withString(localId)],
    );
    final rows = await q.get();
    if (rows.isEmpty) return false;
    return (rows.first.data['dirty'] as int? ?? 0) == 1;
  }

  /// Resolve the stable local id for a server entity. An offline-created row
  /// keeps its uuid `id` and stores the server id in `server_id` — so a pull
  /// must update *that* row, not insert a second one keyed by the server id.
  Future<String> _localIdFor(TableInfo table, String serverId) async {
    final q = db.customSelect(
      'SELECT id FROM ${table.actualTableName} WHERE server_id = ? OR id = ? LIMIT 1',
      variables: [Variable.withString(serverId), Variable.withString(serverId)],
    );
    final rows = await q.get();
    return rows.isEmpty ? serverId : rows.first.data['id'] as String;
  }

  String _idOf(dynamic raw) {
    if (raw is Map) return (raw['_id'] ?? raw['id']).toString();
    return raw.toString();
  }

  Future<void> _upsertUser(Map<String, dynamic> j) async {
    final id = _idOf(j);
    await db.into(db.users).insertOnConflictUpdate(UsersCompanion.insert(
          id: id,
          name: Value(j['name']?.toString() ?? ''),
          email: Value(j['email']?.toString() ?? ''),
          avatarUrl: Value(j['avatarUrl']?.toString()),
          isPlaceholder: Value(j['isPlaceholder'] == true),
          currency: Value(j['currency']?.toString()),
        ));
  }

  Future<void> _upsertGroup(Map<String, dynamic> j) async {
    final serverId = _idOf(j);
    final id = await _localIdFor(db.groups, serverId);
    if (await _isDirty(db.groups, id)) return; // keep un-pushed local edits
    await db.into(db.groups).insertOnConflictUpdate(GroupsCompanion.insert(
          id: id,
          serverId: Value(serverId),
          name: Value(j['name']?.toString() ?? ''),
          description: Value(j['description']?.toString() ?? ''),
          notes: Value(j['notes']?.toString() ?? ''),
          category: Value(j['category']?.toString() ?? 'other'),
          coverColor: Value(j['coverColor']?.toString() ?? '#6C5CE7'),
          icon: Value(j['icon']?.toString() ?? 'group'),
          currency: Value(j['currency']?.toString() ?? 'PKR'),
          inviteCode: Value(j['inviteCode']?.toString() ?? ''),
          pendingMembersJson: Value(jsonEncode(j['pendingMembers'] ?? [])),
          createdAt: Value(_date(j['createdAt'])),
          updatedAt: Value(_date(j['updatedAt'])),
          dirty: const Value(false),
        ));
    // Replace member rows.
    await (db.delete(db.groupMembers)..where((t) => t.groupId.equals(id))).go();
    for (final m in (j['members'] as List? ?? [])) {
      final user = (m as Map)['user'];
      if (user == null) continue;
      final uid = _idOf(user);
      if (user is Map) await _upsertUser(Map<String, dynamic>.from(user));
      await db.into(db.groupMembers).insertOnConflictUpdate(GroupMembersCompanion.insert(
            groupId: id,
            userId: uid,
            role: Value(m['role']?.toString() ?? 'member'),
          ));
    }
  }

  Future<void> _upsertExpense(Map<String, dynamic> j) async {
    final serverId = _idOf(j);
    final id = await _localIdFor(db.expenses, serverId);
    if (await _isDirty(db.expenses, id)) return;
    final group = j['group'];
    final serverGroupId = group is Map ? _idOf(group) : group.toString();
    final groupId = await _localIdFor(db.groups, serverGroupId);
    final paid = j['paidBy'];
    if (paid is Map) await _upsertUser(Map<String, dynamic>.from(paid));
    await db.into(db.expenses).insertOnConflictUpdate(ExpensesCompanion.insert(
          id: id,
          serverId: Value(serverId),
          groupId: groupId,
          description: Value(j['description']?.toString() ?? ''),
          notes: Value(j['notes']?.toString() ?? ''),
          amount: Value((j['amount'] as num?)?.toDouble() ?? 0),
          currency: Value(j['currency']?.toString() ?? 'PKR'),
          category: Value(j['category']?.toString() ?? 'other'),
          splitMode: Value(j['splitMode']?.toString() ?? 'equal'),
          paidById: Value(paid == null ? null : _idOf(paid)),
          tax: Value((j['tax'] as num?)?.toDouble() ?? 0),
          tip: Value((j['tip'] as num?)?.toDouble() ?? 0),
          receiptUrl: Value(j['receiptUrl']?.toString()),
          spentAt: Value(_date(j['spentAt'])),
          createdAt: Value(_date(j['createdAt'])),
          updatedAt: Value(_date(j['updatedAt'])),
          dirty: const Value(false),
        ));
    await (db.delete(db.expenseShares)..where((t) => t.expenseId.equals(id))).go();
    for (final s in (j['shares'] as List? ?? [])) {
      final user = (s as Map)['user'];
      if (user is Map) await _upsertUser(Map<String, dynamic>.from(user));
      await db.into(db.expenseShares).insertOnConflictUpdate(ExpenseSharesCompanion.insert(
            expenseId: id,
            userId: _idOf(user),
            amount: Value((s['amount'] as num?)?.toDouble() ?? 0),
          ));
    }
    await (db.delete(db.expensePayers)..where((t) => t.expenseId.equals(id))).go();
    for (final p in (j['payers'] as List? ?? [])) {
      final user = (p as Map)['user'];
      if (user is Map) await _upsertUser(Map<String, dynamic>.from(user));
      await db.into(db.expensePayers).insertOnConflictUpdate(ExpensePayersCompanion.insert(
            expenseId: id,
            userId: _idOf(user),
            amount: Value((p['amount'] as num?)?.toDouble() ?? 0),
          ));
    }
    if (j.containsKey('reactions')) await _storeReactions('expense', id, j['reactions']);
  }

  Future<void> _upsertSettlement(Map<String, dynamic> j) async {
    final serverId = _idOf(j);
    final id = await _localIdFor(db.settlements, serverId);
    if (await _isDirty(db.settlements, id)) return;
    final group = j['group'];
    final serverGroupId = group is Map ? _idOf(group) : group.toString();
    final from = j['from'];
    final to = j['to'];
    if (from is Map) await _upsertUser(Map<String, dynamic>.from(from));
    if (to is Map) await _upsertUser(Map<String, dynamic>.from(to));
    await db.into(db.settlements).insertOnConflictUpdate(SettlementsCompanion.insert(
          id: id,
          serverId: Value(serverId),
          groupId: await _localIdFor(db.groups, serverGroupId),
          fromUserId: _idOf(from),
          toUserId: _idOf(to),
          amount: Value((j['amount'] as num?)?.toDouble() ?? 0),
          currency: Value(j['currency']?.toString() ?? 'PKR'),
          method: Value(j['method']?.toString() ?? 'cash'),
          note: Value(j['note']?.toString() ?? ''),
          settledAt: Value(_date(j['settledAt'])),
          updatedAt: Value(_date(j['updatedAt'])),
          dirty: const Value(false),
        ));
    if (j.containsKey('reactions')) await _storeReactions('settlement', id, j['reactions']);
  }

  Future<void> _upsertPersonal(Map<String, dynamic> j) async {
    final serverId = _idOf(j);
    final id = await _localIdFor(db.personalExpenses, serverId);
    if (await _isDirty(db.personalExpenses, id)) return;
    await db.into(db.personalExpenses).insertOnConflictUpdate(PersonalExpensesCompanion.insert(
          id: id,
          serverId: Value(serverId),
          description: Value(j['description']?.toString() ?? ''),
          amount: Value((j['amount'] as num?)?.toDouble() ?? 0),
          currency: Value(j['currency']?.toString() ?? 'PKR'),
          category: Value(j['category']?.toString() ?? 'other'),
          date: Value(_date(j['date'])),
          note: Value(j['note']?.toString() ?? ''),
          receiptUrl: Value(j['receiptUrl']?.toString()),
          updatedAt: Value(_date(j['updatedAt'])),
          dirty: const Value(false),
        ));
  }

  Future<void> _upsertGoal(Map<String, dynamic> j) async {
    final serverId = _idOf(j);
    final id = await _localIdFor(db.goals, serverId);
    if (await _isDirty(db.goals, id)) return;
    await db.into(db.goals).insertOnConflictUpdate(GoalsCompanion.insert(
          id: id,
          serverId: Value(serverId),
          title: Value(j['title']?.toString() ?? ''),
          description: Value(j['description']?.toString() ?? ''),
          emoji: Value(j['emoji']?.toString() ?? '🎯'),
          category: Value(j['category']?.toString() ?? 'other'),
          targetAmount: Value((j['targetAmount'] as num?)?.toDouble() ?? 0),
          savedAmount: Value((j['savedAmount'] as num?)?.toDouble() ?? 0),
          currency: Value(j['currency']?.toString() ?? 'PKR'),
          targetDate: Value(_date(j['targetDate'])),
          status: Value(j['status']?.toString() ?? 'active'),
          priority: Value(j['priority']?.toString() ?? 'medium'),
          color: Value(j['color']?.toString() ?? '#6C5CE7'),
          notes: Value(j['notes']?.toString() ?? ''),
          contributionsJson: Value(jsonEncode(j['contributions'] ?? [])),
          updatedAt: Value(_date(j['updatedAt'])),
          dirty: const Value(false),
        ));
  }

  Future<void> _upsertActivity(Map<String, dynamic> j) async {
    final id = _idOf(j);
    final actor = j['actor'];
    final group = j['group'];
    final serverGroupId = group is Map ? _idOf(group) : group?.toString();
    final groupLocalId = serverGroupId == null ? null : await _localIdFor(db.groups, serverGroupId);
    await db.into(db.activities).insertOnConflictUpdate(ActivitiesCompanion.insert(
          id: id,
          groupId: Value(groupLocalId),
          type: Value(j['type']?.toString() ?? 'event'),
          message: Value(j['message']?.toString() ?? ''),
          actorId: Value(actor is Map ? _idOf(actor) : actor?.toString()),
          actorName: Value(actor is Map ? actor['name']?.toString() : null),
          actorAvatar: Value(actor is Map ? actor['avatarUrl']?.toString() : null),
          groupName: Value(group is Map ? group['name']?.toString() : null),
          groupColor: Value(group is Map ? group['coverColor']?.toString() : null),
          createdAt: Value(_date(j['createdAt'])),
        ));
  }

  // ── REACTIONS ───────────────────────────────────────────────────────────
  /// Replace the stored reactions for a target with the given server summaries.
  Future<void> _storeReactions(String targetType, String localTargetId, dynamic rawSummaries) async {
    await (db.delete(db.reactions)
          ..where((t) => t.targetType.equals(targetType) & t.targetId.equals(localTargetId)))
        .go();
    if (rawSummaries is! List) return;
    for (final s in rawSummaries) {
      if (s is! Map) continue;
      final emoji = s['emoji']?.toString() ?? '';
      if (emoji.isEmpty) continue;
      for (final u in (s['users'] as List? ?? [])) {
        if (u is! Map) continue;
        final uid = (u['id'] ?? u['_id'] ?? '').toString();
        if (uid.isEmpty) continue;
        await db.into(db.reactions).insertOnConflictUpdate(ReactionsCompanion.insert(
              targetType: targetType,
              targetId: localTargetId,
              emoji: emoji,
              userId: uid,
              userName: Value(u['name']?.toString()),
              userAvatar: Value(u['avatarUrl']?.toString()),
            ));
      }
    }
  }

  /// Build server-shaped reaction summaries (`[{emoji, users:[...]}]`) for a set
  /// of local target ids, keyed by target id.
  Future<Map<String, List<Map<String, dynamic>>>> _reactionsFor(
      String targetType, List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await (db.select(db.reactions)
          ..where((t) => t.targetType.equals(targetType) & t.targetId.isIn(ids)))
        .get();
    final byTarget = <String, Map<String, List<Map<String, dynamic>>>>{};
    for (final r in rows) {
      final byEmoji = byTarget.putIfAbsent(r.targetId, () => {});
      byEmoji.putIfAbsent(r.emoji, () => []).add({
        'id': r.userId,
        'name': r.userName ?? '',
        'avatarUrl': r.userAvatar,
      });
    }
    return {
      for (final entry in byTarget.entries)
        entry.key: [
          for (final e in entry.value.entries) {'emoji': e.key, 'users': e.value}
        ]
    };
  }

  /// Apply a realtime `reaction:changed` summary to the local DB (resolving the
  /// server target id to its local id). The expense/settlement streams update
  /// reactively from here.
  Future<void> applyReactionsJson(String targetType, String serverTargetId, dynamic rawSummaries) async {
    final String localId;
    if (targetType == 'settlement') {
      localId = await _localIdFor(db.settlements, serverTargetId);
    } else {
      localId = await _localIdFor(db.expenses, serverTargetId);
    }
    await _storeReactions(targetType, localId, rawSummaries);
  }

  Future<void> _applyDeletion(Map<String, dynamic> d) async {
    final type = d['entityType']?.toString();
    final id = d['entityId']?.toString();
    if (id == null) return;
    switch (type) {
      case 'expense':
        final local = await _localIdFor(db.expenses, id);
        await (db.delete(db.expenseShares)..where((t) => t.expenseId.equals(local))).go();
        await (db.delete(db.expensePayers)..where((t) => t.expenseId.equals(local))).go();
        await (db.delete(db.expenses)..where((t) => t.id.equals(local))).go();
        break;
      case 'settlement':
        await (db.delete(db.settlements)
              ..where((t) => t.serverId.equals(id) | t.id.equals(id)))
            .go();
        break;
      case 'personalExpense':
        await (db.delete(db.personalExpenses)
              ..where((t) => t.serverId.equals(id) | t.id.equals(id)))
            .go();
        break;
      case 'goal':
        await (db.delete(db.goals)..where((t) => t.serverId.equals(id) | t.id.equals(id))).go();
        break;
      case 'loan':
        final localLoan = await _localIdFor(db.loans, id);
        await (db.delete(db.loanPayments)..where((t) => t.loanId.equals(localLoan))).go();
        await (db.delete(db.loans)..where((t) => t.id.equals(localLoan))).go();
        break;
      case 'group':
        // Cascade: drop the group and everything under it (using its local id,
        // which may be a uuid for a group created offline then synced).
        final g = await _localIdFor(db.groups, id);
        await (db.delete(db.expenseShares)
              ..where((t) => t.expenseId.isInQuery(
                  db.selectOnly(db.expenses)
                    ..addColumns([db.expenses.id])
                    ..where(db.expenses.groupId.equals(g)))))
            .go();
        await (db.delete(db.expensePayers)
              ..where((t) => t.expenseId.isInQuery(
                  db.selectOnly(db.expenses)
                    ..addColumns([db.expenses.id])
                    ..where(db.expenses.groupId.equals(g)))))
            .go();
        await (db.delete(db.expenses)..where((t) => t.groupId.equals(g))).go();
        await (db.delete(db.settlements)..where((t) => t.groupId.equals(g))).go();
        await (db.delete(db.groupMembers)..where((t) => t.groupId.equals(g))).go();
        await (db.delete(db.activities)..where((t) => t.groupId.equals(g))).go();
        await (db.delete(db.groups)..where((t) => t.id.equals(g))).go();
        break;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helpers to rebuild server-shaped JSON from local rows (so we can reuse the
  // app's existing `Model.fromJson` parsers).
  // ───────────────────────────────────────────────────────────────────────────
  Future<Map<String, Map<String, dynamic>>> _userMap(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await (db.select(db.users)..where((t) => t.id.isIn(ids))).get();
    return {
      for (final u in rows)
        u.id: {
          '_id': u.id,
          'name': u.name,
          'email': u.email,
          'avatarUrl': u.avatarUrl,
          'isPlaceholder': u.isPlaceholder,
        }
    };
  }

  Map<String, dynamic> _userJson(String? id, Map<String, Map<String, dynamic>> users) =>
      (id != null ? users[id] : null) ?? {'_id': id ?? '', 'name': '', 'email': ''};

  // ── GROUPS ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _groupToJson(
      Group g, List<GroupMember> members, Map<String, Map<String, dynamic>> users) async {
    return {
      '_id': g.id,
      'name': g.name,
      'description': g.description,
      'notes': g.notes,
      'category': g.category,
      'coverColor': g.coverColor,
      'icon': g.icon,
      'currency': g.currency,
      'inviteCode': g.inviteCode,
      'members': [
        for (final m in members)
          {'user': _userJson(m.userId, users), 'role': m.role}
      ],
      'pendingMembers': g.pendingMembersJson == null
          ? []
          : (jsonDecode(g.pendingMembersJson!) as List),
      'createdAt': _iso(g.createdAt),
    };
  }

  Stream<List<Map<String, dynamic>>> watchGroupsJson() {
    return (db.select(db.groups)..where((t) => t.deletedAt.isNull()))
        .watch()
        .asyncMap((rows) async {
      final members = await db.select(db.groupMembers).get();
      final byGroup = <String, List<GroupMember>>{};
      for (final m in members) {
        byGroup.putIfAbsent(m.groupId, () => []).add(m);
      }
      final userIds = members.map((m) => m.userId).toSet();
      final users = await _userMap(userIds);
      final out = <Map<String, dynamic>>[];
      for (final g in rows) {
        out.add(await _groupToJson(g, byGroup[g.id] ?? [], users));
      }
      out.sort((a, b) => (b['createdAt'] ?? '').toString().compareTo((a['createdAt'] ?? '').toString()));
      return out;
    });
  }

  Stream<Map<String, dynamic>?> watchGroupJson(String id) {
    // Match by local id OR server id (deep links carry the server id), then key
    // member lookups off the row's real local id.
    return (db.select(db.groups)
          ..where((t) => t.id.equals(id) | t.serverId.equals(id)))
        .watchSingleOrNull()
        .asyncMap((g) async {
      if (g == null) return null;
      final members =
          await (db.select(db.groupMembers)..where((t) => t.groupId.equals(g.id))).get();
      final users = await _userMap(members.map((m) => m.userId).toSet());
      return _groupToJson(g, members, users);
    });
  }

  /// Server ids of every (non-deleted) group, for socket room membership.
  /// Socket rooms are keyed by the server id (`group:<serverId>`), so a group
  /// created offline (whose local id is a uuid) must be joined by its server id
  /// once it has synced. Unsynced groups have no server room yet, so they're
  /// skipped until a later sync assigns them one.
  Future<List<String>> allGroupServerIds() async {
    final rows = await (db.select(db.groups)..where((t) => t.deletedAt.isNull())).get();
    return [
      for (final g in rows)
        if ((g.serverId ?? '').isNotEmpty) g.serverId!
    ];
  }

  // ── EXPENSES ────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _expensesToJson(List<Expense> rows) async {
    if (rows.isEmpty) return [];
    final ids = rows.map((e) => e.id).toList();
    final shares = await (db.select(db.expenseShares)..where((t) => t.expenseId.isIn(ids))).get();
    final payers = await (db.select(db.expensePayers)..where((t) => t.expenseId.isIn(ids))).get();
    final sharesBy = <String, List<ExpenseShare>>{};
    for (final s in shares) {
      sharesBy.putIfAbsent(s.expenseId, () => []).add(s);
    }
    final payersBy = <String, List<ExpensePayer>>{};
    for (final p in payers) {
      payersBy.putIfAbsent(p.expenseId, () => []).add(p);
    }
    final userIds = <String>{
      for (final e in rows) if (e.paidById != null) e.paidById!,
      for (final s in shares) s.userId,
      for (final p in payers) p.userId,
    };
    final users = await _userMap(userIds);
    final groupRows = await db.select(db.groups).get();
    final groupById = {for (final g in groupRows) g.id: g};
    final reactionsBy = await _reactionsFor('expense', ids);
    return [
      for (final e in rows)
        {
          '_id': e.id,
          'group': {
            '_id': e.groupId,
            'name': groupById[e.groupId]?.name,
            'coverColor': groupById[e.groupId]?.coverColor,
          },
          'description': e.description,
          'notes': e.notes,
          'amount': e.amount,
          'currency': e.currency,
          'category': e.category,
          'splitMode': e.splitMode,
          'paidBy': _userJson(e.paidById, users),
          'shares': [
            for (final s in (sharesBy[e.id] ?? []))
              {'user': _userJson(s.userId, users), 'amount': s.amount}
          ],
          'payers': [
            for (final p in (payersBy[e.id] ?? []))
              {'user': _userJson(p.userId, users), 'amount': p.amount}
          ],
          'tax': e.tax,
          'tip': e.tip,
          'receiptUrl': e.receiptUrl,
          'spentAt': _iso(e.spentAt),
          'reactions': reactionsBy[e.id] ?? const [],
        }
    ];
  }

  Stream<List<Map<String, dynamic>>> watchGroupExpensesJson(String groupId, {int? limit}) {
    final q = db.select(db.expenses)
      ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.spentAt)]);
    if (limit != null) q.limit(limit);
    return q.watch().asyncMap(_expensesToJson);
  }

  Stream<List<Map<String, dynamic>>> watchFeedJson({int? limit}) {
    final q = db.select(db.expenses)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.spentAt)]);
    if (limit != null) q.limit(limit);
    return q.watch().asyncMap(_expensesToJson);
  }

  Stream<Map<String, dynamic>?> watchExpenseJson(String id) {
    // Tracks the reactions table too, so reactions update live on the detail
    // screen the moment a `reaction:changed` broadcast is stored locally.
    return db
        .customSelect('SELECT 1 AS x', readsFrom: {
          db.expenses, db.expenseShares, db.expensePayers, db.users, db.groups, db.reactions,
        })
        .watch()
        .asyncMap((_) async {
      // Match by local id OR server id: deep links from notifications carry the
      // server id, but a locally-created expense's row id is a uuid.
      final e = await (db.select(db.expenses)
            ..where((t) => t.id.equals(id) | t.serverId.equals(id)))
          .getSingleOrNull();
      return e == null ? null : (await _expensesToJson([e])).first;
    });
  }

  // ── SETTLEMENTS ───────────────────────────────────────────────────────────
  Future<List<Settlement>> groupSettlements(String groupId) =>
      (db.select(db.settlements)..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull())).get();

  /// Merged expenses + settlement records for a group's Expenses tab.
  Stream<List<Map<String, dynamic>>> watchGroupTransactionsJson(String rawGroupId) {
    return db
        .customSelect('SELECT 1 AS x', readsFrom: {
          db.expenses, db.expenseShares, db.expensePayers, db.settlements, db.users, db.groups, db.reactions,
        })
        .watch()
        .asyncMap((_) async {
      // Accept a local or server id (deep links pass the server id).
      final groupId = await _localIdFor(db.groups, rawGroupId);
      final exRows = await (db.select(db.expenses)
            ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.spentAt)]))
          .get();
      final expenses = await _expensesToJson(exRows);
      final setRows = await (db.select(db.settlements)
            ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull()))
          .get();
      final users = await _userMap({for (final s in setRows) ...[s.fromUserId, s.toUserId]});
      final setReactions = await _reactionsFor('settlement', setRows.map((s) => s.id).toList());
      final settlements = [
        for (final s in setRows)
          {
            'type': 'settlement',
            'id': s.id,
            'groupId': groupId,
            'from': _userJson(s.fromUserId, users),
            'to': _userJson(s.toUserId, users),
            'amount': s.amount,
            'currency': s.currency,
            'note': s.note,
            'settledAt': _iso(s.settledAt),
            'reactions': setReactions[s.id] ?? const [],
          }
      ];
      final all = [...expenses, ...settlements];
      all.sort((a, b) {
        final ad = (a['spentAt'] ?? a['settledAt'] ?? '').toString();
        final bd = (b['spentAt'] ?? b['settledAt'] ?? '').toString();
        return bd.compareTo(ad);
      });
      return all;
    });
  }

  /// Monthly category totals of the user's own share (last [months] months).
  Stream<List<Map<String, dynamic>>> watchMonthlyAnalyticsJson(String myId, {int months = 6}) {
    return db
        .customSelect('SELECT 1 AS x', readsFrom: {db.expenses, db.expenseShares})
        .watch()
        .asyncMap((_) async {
      final since = DateTime(DateTime.now().year, DateTime.now().month - (months - 1), 1);
      final rows = await (db.select(db.expenses)..where((t) => t.deletedAt.isNull())).get();
      final ids = rows.map((e) => e.id).toList();
      if (ids.isEmpty) return <Map<String, dynamic>>[];
      final shares = await (db.select(db.expenseShares)
            ..where((t) => t.expenseId.isIn(ids) & t.userId.equals(myId)))
          .get();
      final myShareByExpense = {for (final s in shares) s.expenseId: s.amount};
      final totals = <String, Map<String, dynamic>>{};
      for (final e in rows) {
        final mine = myShareByExpense[e.id];
        if (mine == null) continue;
        final d = e.spentAt ?? DateTime.now();
        if (d.isBefore(since)) continue;
        final key = '${d.year}-${d.month}-${e.category}';
        final cur = totals.putIfAbsent(
            key, () => {'year': d.year, 'month': d.month, 'category': e.category, 'total': 0.0});
        cur['total'] = (cur['total'] as double) + mine;
      }
      return totals.values.toList();
    });
  }

  // ── PERSONAL ────────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> watchPersonalJson() {
    final q = db.select(db.personalExpenses)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    return q.watch().map((rows) => [
          for (final p in rows)
            {
              '_id': p.id,
              'description': p.description,
              'amount': p.amount,
              'currency': p.currency,
              'category': p.category,
              'date': _iso(p.date) ?? DateTime.now().toIso8601String(),
              'note': p.note,
              'receiptUrl': p.receiptUrl ?? '',
            }
        ]);
  }

  // ── GOALS ─────────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> watchGoalsJson() {
    final q = db.select(db.goals)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return q.watch().map((rows) => [
          for (final g in rows)
            {
              '_id': g.id,
              'title': g.title,
              'description': g.description,
              'emoji': g.emoji,
              'category': g.category,
              'targetAmount': g.targetAmount,
              'savedAmount': g.savedAmount,
              'currency': g.currency,
              'targetDate': _iso(g.targetDate),
              'status': g.status,
              'priority': g.priority,
              'color': g.color,
              'notes': g.notes,
              'contributions': g.contributionsJson == null ? [] : jsonDecode(g.contributionsJson!),
              'createdAt': _iso(g.updatedAt) ?? DateTime.now().toIso8601String(),
            }
        ]);
  }

  // ── ACTIVITY ──────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> watchActivityJson({String? groupId}) {
    final q = db.select(db.activities)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (groupId != null) q.where((t) => t.groupId.equals(groupId));
    return q.watch().map((rows) => [
          for (final a in rows)
            {
              '_id': a.id,
              'type': a.type,
              'message': a.message,
              'createdAt': _iso(a.createdAt),
              if (a.actorId != null)
                'actor': {'_id': a.actorId, 'name': a.actorName, 'avatarUrl': a.actorAvatar},
              if (a.groupId != null)
                'group': {'_id': a.groupId, 'name': a.groupName, 'coverColor': a.groupColor},
            }
        ]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Paginated one-shot reads (LIMIT/OFFSET). Used by the infinite-scroll lists
  // so a screen loads a page at a time as the user scrolls, instead of pulling
  // every local row up front. `hasMore` is `list.length == limit`.
  // ───────────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> feedPage({required int limit, required int offset}) async {
    final rows = await (db.select(db.expenses)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.spentAt)])
          ..limit(limit, offset: offset))
        .get();
    return _expensesToJson(rows);
  }

  Future<List<Map<String, dynamic>>> groupExpensesPage(String groupId,
      {required int limit, required int offset}) async {
    final rows = await (db.select(db.expenses)
          ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.spentAt)])
          ..limit(limit, offset: offset))
        .get();
    return _expensesToJson(rows);
  }

  /// Merged expenses + settlements for the group Expenses tab, paginated.
  Future<List<Map<String, dynamic>>> groupTransactionsPage(String groupId,
      {required int limit, required int offset}) async {
    final all = await watchGroupTransactionsJson(groupId).first;
    return all.skip(offset).take(limit).toList();
  }

  Map<String, dynamic> _activityJson(Activity a) => {
        '_id': a.id,
        'type': a.type,
        'message': a.message,
        'createdAt': _iso(a.createdAt),
        if (a.actorId != null)
          'actor': {'_id': a.actorId, 'name': a.actorName, 'avatarUrl': a.actorAvatar},
        if (a.groupId != null)
          'group': {'_id': a.groupId, 'name': a.groupName, 'coverColor': a.groupColor},
      };

  Future<List<Map<String, dynamic>>> activityPage(
      {String? groupId, required int limit, required int offset}) async {
    final q = db.select(db.activities)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit, offset: offset);
    if (groupId != null) q.where((t) => t.groupId.equals(groupId));
    final rows = await q.get();
    return rows.map(_activityJson).toList();
  }

  Future<List<Map<String, dynamic>>> personalPage(
      {DateTime? from, DateTime? to, String? category, required int limit, required int offset}) async {
    final q = db.select(db.personalExpenses)..where((t) => t.deletedAt.isNull());
    // Half-open interval [from, to): callers pass `to` as the start of the next
    // period (exclusive). An inclusive upper bound would make a midnight-dated
    // expense (what the date picker produces) also match the previous day's
    // range, so it would show under the previous date too.
    if (from != null) q.where((t) => t.date.isBiggerOrEqualValue(from));
    if (to != null) q.where((t) => t.date.isSmallerThanValue(to));
    if (category != null) q.where((t) => t.category.equals(category));
    q
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(limit, offset: offset);
    final rows = await q.get();
    return [
      for (final p in rows)
        {
          '_id': p.id,
          'description': p.description,
          'amount': p.amount,
          'currency': p.currency,
          'category': p.category,
          'date': _iso(p.date) ?? DateTime.now().toIso8601String(),
          'note': p.note,
          'receiptUrl': p.receiptUrl ?? '',
        }
    ];
  }

  Future<List<Map<String, dynamic>>> friendTransactionsPage(String myId, String friendId,
      {required int limit, required int offset}) async {
    final j = await watchFriendDetailJson(myId, friendId).first;
    final all = (j['transactions'] ?? []) as List;
    return all.skip(offset).take(limit).cast<Map<String, dynamic>>().toList();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Enqueue a sync op.
  // ───────────────────────────────────────────────────────────────────────────
  Future<String> enqueue({
    required String entityType,
    required String opType,
    String? entityLocalId,
    Map<String, dynamic> payload = const {},
    String? opId,
  }) async {
    final id = opId ?? newId();
    await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
          opId: id,
          entityType: entityType,
          opType: opType,
          entityLocalId: Value(entityLocalId),
          payloadJson: Value(jsonEncode(payload)),
        ));
    return id;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BALANCES (computed offline from local rows).
  // ───────────────────────────────────────────────────────────────────────────
  Future<List<ExpenseCalc>> _expenseCalcs({String? groupId}) async {
    final q = db.select(db.expenses)..where((t) => t.deletedAt.isNull());
    if (groupId != null) q.where((t) => t.groupId.equals(groupId));
    final rows = await q.get();
    if (rows.isEmpty) return [];
    final ids = rows.map((e) => e.id).toList();
    final shares = await (db.select(db.expenseShares)..where((t) => t.expenseId.isIn(ids))).get();
    final payers = await (db.select(db.expensePayers)..where((t) => t.expenseId.isIn(ids))).get();
    final sharesBy = <String, List<ExpenseShare>>{};
    for (final s in shares) sharesBy.putIfAbsent(s.expenseId, () => []).add(s);
    final payersBy = <String, List<ExpensePayer>>{};
    for (final p in payers) payersBy.putIfAbsent(p.expenseId, () => []).add(p);
    return [
      for (final e in rows)
        ExpenseCalc(
          // Effective payers: explicit breakdown, or single payer for the total.
          payers: (payersBy[e.id]?.isNotEmpty ?? false)
              ? [for (final p in payersBy[e.id]!) PayerAmt(p.userId, p.amount)]
              : [if (e.paidById != null) PayerAmt(e.paidById!, e.amount)],
          shares: [for (final s in (sharesBy[e.id] ?? [])) PayerAmt(s.userId, s.amount)],
        )
    ];
  }

  Future<List<SettlementCalc>> _settlementCalcs({String? groupId}) async {
    final q = db.select(db.settlements)..where((t) => t.deletedAt.isNull());
    if (groupId != null) q.where((t) => t.groupId.equals(groupId));
    final rows = await q.get();
    return [for (final s in rows) SettlementCalc(from: s.fromUserId, to: s.toUserId, amount: s.amount)];
  }

  Stream<Map<String, dynamic>> watchGroupBalancesJson(String groupId) {
    return db
        .customSelect('SELECT 1 AS x', readsFrom: {
          db.expenses, db.expenseShares, db.expensePayers, db.settlements, db.groupMembers, db.users,
        })
        .watch()
        .asyncMap((_) => _computeGroupBalances(groupId));
  }

  Future<Map<String, dynamic>> _computeGroupBalances(String rawGroupId) async {
    // Accept a local or server id (deep links pass the server id).
    final groupId = await _localIdFor(db.groups, rawGroupId);
    final members = await (db.select(db.groupMembers)..where((t) => t.groupId.equals(groupId))).get();
    final memberIds = members.map((m) => m.userId).toList();
    final expenses = await _expenseCalcs(groupId: groupId);
    final settlements = await _settlementCalcs(groupId: groupId);
    final nets = groupNets(memberIds, expenses, settlements);
    final transfers = simplifyDebts(nets);
    final users = await _userMap(nets.keys.toSet());
    Map<String, dynamic>? u(String id) {
      final m = users[id];
      return m == null ? null : {'id': id, 'name': m['name'], 'email': m['email'], 'avatarUrl': m['avatarUrl']};
    }

    return {
      'balances': [
        for (final entry in nets.entries) {'userId': entry.key, 'user': u(entry.key), 'net': entry.value}
      ],
      'transfers': [
        for (final t in transfers)
          {'from': t.from, 'to': t.to, 'amount': t.amount, 'fromUser': u(t.from), 'toUser': u(t.to)}
      ],
    };
  }

  /// Friends summary across every group (mirrors GET /users/friends).
  Stream<List<Map<String, dynamic>>> watchFriendsSummaryJson(String myId) {
    return db
        .customSelect('SELECT 1 AS x', readsFrom: {
          db.expenses, db.expenseShares, db.expensePayers, db.settlements, db.groupMembers, db.users,
        })
        .watch()
        .asyncMap((_) => _computeFriendsSummary(myId));
  }

  Future<List<Map<String, dynamic>>> _computeFriendsSummary(String myId) async {
    final groupsList = await (db.select(db.groups)..where((t) => t.deletedAt.isNull())).get();
    final allMembers = await db.select(db.groupMembers).get();
    final membersByGroup = <String, List<GroupMember>>{};
    for (final m in allMembers) membersByGroup.putIfAbsent(m.groupId, () => []).add(m);

    final netByFriend = <String, double>{};
    final groupsByFriend = <String, List<Map<String, dynamic>>>{};

    for (final g in groupsList) {
      final gm = membersByGroup[g.id] ?? [];
      if (!gm.any((m) => m.userId == myId)) continue;
      final expenses = await _expenseCalcs(groupId: g.id);
      final settlements = await _settlementCalcs(groupId: g.id);
      final pairwise = <String, double>{};
      for (final e in expenses) {
        for (final m in gm) {
          if (m.userId == myId) continue;
          final net = pairwiseNet(e, myId, m.userId);
          if (net != 0) pairwise[m.userId] = (pairwise[m.userId] ?? 0) + net;
        }
      }
      for (final s in settlements) {
        if (s.from == myId) pairwise[s.to] = (pairwise[s.to] ?? 0) + s.amount;
        else if (s.to == myId) pairwise[s.from] = (pairwise[s.from] ?? 0) - s.amount;
      }
      pairwise.forEach((friendId, amt) {
        netByFriend[friendId] = (netByFriend[friendId] ?? 0) + amt;
        final rounded = (amt * 100).round() / 100;
        if (rounded.abs() > 0.001) {
          groupsByFriend.putIfAbsent(friendId, () => []).add({
            'groupId': g.id, 'groupName': g.name, 'net': rounded,
          });
        }
      });
    }

    final users = await _userMap(netByFriend.keys.toSet());
    final result = [
      for (final entry in netByFriend.entries)
        if (!(users[entry.key]?['isPlaceholder'] == true))
          {
            'userId': entry.key,
            'user': users[entry.key] ?? {'_id': entry.key, 'name': 'Unknown', 'email': ''},
            'net': (entry.value * 100).round() / 100,
            'groups': groupsByFriend[entry.key] ?? [],
          }
    ];
    result.sort((a, b) => (b['net'] as double).abs().compareTo((a['net'] as double).abs()));
    return result;
  }

  /// Friend detail (shared groups + the transaction stream between us), mirrors
  /// GET /users/friends/:id/transactions, computed offline.
  Stream<Map<String, dynamic>> watchFriendDetailJson(String myId, String friendId) {
    return db
        .customSelect('SELECT 1 AS x', readsFrom: {
          db.expenses, db.expenseShares, db.expensePayers, db.settlements, db.groupMembers, db.groups, db.users,
        })
        .watch()
        .asyncMap((_) => _computeFriendDetail(myId, friendId));
  }

  Future<Map<String, dynamic>> _computeFriendDetail(String myId, String friendId) async {
    final groupsList = await (db.select(db.groups)..where((t) => t.deletedAt.isNull())).get();
    final allMembers = await db.select(db.groupMembers).get();
    final membersByGroup = <String, Set<String>>{};
    for (final m in allMembers) {
      membersByGroup.putIfAbsent(m.groupId, () => {}).add(m.userId);
    }
    final sharedGroups = groupsList.where((g) {
      final set = membersByGroup[g.id] ?? {};
      return set.contains(myId) && set.contains(friendId);
    }).toList();

    final txns = <Map<String, dynamic>>[];
    for (final g in sharedGroups) {
      // Expenses
      final exRows = await (db.select(db.expenses)
            ..where((t) => t.groupId.equals(g.id) & t.deletedAt.isNull()))
          .get();
      if (exRows.isNotEmpty) {
        final ids = exRows.map((e) => e.id).toList();
        final shares = await (db.select(db.expenseShares)..where((t) => t.expenseId.isIn(ids))).get();
        final payers = await (db.select(db.expensePayers)..where((t) => t.expenseId.isIn(ids))).get();
        final sharesBy = <String, List<ExpenseShare>>{};
        for (final s in shares) sharesBy.putIfAbsent(s.expenseId, () => []).add(s);
        final payersBy = <String, List<ExpensePayer>>{};
        for (final p in payers) payersBy.putIfAbsent(p.expenseId, () => []).add(p);
        for (final e in exRows) {
          final calc = ExpenseCalc(
            payers: (payersBy[e.id]?.isNotEmpty ?? false)
                ? [for (final p in payersBy[e.id]!) PayerAmt(p.userId, p.amount)]
                : [if (e.paidById != null) PayerAmt(e.paidById!, e.amount)],
            shares: [for (final s in (sharesBy[e.id] ?? [])) PayerAmt(s.userId, s.amount)],
          );
          final net = pairwiseNet(calc, myId, friendId);
          if (net.abs() < 0.001) continue;
          txns.add({
            'type': 'expense',
            'id': e.id,
            'description': e.description,
            'groupId': g.id,
            'groupName': g.name,
            'groupColor': g.coverColor,
            'category': e.category,
            'currency': e.currency,
            'totalAmount': e.amount,
            'net': (net * 100).round() / 100,
            'date': _iso(e.spentAt) ?? DateTime.now().toIso8601String(),
          });
        }
      }
      // Settlements between us
      final setRows = await (db.select(db.settlements)
            ..where((t) => t.groupId.equals(g.id) & t.deletedAt.isNull()))
          .get();
      for (final s in setRows) {
        final involves = (s.fromUserId == myId && s.toUserId == friendId) ||
            (s.fromUserId == friendId && s.toUserId == myId);
        if (!involves) continue;
        txns.add({
          'type': 'settlement',
          'id': s.id,
          'description': 'Payment',
          'groupId': g.id,
          'groupName': g.name,
          'groupColor': g.coverColor,
          'category': 'settlement',
          'currency': s.currency,
          'totalAmount': s.amount,
          'net': s.fromUserId == myId ? s.amount : -s.amount,
          'date': _iso(s.settledAt) ?? DateTime.now().toIso8601String(),
        });
      }
    }
    txns.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return {
      'transactions': txns,
      'groups': [for (final g in sharedGroups) {'id': g.id, 'name': g.name, 'coverColor': g.coverColor}],
      'hasMore': false,
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // OPTIMISTIC WRITES (write local rows + queue a sync op).
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> ensureUser(Map<String, dynamic> user) => _upsertUser(user);

  Future<String> createGroupLocal({
    required String name,
    String description = '',
    String category = 'other',
    String? coverColor,
    String? currency,
    List<String> memberEmails = const [],
    Map<String, dynamic>? owner,
  }) async {
    final ownerJson = owner ?? currentUser;
    if (ownerJson == null) {
      throw StateError('No current user to own the group');
    }
    final id = newId();
    final opId = newId();
    await db.transaction(() async {
      await db.into(db.groups).insert(GroupsCompanion.insert(
            id: id,
            name: Value(name),
            description: Value(description),
            category: Value(category),
            coverColor: Value(coverColor ?? '#6C5CE7'),
            currency: Value(currency ?? 'PKR'),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            dirty: const Value(true),
          ));
      await _upsertUser(ownerJson);
      await db.into(db.groupMembers).insertOnConflictUpdate(
          GroupMembersCompanion.insert(groupId: id, userId: _idOf(ownerJson), role: const Value('owner')));
    });
    await enqueue(opId: opId, entityType: 'group', opType: 'create', entityLocalId: id, payload: {
      'name': name,
      'description': description,
      'category': category,
      if (coverColor != null) 'coverColor': coverColor,
      if (currency != null) 'currency': currency,
      'memberEmails': memberEmails,
      'clientOpId': opId,
    });
    return id;
  }

  Future<void> updateGroupNotesLocal(String groupId, String notes) async {
    await (db.update(db.groups)..where((t) => t.id.equals(groupId)))
        .write(GroupsCompanion(notes: Value(notes), dirty: const Value(true), updatedAt: Value(DateTime.now())));
    await enqueue(entityType: 'groupNotes', opType: 'update', entityLocalId: groupId, payload: {'notes': notes});
  }

  Future<void> updateGroupLocal(String groupId, Map<String, dynamic> fields) async {
    await (db.update(db.groups)..where((t) => t.id.equals(groupId))).write(GroupsCompanion(
          name: fields.containsKey('name') ? Value(fields['name']) : const Value.absent(),
          description: fields.containsKey('description') ? Value(fields['description']) : const Value.absent(),
          category: fields.containsKey('category') ? Value(fields['category']) : const Value.absent(),
          coverColor: fields.containsKey('coverColor') ? Value(fields['coverColor']) : const Value.absent(),
          currency: fields.containsKey('currency') ? Value(fields['currency']) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
          dirty: const Value(true),
        ));
    await enqueue(entityType: 'group', opType: 'update', entityLocalId: groupId, payload: fields);
  }

  /// Creates an expense locally (computing shares/payers offline) and queues it.
  Future<String> createExpenseLocal({
    required String groupId,
    required String description,
    required double amount,
    required String splitMode,
    required String paidBy,
    required List<Map<String, dynamic>> splits, // {userId, value?}
    List<Map<String, dynamic>> payers = const [], // {userId, amount}
    String category = 'other',
    String notes = '',
    String currency = 'PKR',
    double tax = 0,
    double tip = 0,
    DateTime? spentAt,
    String? receiptUrl,
  }) async {
    final id = newId();
    final opId = newId();
    final total = amount + tax + tip;
    final shares = computeShares(total: total, mode: splitMode, splits: splits);
    final resolved = resolvePayers(paidBy: paidBy, payers: payers, total: total);

    await db.transaction(() async {
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
            id: id,
            groupId: groupId,
            description: Value(description),
            notes: Value(notes),
            amount: Value(total),
            currency: Value(currency),
            category: Value(category),
            splitMode: Value(splitMode),
            paidById: Value(resolved.paidBy),
            tax: Value(tax),
            tip: Value(tip),
            receiptUrl: Value(receiptUrl),
            spentAt: Value(spentAt ?? DateTime.now()),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            dirty: const Value(true),
          ));
      for (final s in shares) {
        await db.into(db.expenseShares).insert(
            ExpenseSharesCompanion.insert(expenseId: id, userId: s.userId, amount: Value(s.amount)));
      }
      for (final p in resolved.payers) {
        await db.into(db.expensePayers).insert(
            ExpensePayersCompanion.insert(expenseId: id, userId: p.userId, amount: Value(p.amount)));
      }
    });
    await enqueue(opId: opId, entityType: 'expense', opType: 'create', entityLocalId: id, payload: {
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'splitMode': splitMode,
      'paidBy': paidBy,
      if (payers.isNotEmpty) 'payers': payers,
      'splits': splits,
      'category': category,
      'notes': notes,
      'currency': currency,
      'tax': tax,
      'tip': tip,
      if (spentAt != null) 'spentAt': _iso(spentAt),
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      'clientOpId': opId,
    });
    return id;
  }

  Future<void> updateExpenseLocal(
    String id, {
    required String description,
    required double amount,
    required String splitMode,
    required String paidBy,
    required List<Map<String, dynamic>> splits,
    List<Map<String, dynamic>> payers = const [],
    String category = 'other',
    String notes = '',
    double tax = 0,
    double tip = 0,
    String? receiptUrl,
  }) async {
    final total = amount + tax + tip;
    final shares = computeShares(total: total, mode: splitMode, splits: splits);
    final resolved = resolvePayers(paidBy: paidBy, payers: payers, total: total);
    await db.transaction(() async {
      await (db.update(db.expenses)..where((t) => t.id.equals(id))).write(ExpensesCompanion(
            description: Value(description),
            notes: Value(notes),
            amount: Value(total),
            splitMode: Value(splitMode),
            paidById: Value(resolved.paidBy),
            category: Value(category),
            tax: Value(tax),
            tip: Value(tip),
            receiptUrl: Value(receiptUrl),
            updatedAt: Value(DateTime.now()),
            dirty: const Value(true),
          ));
      await (db.delete(db.expenseShares)..where((t) => t.expenseId.equals(id))).go();
      for (final s in shares) {
        await db.into(db.expenseShares).insert(
            ExpenseSharesCompanion.insert(expenseId: id, userId: s.userId, amount: Value(s.amount)));
      }
      await (db.delete(db.expensePayers)..where((t) => t.expenseId.equals(id))).go();
      for (final p in resolved.payers) {
        await db.into(db.expensePayers).insert(
            ExpensePayersCompanion.insert(expenseId: id, userId: p.userId, amount: Value(p.amount)));
      }
    });
    await enqueue(entityType: 'expense', opType: 'update', entityLocalId: id, payload: {
      'description': description,
      'amount': amount,
      'splitMode': splitMode,
      'paidBy': paidBy,
      'payers': payers,
      'splits': splits,
      'category': category,
      'notes': notes,
      'tax': tax,
      'tip': tip,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
    });
  }

  Future<void> deleteExpenseLocal(String id) async {
    await (db.update(db.expenses)..where((t) => t.id.equals(id)))
        .write(ExpensesCompanion(deletedAt: Value(DateTime.now()), dirty: const Value(true)));
    await enqueue(entityType: 'expense', opType: 'delete', entityLocalId: id, payload: const {});
  }

  Future<String> createSettlementLocal({
    required String groupId,
    required String from,
    required String to,
    required double amount,
    String currency = 'PKR',
    String method = 'cash',
    String note = '',
    DateTime? settledAt,
  }) async {
    final id = newId();
    final opId = newId();
    await db.into(db.settlements).insert(SettlementsCompanion.insert(
          id: id,
          groupId: groupId,
          fromUserId: from,
          toUserId: to,
          amount: Value(amount),
          currency: Value(currency),
          method: Value(method),
          note: Value(note),
          settledAt: Value(settledAt ?? DateTime.now()),
          updatedAt: Value(DateTime.now()),
          dirty: const Value(true),
        ));
    await enqueue(opId: opId, entityType: 'settlement', opType: 'create', entityLocalId: id, payload: {
      'groupId': groupId,
      'from': from,
      'to': to,
      'amount': amount,
      'currency': currency,
      'method': method,
      'note': note,
      if (settledAt != null) 'settledAt': _iso(settledAt),
      'clientOpId': opId,
    });
    return id;
  }

  // ── PERSONAL ──────────────────────────────────────────────────────────────
  Future<String> createPersonalLocal({
    required String description,
    required double amount,
    String currency = 'PKR',
    String category = 'other',
    DateTime? date,
    String note = '',
    String? receiptUrl,
  }) async {
    final id = newId();
    final opId = newId();
    await db.into(db.personalExpenses).insert(PersonalExpensesCompanion.insert(
          id: id,
          description: Value(description),
          amount: Value(amount),
          currency: Value(currency),
          category: Value(category),
          date: Value(date ?? DateTime.now()),
          note: Value(note),
          receiptUrl: Value(receiptUrl),
          updatedAt: Value(DateTime.now()),
          dirty: const Value(true),
        ));
    await enqueue(opId: opId, entityType: 'personal', opType: 'create', entityLocalId: id, payload: {
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category,
      'date': _iso(date ?? DateTime.now()),
      'note': note,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      'clientOpId': opId,
    });
    return id;
  }

  Future<void> updatePersonalLocal(String id, Map<String, dynamic> fields) async {
    await (db.update(db.personalExpenses)..where((t) => t.id.equals(id))).write(PersonalExpensesCompanion(
          description: fields.containsKey('description') ? Value(fields['description']) : const Value.absent(),
          amount: fields.containsKey('amount') ? Value((fields['amount'] as num).toDouble()) : const Value.absent(),
          category: fields.containsKey('category') ? Value(fields['category']) : const Value.absent(),
          note: fields.containsKey('note') ? Value(fields['note']) : const Value.absent(),
          date: fields.containsKey('date') ? Value(_date(fields['date'])) : const Value.absent(),
          receiptUrl: fields.containsKey('receiptUrl') ? Value(fields['receiptUrl']) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
          dirty: const Value(true),
        ));
    await enqueue(entityType: 'personal', opType: 'update', entityLocalId: id, payload: fields);
  }

  Future<void> deletePersonalLocal(String id) async {
    await (db.update(db.personalExpenses)..where((t) => t.id.equals(id)))
        .write(PersonalExpensesCompanion(deletedAt: Value(DateTime.now()), dirty: const Value(true)));
    await enqueue(entityType: 'personal', opType: 'delete', entityLocalId: id, payload: const {});
  }

  // ── GOALS ───────────────────────────────────────────────────────────────────
  Future<String> createGoalLocal(Map<String, dynamic> body) async {
    final id = newId();
    final opId = newId();
    await db.into(db.goals).insert(GoalsCompanion.insert(
          id: id,
          title: Value(body['title']?.toString() ?? ''),
          description: Value(body['description']?.toString() ?? ''),
          emoji: Value(body['emoji']?.toString() ?? '🎯'),
          category: Value(body['category']?.toString() ?? 'other'),
          targetAmount: Value((body['targetAmount'] as num?)?.toDouble() ?? 0),
          currency: Value(body['currency']?.toString() ?? 'PKR'),
          targetDate: Value(_date(body['targetDate'])),
          priority: Value(body['priority']?.toString() ?? 'medium'),
          color: Value(body['color']?.toString() ?? '#6C5CE7'),
          notes: Value(body['notes']?.toString() ?? ''),
          updatedAt: Value(DateTime.now()),
          dirty: const Value(true),
        ));
    await enqueue(opId: opId, entityType: 'goal', opType: 'create', entityLocalId: id, payload: {
      ...body,
      'clientOpId': opId,
    });
    return id;
  }

  Future<void> updateGoalLocal(String id, Map<String, dynamic> fields) async {
    await (db.update(db.goals)..where((t) => t.id.equals(id))).write(GoalsCompanion(
          title: fields.containsKey('title') ? Value(fields['title']) : const Value.absent(),
          description: fields.containsKey('description') ? Value(fields['description']) : const Value.absent(),
          emoji: fields.containsKey('emoji') ? Value(fields['emoji']) : const Value.absent(),
          category: fields.containsKey('category') ? Value(fields['category']) : const Value.absent(),
          targetAmount: fields.containsKey('targetAmount')
              ? Value((fields['targetAmount'] as num).toDouble())
              : const Value.absent(),
          currency: fields.containsKey('currency') ? Value(fields['currency']) : const Value.absent(),
          targetDate: fields.containsKey('targetDate') ? Value(_date(fields['targetDate'])) : const Value.absent(),
          status: fields.containsKey('status') ? Value(fields['status']) : const Value.absent(),
          priority: fields.containsKey('priority') ? Value(fields['priority']) : const Value.absent(),
          color: fields.containsKey('color') ? Value(fields['color']) : const Value.absent(),
          notes: fields.containsKey('notes') ? Value(fields['notes']) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
          dirty: const Value(true),
        ));
    await enqueue(entityType: 'goal', opType: 'update', entityLocalId: id, payload: fields);
  }

  Future<void> deleteGoalLocal(String id) async {
    await (db.update(db.goals)..where((t) => t.id.equals(id)))
        .write(GoalsCompanion(deletedAt: Value(DateTime.now()), dirty: const Value(true)));
    await enqueue(entityType: 'goal', opType: 'delete', entityLocalId: id, payload: const {});
  }

  // ── id resolution + sync-state writeback used by SyncEngine ─────────────────
  Future<List<SyncQueueData>> pendingOps() =>
      (db.select(db.syncQueue)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();

  Future<void> deleteOp(String opId) =>
      (db.delete(db.syncQueue)..where((t) => t.opId.equals(opId))).go();

  Future<void> markOpFailed(String opId, String error, int attempts) =>
      (db.update(db.syncQueue)..where((t) => t.opId.equals(opId)))
          .write(SyncQueueCompanion(lastError: Value(error), attempts: Value(attempts), status: const Value('failed')));

  Future<void> bumpOpAttempt(String opId, String error, int attempts) =>
      (db.update(db.syncQueue)..where((t) => t.opId.equals(opId)))
          .write(SyncQueueCompanion(lastError: Value(error), attempts: Value(attempts)));

  /// Resolve a local entity id to its server id (null if not yet synced).
  Future<String?> serverIdFor(String entityType, String localId) async {
    switch (entityType) {
      case 'group':
      case 'groupNotes':
        return (await (db.select(db.groups)..where((t) => t.id.equals(localId))).getSingleOrNull())?.serverId;
      case 'expense':
        return (await (db.select(db.expenses)..where((t) => t.id.equals(localId))).getSingleOrNull())?.serverId;
      case 'settlement':
        return (await (db.select(db.settlements)..where((t) => t.id.equals(localId))).getSingleOrNull())?.serverId;
      case 'personal':
        return (await (db.select(db.personalExpenses)..where((t) => t.id.equals(localId))).getSingleOrNull())?.serverId;
      case 'goal':
        return (await (db.select(db.goals)..where((t) => t.id.equals(localId))).getSingleOrNull())?.serverId;
      case 'loan':
        return (await (db.select(db.loans)..where((t) => t.id.equals(localId))).getSingleOrNull())?.serverId;
    }
    return null;
  }

  /// After a create syncs, store the real server id and clear the dirty flag.
  Future<void> applyServerId(String entityType, String localId, String serverId) async {
    switch (entityType) {
      case 'group':
        await (db.update(db.groups)..where((t) => t.id.equals(localId)))
            .write(GroupsCompanion(serverId: Value(serverId), dirty: const Value(false)));
        break;
      case 'expense':
        await (db.update(db.expenses)..where((t) => t.id.equals(localId)))
            .write(ExpensesCompanion(serverId: Value(serverId), dirty: const Value(false)));
        break;
      case 'settlement':
        await (db.update(db.settlements)..where((t) => t.id.equals(localId)))
            .write(SettlementsCompanion(serverId: Value(serverId), dirty: const Value(false)));
        break;
      case 'personal':
        await (db.update(db.personalExpenses)..where((t) => t.id.equals(localId)))
            .write(PersonalExpensesCompanion(serverId: Value(serverId), dirty: const Value(false)));
        break;
      case 'goal':
        await (db.update(db.goals)..where((t) => t.id.equals(localId)))
            .write(GoalsCompanion(serverId: Value(serverId), dirty: const Value(false)));
        break;
      case 'loan':
        await (db.update(db.loans)..where((t) => t.id.equals(localId)))
            .write(LoansCompanion(serverId: Value(serverId), dirty: const Value(false)));
        break;
    }
  }

  Future<void> clearDirty(String entityType, String localId) async {
    switch (entityType) {
      case 'group':
      case 'groupNotes':
        await (db.update(db.groups)..where((t) => t.id.equals(localId))).write(const GroupsCompanion(dirty: Value(false)));
        break;
      case 'expense':
        await (db.update(db.expenses)..where((t) => t.id.equals(localId))).write(const ExpensesCompanion(dirty: Value(false)));
        break;
      case 'personal':
        await (db.update(db.personalExpenses)..where((t) => t.id.equals(localId))).write(const PersonalExpensesCompanion(dirty: Value(false)));
        break;
      case 'goal':
        await (db.update(db.goals)..where((t) => t.id.equals(localId))).write(const GoalsCompanion(dirty: Value(false)));
        break;
    }
  }

  Future<void> hardDeleteAfterSync(String entityType, String localId) async {
    switch (entityType) {
      case 'expense':
        await (db.delete(db.expenseShares)..where((t) => t.expenseId.equals(localId))).go();
        await (db.delete(db.expensePayers)..where((t) => t.expenseId.equals(localId))).go();
        await (db.delete(db.expenses)..where((t) => t.id.equals(localId))).go();
        break;
      case 'personal':
        await (db.delete(db.personalExpenses)..where((t) => t.id.equals(localId))).go();
        break;
      case 'goal':
        await (db.delete(db.goals)..where((t) => t.id.equals(localId))).go();
        break;
      case 'loan':
        await (db.delete(db.loanPayments)..where((t) => t.loanId.equals(localId))).go();
        await (db.delete(db.loans)..where((t) => t.id.equals(localId))).go();
        break;
      case 'loanPayment':
        await (db.delete(db.loanPayments)..where((t) => t.id.equals(localId))).go();
        break;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GUEST CONTACTS
  // ───────────────────────────────────────────────────────────────────────────
  Future<String> createGuestContactLocal({
    required String name,
    String? phone,
    String? email,
    String? avatarColor,
  }) async {
    final id = newId();
    await db.into(db.guestContacts).insert(GuestContactsCompanion.insert(
          id: id,
          name: Value(name),
          phone: Value(phone),
          email: Value(email),
          avatarColor: Value(avatarColor ?? '#6C5CE7'),
          createdAt: Value(DateTime.now()),
        ));
    return id;
  }

  Future<void> updateGuestContactLocal(String id, {String? name, String? phone, String? email}) async {
    await (db.update(db.guestContacts)..where((t) => t.id.equals(id))).write(GuestContactsCompanion(
          name: name != null ? Value(name) : const Value.absent(),
          phone: phone != null ? Value(phone) : const Value.absent(),
          email: email != null ? Value(email) : const Value.absent(),
        ));
  }

  Future<void> deleteGuestContactLocal(String id) async {
    await (db.delete(db.guestContacts)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Map<String, dynamic>>> watchGuestContactsJson() {
    return (db.select(db.guestContacts)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => [
              for (final c in rows)
                {
                  '_id': c.id,
                  'name': c.name,
                  'phone': c.phone,
                  'email': c.email,
                  'avatarColor': c.avatarColor,
                  'isGuest': true,
                }
            ]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LOANS
  // ───────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _loanToJson(Loan loan, List<LoanPayment> payments) async {
    return {
      '_id': loan.id,
      'serverId': loan.serverId,
      'counterpartyId': loan.counterpartyId,
      'counterpartyType': loan.counterpartyType,
      'counterpartyName': loan.counterpartyName,
      'counterpartyAvatar': loan.counterpartyAvatar,
      'loanType': loan.loanType,
      'amount': loan.amount,
      'paidAmount': loan.paidAmount,
      'currency': loan.currency,
      'description': loan.description,
      'notes': loan.notes,
      'dueDate': _iso(loan.dueDate),
      'status': loan.status,
      'createdAt': _iso(loan.createdAt),
      'updatedAt': _iso(loan.updatedAt),
      'payments': [
        for (final p in payments)
          {
            '_id': p.id,
            'loanId': p.loanId,
            'amount': p.amount,
            'note': p.note,
            'method': p.method,
            'paidAt': _iso(p.paidAt),
            'createdAt': _iso(p.createdAt),
          }
      ],
    };
  }

  Stream<List<Map<String, dynamic>>> watchLoansJson() {
    return db
        .customSelect('SELECT 1 AS x', readsFrom: {db.loans, db.loanPayments})
        .watch()
        .asyncMap((_) async {
      final loanRows = await (db.select(db.loans)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
      final ids = loanRows.map((l) => l.id).toList();
      if (ids.isEmpty) return <Map<String, dynamic>>[];
      final payments = await (db.select(db.loanPayments)
            ..where((t) => t.loanId.isIn(ids) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.paidAt)]))
          .get();
      final paymentsByLoan = <String, List<LoanPayment>>{};
      for (final p in payments) {
        paymentsByLoan.putIfAbsent(p.loanId, () => []).add(p);
      }
      return [
        for (final loan in loanRows)
          await _loanToJson(loan, paymentsByLoan[loan.id] ?? [])
      ];
    });
  }

  Stream<Map<String, dynamic>?> watchLoanJson(String id) {
    return db
        .customSelect('SELECT 1 AS x', readsFrom: {db.loans, db.loanPayments})
        .watch()
        .asyncMap((_) async {
      final loan = await (db.select(db.loans)
            ..where((t) => (t.id.equals(id) | t.serverId.equals(id)) & t.deletedAt.isNull()))
          .getSingleOrNull();
      if (loan == null) return null;
      final payments = await (db.select(db.loanPayments)
            ..where((t) => t.loanId.equals(loan.id) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.paidAt)]))
          .get();
      return _loanToJson(loan, payments);
    });
  }

  Future<String> createLoanLocal({
    required String counterpartyId,
    required String counterpartyType,
    required String counterpartyName,
    String? counterpartyAvatar,
    required String loanType,
    required double amount,
    required String currency,
    String description = '',
    String notes = '',
    DateTime? dueDate,
    String? forcedStatus,
  }) async {
    final id = newId();
    final opId = newId();
    // Guest loans are local-only and immediately active. App-user loans need
    // the counterparty to confirm: the creator's own copy is 'pending_sent'
    // (awaiting them), while the counterparty's pulled copy is 'pending_approval'
    // (they must act) — see [_upsertLoan].
    final status = forcedStatus ?? (counterpartyType == 'guest' ? 'active' : 'pending_sent');
    await db.into(db.loans).insert(LoansCompanion.insert(
          id: id,
          counterpartyId: counterpartyId,
          counterpartyType: Value(counterpartyType),
          counterpartyName: Value(counterpartyName),
          counterpartyAvatar: Value(counterpartyAvatar),
          loanType: Value(loanType),
          amount: Value(amount),
          currency: Value(currency),
          description: Value(description),
          notes: Value(notes),
          dueDate: Value(dueDate),
          status: Value(status),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          dirty: const Value(true),
        ));
    // Only queue server sync when counterparty is an app user.
    if (counterpartyType == 'user') {
      await enqueue(
        opId: opId,
        entityType: 'loan',
        opType: 'create',
        entityLocalId: id,
        payload: {
          'borrowerId': loanType == 'given' ? counterpartyId : currentUser?['_id'] ?? '',
          'lenderId': loanType == 'given' ? currentUser?['_id'] ?? '' : counterpartyId,
          'amount': amount,
          'currency': currency,
          'description': description,
          'notes': notes,
          if (dueDate != null) 'dueDate': _iso(dueDate),
          'clientOpId': opId,
        },
      );
    }
    return id;
  }

  Future<void> updateLoanStatusLocal(String id, String status) async {
    await (db.update(db.loans)..where((t) => t.id.equals(id) | t.serverId.equals(id)))
        .write(LoansCompanion(status: Value(status), updatedAt: Value(DateTime.now())));
  }

  Future<void> updateLoanPaidAmountLocal(String loanId) async {
    final payments = await (db.select(db.loanPayments)
          ..where((t) => t.loanId.equals(loanId) & t.deletedAt.isNull()))
        .get();
    final loan = await (db.select(db.loans)..where((t) => t.id.equals(loanId))).getSingleOrNull();
    if (loan == null) return;
    final total = payments.fold(0.0, (s, p) => s + p.amount);
    final paid = total.clamp(0.0, loan.amount);
    final newStatus = paid >= loan.amount ? 'settled' : (loan.status == 'settled' ? 'active' : loan.status);
    await (db.update(db.loans)..where((t) => t.id.equals(loanId))).write(LoansCompanion(
          paidAmount: Value(paid),
          status: Value(newStatus),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> deleteLoanLocal(String id) async {
    await (db.update(db.loans)..where((t) => t.id.equals(id)))
        .write(LoansCompanion(deletedAt: Value(DateTime.now()), dirty: const Value(true)));
    // Find serverId to enqueue delete.
    final loan = await (db.select(db.loans)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (loan?.serverId != null && loan!.counterpartyType == 'user') {
      await enqueue(entityType: 'loan', opType: 'delete', entityLocalId: id, payload: {});
    }
  }

  // ── LOAN PAYMENTS ──────────────────────────────────────────────────────────
  Future<String> createLoanPaymentLocal({
    required String loanId,
    required double amount,
    String note = '',
    String method = 'cash',
    DateTime? paidAt,
  }) async {
    final id = newId();
    final opId = newId();
    final loan = await (db.select(db.loans)..where((t) => t.id.equals(loanId))).getSingleOrNull();
    await db.into(db.loanPayments).insert(LoanPaymentsCompanion.insert(
          id: id,
          loanId: loanId,
          amount: Value(amount),
          note: Value(note),
          method: Value(method),
          paidAt: Value(paidAt ?? DateTime.now()),
          createdAt: Value(DateTime.now()),
          dirty: const Value(true),
        ));
    await updateLoanPaidAmountLocal(loanId);
    // Queue server sync only for app-user loans that are synced.
    if (loan != null && loan.counterpartyType == 'user' && loan.serverId != null) {
      await enqueue(
        opId: opId,
        entityType: 'loanPayment',
        opType: 'create',
        entityLocalId: id,
        payload: {
          'loanLocalId': loanId,
          'amount': amount,
          'note': note,
          'method': method,
          if (paidAt != null) 'paidAt': _iso(paidAt),
          'clientOpId': opId,
        },
      );
    }
    return id;
  }

  Future<void> deleteLoanPaymentLocal(String paymentId, String loanId) async {
    final payment =
        await (db.select(db.loanPayments)..where((t) => t.id.equals(paymentId))).getSingleOrNull();
    final loan = await (db.select(db.loans)..where((t) => t.id.equals(loanId))).getSingleOrNull();
    final isSynced = loan != null && loan.counterpartyType == 'user';

    if (payment != null && isSynced && payment.serverId != null) {
      // Already on the server — soft-delete locally (so a pull can't resurrect
      // it via the dirty guard) and queue a server-side delete.
      await (db.update(db.loanPayments)..where((t) => t.id.equals(paymentId)))
          .write(LoanPaymentsCompanion(deletedAt: Value(DateTime.now()), dirty: const Value(true)));
      await enqueue(
        entityType: 'loanPayment',
        opType: 'delete',
        entityLocalId: paymentId,
        payload: {'loanLocalId': loanId, 'paymentServerId': payment.serverId},
      );
    } else if (payment != null && isSynced) {
      // Created offline and not yet pushed — cancel the pending create so it
      // never reaches the server, then hard-delete the local row.
      await (db.delete(db.syncQueue)
            ..where((t) =>
                t.entityType.equals('loanPayment') & t.entityLocalId.equals(paymentId)))
          .go();
      await (db.delete(db.loanPayments)..where((t) => t.id.equals(paymentId))).go();
    } else {
      // Guest (local-only) loan — nothing to sync, just remove it.
      await (db.delete(db.loanPayments)..where((t) => t.id.equals(paymentId))).go();
    }
    await updateLoanPaidAmountLocal(loanId);
  }

  // ── LOAN PULL (from /sync) ─────────────────────────────────────────────────
  Future<void> _upsertLoan(Map<String, dynamic> j, String myId) async {
    final serverId = _idOf(j);
    final id = await _localIdFor(db.loans, serverId);
    if (await _isDirty(db.loans, id)) return;

    final lender = j['lender'];
    final borrower = j['borrower'];
    final lenderId = lender is Map ? _idOf(lender) : lender.toString();
    final borrowerId = borrower is Map ? _idOf(borrower) : borrower.toString();

    final isLender = lenderId == myId;
    final loanType = isLender ? 'given' : 'taken';
    final counterparty = isLender ? borrower : lender;
    final counterpartyId = isLender ? borrowerId : lenderId;
    final counterpartyName = counterparty is Map ? (counterparty['name'] ?? '') : '';
    final counterpartyAvatar = counterparty is Map ? counterparty['avatarUrl'] : null;

    // A pending loan reads differently per viewer: the creator is *awaiting*
    // the counterparty's decision ('pending_sent'), the counterparty must act
    // on it ('pending_approval'). The server stores a single 'pending_approval'.
    final createdById = _idOf(j['createdBy']);
    var status = j['status']?.toString() ?? 'active';
    if (status == 'pending_approval' && createdById == myId) {
      status = 'pending_sent';
    }

    await db.into(db.loans).insertOnConflictUpdate(LoansCompanion.insert(
          id: id,
          serverId: Value(serverId),
          counterpartyId: counterpartyId.toString(),
          counterpartyType: const Value('user'),
          counterpartyName: Value(counterpartyName.toString()),
          counterpartyAvatar: Value(counterpartyAvatar?.toString()),
          loanType: Value(loanType),
          amount: Value((j['amount'] as num?)?.toDouble() ?? 0),
          paidAmount: Value((j['paidAmount'] as num?)?.toDouble() ?? 0),
          currency: Value(j['currency']?.toString() ?? 'PKR'),
          description: Value(j['description']?.toString() ?? ''),
          notes: Value(j['notes']?.toString() ?? ''),
          dueDate: Value(_date(j['dueDate'])),
          status: Value(status),
          createdAt: Value(_date(j['createdAt'])),
          updatedAt: Value(_date(j['updatedAt'])),
          dirty: const Value(false),
        ));

    // Reconcile payments. Resolve each server payment to its stable local id
    // (an offline-created payment keeps its uuid `id` with `server_id` set) so
    // we update that row instead of inserting a duplicate keyed by the server
    // id. Un-pushed local (dirty) rows — e.g. a payment deleted offline and
    // queued for a server delete — are left untouched so the pull can't
    // resurrect them.
    final keepIds = <String>[];
    for (final p in (j['payments'] as List? ?? [])) {
      if (p is! Map) continue;
      final pServerId = _idOf(p);
      final pLocalId = await _localIdFor(db.loanPayments, pServerId);
      keepIds.add(pLocalId);
      if (await _isDirty(db.loanPayments, pLocalId)) continue; // keep local change
      await db.into(db.loanPayments).insertOnConflictUpdate(LoanPaymentsCompanion.insert(
            id: pLocalId,
            serverId: Value(pServerId),
            loanId: id,
            amount: Value((p['amount'] as num?)?.toDouble() ?? 0),
            note: Value(p['note']?.toString() ?? ''),
            method: Value(p['method']?.toString() ?? 'cash'),
            paidAt: Value(_date(p['paidAt'])),
            createdAt: Value(_date(p['createdAt'])),
            dirty: const Value(false),
          ));
    }
    // Drop server-synced payments that no longer exist remotely (deleted on
    // another device), but never touch dirty rows that still need to push.
    await (db.delete(db.loanPayments)
          ..where((t) =>
              t.loanId.equals(id) &
              t.dirty.equals(false) &
              (keepIds.isEmpty ? const Constant(true) : t.id.isNotIn(keepIds))))
        .go();
    // If un-pushed local payments survived (created or deleted offline), the
    // server's paidAmount is stale — recompute optimistically from local rows.
    final dirtyLeft = await (db.select(db.loanPayments)
          ..where((t) => t.loanId.equals(id) & t.dirty.equals(true)))
        .get();
    if (dirtyLeft.isNotEmpty) {
      await updateLoanPaidAmountLocal(id);
    }
  }

  /// Wipe everything (used on logout).
  Future<void> wipe() async {
    currentUser = null;
    await db.transaction(() async {
      for (final t in db.allTables) {
        await db.delete(t).go();
      }
    });
  }
}
