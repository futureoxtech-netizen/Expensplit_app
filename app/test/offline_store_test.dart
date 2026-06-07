import 'package:drift/native.dart';
import 'package:expense_app/core/db/app_database.dart';
import 'package:expense_app/core/db/local_store.dart';
import 'package:expense_app/features/expenses/data/expense_model.dart';
import 'package:expense_app/features/groups/data/group_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end offline-first behaviour against an in-memory Drift DB.
void main() {
  late AppDatabase db;
  late LocalStore store;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    store = LocalStore(db);
    store.setCurrentUser({'_id': 'me', 'name': 'Me', 'email': 'me@test.com'});
  });

  tearDown(() async => db.close());

  test('offline: create group + expense reflects in reads and queues sync ops', () async {
    final gid = await store.createGroupLocal(name: 'Trip');
    // The group is readable immediately (optimistic), owner is a member.
    final groups = await store.watchGroupsJson().first;
    expect(groups.length, 1);
    final group = GroupModel.fromJson(groups.first);
    expect(group.name, 'Trip');
    expect(group.members.any((m) => m.user.id == 'me'), isTrue);

    // Add a second member directly so we can split.
    await store.ensureUser({'_id': 'bob', 'name': 'Bob'});
    await db.into(db.groupMembers).insert(
        GroupMembersCompanion.insert(groupId: gid, userId: 'bob'));

    await store.createExpenseLocal(
      groupId: gid,
      description: 'Dinner',
      amount: 100,
      splitMode: 'equal',
      paidBy: 'me',
      splits: [{'userId': 'me'}, {'userId': 'bob'}],
    );

    final expenses = await store.watchGroupExpensesJson(gid).first;
    expect(expenses.length, 1);
    final exp = ExpenseModel.fromJson(expenses.first);
    expect(exp.description, 'Dinner');
    expect(exp.shares.length, 2);

    // Balances computed offline: Bob owes me 50.
    final bal = await store.watchGroupBalancesJson(gid).first;
    final balances = bal['balances'] as List;
    final me = balances.firstWhere((b) => b['userId'] == 'me');
    expect((me['net'] as num).toDouble(), closeTo(50, 0.001));

    // Two create ops queued (group + expense), both with clientOpIds.
    final ops = await store.pendingOps();
    expect(ops.length, 2);
    expect(ops.where((o) => o.opType == 'create').length, 2);
  });

  test('applyPull merges server data and respects dirty local rows', () async {
    // A server group arrives.
    await store.applyPull({
      'serverTime': DateTime.now().toIso8601String(),
      'users': [
        {'_id': 'me', 'name': 'Me'},
        {'_id': 'bob', 'name': 'Bob'},
      ],
      'groups': [
        {
          '_id': 'g1',
          'name': 'Server Group',
          'members': [
            {'user': {'_id': 'me', 'name': 'Me'}, 'role': 'owner'},
            {'user': {'_id': 'bob', 'name': 'Bob'}, 'role': 'member'},
          ],
        }
      ],
      'expenses': [
        {
          '_id': 'e1',
          'group': 'g1',
          'description': 'Lunch',
          'amount': 40,
          'splitMode': 'equal',
          'paidBy': {'_id': 'bob', 'name': 'Bob'},
          'shares': [
            {'user': {'_id': 'me'}, 'amount': 20},
            {'user': {'_id': 'bob'}, 'amount': 20},
          ],
        }
      ],
    });

    var groups = await store.watchGroupsJson().first;
    expect(groups.length, 1);
    expect(GroupModel.fromJson(groups.first).name, 'Server Group');

    // Locally edit the group's notes (marks it dirty).
    await store.updateGroupNotesLocal('g1', 'my local note');

    // A stale pull tries to overwrite — dirty row must be preserved.
    await store.applyPull({
      'groups': [
        {'_id': 'g1', 'name': 'Renamed On Server', 'notes': '', 'members': []}
      ],
    });
    groups = await store.watchGroupsJson().first;
    expect(GroupModel.fromJson(groups.first).notes, 'my local note',
        reason: 'un-pushed local edits must not be clobbered by pull');
  });

  test('tombstone deletion removes the entity locally', () async {
    await store.applyPull({
      'expenses': [
        {
          '_id': 'e9', 'group': 'gX', 'description': 'X', 'amount': 10,
          'splitMode': 'equal', 'paidBy': {'_id': 'me'},
          'shares': [{'user': {'_id': 'me'}, 'amount': 10}],
        }
      ],
    });
    expect((await store.watchFeedJson().first).length, 1);

    await store.applyPull({
      'deletions': [{'entityType': 'expense', 'entityId': 'e9'}],
    });
    expect((await store.watchFeedJson().first).length, 0);
  });

  test('friends summary computed offline across a shared group', () async {
    await store.applyPull({
      'users': [
        {'_id': 'me', 'name': 'Me'},
        {'_id': 'sara', 'name': 'Sara'},
      ],
      'groups': [
        {
          '_id': 'g2', 'name': 'Flat',
          'members': [
            {'user': {'_id': 'me'}, 'role': 'owner'},
            {'user': {'_id': 'sara'}, 'role': 'member'},
          ],
        }
      ],
      'expenses': [
        {
          '_id': 'e2', 'group': 'g2', 'description': 'Rent', 'amount': 200,
          'splitMode': 'equal', 'paidBy': {'_id': 'me'},
          'shares': [
            {'user': {'_id': 'me'}, 'amount': 100},
            {'user': {'_id': 'sara'}, 'amount': 100},
          ],
        }
      ],
    });

    final friends = await store.watchFriendsSummaryJson('me').first;
    expect(friends.length, 1);
    expect(friends.first['userId'], 'sara');
    expect((friends.first['net'] as num).toDouble(), closeTo(100, 0.001)); // Sara owes me 100
  });

  test('create then sync then pull does NOT duplicate (id reconciliation)', () async {
    final gid = await store.createGroupLocal(name: 'G');
    await store.ensureUser({'_id': 'bob', 'name': 'Bob'});
    await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(groupId: gid, userId: 'bob'));
    final eid = await store.createExpenseLocal(
      groupId: gid,
      description: 'Taxi',
      amount: 40,
      splitMode: 'equal',
      paidBy: 'me',
      splits: [{'userId': 'me'}, {'userId': 'bob'}],
    );
    expect((await store.watchFeedJson().first).length, 1);

    // Simulate the push completing: server ids assigned.
    await store.applyServerId('group', gid, 'gSrv');
    await store.applyServerId('expense', eid, 'eSrv');

    // Now a pull returns the same group + expense keyed by their server ids.
    await store.applyPull({
      'groups': [
        {'_id': 'gSrv', 'name': 'G', 'members': [
          {'user': {'_id': 'me'}, 'role': 'owner'},
          {'user': {'_id': 'bob'}, 'role': 'member'},
        ]}
      ],
      'expenses': [
        {
          '_id': 'eSrv', 'group': 'gSrv', 'description': 'Taxi', 'amount': 40,
          'splitMode': 'equal', 'paidBy': {'_id': 'me'},
          'shares': [{'user': {'_id': 'me'}, 'amount': 20}, {'user': {'_id': 'bob'}, 'amount': 20}],
        }
      ],
    });

    // Still exactly one group and one expense — the local uuid rows were updated,
    // not duplicated by the server-id rows.
    expect((await store.watchGroupsJson().first).length, 1);
    expect((await store.watchFeedJson().first).length, 1);
    // And the expense still resolves into the (locally-id'd) group.
    expect((await store.watchGroupExpensesJson(gid).first).length, 1);
  });

  test('applyPull reports change only for non-empty deltas (no sync loop)', () async {
    // Empty delta → false → caller must NOT bump revision (would re-kick forever).
    final emptyChanged = await store.applyPull({
      'serverTime': DateTime.now().toIso8601String(),
      'hasMore': false,
      'groups': [], 'expenses': [], 'settlements': [],
      'personalExpenses': [], 'goals': [], 'activity': [], 'users': [], 'deletions': [],
    });
    expect(emptyChanged, isFalse);

    final realChanged = await store.applyPull({
      'users': [{'_id': 'x', 'name': 'X'}],
    });
    expect(realChanged, isTrue);
  });

  test('feedPage paginates local rows', () async {
    final exps = [
      for (var i = 0; i < 5; i++)
        {
          '_id': 'e$i', 'group': 'g', 'description': 'x$i', 'amount': 10,
          'splitMode': 'equal', 'paidBy': {'_id': 'me'},
          'spentAt': DateTime(2026, 1, i + 1).toIso8601String(),
          'shares': [{'user': {'_id': 'me'}, 'amount': 10}],
        }
    ];
    await store.applyPull({'expenses': exps});
    final page1 = await store.feedPage(limit: 2, offset: 0);
    final page2 = await store.feedPage(limit: 2, offset: 2);
    expect(page1.length, 2);
    expect(page2.length, 2);
    expect(page1.first['_id'], isNot(page2.first['_id']));
  });

  test('reactions persist from pull and update via applyReactionsJson', () async {
    await store.applyPull({
      'users': [
        {'_id': 'me', 'name': 'Me'},
        {'_id': 'bob', 'name': 'Bob'},
      ],
      'expenses': [
        {
          '_id': 'er', 'group': 'g', 'description': 'Pizza', 'amount': 20,
          'splitMode': 'equal', 'paidBy': {'_id': 'me'},
          'shares': [{'user': {'_id': 'me'}, 'amount': 20}],
          'reactions': [
            {'emoji': '👍', 'users': [{'id': 'bob', 'name': 'Bob'}]},
          ],
        }
      ],
    });
    var feed = await store.watchFeedJson().first;
    expect(feed.length, 1);
    var reactions = feed.first['reactions'] as List;
    expect(reactions.length, 1);
    expect(reactions.first['emoji'], '👍');
    expect((reactions.first['users'] as List).length, 1);

    // A realtime reaction:changed adds my reaction.
    await store.applyReactionsJson('expense', 'er', [
      {'emoji': '👍', 'users': [{'id': 'bob', 'name': 'Bob'}, {'id': 'me', 'name': 'Me'}]},
      {'emoji': '🎉', 'users': [{'id': 'me', 'name': 'Me'}]},
    ]);
    feed = await store.watchFeedJson().first;
    reactions = feed.first['reactions'] as List;
    expect(reactions.length, 2, reason: 'two emoji buckets now');
    final thumbs = reactions.firstWhere((r) => r['emoji'] == '👍');
    expect((thumbs['users'] as List).length, 2);
  });

  test('offline delete marks dirty + queues a delete op', () async {
    await store.applyPull({
      'expenses': [
        {
          '_id': 'e3', 'group': 'g3', 'description': 'Y', 'amount': 10,
          'splitMode': 'equal', 'paidBy': {'_id': 'me'},
          'shares': [{'user': {'_id': 'me'}, 'amount': 10}],
        }
      ],
    });
    await store.deleteExpenseLocal('e3');
    // Soft-deleted → no longer shown.
    expect((await store.watchFeedJson().first).length, 0);
    final ops = await store.pendingOps();
    expect(ops.any((o) => o.entityType == 'expense' && o.opType == 'delete'), isTrue);
  });
}
