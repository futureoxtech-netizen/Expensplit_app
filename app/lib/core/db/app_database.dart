import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Offline-first local database (source of truth).
//
// ID strategy: every row's `id` is a stable local key that never changes.
//   • Server-origin rows:   id == serverId (the Mongo _id).
//   • Offline-created rows:  id == a client uuid, serverId == null until synced.
// Foreign keys always hold the *local* `id`. Because pulled rows use id==serverId,
// a server reference (an _id) resolves directly to the local row.
// `dirty` marks rows with un-pushed local changes (pull must not clobber them).
// ─────────────────────────────────────────────────────────────────────────────

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get avatarUrl => text().nullable()();
  BoolColumn get isPlaceholder => boolean().withDefault(const Constant(false))();
  TextColumn get currency => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant('other'))();
  TextColumn get coverColor => text().withDefault(const Constant('#6C5CE7'))();
  TextColumn get icon => text().withDefault(const Constant('group'))();
  TextColumn get currency => text().withDefault(const Constant('PKR'))();
  TextColumn get inviteCode => text().withDefault(const Constant(''))();
  TextColumn get pendingMembersJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class GroupMembers extends Table {
  TextColumn get groupId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text().withDefault(const Constant('member'))();
  @override
  Set<Column> get primaryKey => {groupId, userId};
}

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get groupId => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  RealColumn get amount => real().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('PKR'))();
  TextColumn get category => text().withDefault(const Constant('other'))();
  TextColumn get splitMode => text().withDefault(const Constant('equal'))();
  TextColumn get paidById => text().nullable()();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get tip => real().withDefault(const Constant(0))();
  TextColumn get receiptUrl => text().nullable()();
  TextColumn get receiptLocalPath => text().nullable()();
  DateTimeColumn get spentAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class ExpenseShares extends Table {
  TextColumn get expenseId => text()();
  TextColumn get userId => text()();
  RealColumn get amount => real().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {expenseId, userId};
}

class ExpensePayers extends Table {
  TextColumn get expenseId => text()();
  TextColumn get userId => text()();
  RealColumn get amount => real().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {expenseId, userId};
}

class Settlements extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get groupId => text()();
  TextColumn get fromUserId => text()();
  TextColumn get toUserId => text()();
  RealColumn get amount => real().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('PKR'))();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get settledAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class PersonalExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  RealColumn get amount => real().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('PKR'))();
  TextColumn get category => text().withDefault(const Constant('other'))();
  DateTimeColumn get date => dateTime().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get receiptUrl => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get emoji => text().withDefault(const Constant('🎯'))();
  TextColumn get category => text().withDefault(const Constant('other'))();
  RealColumn get targetAmount => real().withDefault(const Constant(0))();
  RealColumn get savedAmount => real().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('PKR'))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get color => text().withDefault(const Constant('#6C5CE7'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get contributionsJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('event'))();
  TextColumn get message => text().withDefault(const Constant(''))();
  TextColumn get actorId => text().nullable()();
  TextColumn get actorName => text().nullable()();
  TextColumn get actorAvatar => text().nullable()();
  TextColumn get groupName => text().nullable()();
  TextColumn get groupColor => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Reactions on an expense or settlement. `targetId` is the target's local id.
class Reactions extends Table {
  TextColumn get targetType => text()(); // expense | settlement
  TextColumn get targetId => text()();
  TextColumn get emoji => text()();
  TextColumn get userId => text()();
  TextColumn get userName => text().nullable()();
  TextColumn get userAvatar => text().nullable()();
  @override
  Set<Column> get primaryKey => {targetType, targetId, emoji, userId};
}

// ── LOAN FEATURE ─────────────────────────────────────────────────────────────

/// Local-only contacts (no app account). Used as counterparties for loans.
class GuestContacts extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get avatarColor => text().withDefault(const Constant('#6C5CE7'))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// A single loan record. `loanType` is from the creating user's perspective:
///   'given' = I lent money to counterparty
///   'taken' = I borrowed money from counterparty
class Loans extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get counterpartyId => text()();
  TextColumn get counterpartyType => text().withDefault(const Constant('guest'))(); // 'user'|'guest'
  TextColumn get counterpartyName => text().withDefault(const Constant(''))();
  TextColumn get counterpartyAvatar => text().nullable()();
  TextColumn get loanType => text().withDefault(const Constant('given'))(); // 'given'|'taken'
  RealColumn get amount => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('PKR'))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  // 'pending_approval' | 'active' | 'settled' | 'rejected'
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Individual payment records against a loan.
class LoanPayments extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get loanId => text()();
  RealColumn get amount => real().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  DateTimeColumn get paidAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Pending offline mutations, replayed FIFO by the SyncEngine.
class SyncQueue extends Table {
  TextColumn get opId => text()();
  TextColumn get entityType => text()(); // group|expense|settlement|personal|goal|profile|reaction|groupNotes
  TextColumn get entityLocalId => text().nullable()();
  TextColumn get opType => text()(); // create|update|delete
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending|failed
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {opId};
}

class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  Users,
  Groups,
  GroupMembers,
  Expenses,
  ExpenseShares,
  ExpensePayers,
  Settlements,
  PersonalExpenses,
  Goals,
  Activities,
  Reactions,
  GuestContacts,
  Loans,
  LoanPayments,
  SyncQueue,
  SyncMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(driftDatabase(
          name: 'expensplit_offline',
          // On web, Drift needs to be told where the sqlite3 WASM build and the
          // drift worker live. Both ship from web/ (served at the app root), so
          // they resolve to root-relative URLs. Native platforms ignore this.
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),);

  /// Test/override constructor.
  AppDatabase.forExecutor(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(reactions);
          if (from < 3) {
            // createTable builds from the *current* table definition, so the
            // guestContacts created here already has serverId/dirty/deletedAt.
            await m.createTable(guestContacts);
            await m.createTable(loans);
            await m.createTable(loanPayments);
          }
          // Only a database that was actually at schema 3 has the *old*
          // guestContacts table that lacks these columns. Running addColumn for
          // a from<3 upgrade would hit "duplicate column name" (createTable
          // above already added them) and crash the app on update.
          if (from == 3) {
            await m.addColumn(guestContacts, guestContacts.serverId);
            await m.addColumn(guestContacts, guestContacts.dirty);
            await m.addColumn(guestContacts, guestContacts.deletedAt);
          }
        },
      );

  // Singleton — the app uses one database for its whole lifetime.
  static final AppDatabase instance = AppDatabase();

  // ── sync_meta helpers ──────────────────────────────────────────────────────
  Future<String?> metaGet(String key) async {
    final row = await (select(syncMeta)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> metaSet(String key, String value) =>
      into(syncMeta).insertOnConflictUpdate(SyncMetaCompanion.insert(key: key, value: Value(value)));

  // ── id resolution (local id -> serverId for push) ──────────────────────────
  Future<String?> groupServerId(String localId) async =>
      (await (select(groups)..where((t) => t.id.equals(localId))).getSingleOrNull())?.serverId;
}
