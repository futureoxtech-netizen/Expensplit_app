// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _avatarUrlMeta =
      const VerificationMeta('avatarUrl');
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
      'avatar_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPlaceholderMeta =
      const VerificationMeta('isPlaceholder');
  @override
  late final GeneratedColumn<bool> isPlaceholder = GeneratedColumn<bool>(
      'is_placeholder', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_placeholder" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, email, avatarUrl, isPlaceholder, currency];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('avatar_url')) {
      context.handle(_avatarUrlMeta,
          avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta));
    }
    if (data.containsKey('is_placeholder')) {
      context.handle(
          _isPlaceholderMeta,
          isPlaceholder.isAcceptableOrUnknown(
              data['is_placeholder']!, _isPlaceholderMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      avatarUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_url']),
      isPlaceholder: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_placeholder'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency']),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isPlaceholder;
  final String? currency;
  const User(
      {required this.id,
      required this.name,
      required this.email,
      this.avatarUrl,
      required this.isPlaceholder,
      this.currency});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    map['is_placeholder'] = Variable<bool>(isPlaceholder);
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      isPlaceholder: Value(isPlaceholder),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      isPlaceholder: serializer.fromJson<bool>(json['isPlaceholder']),
      currency: serializer.fromJson<String?>(json['currency']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'isPlaceholder': serializer.toJson<bool>(isPlaceholder),
      'currency': serializer.toJson<String?>(currency),
    };
  }

  User copyWith(
          {String? id,
          String? name,
          String? email,
          Value<String?> avatarUrl = const Value.absent(),
          bool? isPlaceholder,
          Value<String?> currency = const Value.absent()}) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
        isPlaceholder: isPlaceholder ?? this.isPlaceholder,
        currency: currency.present ? currency.value : this.currency,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      isPlaceholder: data.isPlaceholder.present
          ? data.isPlaceholder.value
          : this.isPlaceholder,
      currency: data.currency.present ? data.currency.value : this.currency,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isPlaceholder: $isPlaceholder, ')
          ..write('currency: $currency')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, email, avatarUrl, isPlaceholder, currency);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.avatarUrl == this.avatarUrl &&
          other.isPlaceholder == this.isPlaceholder &&
          other.currency == this.currency);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> email;
  final Value<String?> avatarUrl;
  final Value<bool> isPlaceholder;
  final Value<String?> currency;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isPlaceholder = const Value.absent(),
    this.currency = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isPlaceholder = const Value.absent(),
    this.currency = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? avatarUrl,
    Expression<bool>? isPlaceholder,
    Expression<String>? currency,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (isPlaceholder != null) 'is_placeholder': isPlaceholder,
      if (currency != null) 'currency': currency,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? email,
      Value<String?>? avatarUrl,
      Value<bool>? isPlaceholder,
      Value<String?>? currency,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
      currency: currency ?? this.currency,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (isPlaceholder.present) {
      map['is_placeholder'] = Variable<bool>(isPlaceholder.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isPlaceholder: $isPlaceholder, ')
          ..write('currency: $currency, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, Group> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('other'));
  static const VerificationMeta _coverColorMeta =
      const VerificationMeta('coverColor');
  @override
  late final GeneratedColumn<String> coverColor = GeneratedColumn<String>(
      'cover_color', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#6C5CE7'));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('group'));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PKR'));
  static const VerificationMeta _inviteCodeMeta =
      const VerificationMeta('inviteCode');
  @override
  late final GeneratedColumn<String> inviteCode = GeneratedColumn<String>(
      'invite_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _pendingMembersJsonMeta =
      const VerificationMeta('pendingMembersJson');
  @override
  late final GeneratedColumn<String> pendingMembersJson =
      GeneratedColumn<String>('pending_members_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        name,
        description,
        notes,
        category,
        coverColor,
        icon,
        currency,
        inviteCode,
        pendingMembersJson,
        createdAt,
        updatedAt,
        deletedAt,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(Insertable<Group> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('cover_color')) {
      context.handle(
          _coverColorMeta,
          coverColor.isAcceptableOrUnknown(
              data['cover_color']!, _coverColorMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('invite_code')) {
      context.handle(
          _inviteCodeMeta,
          inviteCode.isAcceptableOrUnknown(
              data['invite_code']!, _inviteCodeMeta));
    }
    if (data.containsKey('pending_members_json')) {
      context.handle(
          _pendingMembersJsonMeta,
          pendingMembersJson.isAcceptableOrUnknown(
              data['pending_members_json']!, _pendingMembersJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      coverColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_color'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      inviteCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invite_code'])!,
      pendingMembersJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}pending_members_json']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class Group extends DataClass implements Insertable<Group> {
  final String id;
  final String? serverId;
  final String name;
  final String description;
  final String notes;
  final String category;
  final String coverColor;
  final String icon;
  final String currency;
  final String inviteCode;
  final String? pendingMembersJson;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const Group(
      {required this.id,
      this.serverId,
      required this.name,
      required this.description,
      required this.notes,
      required this.category,
      required this.coverColor,
      required this.icon,
      required this.currency,
      required this.inviteCode,
      this.pendingMembersJson,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['notes'] = Variable<String>(notes);
    map['category'] = Variable<String>(category);
    map['cover_color'] = Variable<String>(coverColor);
    map['icon'] = Variable<String>(icon);
    map['currency'] = Variable<String>(currency);
    map['invite_code'] = Variable<String>(inviteCode);
    if (!nullToAbsent || pendingMembersJson != null) {
      map['pending_members_json'] = Variable<String>(pendingMembersJson);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      name: Value(name),
      description: Value(description),
      notes: Value(notes),
      category: Value(category),
      coverColor: Value(coverColor),
      icon: Value(icon),
      currency: Value(currency),
      inviteCode: Value(inviteCode),
      pendingMembersJson: pendingMembersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingMembersJson),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory Group.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      notes: serializer.fromJson<String>(json['notes']),
      category: serializer.fromJson<String>(json['category']),
      coverColor: serializer.fromJson<String>(json['coverColor']),
      icon: serializer.fromJson<String>(json['icon']),
      currency: serializer.fromJson<String>(json['currency']),
      inviteCode: serializer.fromJson<String>(json['inviteCode']),
      pendingMembersJson:
          serializer.fromJson<String?>(json['pendingMembersJson']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'notes': serializer.toJson<String>(notes),
      'category': serializer.toJson<String>(category),
      'coverColor': serializer.toJson<String>(coverColor),
      'icon': serializer.toJson<String>(icon),
      'currency': serializer.toJson<String>(currency),
      'inviteCode': serializer.toJson<String>(inviteCode),
      'pendingMembersJson': serializer.toJson<String?>(pendingMembersJson),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Group copyWith(
          {String? id,
          Value<String?> serverId = const Value.absent(),
          String? name,
          String? description,
          String? notes,
          String? category,
          String? coverColor,
          String? icon,
          String? currency,
          String? inviteCode,
          Value<String?> pendingMembersJson = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? dirty}) =>
      Group(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        name: name ?? this.name,
        description: description ?? this.description,
        notes: notes ?? this.notes,
        category: category ?? this.category,
        coverColor: coverColor ?? this.coverColor,
        icon: icon ?? this.icon,
        currency: currency ?? this.currency,
        inviteCode: inviteCode ?? this.inviteCode,
        pendingMembersJson: pendingMembersJson.present
            ? pendingMembersJson.value
            : this.pendingMembersJson,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        dirty: dirty ?? this.dirty,
      );
  Group copyWithCompanion(GroupsCompanion data) {
    return Group(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      notes: data.notes.present ? data.notes.value : this.notes,
      category: data.category.present ? data.category.value : this.category,
      coverColor:
          data.coverColor.present ? data.coverColor.value : this.coverColor,
      icon: data.icon.present ? data.icon.value : this.icon,
      currency: data.currency.present ? data.currency.value : this.currency,
      inviteCode:
          data.inviteCode.present ? data.inviteCode.value : this.inviteCode,
      pendingMembersJson: data.pendingMembersJson.present
          ? data.pendingMembersJson.value
          : this.pendingMembersJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('notes: $notes, ')
          ..write('category: $category, ')
          ..write('coverColor: $coverColor, ')
          ..write('icon: $icon, ')
          ..write('currency: $currency, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('pendingMembersJson: $pendingMembersJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      serverId,
      name,
      description,
      notes,
      category,
      coverColor,
      icon,
      currency,
      inviteCode,
      pendingMembersJson,
      createdAt,
      updatedAt,
      deletedAt,
      dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.description == this.description &&
          other.notes == this.notes &&
          other.category == this.category &&
          other.coverColor == this.coverColor &&
          other.icon == this.icon &&
          other.currency == this.currency &&
          other.inviteCode == this.inviteCode &&
          other.pendingMembersJson == this.pendingMembersJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<String> id;
  final Value<String?> serverId;
  final Value<String> name;
  final Value<String> description;
  final Value<String> notes;
  final Value<String> category;
  final Value<String> coverColor;
  final Value<String> icon;
  final Value<String> currency;
  final Value<String> inviteCode;
  final Value<String?> pendingMembersJson;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.notes = const Value.absent(),
    this.category = const Value.absent(),
    this.coverColor = const Value.absent(),
    this.icon = const Value.absent(),
    this.currency = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.pendingMembersJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String id,
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.notes = const Value.absent(),
    this.category = const Value.absent(),
    this.coverColor = const Value.absent(),
    this.icon = const Value.absent(),
    this.currency = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.pendingMembersJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Group> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? notes,
    Expression<String>? category,
    Expression<String>? coverColor,
    Expression<String>? icon,
    Expression<String>? currency,
    Expression<String>? inviteCode,
    Expression<String>? pendingMembersJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      if (category != null) 'category': category,
      if (coverColor != null) 'cover_color': coverColor,
      if (icon != null) 'icon': icon,
      if (currency != null) 'currency': currency,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (pendingMembersJson != null)
        'pending_members_json': pendingMembersJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? serverId,
      Value<String>? name,
      Value<String>? description,
      Value<String>? notes,
      Value<String>? category,
      Value<String>? coverColor,
      Value<String>? icon,
      Value<String>? currency,
      Value<String>? inviteCode,
      Value<String?>? pendingMembersJson,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return GroupsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      coverColor: coverColor ?? this.coverColor,
      icon: icon ?? this.icon,
      currency: currency ?? this.currency,
      inviteCode: inviteCode ?? this.inviteCode,
      pendingMembersJson: pendingMembersJson ?? this.pendingMembersJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (coverColor.present) {
      map['cover_color'] = Variable<String>(coverColor.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (inviteCode.present) {
      map['invite_code'] = Variable<String>(inviteCode.value);
    }
    if (pendingMembersJson.present) {
      map['pending_members_json'] = Variable<String>(pendingMembersJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('notes: $notes, ')
          ..write('category: $category, ')
          ..write('coverColor: $coverColor, ')
          ..write('icon: $icon, ')
          ..write('currency: $currency, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('pendingMembersJson: $pendingMembersJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupMembersTable extends GroupMembers
    with TableInfo<$GroupMembersTable, GroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('member'));
  @override
  List<GeneratedColumn> get $columns => [groupId, userId, role];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(Insertable<GroupMember> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, userId};
  @override
  GroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMember(
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
    );
  }

  @override
  $GroupMembersTable createAlias(String alias) {
    return $GroupMembersTable(attachedDatabase, alias);
  }
}

class GroupMember extends DataClass implements Insertable<GroupMember> {
  final String groupId;
  final String userId;
  final String role;
  const GroupMember(
      {required this.groupId, required this.userId, required this.role});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      groupId: Value(groupId),
      userId: Value(userId),
      role: Value(role),
    );
  }

  factory GroupMember.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMember(
      groupId: serializer.fromJson<String>(json['groupId']),
      userId: serializer.fromJson<String>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'userId': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
    };
  }

  GroupMember copyWith({String? groupId, String? userId, String? role}) =>
      GroupMember(
        groupId: groupId ?? this.groupId,
        userId: userId ?? this.userId,
        role: role ?? this.role,
      );
  GroupMember copyWithCompanion(GroupMembersCompanion data) {
    return GroupMember(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMember(')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, userId, role);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMember &&
          other.groupId == this.groupId &&
          other.userId == this.userId &&
          other.role == this.role);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMember> {
  final Value<String> groupId;
  final Value<String> userId;
  final Value<String> role;
  final Value<int> rowid;
  const GroupMembersCompanion({
    this.groupId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    required String groupId,
    required String userId,
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : groupId = Value(groupId),
        userId = Value(userId);
  static Insertable<GroupMember> custom({
    Expression<String>? groupId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersCompanion copyWith(
      {Value<String>? groupId,
      Value<String>? userId,
      Value<String>? role,
      Value<int>? rowid}) {
    return GroupMembersCompanion(
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersCompanion(')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PKR'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('other'));
  static const VerificationMeta _splitModeMeta =
      const VerificationMeta('splitMode');
  @override
  late final GeneratedColumn<String> splitMode = GeneratedColumn<String>(
      'split_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('equal'));
  static const VerificationMeta _paidByIdMeta =
      const VerificationMeta('paidById');
  @override
  late final GeneratedColumn<String> paidById = GeneratedColumn<String>(
      'paid_by_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _taxMeta = const VerificationMeta('tax');
  @override
  late final GeneratedColumn<double> tax = GeneratedColumn<double>(
      'tax', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _tipMeta = const VerificationMeta('tip');
  @override
  late final GeneratedColumn<double> tip = GeneratedColumn<double>(
      'tip', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _receiptUrlMeta =
      const VerificationMeta('receiptUrl');
  @override
  late final GeneratedColumn<String> receiptUrl = GeneratedColumn<String>(
      'receipt_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receiptLocalPathMeta =
      const VerificationMeta('receiptLocalPath');
  @override
  late final GeneratedColumn<String> receiptLocalPath = GeneratedColumn<String>(
      'receipt_local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _spentAtMeta =
      const VerificationMeta('spentAt');
  @override
  late final GeneratedColumn<DateTime> spentAt = GeneratedColumn<DateTime>(
      'spent_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        groupId,
        description,
        notes,
        amount,
        currency,
        category,
        splitMode,
        paidById,
        tax,
        tip,
        receiptUrl,
        receiptLocalPath,
        spentAt,
        createdAt,
        updatedAt,
        deletedAt,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(Insertable<Expense> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('split_mode')) {
      context.handle(_splitModeMeta,
          splitMode.isAcceptableOrUnknown(data['split_mode']!, _splitModeMeta));
    }
    if (data.containsKey('paid_by_id')) {
      context.handle(_paidByIdMeta,
          paidById.isAcceptableOrUnknown(data['paid_by_id']!, _paidByIdMeta));
    }
    if (data.containsKey('tax')) {
      context.handle(
          _taxMeta, tax.isAcceptableOrUnknown(data['tax']!, _taxMeta));
    }
    if (data.containsKey('tip')) {
      context.handle(
          _tipMeta, tip.isAcceptableOrUnknown(data['tip']!, _tipMeta));
    }
    if (data.containsKey('receipt_url')) {
      context.handle(
          _receiptUrlMeta,
          receiptUrl.isAcceptableOrUnknown(
              data['receipt_url']!, _receiptUrlMeta));
    }
    if (data.containsKey('receipt_local_path')) {
      context.handle(
          _receiptLocalPathMeta,
          receiptLocalPath.isAcceptableOrUnknown(
              data['receipt_local_path']!, _receiptLocalPathMeta));
    }
    if (data.containsKey('spent_at')) {
      context.handle(_spentAtMeta,
          spentAt.isAcceptableOrUnknown(data['spent_at']!, _spentAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      splitMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}split_mode'])!,
      paidById: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}paid_by_id']),
      tax: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax'])!,
      tip: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tip'])!,
      receiptUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_url']),
      receiptLocalPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}receipt_local_path']),
      spentAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}spent_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final String? serverId;
  final String groupId;
  final String description;
  final String notes;
  final double amount;
  final String currency;
  final String category;
  final String splitMode;
  final String? paidById;
  final double tax;
  final double tip;
  final String? receiptUrl;
  final String? receiptLocalPath;
  final DateTime? spentAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const Expense(
      {required this.id,
      this.serverId,
      required this.groupId,
      required this.description,
      required this.notes,
      required this.amount,
      required this.currency,
      required this.category,
      required this.splitMode,
      this.paidById,
      required this.tax,
      required this.tip,
      this.receiptUrl,
      this.receiptLocalPath,
      this.spentAt,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['group_id'] = Variable<String>(groupId);
    map['description'] = Variable<String>(description);
    map['notes'] = Variable<String>(notes);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['category'] = Variable<String>(category);
    map['split_mode'] = Variable<String>(splitMode);
    if (!nullToAbsent || paidById != null) {
      map['paid_by_id'] = Variable<String>(paidById);
    }
    map['tax'] = Variable<double>(tax);
    map['tip'] = Variable<double>(tip);
    if (!nullToAbsent || receiptUrl != null) {
      map['receipt_url'] = Variable<String>(receiptUrl);
    }
    if (!nullToAbsent || receiptLocalPath != null) {
      map['receipt_local_path'] = Variable<String>(receiptLocalPath);
    }
    if (!nullToAbsent || spentAt != null) {
      map['spent_at'] = Variable<DateTime>(spentAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      groupId: Value(groupId),
      description: Value(description),
      notes: Value(notes),
      amount: Value(amount),
      currency: Value(currency),
      category: Value(category),
      splitMode: Value(splitMode),
      paidById: paidById == null && nullToAbsent
          ? const Value.absent()
          : Value(paidById),
      tax: Value(tax),
      tip: Value(tip),
      receiptUrl: receiptUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptUrl),
      receiptLocalPath: receiptLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptLocalPath),
      spentAt: spentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(spentAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      description: serializer.fromJson<String>(json['description']),
      notes: serializer.fromJson<String>(json['notes']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      category: serializer.fromJson<String>(json['category']),
      splitMode: serializer.fromJson<String>(json['splitMode']),
      paidById: serializer.fromJson<String?>(json['paidById']),
      tax: serializer.fromJson<double>(json['tax']),
      tip: serializer.fromJson<double>(json['tip']),
      receiptUrl: serializer.fromJson<String?>(json['receiptUrl']),
      receiptLocalPath: serializer.fromJson<String?>(json['receiptLocalPath']),
      spentAt: serializer.fromJson<DateTime?>(json['spentAt']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'groupId': serializer.toJson<String>(groupId),
      'description': serializer.toJson<String>(description),
      'notes': serializer.toJson<String>(notes),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'category': serializer.toJson<String>(category),
      'splitMode': serializer.toJson<String>(splitMode),
      'paidById': serializer.toJson<String?>(paidById),
      'tax': serializer.toJson<double>(tax),
      'tip': serializer.toJson<double>(tip),
      'receiptUrl': serializer.toJson<String?>(receiptUrl),
      'receiptLocalPath': serializer.toJson<String?>(receiptLocalPath),
      'spentAt': serializer.toJson<DateTime?>(spentAt),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Expense copyWith(
          {String? id,
          Value<String?> serverId = const Value.absent(),
          String? groupId,
          String? description,
          String? notes,
          double? amount,
          String? currency,
          String? category,
          String? splitMode,
          Value<String?> paidById = const Value.absent(),
          double? tax,
          double? tip,
          Value<String?> receiptUrl = const Value.absent(),
          Value<String?> receiptLocalPath = const Value.absent(),
          Value<DateTime?> spentAt = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? dirty}) =>
      Expense(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        groupId: groupId ?? this.groupId,
        description: description ?? this.description,
        notes: notes ?? this.notes,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        category: category ?? this.category,
        splitMode: splitMode ?? this.splitMode,
        paidById: paidById.present ? paidById.value : this.paidById,
        tax: tax ?? this.tax,
        tip: tip ?? this.tip,
        receiptUrl: receiptUrl.present ? receiptUrl.value : this.receiptUrl,
        receiptLocalPath: receiptLocalPath.present
            ? receiptLocalPath.value
            : this.receiptLocalPath,
        spentAt: spentAt.present ? spentAt.value : this.spentAt,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        dirty: dirty ?? this.dirty,
      );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      description:
          data.description.present ? data.description.value : this.description,
      notes: data.notes.present ? data.notes.value : this.notes,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      category: data.category.present ? data.category.value : this.category,
      splitMode: data.splitMode.present ? data.splitMode.value : this.splitMode,
      paidById: data.paidById.present ? data.paidById.value : this.paidById,
      tax: data.tax.present ? data.tax.value : this.tax,
      tip: data.tip.present ? data.tip.value : this.tip,
      receiptUrl:
          data.receiptUrl.present ? data.receiptUrl.value : this.receiptUrl,
      receiptLocalPath: data.receiptLocalPath.present
          ? data.receiptLocalPath.value
          : this.receiptLocalPath,
      spentAt: data.spentAt.present ? data.spentAt.value : this.spentAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('groupId: $groupId, ')
          ..write('description: $description, ')
          ..write('notes: $notes, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('splitMode: $splitMode, ')
          ..write('paidById: $paidById, ')
          ..write('tax: $tax, ')
          ..write('tip: $tip, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('receiptLocalPath: $receiptLocalPath, ')
          ..write('spentAt: $spentAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      serverId,
      groupId,
      description,
      notes,
      amount,
      currency,
      category,
      splitMode,
      paidById,
      tax,
      tip,
      receiptUrl,
      receiptLocalPath,
      spentAt,
      createdAt,
      updatedAt,
      deletedAt,
      dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.groupId == this.groupId &&
          other.description == this.description &&
          other.notes == this.notes &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.category == this.category &&
          other.splitMode == this.splitMode &&
          other.paidById == this.paidById &&
          other.tax == this.tax &&
          other.tip == this.tip &&
          other.receiptUrl == this.receiptUrl &&
          other.receiptLocalPath == this.receiptLocalPath &&
          other.spentAt == this.spentAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<String?> serverId;
  final Value<String> groupId;
  final Value<String> description;
  final Value<String> notes;
  final Value<double> amount;
  final Value<String> currency;
  final Value<String> category;
  final Value<String> splitMode;
  final Value<String?> paidById;
  final Value<double> tax;
  final Value<double> tip;
  final Value<String?> receiptUrl;
  final Value<String?> receiptLocalPath;
  final Value<DateTime?> spentAt;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.description = const Value.absent(),
    this.notes = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.category = const Value.absent(),
    this.splitMode = const Value.absent(),
    this.paidById = const Value.absent(),
    this.tax = const Value.absent(),
    this.tip = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.receiptLocalPath = const Value.absent(),
    this.spentAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    this.serverId = const Value.absent(),
    required String groupId,
    this.description = const Value.absent(),
    this.notes = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.category = const Value.absent(),
    this.splitMode = const Value.absent(),
    this.paidById = const Value.absent(),
    this.tax = const Value.absent(),
    this.tip = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.receiptLocalPath = const Value.absent(),
    this.spentAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? groupId,
    Expression<String>? description,
    Expression<String>? notes,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<String>? category,
    Expression<String>? splitMode,
    Expression<String>? paidById,
    Expression<double>? tax,
    Expression<double>? tip,
    Expression<String>? receiptUrl,
    Expression<String>? receiptLocalPath,
    Expression<DateTime>? spentAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (groupId != null) 'group_id': groupId,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (category != null) 'category': category,
      if (splitMode != null) 'split_mode': splitMode,
      if (paidById != null) 'paid_by_id': paidById,
      if (tax != null) 'tax': tax,
      if (tip != null) 'tip': tip,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (receiptLocalPath != null) 'receipt_local_path': receiptLocalPath,
      if (spentAt != null) 'spent_at': spentAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? serverId,
      Value<String>? groupId,
      Value<String>? description,
      Value<String>? notes,
      Value<double>? amount,
      Value<String>? currency,
      Value<String>? category,
      Value<String>? splitMode,
      Value<String?>? paidById,
      Value<double>? tax,
      Value<double>? tip,
      Value<String?>? receiptUrl,
      Value<String?>? receiptLocalPath,
      Value<DateTime?>? spentAt,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return ExpensesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      splitMode: splitMode ?? this.splitMode,
      paidById: paidById ?? this.paidById,
      tax: tax ?? this.tax,
      tip: tip ?? this.tip,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      receiptLocalPath: receiptLocalPath ?? this.receiptLocalPath,
      spentAt: spentAt ?? this.spentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (splitMode.present) {
      map['split_mode'] = Variable<String>(splitMode.value);
    }
    if (paidById.present) {
      map['paid_by_id'] = Variable<String>(paidById.value);
    }
    if (tax.present) {
      map['tax'] = Variable<double>(tax.value);
    }
    if (tip.present) {
      map['tip'] = Variable<double>(tip.value);
    }
    if (receiptUrl.present) {
      map['receipt_url'] = Variable<String>(receiptUrl.value);
    }
    if (receiptLocalPath.present) {
      map['receipt_local_path'] = Variable<String>(receiptLocalPath.value);
    }
    if (spentAt.present) {
      map['spent_at'] = Variable<DateTime>(spentAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('groupId: $groupId, ')
          ..write('description: $description, ')
          ..write('notes: $notes, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('splitMode: $splitMode, ')
          ..write('paidById: $paidById, ')
          ..write('tax: $tax, ')
          ..write('tip: $tip, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('receiptLocalPath: $receiptLocalPath, ')
          ..write('spentAt: $spentAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpenseSharesTable extends ExpenseShares
    with TableInfo<$ExpenseSharesTable, ExpenseShare> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseSharesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _expenseIdMeta =
      const VerificationMeta('expenseId');
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
      'expense_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [expenseId, userId, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_shares';
  @override
  VerificationContext validateIntegrity(Insertable<ExpenseShare> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('expense_id')) {
      context.handle(_expenseIdMeta,
          expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta));
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {expenseId, userId};
  @override
  ExpenseShare map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseShare(
      expenseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expense_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
    );
  }

  @override
  $ExpenseSharesTable createAlias(String alias) {
    return $ExpenseSharesTable(attachedDatabase, alias);
  }
}

class ExpenseShare extends DataClass implements Insertable<ExpenseShare> {
  final String expenseId;
  final String userId;
  final double amount;
  const ExpenseShare(
      {required this.expenseId, required this.userId, required this.amount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['expense_id'] = Variable<String>(expenseId);
    map['user_id'] = Variable<String>(userId);
    map['amount'] = Variable<double>(amount);
    return map;
  }

  ExpenseSharesCompanion toCompanion(bool nullToAbsent) {
    return ExpenseSharesCompanion(
      expenseId: Value(expenseId),
      userId: Value(userId),
      amount: Value(amount),
    );
  }

  factory ExpenseShare.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseShare(
      expenseId: serializer.fromJson<String>(json['expenseId']),
      userId: serializer.fromJson<String>(json['userId']),
      amount: serializer.fromJson<double>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'expenseId': serializer.toJson<String>(expenseId),
      'userId': serializer.toJson<String>(userId),
      'amount': serializer.toJson<double>(amount),
    };
  }

  ExpenseShare copyWith({String? expenseId, String? userId, double? amount}) =>
      ExpenseShare(
        expenseId: expenseId ?? this.expenseId,
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
      );
  ExpenseShare copyWithCompanion(ExpenseSharesCompanion data) {
    return ExpenseShare(
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      userId: data.userId.present ? data.userId.value : this.userId,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseShare(')
          ..write('expenseId: $expenseId, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(expenseId, userId, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseShare &&
          other.expenseId == this.expenseId &&
          other.userId == this.userId &&
          other.amount == this.amount);
}

class ExpenseSharesCompanion extends UpdateCompanion<ExpenseShare> {
  final Value<String> expenseId;
  final Value<String> userId;
  final Value<double> amount;
  final Value<int> rowid;
  const ExpenseSharesCompanion({
    this.expenseId = const Value.absent(),
    this.userId = const Value.absent(),
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseSharesCompanion.insert({
    required String expenseId,
    required String userId,
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : expenseId = Value(expenseId),
        userId = Value(userId);
  static Insertable<ExpenseShare> custom({
    Expression<String>? expenseId,
    Expression<String>? userId,
    Expression<double>? amount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (expenseId != null) 'expense_id': expenseId,
      if (userId != null) 'user_id': userId,
      if (amount != null) 'amount': amount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseSharesCompanion copyWith(
      {Value<String>? expenseId,
      Value<String>? userId,
      Value<double>? amount,
      Value<int>? rowid}) {
    return ExpenseSharesCompanion(
      expenseId: expenseId ?? this.expenseId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseSharesCompanion(')
          ..write('expenseId: $expenseId, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensePayersTable extends ExpensePayers
    with TableInfo<$ExpensePayersTable, ExpensePayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensePayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _expenseIdMeta =
      const VerificationMeta('expenseId');
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
      'expense_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [expenseId, userId, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_payers';
  @override
  VerificationContext validateIntegrity(Insertable<ExpensePayer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('expense_id')) {
      context.handle(_expenseIdMeta,
          expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta));
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {expenseId, userId};
  @override
  ExpensePayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpensePayer(
      expenseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expense_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
    );
  }

  @override
  $ExpensePayersTable createAlias(String alias) {
    return $ExpensePayersTable(attachedDatabase, alias);
  }
}

class ExpensePayer extends DataClass implements Insertable<ExpensePayer> {
  final String expenseId;
  final String userId;
  final double amount;
  const ExpensePayer(
      {required this.expenseId, required this.userId, required this.amount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['expense_id'] = Variable<String>(expenseId);
    map['user_id'] = Variable<String>(userId);
    map['amount'] = Variable<double>(amount);
    return map;
  }

  ExpensePayersCompanion toCompanion(bool nullToAbsent) {
    return ExpensePayersCompanion(
      expenseId: Value(expenseId),
      userId: Value(userId),
      amount: Value(amount),
    );
  }

  factory ExpensePayer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpensePayer(
      expenseId: serializer.fromJson<String>(json['expenseId']),
      userId: serializer.fromJson<String>(json['userId']),
      amount: serializer.fromJson<double>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'expenseId': serializer.toJson<String>(expenseId),
      'userId': serializer.toJson<String>(userId),
      'amount': serializer.toJson<double>(amount),
    };
  }

  ExpensePayer copyWith({String? expenseId, String? userId, double? amount}) =>
      ExpensePayer(
        expenseId: expenseId ?? this.expenseId,
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
      );
  ExpensePayer copyWithCompanion(ExpensePayersCompanion data) {
    return ExpensePayer(
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      userId: data.userId.present ? data.userId.value : this.userId,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpensePayer(')
          ..write('expenseId: $expenseId, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(expenseId, userId, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpensePayer &&
          other.expenseId == this.expenseId &&
          other.userId == this.userId &&
          other.amount == this.amount);
}

class ExpensePayersCompanion extends UpdateCompanion<ExpensePayer> {
  final Value<String> expenseId;
  final Value<String> userId;
  final Value<double> amount;
  final Value<int> rowid;
  const ExpensePayersCompanion({
    this.expenseId = const Value.absent(),
    this.userId = const Value.absent(),
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensePayersCompanion.insert({
    required String expenseId,
    required String userId,
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : expenseId = Value(expenseId),
        userId = Value(userId);
  static Insertable<ExpensePayer> custom({
    Expression<String>? expenseId,
    Expression<String>? userId,
    Expression<double>? amount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (expenseId != null) 'expense_id': expenseId,
      if (userId != null) 'user_id': userId,
      if (amount != null) 'amount': amount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensePayersCompanion copyWith(
      {Value<String>? expenseId,
      Value<String>? userId,
      Value<double>? amount,
      Value<int>? rowid}) {
    return ExpensePayersCompanion(
      expenseId: expenseId ?? this.expenseId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensePayersCompanion(')
          ..write('expenseId: $expenseId, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettlementsTable extends Settlements
    with TableInfo<$SettlementsTable, Settlement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettlementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fromUserIdMeta =
      const VerificationMeta('fromUserId');
  @override
  late final GeneratedColumn<String> fromUserId = GeneratedColumn<String>(
      'from_user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toUserIdMeta =
      const VerificationMeta('toUserId');
  @override
  late final GeneratedColumn<String> toUserId = GeneratedColumn<String>(
      'to_user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PKR'));
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _settledAtMeta =
      const VerificationMeta('settledAt');
  @override
  late final GeneratedColumn<DateTime> settledAt = GeneratedColumn<DateTime>(
      'settled_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        groupId,
        fromUserId,
        toUserId,
        amount,
        currency,
        method,
        note,
        settledAt,
        updatedAt,
        deletedAt,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settlements';
  @override
  VerificationContext validateIntegrity(Insertable<Settlement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('from_user_id')) {
      context.handle(
          _fromUserIdMeta,
          fromUserId.isAcceptableOrUnknown(
              data['from_user_id']!, _fromUserIdMeta));
    } else if (isInserting) {
      context.missing(_fromUserIdMeta);
    }
    if (data.containsKey('to_user_id')) {
      context.handle(_toUserIdMeta,
          toUserId.isAcceptableOrUnknown(data['to_user_id']!, _toUserIdMeta));
    } else if (isInserting) {
      context.missing(_toUserIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('settled_at')) {
      context.handle(_settledAtMeta,
          settledAt.isAcceptableOrUnknown(data['settled_at']!, _settledAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Settlement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Settlement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      fromUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_user_id'])!,
      toUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_user_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      settledAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}settled_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $SettlementsTable createAlias(String alias) {
    return $SettlementsTable(attachedDatabase, alias);
  }
}

class Settlement extends DataClass implements Insertable<Settlement> {
  final String id;
  final String? serverId;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String currency;
  final String method;
  final String note;
  final DateTime? settledAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const Settlement(
      {required this.id,
      this.serverId,
      required this.groupId,
      required this.fromUserId,
      required this.toUserId,
      required this.amount,
      required this.currency,
      required this.method,
      required this.note,
      this.settledAt,
      this.updatedAt,
      this.deletedAt,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['group_id'] = Variable<String>(groupId);
    map['from_user_id'] = Variable<String>(fromUserId);
    map['to_user_id'] = Variable<String>(toUserId);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['method'] = Variable<String>(method);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || settledAt != null) {
      map['settled_at'] = Variable<DateTime>(settledAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  SettlementsCompanion toCompanion(bool nullToAbsent) {
    return SettlementsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      groupId: Value(groupId),
      fromUserId: Value(fromUserId),
      toUserId: Value(toUserId),
      amount: Value(amount),
      currency: Value(currency),
      method: Value(method),
      note: Value(note),
      settledAt: settledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(settledAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory Settlement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Settlement(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      fromUserId: serializer.fromJson<String>(json['fromUserId']),
      toUserId: serializer.fromJson<String>(json['toUserId']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      method: serializer.fromJson<String>(json['method']),
      note: serializer.fromJson<String>(json['note']),
      settledAt: serializer.fromJson<DateTime?>(json['settledAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'groupId': serializer.toJson<String>(groupId),
      'fromUserId': serializer.toJson<String>(fromUserId),
      'toUserId': serializer.toJson<String>(toUserId),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'method': serializer.toJson<String>(method),
      'note': serializer.toJson<String>(note),
      'settledAt': serializer.toJson<DateTime?>(settledAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Settlement copyWith(
          {String? id,
          Value<String?> serverId = const Value.absent(),
          String? groupId,
          String? fromUserId,
          String? toUserId,
          double? amount,
          String? currency,
          String? method,
          String? note,
          Value<DateTime?> settledAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? dirty}) =>
      Settlement(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        groupId: groupId ?? this.groupId,
        fromUserId: fromUserId ?? this.fromUserId,
        toUserId: toUserId ?? this.toUserId,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        method: method ?? this.method,
        note: note ?? this.note,
        settledAt: settledAt.present ? settledAt.value : this.settledAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        dirty: dirty ?? this.dirty,
      );
  Settlement copyWithCompanion(SettlementsCompanion data) {
    return Settlement(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      fromUserId:
          data.fromUserId.present ? data.fromUserId.value : this.fromUserId,
      toUserId: data.toUserId.present ? data.toUserId.value : this.toUserId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      method: data.method.present ? data.method.value : this.method,
      note: data.note.present ? data.note.value : this.note,
      settledAt: data.settledAt.present ? data.settledAt.value : this.settledAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Settlement(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('groupId: $groupId, ')
          ..write('fromUserId: $fromUserId, ')
          ..write('toUserId: $toUserId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('method: $method, ')
          ..write('note: $note, ')
          ..write('settledAt: $settledAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serverId, groupId, fromUserId, toUserId,
      amount, currency, method, note, settledAt, updatedAt, deletedAt, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Settlement &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.groupId == this.groupId &&
          other.fromUserId == this.fromUserId &&
          other.toUserId == this.toUserId &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.method == this.method &&
          other.note == this.note &&
          other.settledAt == this.settledAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class SettlementsCompanion extends UpdateCompanion<Settlement> {
  final Value<String> id;
  final Value<String?> serverId;
  final Value<String> groupId;
  final Value<String> fromUserId;
  final Value<String> toUserId;
  final Value<double> amount;
  final Value<String> currency;
  final Value<String> method;
  final Value<String> note;
  final Value<DateTime?> settledAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const SettlementsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.fromUserId = const Value.absent(),
    this.toUserId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.method = const Value.absent(),
    this.note = const Value.absent(),
    this.settledAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettlementsCompanion.insert({
    required String id,
    this.serverId = const Value.absent(),
    required String groupId,
    required String fromUserId,
    required String toUserId,
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.method = const Value.absent(),
    this.note = const Value.absent(),
    this.settledAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId),
        fromUserId = Value(fromUserId),
        toUserId = Value(toUserId);
  static Insertable<Settlement> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? groupId,
    Expression<String>? fromUserId,
    Expression<String>? toUserId,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<String>? method,
    Expression<String>? note,
    Expression<DateTime>? settledAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (groupId != null) 'group_id': groupId,
      if (fromUserId != null) 'from_user_id': fromUserId,
      if (toUserId != null) 'to_user_id': toUserId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (method != null) 'method': method,
      if (note != null) 'note': note,
      if (settledAt != null) 'settled_at': settledAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettlementsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? serverId,
      Value<String>? groupId,
      Value<String>? fromUserId,
      Value<String>? toUserId,
      Value<double>? amount,
      Value<String>? currency,
      Value<String>? method,
      Value<String>? note,
      Value<DateTime?>? settledAt,
      Value<DateTime?>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return SettlementsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      groupId: groupId ?? this.groupId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      method: method ?? this.method,
      note: note ?? this.note,
      settledAt: settledAt ?? this.settledAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (fromUserId.present) {
      map['from_user_id'] = Variable<String>(fromUserId.value);
    }
    if (toUserId.present) {
      map['to_user_id'] = Variable<String>(toUserId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (settledAt.present) {
      map['settled_at'] = Variable<DateTime>(settledAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettlementsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('groupId: $groupId, ')
          ..write('fromUserId: $fromUserId, ')
          ..write('toUserId: $toUserId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('method: $method, ')
          ..write('note: $note, ')
          ..write('settledAt: $settledAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonalExpensesTable extends PersonalExpenses
    with TableInfo<$PersonalExpensesTable, PersonalExpense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PKR'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('other'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _receiptUrlMeta =
      const VerificationMeta('receiptUrl');
  @override
  late final GeneratedColumn<String> receiptUrl = GeneratedColumn<String>(
      'receipt_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        description,
        amount,
        currency,
        category,
        date,
        note,
        receiptUrl,
        updatedAt,
        deletedAt,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_expenses';
  @override
  VerificationContext validateIntegrity(Insertable<PersonalExpense> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('receipt_url')) {
      context.handle(
          _receiptUrlMeta,
          receiptUrl.isAcceptableOrUnknown(
              data['receipt_url']!, _receiptUrlMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonalExpense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalExpense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      receiptUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_url']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $PersonalExpensesTable createAlias(String alias) {
    return $PersonalExpensesTable(attachedDatabase, alias);
  }
}

class PersonalExpense extends DataClass implements Insertable<PersonalExpense> {
  final String id;
  final String? serverId;
  final String description;
  final double amount;
  final String currency;
  final String category;
  final DateTime? date;
  final String note;
  final String? receiptUrl;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const PersonalExpense(
      {required this.id,
      this.serverId,
      required this.description,
      required this.amount,
      required this.currency,
      required this.category,
      this.date,
      required this.note,
      this.receiptUrl,
      this.updatedAt,
      this.deletedAt,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['description'] = Variable<String>(description);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<DateTime>(date);
    }
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || receiptUrl != null) {
      map['receipt_url'] = Variable<String>(receiptUrl);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  PersonalExpensesCompanion toCompanion(bool nullToAbsent) {
    return PersonalExpensesCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      description: Value(description),
      amount: Value(amount),
      currency: Value(currency),
      category: Value(category),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      note: Value(note),
      receiptUrl: receiptUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptUrl),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory PersonalExpense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalExpense(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      description: serializer.fromJson<String>(json['description']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      category: serializer.fromJson<String>(json['category']),
      date: serializer.fromJson<DateTime?>(json['date']),
      note: serializer.fromJson<String>(json['note']),
      receiptUrl: serializer.fromJson<String?>(json['receiptUrl']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'description': serializer.toJson<String>(description),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'category': serializer.toJson<String>(category),
      'date': serializer.toJson<DateTime?>(date),
      'note': serializer.toJson<String>(note),
      'receiptUrl': serializer.toJson<String?>(receiptUrl),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  PersonalExpense copyWith(
          {String? id,
          Value<String?> serverId = const Value.absent(),
          String? description,
          double? amount,
          String? currency,
          String? category,
          Value<DateTime?> date = const Value.absent(),
          String? note,
          Value<String?> receiptUrl = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? dirty}) =>
      PersonalExpense(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        category: category ?? this.category,
        date: date.present ? date.value : this.date,
        note: note ?? this.note,
        receiptUrl: receiptUrl.present ? receiptUrl.value : this.receiptUrl,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        dirty: dirty ?? this.dirty,
      );
  PersonalExpense copyWithCompanion(PersonalExpensesCompanion data) {
    return PersonalExpense(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      description:
          data.description.present ? data.description.value : this.description,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      category: data.category.present ? data.category.value : this.category,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      receiptUrl:
          data.receiptUrl.present ? data.receiptUrl.value : this.receiptUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalExpense(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serverId, description, amount, currency,
      category, date, note, receiptUrl, updatedAt, deletedAt, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalExpense &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.description == this.description &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.category == this.category &&
          other.date == this.date &&
          other.note == this.note &&
          other.receiptUrl == this.receiptUrl &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class PersonalExpensesCompanion extends UpdateCompanion<PersonalExpense> {
  final Value<String> id;
  final Value<String?> serverId;
  final Value<String> description;
  final Value<double> amount;
  final Value<String> currency;
  final Value<String> category;
  final Value<DateTime?> date;
  final Value<String> note;
  final Value<String?> receiptUrl;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const PersonalExpensesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.category = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonalExpensesCompanion.insert({
    required String id,
    this.serverId = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.category = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<PersonalExpense> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? description,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<String>? category,
    Expression<DateTime>? date,
    Expression<String>? note,
    Expression<String>? receiptUrl,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (category != null) 'category': category,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonalExpensesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? serverId,
      Value<String>? description,
      Value<double>? amount,
      Value<String>? currency,
      Value<String>? category,
      Value<DateTime?>? date,
      Value<String>? note,
      Value<String?>? receiptUrl,
      Value<DateTime?>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return PersonalExpensesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (receiptUrl.present) {
      map['receipt_url'] = Variable<String>(receiptUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalExpensesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
      'emoji', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('🎯'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('other'));
  static const VerificationMeta _targetAmountMeta =
      const VerificationMeta('targetAmount');
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
      'target_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _savedAmountMeta =
      const VerificationMeta('savedAmount');
  @override
  late final GeneratedColumn<double> savedAmount = GeneratedColumn<double>(
      'saved_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PKR'));
  static const VerificationMeta _targetDateMeta =
      const VerificationMeta('targetDate');
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
      'target_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
      'priority', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('medium'));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#6C5CE7'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _contributionsJsonMeta =
      const VerificationMeta('contributionsJson');
  @override
  late final GeneratedColumn<String> contributionsJson =
      GeneratedColumn<String>('contributions_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        title,
        description,
        emoji,
        category,
        targetAmount,
        savedAmount,
        currency,
        targetDate,
        status,
        priority,
        color,
        notes,
        contributionsJson,
        updatedAt,
        deletedAt,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<Goal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('emoji')) {
      context.handle(
          _emojiMeta, emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('target_amount')) {
      context.handle(
          _targetAmountMeta,
          targetAmount.isAcceptableOrUnknown(
              data['target_amount']!, _targetAmountMeta));
    }
    if (data.containsKey('saved_amount')) {
      context.handle(
          _savedAmountMeta,
          savedAmount.isAcceptableOrUnknown(
              data['saved_amount']!, _savedAmountMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('target_date')) {
      context.handle(
          _targetDateMeta,
          targetDate.isAcceptableOrUnknown(
              data['target_date']!, _targetDateMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('contributions_json')) {
      context.handle(
          _contributionsJsonMeta,
          contributionsJson.isAcceptableOrUnknown(
              data['contributions_json']!, _contributionsJsonMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      emoji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      targetAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_amount'])!,
      savedAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}saved_amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      targetDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}target_date']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      contributionsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}contributions_json']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final String id;
  final String? serverId;
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
  final String? contributionsJson;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const Goal(
      {required this.id,
      this.serverId,
      required this.title,
      required this.description,
      required this.emoji,
      required this.category,
      required this.targetAmount,
      required this.savedAmount,
      required this.currency,
      this.targetDate,
      required this.status,
      required this.priority,
      required this.color,
      required this.notes,
      this.contributionsJson,
      this.updatedAt,
      this.deletedAt,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['emoji'] = Variable<String>(emoji);
    map['category'] = Variable<String>(category);
    map['target_amount'] = Variable<double>(targetAmount);
    map['saved_amount'] = Variable<double>(savedAmount);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<String>(priority);
    map['color'] = Variable<String>(color);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || contributionsJson != null) {
      map['contributions_json'] = Variable<String>(contributionsJson);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      title: Value(title),
      description: Value(description),
      emoji: Value(emoji),
      category: Value(category),
      targetAmount: Value(targetAmount),
      savedAmount: Value(savedAmount),
      currency: Value(currency),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      status: Value(status),
      priority: Value(priority),
      color: Value(color),
      notes: Value(notes),
      contributionsJson: contributionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(contributionsJson),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      emoji: serializer.fromJson<String>(json['emoji']),
      category: serializer.fromJson<String>(json['category']),
      targetAmount: serializer.fromJson<double>(json['targetAmount']),
      savedAmount: serializer.fromJson<double>(json['savedAmount']),
      currency: serializer.fromJson<String>(json['currency']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<String>(json['priority']),
      color: serializer.fromJson<String>(json['color']),
      notes: serializer.fromJson<String>(json['notes']),
      contributionsJson:
          serializer.fromJson<String?>(json['contributionsJson']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'emoji': serializer.toJson<String>(emoji),
      'category': serializer.toJson<String>(category),
      'targetAmount': serializer.toJson<double>(targetAmount),
      'savedAmount': serializer.toJson<double>(savedAmount),
      'currency': serializer.toJson<String>(currency),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<String>(priority),
      'color': serializer.toJson<String>(color),
      'notes': serializer.toJson<String>(notes),
      'contributionsJson': serializer.toJson<String?>(contributionsJson),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Goal copyWith(
          {String? id,
          Value<String?> serverId = const Value.absent(),
          String? title,
          String? description,
          String? emoji,
          String? category,
          double? targetAmount,
          double? savedAmount,
          String? currency,
          Value<DateTime?> targetDate = const Value.absent(),
          String? status,
          String? priority,
          String? color,
          String? notes,
          Value<String?> contributionsJson = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? dirty}) =>
      Goal(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        title: title ?? this.title,
        description: description ?? this.description,
        emoji: emoji ?? this.emoji,
        category: category ?? this.category,
        targetAmount: targetAmount ?? this.targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        currency: currency ?? this.currency,
        targetDate: targetDate.present ? targetDate.value : this.targetDate,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        color: color ?? this.color,
        notes: notes ?? this.notes,
        contributionsJson: contributionsJson.present
            ? contributionsJson.value
            : this.contributionsJson,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        dirty: dirty ?? this.dirty,
      );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      category: data.category.present ? data.category.value : this.category,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      savedAmount:
          data.savedAmount.present ? data.savedAmount.value : this.savedAmount,
      currency: data.currency.present ? data.currency.value : this.currency,
      targetDate:
          data.targetDate.present ? data.targetDate.value : this.targetDate,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      color: data.color.present ? data.color.value : this.color,
      notes: data.notes.present ? data.notes.value : this.notes,
      contributionsJson: data.contributionsJson.present
          ? data.contributionsJson.value
          : this.contributionsJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('emoji: $emoji, ')
          ..write('category: $category, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('savedAmount: $savedAmount, ')
          ..write('currency: $currency, ')
          ..write('targetDate: $targetDate, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('color: $color, ')
          ..write('notes: $notes, ')
          ..write('contributionsJson: $contributionsJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      serverId,
      title,
      description,
      emoji,
      category,
      targetAmount,
      savedAmount,
      currency,
      targetDate,
      status,
      priority,
      color,
      notes,
      contributionsJson,
      updatedAt,
      deletedAt,
      dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.title == this.title &&
          other.description == this.description &&
          other.emoji == this.emoji &&
          other.category == this.category &&
          other.targetAmount == this.targetAmount &&
          other.savedAmount == this.savedAmount &&
          other.currency == this.currency &&
          other.targetDate == this.targetDate &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.color == this.color &&
          other.notes == this.notes &&
          other.contributionsJson == this.contributionsJson &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<String?> serverId;
  final Value<String> title;
  final Value<String> description;
  final Value<String> emoji;
  final Value<String> category;
  final Value<double> targetAmount;
  final Value<double> savedAmount;
  final Value<String> currency;
  final Value<DateTime?> targetDate;
  final Value<String> status;
  final Value<String> priority;
  final Value<String> color;
  final Value<String> notes;
  final Value<String?> contributionsJson;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.emoji = const Value.absent(),
    this.category = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.savedAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.color = const Value.absent(),
    this.notes = const Value.absent(),
    this.contributionsJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    this.serverId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.emoji = const Value.absent(),
    this.category = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.savedAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.color = const Value.absent(),
    this.notes = const Value.absent(),
    this.contributionsJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? emoji,
    Expression<String>? category,
    Expression<double>? targetAmount,
    Expression<double>? savedAmount,
    Expression<String>? currency,
    Expression<DateTime>? targetDate,
    Expression<String>? status,
    Expression<String>? priority,
    Expression<String>? color,
    Expression<String>? notes,
    Expression<String>? contributionsJson,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (emoji != null) 'emoji': emoji,
      if (category != null) 'category': category,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (savedAmount != null) 'saved_amount': savedAmount,
      if (currency != null) 'currency': currency,
      if (targetDate != null) 'target_date': targetDate,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (color != null) 'color': color,
      if (notes != null) 'notes': notes,
      if (contributionsJson != null) 'contributions_json': contributionsJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? serverId,
      Value<String>? title,
      Value<String>? description,
      Value<String>? emoji,
      Value<String>? category,
      Value<double>? targetAmount,
      Value<double>? savedAmount,
      Value<String>? currency,
      Value<DateTime?>? targetDate,
      Value<String>? status,
      Value<String>? priority,
      Value<String>? color,
      Value<String>? notes,
      Value<String?>? contributionsJson,
      Value<DateTime?>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return GoalsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      currency: currency ?? this.currency,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      contributionsJson: contributionsJson ?? this.contributionsJson,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    if (savedAmount.present) {
      map['saved_amount'] = Variable<double>(savedAmount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (contributionsJson.present) {
      map['contributions_json'] = Variable<String>(contributionsJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('emoji: $emoji, ')
          ..write('category: $category, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('savedAmount: $savedAmount, ')
          ..write('currency: $currency, ')
          ..write('targetDate: $targetDate, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('color: $color, ')
          ..write('notes: $notes, ')
          ..write('contributionsJson: $contributionsJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivitiesTable extends Activities
    with TableInfo<$ActivitiesTable, Activity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('event'));
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _actorIdMeta =
      const VerificationMeta('actorId');
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
      'actor_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actorNameMeta =
      const VerificationMeta('actorName');
  @override
  late final GeneratedColumn<String> actorName = GeneratedColumn<String>(
      'actor_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actorAvatarMeta =
      const VerificationMeta('actorAvatar');
  @override
  late final GeneratedColumn<String> actorAvatar = GeneratedColumn<String>(
      'actor_avatar', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _groupNameMeta =
      const VerificationMeta('groupName');
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
      'group_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _groupColorMeta =
      const VerificationMeta('groupColor');
  @override
  late final GeneratedColumn<String> groupColor = GeneratedColumn<String>(
      'group_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        groupId,
        type,
        message,
        actorId,
        actorName,
        actorAvatar,
        groupName,
        groupColor,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(Insertable<Activity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    }
    if (data.containsKey('actor_id')) {
      context.handle(_actorIdMeta,
          actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta));
    }
    if (data.containsKey('actor_name')) {
      context.handle(_actorNameMeta,
          actorName.isAcceptableOrUnknown(data['actor_name']!, _actorNameMeta));
    }
    if (data.containsKey('actor_avatar')) {
      context.handle(
          _actorAvatarMeta,
          actorAvatar.isAcceptableOrUnknown(
              data['actor_avatar']!, _actorAvatarMeta));
    }
    if (data.containsKey('group_name')) {
      context.handle(_groupNameMeta,
          groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta));
    }
    if (data.containsKey('group_color')) {
      context.handle(
          _groupColorMeta,
          groupColor.isAcceptableOrUnknown(
              data['group_color']!, _groupColorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Activity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Activity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message'])!,
      actorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}actor_id']),
      actorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}actor_name']),
      actorAvatar: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}actor_avatar']),
      groupName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_name']),
      groupColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_color']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }
}

class Activity extends DataClass implements Insertable<Activity> {
  final String id;
  final String? groupId;
  final String type;
  final String message;
  final String? actorId;
  final String? actorName;
  final String? actorAvatar;
  final String? groupName;
  final String? groupColor;
  final DateTime? createdAt;
  const Activity(
      {required this.id,
      this.groupId,
      required this.type,
      required this.message,
      this.actorId,
      this.actorName,
      this.actorAvatar,
      this.groupName,
      this.groupColor,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    map['type'] = Variable<String>(type);
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || actorId != null) {
      map['actor_id'] = Variable<String>(actorId);
    }
    if (!nullToAbsent || actorName != null) {
      map['actor_name'] = Variable<String>(actorName);
    }
    if (!nullToAbsent || actorAvatar != null) {
      map['actor_avatar'] = Variable<String>(actorAvatar);
    }
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    if (!nullToAbsent || groupColor != null) {
      map['group_color'] = Variable<String>(groupColor);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      type: Value(type),
      message: Value(message),
      actorId: actorId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorId),
      actorName: actorName == null && nullToAbsent
          ? const Value.absent()
          : Value(actorName),
      actorAvatar: actorAvatar == null && nullToAbsent
          ? const Value.absent()
          : Value(actorAvatar),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
      groupColor: groupColor == null && nullToAbsent
          ? const Value.absent()
          : Value(groupColor),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Activity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Activity(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      type: serializer.fromJson<String>(json['type']),
      message: serializer.fromJson<String>(json['message']),
      actorId: serializer.fromJson<String?>(json['actorId']),
      actorName: serializer.fromJson<String?>(json['actorName']),
      actorAvatar: serializer.fromJson<String?>(json['actorAvatar']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      groupColor: serializer.fromJson<String?>(json['groupColor']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String?>(groupId),
      'type': serializer.toJson<String>(type),
      'message': serializer.toJson<String>(message),
      'actorId': serializer.toJson<String?>(actorId),
      'actorName': serializer.toJson<String?>(actorName),
      'actorAvatar': serializer.toJson<String?>(actorAvatar),
      'groupName': serializer.toJson<String?>(groupName),
      'groupColor': serializer.toJson<String?>(groupColor),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  Activity copyWith(
          {String? id,
          Value<String?> groupId = const Value.absent(),
          String? type,
          String? message,
          Value<String?> actorId = const Value.absent(),
          Value<String?> actorName = const Value.absent(),
          Value<String?> actorAvatar = const Value.absent(),
          Value<String?> groupName = const Value.absent(),
          Value<String?> groupColor = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent()}) =>
      Activity(
        id: id ?? this.id,
        groupId: groupId.present ? groupId.value : this.groupId,
        type: type ?? this.type,
        message: message ?? this.message,
        actorId: actorId.present ? actorId.value : this.actorId,
        actorName: actorName.present ? actorName.value : this.actorName,
        actorAvatar: actorAvatar.present ? actorAvatar.value : this.actorAvatar,
        groupName: groupName.present ? groupName.value : this.groupName,
        groupColor: groupColor.present ? groupColor.value : this.groupColor,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  Activity copyWithCompanion(ActivitiesCompanion data) {
    return Activity(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      type: data.type.present ? data.type.value : this.type,
      message: data.message.present ? data.message.value : this.message,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      actorName: data.actorName.present ? data.actorName.value : this.actorName,
      actorAvatar:
          data.actorAvatar.present ? data.actorAvatar.value : this.actorAvatar,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      groupColor:
          data.groupColor.present ? data.groupColor.value : this.groupColor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Activity(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('type: $type, ')
          ..write('message: $message, ')
          ..write('actorId: $actorId, ')
          ..write('actorName: $actorName, ')
          ..write('actorAvatar: $actorAvatar, ')
          ..write('groupName: $groupName, ')
          ..write('groupColor: $groupColor, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, type, message, actorId,
      actorName, actorAvatar, groupName, groupColor, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Activity &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.type == this.type &&
          other.message == this.message &&
          other.actorId == this.actorId &&
          other.actorName == this.actorName &&
          other.actorAvatar == this.actorAvatar &&
          other.groupName == this.groupName &&
          other.groupColor == this.groupColor &&
          other.createdAt == this.createdAt);
}

class ActivitiesCompanion extends UpdateCompanion<Activity> {
  final Value<String> id;
  final Value<String?> groupId;
  final Value<String> type;
  final Value<String> message;
  final Value<String?> actorId;
  final Value<String?> actorName;
  final Value<String?> actorAvatar;
  final Value<String?> groupName;
  final Value<String?> groupColor;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.type = const Value.absent(),
    this.message = const Value.absent(),
    this.actorId = const Value.absent(),
    this.actorName = const Value.absent(),
    this.actorAvatar = const Value.absent(),
    this.groupName = const Value.absent(),
    this.groupColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    required String id,
    this.groupId = const Value.absent(),
    this.type = const Value.absent(),
    this.message = const Value.absent(),
    this.actorId = const Value.absent(),
    this.actorName = const Value.absent(),
    this.actorAvatar = const Value.absent(),
    this.groupName = const Value.absent(),
    this.groupColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Activity> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? type,
    Expression<String>? message,
    Expression<String>? actorId,
    Expression<String>? actorName,
    Expression<String>? actorAvatar,
    Expression<String>? groupName,
    Expression<String>? groupColor,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (type != null) 'type': type,
      if (message != null) 'message': message,
      if (actorId != null) 'actor_id': actorId,
      if (actorName != null) 'actor_name': actorName,
      if (actorAvatar != null) 'actor_avatar': actorAvatar,
      if (groupName != null) 'group_name': groupName,
      if (groupColor != null) 'group_color': groupColor,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivitiesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? groupId,
      Value<String>? type,
      Value<String>? message,
      Value<String?>? actorId,
      Value<String?>? actorName,
      Value<String?>? actorAvatar,
      Value<String?>? groupName,
      Value<String?>? groupColor,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      message: message ?? this.message,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorAvatar: actorAvatar ?? this.actorAvatar,
      groupName: groupName ?? this.groupName,
      groupColor: groupColor ?? this.groupColor,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (actorName.present) {
      map['actor_name'] = Variable<String>(actorName.value);
    }
    if (actorAvatar.present) {
      map['actor_avatar'] = Variable<String>(actorAvatar.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (groupColor.present) {
      map['group_color'] = Variable<String>(groupColor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('type: $type, ')
          ..write('message: $message, ')
          ..write('actorId: $actorId, ')
          ..write('actorName: $actorName, ')
          ..write('actorAvatar: $actorAvatar, ')
          ..write('groupName: $groupName, ')
          ..write('groupColor: $groupColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReactionsTable extends Reactions
    with TableInfo<$ReactionsTable, Reaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _targetTypeMeta =
      const VerificationMeta('targetType');
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
      'target_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetIdMeta =
      const VerificationMeta('targetId');
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
      'target_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
      'emoji', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userNameMeta =
      const VerificationMeta('userName');
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
      'user_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userAvatarMeta =
      const VerificationMeta('userAvatar');
  @override
  late final GeneratedColumn<String> userAvatar = GeneratedColumn<String>(
      'user_avatar', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [targetType, targetId, emoji, userId, userName, userAvatar];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reactions';
  @override
  VerificationContext validateIntegrity(Insertable<Reaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('target_type')) {
      context.handle(
          _targetTypeMeta,
          targetType.isAcceptableOrUnknown(
              data['target_type']!, _targetTypeMeta));
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(_targetIdMeta,
          targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta));
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
          _emojiMeta, emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta));
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('user_name')) {
      context.handle(_userNameMeta,
          userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta));
    }
    if (data.containsKey('user_avatar')) {
      context.handle(
          _userAvatarMeta,
          userAvatar.isAcceptableOrUnknown(
              data['user_avatar']!, _userAvatarMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {targetType, targetId, emoji, userId};
  @override
  Reaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reaction(
      targetType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_type'])!,
      targetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_id'])!,
      emoji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      userName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_name']),
      userAvatar: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_avatar']),
    );
  }

  @override
  $ReactionsTable createAlias(String alias) {
    return $ReactionsTable(attachedDatabase, alias);
  }
}

class Reaction extends DataClass implements Insertable<Reaction> {
  final String targetType;
  final String targetId;
  final String emoji;
  final String userId;
  final String? userName;
  final String? userAvatar;
  const Reaction(
      {required this.targetType,
      required this.targetId,
      required this.emoji,
      required this.userId,
      this.userName,
      this.userAvatar});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['target_type'] = Variable<String>(targetType);
    map['target_id'] = Variable<String>(targetId);
    map['emoji'] = Variable<String>(emoji);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || userName != null) {
      map['user_name'] = Variable<String>(userName);
    }
    if (!nullToAbsent || userAvatar != null) {
      map['user_avatar'] = Variable<String>(userAvatar);
    }
    return map;
  }

  ReactionsCompanion toCompanion(bool nullToAbsent) {
    return ReactionsCompanion(
      targetType: Value(targetType),
      targetId: Value(targetId),
      emoji: Value(emoji),
      userId: Value(userId),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
      userAvatar: userAvatar == null && nullToAbsent
          ? const Value.absent()
          : Value(userAvatar),
    );
  }

  factory Reaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reaction(
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<String>(json['targetId']),
      emoji: serializer.fromJson<String>(json['emoji']),
      userId: serializer.fromJson<String>(json['userId']),
      userName: serializer.fromJson<String?>(json['userName']),
      userAvatar: serializer.fromJson<String?>(json['userAvatar']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<String>(targetId),
      'emoji': serializer.toJson<String>(emoji),
      'userId': serializer.toJson<String>(userId),
      'userName': serializer.toJson<String?>(userName),
      'userAvatar': serializer.toJson<String?>(userAvatar),
    };
  }

  Reaction copyWith(
          {String? targetType,
          String? targetId,
          String? emoji,
          String? userId,
          Value<String?> userName = const Value.absent(),
          Value<String?> userAvatar = const Value.absent()}) =>
      Reaction(
        targetType: targetType ?? this.targetType,
        targetId: targetId ?? this.targetId,
        emoji: emoji ?? this.emoji,
        userId: userId ?? this.userId,
        userName: userName.present ? userName.value : this.userName,
        userAvatar: userAvatar.present ? userAvatar.value : this.userAvatar,
      );
  Reaction copyWithCompanion(ReactionsCompanion data) {
    return Reaction(
      targetType:
          data.targetType.present ? data.targetType.value : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      userId: data.userId.present ? data.userId.value : this.userId,
      userName: data.userName.present ? data.userName.value : this.userName,
      userAvatar:
          data.userAvatar.present ? data.userAvatar.value : this.userAvatar,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reaction(')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('emoji: $emoji, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('userAvatar: $userAvatar')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(targetType, targetId, emoji, userId, userName, userAvatar);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reaction &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.emoji == this.emoji &&
          other.userId == this.userId &&
          other.userName == this.userName &&
          other.userAvatar == this.userAvatar);
}

class ReactionsCompanion extends UpdateCompanion<Reaction> {
  final Value<String> targetType;
  final Value<String> targetId;
  final Value<String> emoji;
  final Value<String> userId;
  final Value<String?> userName;
  final Value<String?> userAvatar;
  final Value<int> rowid;
  const ReactionsCompanion({
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.emoji = const Value.absent(),
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    this.userAvatar = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReactionsCompanion.insert({
    required String targetType,
    required String targetId,
    required String emoji,
    required String userId,
    this.userName = const Value.absent(),
    this.userAvatar = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : targetType = Value(targetType),
        targetId = Value(targetId),
        emoji = Value(emoji),
        userId = Value(userId);
  static Insertable<Reaction> custom({
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<String>? emoji,
    Expression<String>? userId,
    Expression<String>? userName,
    Expression<String>? userAvatar,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (emoji != null) 'emoji': emoji,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (userAvatar != null) 'user_avatar': userAvatar,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReactionsCompanion copyWith(
      {Value<String>? targetType,
      Value<String>? targetId,
      Value<String>? emoji,
      Value<String>? userId,
      Value<String?>? userName,
      Value<String?>? userAvatar,
      Value<int>? rowid}) {
    return ReactionsCompanion(
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      emoji: emoji ?? this.emoji,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (userAvatar.present) {
      map['user_avatar'] = Variable<String>(userAvatar.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReactionsCompanion(')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('emoji: $emoji, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('userAvatar: $userAvatar, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GuestContactsTable extends GuestContacts
    with TableInfo<$GuestContactsTable, GuestContact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GuestContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _avatarColorMeta =
      const VerificationMeta('avatarColor');
  @override
  late final GeneratedColumn<String> avatarColor = GeneratedColumn<String>(
      'avatar_color', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#6C5CE7'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, phone, email, avatarColor, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'guest_contacts';
  @override
  VerificationContext validateIntegrity(Insertable<GuestContact> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('avatar_color')) {
      context.handle(
          _avatarColorMeta,
          avatarColor.isAcceptableOrUnknown(
              data['avatar_color']!, _avatarColorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
          _createdAtMeta,
          createdAt.isAcceptableOrUnknown(
              data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GuestContact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GuestContact(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      avatarColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_color'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $GuestContactsTable createAlias(String alias) {
    return $GuestContactsTable(attachedDatabase, alias);
  }
}

class GuestContact extends DataClass implements Insertable<GuestContact> {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String avatarColor;
  final DateTime? createdAt;
  const GuestContact(
      {required this.id,
      required this.name,
      this.phone,
      this.email,
      required this.avatarColor,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['avatar_color'] = Variable<String>(avatarColor);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  GuestContactsCompanion toCompanion(bool nullToAbsent) {
    return GuestContactsCompanion(
      id: Value(id),
      name: Value(name),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      avatarColor: Value(avatarColor),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory GuestContact.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GuestContact(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      avatarColor: serializer.fromJson<String>(json['avatarColor']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'avatarColor': serializer.toJson<String>(avatarColor),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  GuestContact copyWith(
          {String? id,
          String? name,
          Value<String?> phone = const Value.absent(),
          Value<String?> email = const Value.absent(),
          String? avatarColor,
          Value<DateTime?> createdAt = const Value.absent()}) =>
      GuestContact(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone.present ? phone.value : this.phone,
        email: email.present ? email.value : this.email,
        avatarColor: avatarColor ?? this.avatarColor,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  GuestContact copyWithCompanion(GuestContactsCompanion data) {
    return GuestContact(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      avatarColor:
          data.avatarColor.present ? data.avatarColor.value : this.avatarColor,
      createdAt:
          data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GuestContact(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, phone, email, avatarColor, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GuestContact &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.avatarColor == this.avatarColor &&
          other.createdAt == this.createdAt);
}

class GuestContactsCompanion extends UpdateCompanion<GuestContact> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String> avatarColor;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const GuestContactsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GuestContactsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<GuestContact> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? avatarColor,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (avatarColor != null) 'avatar_color': avatarColor,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GuestContactsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? phone,
      Value<String?>? email,
      Value<String>? avatarColor,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return GuestContactsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarColor: avatarColor ?? this.avatarColor,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (avatarColor.present) {
      map['avatar_color'] = Variable<String>(avatarColor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GuestContactsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoansTable extends Loans with TableInfo<$LoansTable, Loan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _counterpartyIdMeta =
      const VerificationMeta('counterpartyId');
  @override
  late final GeneratedColumn<String> counterpartyId = GeneratedColumn<String>(
      'counterparty_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _counterpartyTypeMeta =
      const VerificationMeta('counterpartyType');
  @override
  late final GeneratedColumn<String> counterpartyType = GeneratedColumn<String>(
      'counterparty_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('guest'));
  static const VerificationMeta _counterpartyNameMeta =
      const VerificationMeta('counterpartyName');
  @override
  late final GeneratedColumn<String> counterpartyName = GeneratedColumn<String>(
      'counterparty_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _counterpartyAvatarMeta =
      const VerificationMeta('counterpartyAvatar');
  @override
  late final GeneratedColumn<String> counterpartyAvatar =
      GeneratedColumn<String>('counterparty_avatar', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _loanTypeMeta =
      const VerificationMeta('loanType');
  @override
  late final GeneratedColumn<String> loanType = GeneratedColumn<String>(
      'loan_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('given'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _paidAmountMeta =
      const VerificationMeta('paidAmount');
  @override
  late final GeneratedColumn<double> paidAmount = GeneratedColumn<double>(
      'paid_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PKR'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        counterpartyId,
        counterpartyType,
        counterpartyName,
        counterpartyAvatar,
        loanType,
        amount,
        paidAmount,
        currency,
        description,
        notes,
        dueDate,
        status,
        createdAt,
        updatedAt,
        deletedAt,
        dirty,
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loans';
  @override
  VerificationContext validateIntegrity(Insertable<Loan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('counterparty_id')) {
      context.handle(
          _counterpartyIdMeta,
          counterpartyId.isAcceptableOrUnknown(
              data['counterparty_id']!, _counterpartyIdMeta));
    } else if (isInserting) {
      context.missing(_counterpartyIdMeta);
    }
    if (data.containsKey('counterparty_type')) {
      context.handle(
          _counterpartyTypeMeta,
          counterpartyType.isAcceptableOrUnknown(
              data['counterparty_type']!, _counterpartyTypeMeta));
    }
    if (data.containsKey('counterparty_name')) {
      context.handle(
          _counterpartyNameMeta,
          counterpartyName.isAcceptableOrUnknown(
              data['counterparty_name']!, _counterpartyNameMeta));
    }
    if (data.containsKey('counterparty_avatar')) {
      context.handle(
          _counterpartyAvatarMeta,
          counterpartyAvatar.isAcceptableOrUnknown(
              data['counterparty_avatar']!, _counterpartyAvatarMeta));
    }
    if (data.containsKey('loan_type')) {
      context.handle(_loanTypeMeta,
          loanType.isAcceptableOrUnknown(data['loan_type']!, _loanTypeMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('paid_amount')) {
      context.handle(
          _paidAmountMeta,
          paidAmount.isAcceptableOrUnknown(
              data['paid_amount']!, _paidAmountMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
          _createdAtMeta,
          createdAt.isAcceptableOrUnknown(
              data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
          _updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(
              data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
          _deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(
              data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Loan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Loan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      counterpartyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}counterparty_id'])!,
      counterpartyType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}counterparty_type'])!,
      counterpartyName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}counterparty_name'])!,
      counterpartyAvatar: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}counterparty_avatar']),
      loanType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}loan_type'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      paidAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}paid_amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $LoansTable createAlias(String alias) {
    return $LoansTable(attachedDatabase, alias);
  }
}

class Loan extends DataClass implements Insertable<Loan> {
  final String id;
  final String? serverId;
  final String counterpartyId;
  final String counterpartyType;
  final String counterpartyName;
  final String? counterpartyAvatar;
  final String loanType;
  final double amount;
  final double paidAmount;
  final String currency;
  final String description;
  final String notes;
  final DateTime? dueDate;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const Loan(
      {required this.id,
      this.serverId,
      required this.counterpartyId,
      required this.counterpartyType,
      required this.counterpartyName,
      this.counterpartyAvatar,
      required this.loanType,
      required this.amount,
      required this.paidAmount,
      required this.currency,
      required this.description,
      required this.notes,
      this.dueDate,
      required this.status,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['counterparty_id'] = Variable<String>(counterpartyId);
    map['counterparty_type'] = Variable<String>(counterpartyType);
    map['counterparty_name'] = Variable<String>(counterpartyName);
    if (!nullToAbsent || counterpartyAvatar != null) {
      map['counterparty_avatar'] = Variable<String>(counterpartyAvatar);
    }
    map['loan_type'] = Variable<String>(loanType);
    map['amount'] = Variable<double>(amount);
    map['paid_amount'] = Variable<double>(paidAmount);
    map['currency'] = Variable<String>(currency);
    map['description'] = Variable<String>(description);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  LoansCompanion toCompanion(bool nullToAbsent) {
    return LoansCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      counterpartyId: Value(counterpartyId),
      counterpartyType: Value(counterpartyType),
      counterpartyName: Value(counterpartyName),
      counterpartyAvatar: counterpartyAvatar == null && nullToAbsent
          ? const Value.absent()
          : Value(counterpartyAvatar),
      loanType: Value(loanType),
      amount: Value(amount),
      paidAmount: Value(paidAmount),
      currency: Value(currency),
      description: Value(description),
      notes: Value(notes),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      status: Value(status),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory Loan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Loan(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      counterpartyId: serializer.fromJson<String>(json['counterpartyId']),
      counterpartyType: serializer.fromJson<String>(json['counterpartyType']),
      counterpartyName: serializer.fromJson<String>(json['counterpartyName']),
      counterpartyAvatar:
          serializer.fromJson<String?>(json['counterpartyAvatar']),
      loanType: serializer.fromJson<String>(json['loanType']),
      amount: serializer.fromJson<double>(json['amount']),
      paidAmount: serializer.fromJson<double>(json['paidAmount']),
      currency: serializer.fromJson<String>(json['currency']),
      description: serializer.fromJson<String>(json['description']),
      notes: serializer.fromJson<String>(json['notes']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'counterpartyId': serializer.toJson<String>(counterpartyId),
      'counterpartyType': serializer.toJson<String>(counterpartyType),
      'counterpartyName': serializer.toJson<String>(counterpartyName),
      'counterpartyAvatar': serializer.toJson<String?>(counterpartyAvatar),
      'loanType': serializer.toJson<String>(loanType),
      'amount': serializer.toJson<double>(amount),
      'paidAmount': serializer.toJson<double>(paidAmount),
      'currency': serializer.toJson<String>(currency),
      'description': serializer.toJson<String>(description),
      'notes': serializer.toJson<String>(notes),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Loan copyWith(
          {String? id,
          Value<String?> serverId = const Value.absent(),
          String? counterpartyId,
          String? counterpartyType,
          String? counterpartyName,
          Value<String?> counterpartyAvatar = const Value.absent(),
          String? loanType,
          double? amount,
          double? paidAmount,
          String? currency,
          String? description,
          String? notes,
          Value<DateTime?> dueDate = const Value.absent(),
          String? status,
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? dirty}) =>
      Loan(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        counterpartyId: counterpartyId ?? this.counterpartyId,
        counterpartyType: counterpartyType ?? this.counterpartyType,
        counterpartyName: counterpartyName ?? this.counterpartyName,
        counterpartyAvatar: counterpartyAvatar.present
            ? counterpartyAvatar.value
            : this.counterpartyAvatar,
        loanType: loanType ?? this.loanType,
        amount: amount ?? this.amount,
        paidAmount: paidAmount ?? this.paidAmount,
        currency: currency ?? this.currency,
        description: description ?? this.description,
        notes: notes ?? this.notes,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        status: status ?? this.status,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        dirty: dirty ?? this.dirty,
      );
  Loan copyWithCompanion(LoansCompanion data) {
    return Loan(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      counterpartyId: data.counterpartyId.present
          ? data.counterpartyId.value
          : this.counterpartyId,
      counterpartyType: data.counterpartyType.present
          ? data.counterpartyType.value
          : this.counterpartyType,
      counterpartyName: data.counterpartyName.present
          ? data.counterpartyName.value
          : this.counterpartyName,
      counterpartyAvatar: data.counterpartyAvatar.present
          ? data.counterpartyAvatar.value
          : this.counterpartyAvatar,
      loanType: data.loanType.present ? data.loanType.value : this.loanType,
      amount: data.amount.present ? data.amount.value : this.amount,
      paidAmount:
          data.paidAmount.present ? data.paidAmount.value : this.paidAmount,
      currency: data.currency.present ? data.currency.value : this.currency,
      description:
          data.description.present ? data.description.value : this.description,
      notes: data.notes.present ? data.notes.value : this.notes,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Loan(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('counterpartyId: $counterpartyId, ')
          ..write('counterpartyType: $counterpartyType, ')
          ..write('counterpartyName: $counterpartyName, ')
          ..write('counterpartyAvatar: $counterpartyAvatar, ')
          ..write('loanType: $loanType, ')
          ..write('amount: $amount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('currency: $currency, ')
          ..write('description: $description, ')
          ..write('notes: $notes, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        serverId,
        counterpartyId,
        counterpartyType,
        counterpartyName,
        counterpartyAvatar,
        loanType,
        amount,
        paidAmount,
        currency,
        description,
        notes,
        dueDate,
        status,
        createdAt,
        updatedAt,
        deletedAt,
        dirty,
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Loan &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.counterpartyId == this.counterpartyId &&
          other.counterpartyType == this.counterpartyType &&
          other.counterpartyName == this.counterpartyName &&
          other.counterpartyAvatar == this.counterpartyAvatar &&
          other.loanType == this.loanType &&
          other.amount == this.amount &&
          other.paidAmount == this.paidAmount &&
          other.currency == this.currency &&
          other.description == this.description &&
          other.notes == this.notes &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class LoansCompanion extends UpdateCompanion<Loan> {
  final Value<String> id;
  final Value<String?> serverId;
  final Value<String> counterpartyId;
  final Value<String> counterpartyType;
  final Value<String> counterpartyName;
  final Value<String?> counterpartyAvatar;
  final Value<String> loanType;
  final Value<double> amount;
  final Value<double> paidAmount;
  final Value<String> currency;
  final Value<String> description;
  final Value<String> notes;
  final Value<DateTime?> dueDate;
  final Value<String> status;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const LoansCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.counterpartyId = const Value.absent(),
    this.counterpartyType = const Value.absent(),
    this.counterpartyName = const Value.absent(),
    this.counterpartyAvatar = const Value.absent(),
    this.loanType = const Value.absent(),
    this.amount = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.description = const Value.absent(),
    this.notes = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoansCompanion.insert({
    required String id,
    this.serverId = const Value.absent(),
    required String counterpartyId,
    this.counterpartyType = const Value.absent(),
    this.counterpartyName = const Value.absent(),
    this.counterpartyAvatar = const Value.absent(),
    this.loanType = const Value.absent(),
    this.amount = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.description = const Value.absent(),
    this.notes = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        counterpartyId = Value(counterpartyId);
  static Insertable<Loan> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? counterpartyId,
    Expression<String>? counterpartyType,
    Expression<String>? counterpartyName,
    Expression<String>? counterpartyAvatar,
    Expression<String>? loanType,
    Expression<double>? amount,
    Expression<double>? paidAmount,
    Expression<String>? currency,
    Expression<String>? description,
    Expression<String>? notes,
    Expression<DateTime>? dueDate,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (counterpartyId != null) 'counterparty_id': counterpartyId,
      if (counterpartyType != null) 'counterparty_type': counterpartyType,
      if (counterpartyName != null) 'counterparty_name': counterpartyName,
      if (counterpartyAvatar != null) 'counterparty_avatar': counterpartyAvatar,
      if (loanType != null) 'loan_type': loanType,
      if (amount != null) 'amount': amount,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (currency != null) 'currency': currency,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoansCompanion copyWith(
      {Value<String>? id,
      Value<String?>? serverId,
      Value<String>? counterpartyId,
      Value<String>? counterpartyType,
      Value<String>? counterpartyName,
      Value<String?>? counterpartyAvatar,
      Value<String>? loanType,
      Value<double>? amount,
      Value<double>? paidAmount,
      Value<String>? currency,
      Value<String>? description,
      Value<String>? notes,
      Value<DateTime?>? dueDate,
      Value<String>? status,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return LoansCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      counterpartyId: counterpartyId ?? this.counterpartyId,
      counterpartyType: counterpartyType ?? this.counterpartyType,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      counterpartyAvatar: counterpartyAvatar ?? this.counterpartyAvatar,
      loanType: loanType ?? this.loanType,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (counterpartyId.present) {
      map['counterparty_id'] = Variable<String>(counterpartyId.value);
    }
    if (counterpartyType.present) {
      map['counterparty_type'] = Variable<String>(counterpartyType.value);
    }
    if (counterpartyName.present) {
      map['counterparty_name'] = Variable<String>(counterpartyName.value);
    }
    if (counterpartyAvatar.present) {
      map['counterparty_avatar'] = Variable<String>(counterpartyAvatar.value);
    }
    if (loanType.present) {
      map['loan_type'] = Variable<String>(loanType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paidAmount.present) {
      map['paid_amount'] = Variable<double>(paidAmount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoansCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('counterpartyId: $counterpartyId, ')
          ..write('counterpartyType: $counterpartyType, ')
          ..write('counterpartyName: $counterpartyName, ')
          ..write('counterpartyAvatar: $counterpartyAvatar, ')
          ..write('loanType: $loanType, ')
          ..write('amount: $amount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('currency: $currency, ')
          ..write('description: $description, ')
          ..write('notes: $notes, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoanPaymentsTable extends LoanPayments
    with TableInfo<$LoanPaymentsTable, LoanPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoanPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _loanIdMeta = const VerificationMeta('loanId');
  @override
  late final GeneratedColumn<String> loanId = GeneratedColumn<String>(
      'loan_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
      'paid_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, serverId, loanId, amount, note, method, paidAt, createdAt, deletedAt, dirty];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loan_payments';
  @override
  VerificationContext validateIntegrity(Insertable<LoanPayment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('loan_id')) {
      context.handle(_loanIdMeta,
          loanId.isAcceptableOrUnknown(data['loan_id']!, _loanIdMeta));
    } else if (isInserting) {
      context.missing(_loanIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    }
    if (data.containsKey('paid_at')) {
      context.handle(_paidAtMeta,
          paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
          _createdAtMeta,
          createdAt.isAcceptableOrUnknown(
              data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
          _deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(
              data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoanPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoanPayment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      loanId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}loan_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      paidAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paid_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $LoanPaymentsTable createAlias(String alias) {
    return $LoanPaymentsTable(attachedDatabase, alias);
  }
}

class LoanPayment extends DataClass implements Insertable<LoanPayment> {
  final String id;
  final String? serverId;
  final String loanId;
  final double amount;
  final String note;
  final String method;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final bool dirty;
  const LoanPayment(
      {required this.id,
      this.serverId,
      required this.loanId,
      required this.amount,
      required this.note,
      required this.method,
      this.paidAt,
      this.createdAt,
      this.deletedAt,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['loan_id'] = Variable<String>(loanId);
    map['amount'] = Variable<double>(amount);
    map['note'] = Variable<String>(note);
    map['method'] = Variable<String>(method);
    if (!nullToAbsent || paidAt != null) {
      map['paid_at'] = Variable<DateTime>(paidAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  LoanPaymentsCompanion toCompanion(bool nullToAbsent) {
    return LoanPaymentsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      loanId: Value(loanId),
      amount: Value(amount),
      note: Value(note),
      method: Value(method),
      paidAt:
          paidAt == null && nullToAbsent ? const Value.absent() : Value(paidAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory LoanPayment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoanPayment(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      loanId: serializer.fromJson<String>(json['loanId']),
      amount: serializer.fromJson<double>(json['amount']),
      note: serializer.fromJson<String>(json['note']),
      method: serializer.fromJson<String>(json['method']),
      paidAt: serializer.fromJson<DateTime?>(json['paidAt']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String?>(serverId),
      'loanId': serializer.toJson<String>(loanId),
      'amount': serializer.toJson<double>(amount),
      'note': serializer.toJson<String>(note),
      'method': serializer.toJson<String>(method),
      'paidAt': serializer.toJson<DateTime?>(paidAt),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  LoanPayment copyWith(
          {String? id,
          Value<String?> serverId = const Value.absent(),
          String? loanId,
          double? amount,
          String? note,
          String? method,
          Value<DateTime?> paidAt = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? dirty}) =>
      LoanPayment(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        loanId: loanId ?? this.loanId,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        method: method ?? this.method,
        paidAt: paidAt.present ? paidAt.value : this.paidAt,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        dirty: dirty ?? this.dirty,
      );
  LoanPayment copyWithCompanion(LoanPaymentsCompanion data) {
    return LoanPayment(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      loanId: data.loanId.present ? data.loanId.value : this.loanId,
      amount: data.amount.present ? data.amount.value : this.amount,
      note: data.note.present ? data.note.value : this.note,
      method: data.method.present ? data.method.value : this.method,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoanPayment(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('loanId: $loanId, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('method: $method, ')
          ..write('paidAt: $paidAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, serverId, loanId, amount, note, method, paidAt, createdAt, deletedAt, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoanPayment &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.loanId == this.loanId &&
          other.amount == this.amount &&
          other.note == this.note &&
          other.method == this.method &&
          other.paidAt == this.paidAt &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class LoanPaymentsCompanion extends UpdateCompanion<LoanPayment> {
  final Value<String> id;
  final Value<String?> serverId;
  final Value<String> loanId;
  final Value<double> amount;
  final Value<String> note;
  final Value<String> method;
  final Value<DateTime?> paidAt;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const LoanPaymentsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.loanId = const Value.absent(),
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.method = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoanPaymentsCompanion.insert({
    required String id,
    this.serverId = const Value.absent(),
    required String loanId,
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.method = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        loanId = Value(loanId);
  static Insertable<LoanPayment> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? loanId,
    Expression<double>? amount,
    Expression<String>? note,
    Expression<String>? method,
    Expression<DateTime>? paidAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (loanId != null) 'loan_id': loanId,
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
      if (method != null) 'method': method,
      if (paidAt != null) 'paid_at': paidAt,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoanPaymentsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? serverId,
      Value<String>? loanId,
      Value<double>? amount,
      Value<String>? note,
      Value<String>? method,
      Value<DateTime?>? paidAt,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return LoanPaymentsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      loanId: loanId ?? this.loanId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      method: method ?? this.method,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (loanId.present) {
      map['loan_id'] = Variable<String>(loanId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoanPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('loanId: $loanId, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('method: $method, ')
          ..write('paidAt: $paidAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
      'op_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityLocalIdMeta =
      const VerificationMeta('entityLocalId');
  @override
  late final GeneratedColumn<String> entityLocalId = GeneratedColumn<String>(
      'entity_local_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
      'op_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        opId,
        entityType,
        entityLocalId,
        opType,
        payloadJson,
        attempts,
        lastError,
        status,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
          _opIdMeta, opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta));
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_local_id')) {
      context.handle(
          _entityLocalIdMeta,
          entityLocalId.isAcceptableOrUnknown(
              data['entity_local_id']!, _entityLocalIdMeta));
    }
    if (data.containsKey('op_type')) {
      context.handle(_opTypeMeta,
          opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta));
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      opId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}op_id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityLocalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_local_id']),
      opType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}op_type'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String opId;
  final String entityType;
  final String? entityLocalId;
  final String opType;
  final String payloadJson;
  final int attempts;
  final String? lastError;
  final String status;
  final DateTime createdAt;
  const SyncQueueData(
      {required this.opId,
      required this.entityType,
      this.entityLocalId,
      required this.opType,
      required this.payloadJson,
      required this.attempts,
      this.lastError,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['op_id'] = Variable<String>(opId);
    map['entity_type'] = Variable<String>(entityType);
    if (!nullToAbsent || entityLocalId != null) {
      map['entity_local_id'] = Variable<String>(entityLocalId);
    }
    map['op_type'] = Variable<String>(opType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      opId: Value(opId),
      entityType: Value(entityType),
      entityLocalId: entityLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityLocalId),
      opType: Value(opType),
      payloadJson: Value(payloadJson),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      opId: serializer.fromJson<String>(json['opId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityLocalId: serializer.fromJson<String?>(json['entityLocalId']),
      opType: serializer.fromJson<String>(json['opType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<String>(opId),
      'entityType': serializer.toJson<String>(entityType),
      'entityLocalId': serializer.toJson<String?>(entityLocalId),
      'opType': serializer.toJson<String>(opType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueData copyWith(
          {String? opId,
          String? entityType,
          Value<String?> entityLocalId = const Value.absent(),
          String? opType,
          String? payloadJson,
          int? attempts,
          Value<String?> lastError = const Value.absent(),
          String? status,
          DateTime? createdAt}) =>
      SyncQueueData(
        opId: opId ?? this.opId,
        entityType: entityType ?? this.entityType,
        entityLocalId:
            entityLocalId.present ? entityLocalId.value : this.entityLocalId,
        opType: opType ?? this.opType,
        payloadJson: payloadJson ?? this.payloadJson,
        attempts: attempts ?? this.attempts,
        lastError: lastError.present ? lastError.value : this.lastError,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      opId: data.opId.present ? data.opId.value : this.opId,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityLocalId: data.entityLocalId.present
          ? data.entityLocalId.value
          : this.entityLocalId,
      opType: data.opType.present ? data.opType.value : this.opType,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('opId: $opId, ')
          ..write('entityType: $entityType, ')
          ..write('entityLocalId: $entityLocalId, ')
          ..write('opType: $opType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(opId, entityType, entityLocalId, opType,
      payloadJson, attempts, lastError, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.opId == this.opId &&
          other.entityType == this.entityType &&
          other.entityLocalId == this.entityLocalId &&
          other.opType == this.opType &&
          other.payloadJson == this.payloadJson &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> opId;
  final Value<String> entityType;
  final Value<String?> entityLocalId;
  final Value<String> opType;
  final Value<String> payloadJson;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.opId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityLocalId = const Value.absent(),
    this.opType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String opId,
    required String entityType,
    this.entityLocalId = const Value.absent(),
    required String opType,
    this.payloadJson = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : opId = Value(opId),
        entityType = Value(entityType),
        opType = Value(opType);
  static Insertable<SyncQueueData> custom({
    Expression<String>? opId,
    Expression<String>? entityType,
    Expression<String>? entityLocalId,
    Expression<String>? opType,
    Expression<String>? payloadJson,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (entityType != null) 'entity_type': entityType,
      if (entityLocalId != null) 'entity_local_id': entityLocalId,
      if (opType != null) 'op_type': opType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<String>? opId,
      Value<String>? entityType,
      Value<String?>? entityLocalId,
      Value<String>? opType,
      Value<String>? payloadJson,
      Value<int>? attempts,
      Value<String?>? lastError,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SyncQueueCompanion(
      opId: opId ?? this.opId,
      entityType: entityType ?? this.entityType,
      entityLocalId: entityLocalId ?? this.entityLocalId,
      opType: opType ?? this.opType,
      payloadJson: payloadJson ?? this.payloadJson,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityLocalId.present) {
      map['entity_local_id'] = Variable<String>(entityLocalId.value);
    }
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('opId: $opId, ')
          ..write('entityType: $entityType, ')
          ..write('entityLocalId: $entityLocalId, ')
          ..write('opType: $opType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(Insertable<SyncMetaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final String key;
  final String? value;
  const SyncMetaData({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      key: Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
    );
  }

  factory SyncMetaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  SyncMetaData copyWith(
          {String? key, Value<String?> value = const Value.absent()}) =>
      SyncMetaData(
        key: key ?? this.key,
        value: value.present ? value.value : this.value,
      );
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<SyncMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith(
      {Value<String>? key, Value<String?>? value, Value<int>? rowid}) {
    return SyncMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $GroupMembersTable groupMembers = $GroupMembersTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $ExpenseSharesTable expenseShares = $ExpenseSharesTable(this);
  late final $ExpensePayersTable expensePayers = $ExpensePayersTable(this);
  late final $SettlementsTable settlements = $SettlementsTable(this);
  late final $PersonalExpensesTable personalExpenses =
      $PersonalExpensesTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  late final $ReactionsTable reactions = $ReactionsTable(this);
  late final $GuestContactsTable guestContacts = $GuestContactsTable(this);
  late final $LoansTable loans = $LoansTable(this);
  late final $LoanPaymentsTable loanPayments = $LoanPaymentsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        groups,
        groupMembers,
        expenses,
        expenseShares,
        expensePayers,
        settlements,
        personalExpenses,
        goals,
        activities,
        reactions,
        guestContacts,
        loans,
        loanPayments,
        syncQueue,
        syncMeta
      ];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  Value<String> name,
  Value<String> email,
  Value<String?> avatarUrl,
  Value<bool> isPlaceholder,
  Value<String?> currency,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> email,
  Value<String?> avatarUrl,
  Value<bool> isPlaceholder,
  Value<String?> currency,
  Value<int> rowid,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatarUrl => $composableBuilder(
      column: $table.avatarUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPlaceholder => $composableBuilder(
      column: $table.isPlaceholder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
      column: $table.avatarUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPlaceholder => $composableBuilder(
      column: $table.isPlaceholder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<bool> get isPlaceholder => $composableBuilder(
      column: $table.isPlaceholder, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<bool> isPlaceholder = const Value.absent(),
            Value<String?> currency = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            name: name,
            email: email,
            avatarUrl: avatarUrl,
            isPlaceholder: isPlaceholder,
            currency: currency,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> name = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<bool> isPlaceholder = const Value.absent(),
            Value<String?> currency = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            name: name,
            email: email,
            avatarUrl: avatarUrl,
            isPlaceholder: isPlaceholder,
            currency: currency,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()>;
typedef $$GroupsTableCreateCompanionBuilder = GroupsCompanion Function({
  required String id,
  Value<String?> serverId,
  Value<String> name,
  Value<String> description,
  Value<String> notes,
  Value<String> category,
  Value<String> coverColor,
  Value<String> icon,
  Value<String> currency,
  Value<String> inviteCode,
  Value<String?> pendingMembersJson,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$GroupsTableUpdateCompanionBuilder = GroupsCompanion Function({
  Value<String> id,
  Value<String?> serverId,
  Value<String> name,
  Value<String> description,
  Value<String> notes,
  Value<String> category,
  Value<String> coverColor,
  Value<String> icon,
  Value<String> currency,
  Value<String> inviteCode,
  Value<String?> pendingMembersJson,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverColor => $composableBuilder(
      column: $table.coverColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inviteCode => $composableBuilder(
      column: $table.inviteCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pendingMembersJson => $composableBuilder(
      column: $table.pendingMembersJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverColor => $composableBuilder(
      column: $table.coverColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inviteCode => $composableBuilder(
      column: $table.inviteCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pendingMembersJson => $composableBuilder(
      column: $table.pendingMembersJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get coverColor => $composableBuilder(
      column: $table.coverColor, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get inviteCode => $composableBuilder(
      column: $table.inviteCode, builder: (column) => column);

  GeneratedColumn<String> get pendingMembersJson => $composableBuilder(
      column: $table.pendingMembersJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$GroupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GroupsTable,
    Group,
    $$GroupsTableFilterComposer,
    $$GroupsTableOrderingComposer,
    $$GroupsTableAnnotationComposer,
    $$GroupsTableCreateCompanionBuilder,
    $$GroupsTableUpdateCompanionBuilder,
    (Group, BaseReferences<_$AppDatabase, $GroupsTable, Group>),
    Group,
    PrefetchHooks Function()> {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> coverColor = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> inviteCode = const Value.absent(),
            Value<String?> pendingMembersJson = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupsCompanion(
            id: id,
            serverId: serverId,
            name: name,
            description: description,
            notes: notes,
            category: category,
            coverColor: coverColor,
            icon: icon,
            currency: currency,
            inviteCode: inviteCode,
            pendingMembersJson: pendingMembersJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> serverId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> coverColor = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> inviteCode = const Value.absent(),
            Value<String?> pendingMembersJson = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupsCompanion.insert(
            id: id,
            serverId: serverId,
            name: name,
            description: description,
            notes: notes,
            category: category,
            coverColor: coverColor,
            icon: icon,
            currency: currency,
            inviteCode: inviteCode,
            pendingMembersJson: pendingMembersJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GroupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GroupsTable,
    Group,
    $$GroupsTableFilterComposer,
    $$GroupsTableOrderingComposer,
    $$GroupsTableAnnotationComposer,
    $$GroupsTableCreateCompanionBuilder,
    $$GroupsTableUpdateCompanionBuilder,
    (Group, BaseReferences<_$AppDatabase, $GroupsTable, Group>),
    Group,
    PrefetchHooks Function()>;
typedef $$GroupMembersTableCreateCompanionBuilder = GroupMembersCompanion
    Function({
  required String groupId,
  required String userId,
  Value<String> role,
  Value<int> rowid,
});
typedef $$GroupMembersTableUpdateCompanionBuilder = GroupMembersCompanion
    Function({
  Value<String> groupId,
  Value<String> userId,
  Value<String> role,
  Value<int> rowid,
});

class $$GroupMembersTableFilterComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));
}

class $$GroupMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));
}

class $$GroupMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);
}

class $$GroupMembersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GroupMembersTable,
    GroupMember,
    $$GroupMembersTableFilterComposer,
    $$GroupMembersTableOrderingComposer,
    $$GroupMembersTableAnnotationComposer,
    $$GroupMembersTableCreateCompanionBuilder,
    $$GroupMembersTableUpdateCompanionBuilder,
    (
      GroupMember,
      BaseReferences<_$AppDatabase, $GroupMembersTable, GroupMember>
    ),
    GroupMember,
    PrefetchHooks Function()> {
  $$GroupMembersTableTableManager(_$AppDatabase db, $GroupMembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> groupId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupMembersCompanion(
            groupId: groupId,
            userId: userId,
            role: role,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String groupId,
            required String userId,
            Value<String> role = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupMembersCompanion.insert(
            groupId: groupId,
            userId: userId,
            role: role,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GroupMembersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GroupMembersTable,
    GroupMember,
    $$GroupMembersTableFilterComposer,
    $$GroupMembersTableOrderingComposer,
    $$GroupMembersTableAnnotationComposer,
    $$GroupMembersTableCreateCompanionBuilder,
    $$GroupMembersTableUpdateCompanionBuilder,
    (
      GroupMember,
      BaseReferences<_$AppDatabase, $GroupMembersTable, GroupMember>
    ),
    GroupMember,
    PrefetchHooks Function()>;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  Value<String?> serverId,
  required String groupId,
  Value<String> description,
  Value<String> notes,
  Value<double> amount,
  Value<String> currency,
  Value<String> category,
  Value<String> splitMode,
  Value<String?> paidById,
  Value<double> tax,
  Value<double> tip,
  Value<String?> receiptUrl,
  Value<String?> receiptLocalPath,
  Value<DateTime?> spentAt,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<String?> serverId,
  Value<String> groupId,
  Value<String> description,
  Value<String> notes,
  Value<double> amount,
  Value<String> currency,
  Value<String> category,
  Value<String> splitMode,
  Value<String?> paidById,
  Value<double> tax,
  Value<double> tip,
  Value<String?> receiptUrl,
  Value<String?> receiptLocalPath,
  Value<DateTime?> spentAt,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get splitMode => $composableBuilder(
      column: $table.splitMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paidById => $composableBuilder(
      column: $table.paidById, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get tax => $composableBuilder(
      column: $table.tax, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get tip => $composableBuilder(
      column: $table.tip, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiptLocalPath => $composableBuilder(
      column: $table.receiptLocalPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get spentAt => $composableBuilder(
      column: $table.spentAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get splitMode => $composableBuilder(
      column: $table.splitMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paidById => $composableBuilder(
      column: $table.paidById, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get tax => $composableBuilder(
      column: $table.tax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get tip => $composableBuilder(
      column: $table.tip, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiptLocalPath => $composableBuilder(
      column: $table.receiptLocalPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get spentAt => $composableBuilder(
      column: $table.spentAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get splitMode =>
      $composableBuilder(column: $table.splitMode, builder: (column) => column);

  GeneratedColumn<String> get paidById =>
      $composableBuilder(column: $table.paidById, builder: (column) => column);

  GeneratedColumn<double> get tax =>
      $composableBuilder(column: $table.tax, builder: (column) => column);

  GeneratedColumn<double> get tip =>
      $composableBuilder(column: $table.tip, builder: (column) => column);

  GeneratedColumn<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => column);

  GeneratedColumn<String> get receiptLocalPath => $composableBuilder(
      column: $table.receiptLocalPath, builder: (column) => column);

  GeneratedColumn<DateTime> get spentAt =>
      $composableBuilder(column: $table.spentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$ExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
    Expense,
    PrefetchHooks Function()> {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> splitMode = const Value.absent(),
            Value<String?> paidById = const Value.absent(),
            Value<double> tax = const Value.absent(),
            Value<double> tip = const Value.absent(),
            Value<String?> receiptUrl = const Value.absent(),
            Value<String?> receiptLocalPath = const Value.absent(),
            Value<DateTime?> spentAt = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion(
            id: id,
            serverId: serverId,
            groupId: groupId,
            description: description,
            notes: notes,
            amount: amount,
            currency: currency,
            category: category,
            splitMode: splitMode,
            paidById: paidById,
            tax: tax,
            tip: tip,
            receiptUrl: receiptUrl,
            receiptLocalPath: receiptLocalPath,
            spentAt: spentAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> serverId = const Value.absent(),
            required String groupId,
            Value<String> description = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> splitMode = const Value.absent(),
            Value<String?> paidById = const Value.absent(),
            Value<double> tax = const Value.absent(),
            Value<double> tip = const Value.absent(),
            Value<String?> receiptUrl = const Value.absent(),
            Value<String?> receiptLocalPath = const Value.absent(),
            Value<DateTime?> spentAt = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion.insert(
            id: id,
            serverId: serverId,
            groupId: groupId,
            description: description,
            notes: notes,
            amount: amount,
            currency: currency,
            category: category,
            splitMode: splitMode,
            paidById: paidById,
            tax: tax,
            tip: tip,
            receiptUrl: receiptUrl,
            receiptLocalPath: receiptLocalPath,
            spentAt: spentAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExpensesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
    Expense,
    PrefetchHooks Function()>;
typedef $$ExpenseSharesTableCreateCompanionBuilder = ExpenseSharesCompanion
    Function({
  required String expenseId,
  required String userId,
  Value<double> amount,
  Value<int> rowid,
});
typedef $$ExpenseSharesTableUpdateCompanionBuilder = ExpenseSharesCompanion
    Function({
  Value<String> expenseId,
  Value<String> userId,
  Value<double> amount,
  Value<int> rowid,
});

class $$ExpenseSharesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseSharesTable> {
  $$ExpenseSharesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get expenseId => $composableBuilder(
      column: $table.expenseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));
}

class $$ExpenseSharesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseSharesTable> {
  $$ExpenseSharesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get expenseId => $composableBuilder(
      column: $table.expenseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));
}

class $$ExpenseSharesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseSharesTable> {
  $$ExpenseSharesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get expenseId =>
      $composableBuilder(column: $table.expenseId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);
}

class $$ExpenseSharesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExpenseSharesTable,
    ExpenseShare,
    $$ExpenseSharesTableFilterComposer,
    $$ExpenseSharesTableOrderingComposer,
    $$ExpenseSharesTableAnnotationComposer,
    $$ExpenseSharesTableCreateCompanionBuilder,
    $$ExpenseSharesTableUpdateCompanionBuilder,
    (
      ExpenseShare,
      BaseReferences<_$AppDatabase, $ExpenseSharesTable, ExpenseShare>
    ),
    ExpenseShare,
    PrefetchHooks Function()> {
  $$ExpenseSharesTableTableManager(_$AppDatabase db, $ExpenseSharesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseSharesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseSharesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseSharesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> expenseId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpenseSharesCompanion(
            expenseId: expenseId,
            userId: userId,
            amount: amount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String expenseId,
            required String userId,
            Value<double> amount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpenseSharesCompanion.insert(
            expenseId: expenseId,
            userId: userId,
            amount: amount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExpenseSharesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExpenseSharesTable,
    ExpenseShare,
    $$ExpenseSharesTableFilterComposer,
    $$ExpenseSharesTableOrderingComposer,
    $$ExpenseSharesTableAnnotationComposer,
    $$ExpenseSharesTableCreateCompanionBuilder,
    $$ExpenseSharesTableUpdateCompanionBuilder,
    (
      ExpenseShare,
      BaseReferences<_$AppDatabase, $ExpenseSharesTable, ExpenseShare>
    ),
    ExpenseShare,
    PrefetchHooks Function()>;
typedef $$ExpensePayersTableCreateCompanionBuilder = ExpensePayersCompanion
    Function({
  required String expenseId,
  required String userId,
  Value<double> amount,
  Value<int> rowid,
});
typedef $$ExpensePayersTableUpdateCompanionBuilder = ExpensePayersCompanion
    Function({
  Value<String> expenseId,
  Value<String> userId,
  Value<double> amount,
  Value<int> rowid,
});

class $$ExpensePayersTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensePayersTable> {
  $$ExpensePayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get expenseId => $composableBuilder(
      column: $table.expenseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));
}

class $$ExpensePayersTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensePayersTable> {
  $$ExpensePayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get expenseId => $composableBuilder(
      column: $table.expenseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));
}

class $$ExpensePayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensePayersTable> {
  $$ExpensePayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get expenseId =>
      $composableBuilder(column: $table.expenseId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);
}

class $$ExpensePayersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExpensePayersTable,
    ExpensePayer,
    $$ExpensePayersTableFilterComposer,
    $$ExpensePayersTableOrderingComposer,
    $$ExpensePayersTableAnnotationComposer,
    $$ExpensePayersTableCreateCompanionBuilder,
    $$ExpensePayersTableUpdateCompanionBuilder,
    (
      ExpensePayer,
      BaseReferences<_$AppDatabase, $ExpensePayersTable, ExpensePayer>
    ),
    ExpensePayer,
    PrefetchHooks Function()> {
  $$ExpensePayersTableTableManager(_$AppDatabase db, $ExpensePayersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensePayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensePayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensePayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> expenseId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensePayersCompanion(
            expenseId: expenseId,
            userId: userId,
            amount: amount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String expenseId,
            required String userId,
            Value<double> amount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensePayersCompanion.insert(
            expenseId: expenseId,
            userId: userId,
            amount: amount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExpensePayersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExpensePayersTable,
    ExpensePayer,
    $$ExpensePayersTableFilterComposer,
    $$ExpensePayersTableOrderingComposer,
    $$ExpensePayersTableAnnotationComposer,
    $$ExpensePayersTableCreateCompanionBuilder,
    $$ExpensePayersTableUpdateCompanionBuilder,
    (
      ExpensePayer,
      BaseReferences<_$AppDatabase, $ExpensePayersTable, ExpensePayer>
    ),
    ExpensePayer,
    PrefetchHooks Function()>;
typedef $$SettlementsTableCreateCompanionBuilder = SettlementsCompanion
    Function({
  required String id,
  Value<String?> serverId,
  required String groupId,
  required String fromUserId,
  required String toUserId,
  Value<double> amount,
  Value<String> currency,
  Value<String> method,
  Value<String> note,
  Value<DateTime?> settledAt,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$SettlementsTableUpdateCompanionBuilder = SettlementsCompanion
    Function({
  Value<String> id,
  Value<String?> serverId,
  Value<String> groupId,
  Value<String> fromUserId,
  Value<String> toUserId,
  Value<double> amount,
  Value<String> currency,
  Value<String> method,
  Value<String> note,
  Value<DateTime?> settledAt,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$SettlementsTableFilterComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromUserId => $composableBuilder(
      column: $table.fromUserId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toUserId => $composableBuilder(
      column: $table.toUserId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get settledAt => $composableBuilder(
      column: $table.settledAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$SettlementsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromUserId => $composableBuilder(
      column: $table.fromUserId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toUserId => $composableBuilder(
      column: $table.toUserId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get settledAt => $composableBuilder(
      column: $table.settledAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$SettlementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get fromUserId => $composableBuilder(
      column: $table.fromUserId, builder: (column) => column);

  GeneratedColumn<String> get toUserId =>
      $composableBuilder(column: $table.toUserId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get settledAt =>
      $composableBuilder(column: $table.settledAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$SettlementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettlementsTable,
    Settlement,
    $$SettlementsTableFilterComposer,
    $$SettlementsTableOrderingComposer,
    $$SettlementsTableAnnotationComposer,
    $$SettlementsTableCreateCompanionBuilder,
    $$SettlementsTableUpdateCompanionBuilder,
    (Settlement, BaseReferences<_$AppDatabase, $SettlementsTable, Settlement>),
    Settlement,
    PrefetchHooks Function()> {
  $$SettlementsTableTableManager(_$AppDatabase db, $SettlementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettlementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettlementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettlementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> fromUserId = const Value.absent(),
            Value<String> toUserId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime?> settledAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettlementsCompanion(
            id: id,
            serverId: serverId,
            groupId: groupId,
            fromUserId: fromUserId,
            toUserId: toUserId,
            amount: amount,
            currency: currency,
            method: method,
            note: note,
            settledAt: settledAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> serverId = const Value.absent(),
            required String groupId,
            required String fromUserId,
            required String toUserId,
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime?> settledAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettlementsCompanion.insert(
            id: id,
            serverId: serverId,
            groupId: groupId,
            fromUserId: fromUserId,
            toUserId: toUserId,
            amount: amount,
            currency: currency,
            method: method,
            note: note,
            settledAt: settledAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettlementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettlementsTable,
    Settlement,
    $$SettlementsTableFilterComposer,
    $$SettlementsTableOrderingComposer,
    $$SettlementsTableAnnotationComposer,
    $$SettlementsTableCreateCompanionBuilder,
    $$SettlementsTableUpdateCompanionBuilder,
    (Settlement, BaseReferences<_$AppDatabase, $SettlementsTable, Settlement>),
    Settlement,
    PrefetchHooks Function()>;
typedef $$PersonalExpensesTableCreateCompanionBuilder
    = PersonalExpensesCompanion Function({
  required String id,
  Value<String?> serverId,
  Value<String> description,
  Value<double> amount,
  Value<String> currency,
  Value<String> category,
  Value<DateTime?> date,
  Value<String> note,
  Value<String?> receiptUrl,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$PersonalExpensesTableUpdateCompanionBuilder
    = PersonalExpensesCompanion Function({
  Value<String> id,
  Value<String?> serverId,
  Value<String> description,
  Value<double> amount,
  Value<String> currency,
  Value<String> category,
  Value<DateTime?> date,
  Value<String> note,
  Value<String?> receiptUrl,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$PersonalExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $PersonalExpensesTable> {
  $$PersonalExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$PersonalExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonalExpensesTable> {
  $$PersonalExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$PersonalExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonalExpensesTable> {
  $$PersonalExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$PersonalExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PersonalExpensesTable,
    PersonalExpense,
    $$PersonalExpensesTableFilterComposer,
    $$PersonalExpensesTableOrderingComposer,
    $$PersonalExpensesTableAnnotationComposer,
    $$PersonalExpensesTableCreateCompanionBuilder,
    $$PersonalExpensesTableUpdateCompanionBuilder,
    (
      PersonalExpense,
      BaseReferences<_$AppDatabase, $PersonalExpensesTable, PersonalExpense>
    ),
    PersonalExpense,
    PrefetchHooks Function()> {
  $$PersonalExpensesTableTableManager(
      _$AppDatabase db, $PersonalExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonalExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonalExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonalExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<DateTime?> date = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String?> receiptUrl = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PersonalExpensesCompanion(
            id: id,
            serverId: serverId,
            description: description,
            amount: amount,
            currency: currency,
            category: category,
            date: date,
            note: note,
            receiptUrl: receiptUrl,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> serverId = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<DateTime?> date = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String?> receiptUrl = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PersonalExpensesCompanion.insert(
            id: id,
            serverId: serverId,
            description: description,
            amount: amount,
            currency: currency,
            category: category,
            date: date,
            note: note,
            receiptUrl: receiptUrl,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PersonalExpensesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PersonalExpensesTable,
    PersonalExpense,
    $$PersonalExpensesTableFilterComposer,
    $$PersonalExpensesTableOrderingComposer,
    $$PersonalExpensesTableAnnotationComposer,
    $$PersonalExpensesTableCreateCompanionBuilder,
    $$PersonalExpensesTableUpdateCompanionBuilder,
    (
      PersonalExpense,
      BaseReferences<_$AppDatabase, $PersonalExpensesTable, PersonalExpense>
    ),
    PersonalExpense,
    PrefetchHooks Function()>;
typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  required String id,
  Value<String?> serverId,
  Value<String> title,
  Value<String> description,
  Value<String> emoji,
  Value<String> category,
  Value<double> targetAmount,
  Value<double> savedAmount,
  Value<String> currency,
  Value<DateTime?> targetDate,
  Value<String> status,
  Value<String> priority,
  Value<String> color,
  Value<String> notes,
  Value<String?> contributionsJson,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<String> id,
  Value<String?> serverId,
  Value<String> title,
  Value<String> description,
  Value<String> emoji,
  Value<String> category,
  Value<double> targetAmount,
  Value<double> savedAmount,
  Value<String> currency,
  Value<DateTime?> targetDate,
  Value<String> status,
  Value<String> priority,
  Value<String> color,
  Value<String> notes,
  Value<String?> contributionsJson,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get savedAmount => $composableBuilder(
      column: $table.savedAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contributionsJson => $composableBuilder(
      column: $table.contributionsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get savedAmount => $composableBuilder(
      column: $table.savedAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contributionsJson => $composableBuilder(
      column: $table.contributionsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => column);

  GeneratedColumn<double> get savedAmount => $composableBuilder(
      column: $table.savedAmount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get contributionsJson => $composableBuilder(
      column: $table.contributionsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$GoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
    Goal,
    PrefetchHooks Function()> {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> emoji = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<double> targetAmount = const Value.absent(),
            Value<double> savedAmount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<DateTime?> targetDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String?> contributionsJson = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion(
            id: id,
            serverId: serverId,
            title: title,
            description: description,
            emoji: emoji,
            category: category,
            targetAmount: targetAmount,
            savedAmount: savedAmount,
            currency: currency,
            targetDate: targetDate,
            status: status,
            priority: priority,
            color: color,
            notes: notes,
            contributionsJson: contributionsJson,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> serverId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> emoji = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<double> targetAmount = const Value.absent(),
            Value<double> savedAmount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<DateTime?> targetDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String?> contributionsJson = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion.insert(
            id: id,
            serverId: serverId,
            title: title,
            description: description,
            emoji: emoji,
            category: category,
            targetAmount: targetAmount,
            savedAmount: savedAmount,
            currency: currency,
            targetDate: targetDate,
            status: status,
            priority: priority,
            color: color,
            notes: notes,
            contributionsJson: contributionsJson,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
    Goal,
    PrefetchHooks Function()>;
typedef $$ActivitiesTableCreateCompanionBuilder = ActivitiesCompanion Function({
  required String id,
  Value<String?> groupId,
  Value<String> type,
  Value<String> message,
  Value<String?> actorId,
  Value<String?> actorName,
  Value<String?> actorAvatar,
  Value<String?> groupName,
  Value<String?> groupColor,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$ActivitiesTableUpdateCompanionBuilder = ActivitiesCompanion Function({
  Value<String> id,
  Value<String?> groupId,
  Value<String> type,
  Value<String> message,
  Value<String?> actorId,
  Value<String?> actorName,
  Value<String?> actorAvatar,
  Value<String?> groupName,
  Value<String?> groupColor,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$ActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actorId => $composableBuilder(
      column: $table.actorId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actorName => $composableBuilder(
      column: $table.actorName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actorAvatar => $composableBuilder(
      column: $table.actorAvatar, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupName => $composableBuilder(
      column: $table.groupName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupColor => $composableBuilder(
      column: $table.groupColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actorId => $composableBuilder(
      column: $table.actorId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actorName => $composableBuilder(
      column: $table.actorName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actorAvatar => $composableBuilder(
      column: $table.actorAvatar, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupName => $composableBuilder(
      column: $table.groupName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupColor => $composableBuilder(
      column: $table.groupColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get actorName =>
      $composableBuilder(column: $table.actorName, builder: (column) => column);

  GeneratedColumn<String> get actorAvatar => $composableBuilder(
      column: $table.actorAvatar, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get groupColor => $composableBuilder(
      column: $table.groupColor, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ActivitiesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActivitiesTable,
    Activity,
    $$ActivitiesTableFilterComposer,
    $$ActivitiesTableOrderingComposer,
    $$ActivitiesTableAnnotationComposer,
    $$ActivitiesTableCreateCompanionBuilder,
    $$ActivitiesTableUpdateCompanionBuilder,
    (Activity, BaseReferences<_$AppDatabase, $ActivitiesTable, Activity>),
    Activity,
    PrefetchHooks Function()> {
  $$ActivitiesTableTableManager(_$AppDatabase db, $ActivitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> groupId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> message = const Value.absent(),
            Value<String?> actorId = const Value.absent(),
            Value<String?> actorName = const Value.absent(),
            Value<String?> actorAvatar = const Value.absent(),
            Value<String?> groupName = const Value.absent(),
            Value<String?> groupColor = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActivitiesCompanion(
            id: id,
            groupId: groupId,
            type: type,
            message: message,
            actorId: actorId,
            actorName: actorName,
            actorAvatar: actorAvatar,
            groupName: groupName,
            groupColor: groupColor,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> groupId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> message = const Value.absent(),
            Value<String?> actorId = const Value.absent(),
            Value<String?> actorName = const Value.absent(),
            Value<String?> actorAvatar = const Value.absent(),
            Value<String?> groupName = const Value.absent(),
            Value<String?> groupColor = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActivitiesCompanion.insert(
            id: id,
            groupId: groupId,
            type: type,
            message: message,
            actorId: actorId,
            actorName: actorName,
            actorAvatar: actorAvatar,
            groupName: groupName,
            groupColor: groupColor,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ActivitiesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActivitiesTable,
    Activity,
    $$ActivitiesTableFilterComposer,
    $$ActivitiesTableOrderingComposer,
    $$ActivitiesTableAnnotationComposer,
    $$ActivitiesTableCreateCompanionBuilder,
    $$ActivitiesTableUpdateCompanionBuilder,
    (Activity, BaseReferences<_$AppDatabase, $ActivitiesTable, Activity>),
    Activity,
    PrefetchHooks Function()>;
typedef $$ReactionsTableCreateCompanionBuilder = ReactionsCompanion Function({
  required String targetType,
  required String targetId,
  required String emoji,
  required String userId,
  Value<String?> userName,
  Value<String?> userAvatar,
  Value<int> rowid,
});
typedef $$ReactionsTableUpdateCompanionBuilder = ReactionsCompanion Function({
  Value<String> targetType,
  Value<String> targetId,
  Value<String> emoji,
  Value<String> userId,
  Value<String?> userName,
  Value<String?> userAvatar,
  Value<int> rowid,
});

class $$ReactionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReactionsTable> {
  $$ReactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get targetType => $composableBuilder(
      column: $table.targetType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetId => $composableBuilder(
      column: $table.targetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userAvatar => $composableBuilder(
      column: $table.userAvatar, builder: (column) => ColumnFilters(column));
}

class $$ReactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReactionsTable> {
  $$ReactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get targetType => $composableBuilder(
      column: $table.targetType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetId => $composableBuilder(
      column: $table.targetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userAvatar => $composableBuilder(
      column: $table.userAvatar, builder: (column) => ColumnOrderings(column));
}

class $$ReactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReactionsTable> {
  $$ReactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get targetType => $composableBuilder(
      column: $table.targetType, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get userAvatar => $composableBuilder(
      column: $table.userAvatar, builder: (column) => column);
}

class $$ReactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReactionsTable,
    Reaction,
    $$ReactionsTableFilterComposer,
    $$ReactionsTableOrderingComposer,
    $$ReactionsTableAnnotationComposer,
    $$ReactionsTableCreateCompanionBuilder,
    $$ReactionsTableUpdateCompanionBuilder,
    (Reaction, BaseReferences<_$AppDatabase, $ReactionsTable, Reaction>),
    Reaction,
    PrefetchHooks Function()> {
  $$ReactionsTableTableManager(_$AppDatabase db, $ReactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> targetType = const Value.absent(),
            Value<String> targetId = const Value.absent(),
            Value<String> emoji = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> userName = const Value.absent(),
            Value<String?> userAvatar = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReactionsCompanion(
            targetType: targetType,
            targetId: targetId,
            emoji: emoji,
            userId: userId,
            userName: userName,
            userAvatar: userAvatar,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String targetType,
            required String targetId,
            required String emoji,
            required String userId,
            Value<String?> userName = const Value.absent(),
            Value<String?> userAvatar = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReactionsCompanion.insert(
            targetType: targetType,
            targetId: targetId,
            emoji: emoji,
            userId: userId,
            userName: userName,
            userAvatar: userAvatar,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReactionsTable,
    Reaction,
    $$ReactionsTableFilterComposer,
    $$ReactionsTableOrderingComposer,
    $$ReactionsTableAnnotationComposer,
    $$ReactionsTableCreateCompanionBuilder,
    $$ReactionsTableUpdateCompanionBuilder,
    (Reaction, BaseReferences<_$AppDatabase, $ReactionsTable, Reaction>),
    Reaction,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  required String opId,
  required String entityType,
  Value<String?> entityLocalId,
  required String opType,
  Value<String> payloadJson,
  Value<int> attempts,
  Value<String?> lastError,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<String> opId,
  Value<String> entityType,
  Value<String?> entityLocalId,
  Value<String> opType,
  Value<String> payloadJson,
  Value<int> attempts,
  Value<String?> lastError,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get opId => $composableBuilder(
      column: $table.opId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityLocalId => $composableBuilder(
      column: $table.entityLocalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get opType => $composableBuilder(
      column: $table.opType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get opId => $composableBuilder(
      column: $table.opId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityLocalId => $composableBuilder(
      column: $table.entityLocalId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get opType => $composableBuilder(
      column: $table.opType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityLocalId => $composableBuilder(
      column: $table.entityLocalId, builder: (column) => column);

  GeneratedColumn<String> get opType =>
      $composableBuilder(column: $table.opType, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> opId = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String?> entityLocalId = const Value.absent(),
            Value<String> opType = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            opId: opId,
            entityType: entityType,
            entityLocalId: entityLocalId,
            opType: opType,
            payloadJson: payloadJson,
            attempts: attempts,
            lastError: lastError,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String opId,
            required String entityType,
            Value<String?> entityLocalId = const Value.absent(),
            required String opType,
            Value<String> payloadJson = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            opId: opId,
            entityType: entityType,
            entityLocalId: entityLocalId,
            opType: opType,
            payloadJson: payloadJson,
            attempts: attempts,
            lastError: lastError,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()>;
typedef $$SyncMetaTableCreateCompanionBuilder = SyncMetaCompanion Function({
  required String key,
  Value<String?> value,
  Value<int> rowid,
});
typedef $$SyncMetaTableUpdateCompanionBuilder = SyncMetaCompanion Function({
  Value<String> key,
  Value<String?> value,
  Value<int> rowid,
});

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncMetaTable,
    SyncMetaData,
    $$SyncMetaTableFilterComposer,
    $$SyncMetaTableOrderingComposer,
    $$SyncMetaTableAnnotationComposer,
    $$SyncMetaTableCreateCompanionBuilder,
    $$SyncMetaTableUpdateCompanionBuilder,
    (SyncMetaData, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>),
    SyncMetaData,
    PrefetchHooks Function()> {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetaCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetaCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncMetaTable,
    SyncMetaData,
    $$SyncMetaTableFilterComposer,
    $$SyncMetaTableOrderingComposer,
    $$SyncMetaTableAnnotationComposer,
    $$SyncMetaTableCreateCompanionBuilder,
    $$SyncMetaTableUpdateCompanionBuilder,
    (SyncMetaData, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>),
    SyncMetaData,
    PrefetchHooks Function()>;

typedef $$GuestContactsTableCreateCompanionBuilder = GuestContactsCompanion
    Function({
  required String id,
  Value<String> name,
  Value<String?> phone,
  Value<String?> email,
  Value<String> avatarColor,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$GuestContactsTableUpdateCompanionBuilder = GuestContactsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> phone,
  Value<String?> email,
  Value<String> avatarColor,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$GuestContactsTableFilterComposer
    extends Composer<_$AppDatabase, $GuestContactsTable> {
  $$GuestContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatarColor => $composableBuilder(
      column: $table.avatarColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$GuestContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $GuestContactsTable> {
  $$GuestContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarColor => $composableBuilder(
      column: $table.avatarColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$GuestContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GuestContactsTable> {
  $$GuestContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get avatarColor => $composableBuilder(
      column: $table.avatarColor, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GuestContactsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GuestContactsTable,
    GuestContact,
    $$GuestContactsTableFilterComposer,
    $$GuestContactsTableOrderingComposer,
    $$GuestContactsTableAnnotationComposer,
    $$GuestContactsTableCreateCompanionBuilder,
    $$GuestContactsTableUpdateCompanionBuilder,
    (
      GuestContact,
      BaseReferences<_$AppDatabase, $GuestContactsTable, GuestContact>
    ),
    GuestContact,
    PrefetchHooks Function()> {
  $$GuestContactsTableTableManager(
      _$AppDatabase db, $GuestContactsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GuestContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GuestContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GuestContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String> avatarColor = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GuestContactsCompanion(
            id: id,
            name: name,
            phone: phone,
            email: email,
            avatarColor: avatarColor,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> name = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String> avatarColor = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GuestContactsCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            email: email,
            avatarColor: avatarColor,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GuestContactsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GuestContactsTable,
    GuestContact,
    $$GuestContactsTableFilterComposer,
    $$GuestContactsTableOrderingComposer,
    $$GuestContactsTableAnnotationComposer,
    $$GuestContactsTableCreateCompanionBuilder,
    $$GuestContactsTableUpdateCompanionBuilder,
    (
      GuestContact,
      BaseReferences<_$AppDatabase, $GuestContactsTable, GuestContact>
    ),
    GuestContact,
    PrefetchHooks Function()>;

typedef $$LoansTableCreateCompanionBuilder = LoansCompanion Function({
  required String id,
  Value<String?> serverId,
  required String counterpartyId,
  Value<String> counterpartyType,
  Value<String> counterpartyName,
  Value<String?> counterpartyAvatar,
  Value<String> loanType,
  Value<double> amount,
  Value<double> paidAmount,
  Value<String> currency,
  Value<String> description,
  Value<String> notes,
  Value<DateTime?> dueDate,
  Value<String> status,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$LoansTableUpdateCompanionBuilder = LoansCompanion Function({
  Value<String> id,
  Value<String?> serverId,
  Value<String> counterpartyId,
  Value<String> counterpartyType,
  Value<String> counterpartyName,
  Value<String?> counterpartyAvatar,
  Value<String> loanType,
  Value<double> amount,
  Value<double> paidAmount,
  Value<String> currency,
  Value<String> description,
  Value<String> notes,
  Value<DateTime?> dueDate,
  Value<String> status,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$LoansTableFilterComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get counterpartyId => $composableBuilder(
      column: $table.counterpartyId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get counterpartyType => $composableBuilder(
      column: $table.counterpartyType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get counterpartyName => $composableBuilder(
      column: $table.counterpartyName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get counterpartyAvatar => $composableBuilder(
      column: $table.counterpartyAvatar,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get loanType => $composableBuilder(
      column: $table.loanType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get paidAmount => $composableBuilder(
      column: $table.paidAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$LoansTableOrderingComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get counterpartyId => $composableBuilder(
      column: $table.counterpartyId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get counterpartyType => $composableBuilder(
      column: $table.counterpartyType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get counterpartyName => $composableBuilder(
      column: $table.counterpartyName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get counterpartyAvatar => $composableBuilder(
      column: $table.counterpartyAvatar,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get loanType => $composableBuilder(
      column: $table.loanType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get paidAmount => $composableBuilder(
      column: $table.paidAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$LoansTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get counterpartyId => $composableBuilder(
      column: $table.counterpartyId, builder: (column) => column);

  GeneratedColumn<String> get counterpartyType => $composableBuilder(
      column: $table.counterpartyType, builder: (column) => column);

  GeneratedColumn<String> get counterpartyName => $composableBuilder(
      column: $table.counterpartyName, builder: (column) => column);

  GeneratedColumn<String> get counterpartyAvatar => $composableBuilder(
      column: $table.counterpartyAvatar, builder: (column) => column);

  GeneratedColumn<String> get loanType =>
      $composableBuilder(column: $table.loanType, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get paidAmount => $composableBuilder(
      column: $table.paidAmount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$LoansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LoansTable,
    Loan,
    $$LoansTableFilterComposer,
    $$LoansTableOrderingComposer,
    $$LoansTableAnnotationComposer,
    $$LoansTableCreateCompanionBuilder,
    $$LoansTableUpdateCompanionBuilder,
    (Loan, BaseReferences<_$AppDatabase, $LoansTable, Loan>),
    Loan,
    PrefetchHooks Function()> {
  $$LoansTableTableManager(_$AppDatabase db, $LoansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<String> counterpartyId = const Value.absent(),
            Value<String> counterpartyType = const Value.absent(),
            Value<String> counterpartyName = const Value.absent(),
            Value<String?> counterpartyAvatar = const Value.absent(),
            Value<String> loanType = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<double> paidAmount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LoansCompanion(
            id: id,
            serverId: serverId,
            counterpartyId: counterpartyId,
            counterpartyType: counterpartyType,
            counterpartyName: counterpartyName,
            counterpartyAvatar: counterpartyAvatar,
            loanType: loanType,
            amount: amount,
            paidAmount: paidAmount,
            currency: currency,
            description: description,
            notes: notes,
            dueDate: dueDate,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> serverId = const Value.absent(),
            required String counterpartyId,
            Value<String> counterpartyType = const Value.absent(),
            Value<String> counterpartyName = const Value.absent(),
            Value<String?> counterpartyAvatar = const Value.absent(),
            Value<String> loanType = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<double> paidAmount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LoansCompanion.insert(
            id: id,
            serverId: serverId,
            counterpartyId: counterpartyId,
            counterpartyType: counterpartyType,
            counterpartyName: counterpartyName,
            counterpartyAvatar: counterpartyAvatar,
            loanType: loanType,
            amount: amount,
            paidAmount: paidAmount,
            currency: currency,
            description: description,
            notes: notes,
            dueDate: dueDate,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LoansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LoansTable,
    Loan,
    $$LoansTableFilterComposer,
    $$LoansTableOrderingComposer,
    $$LoansTableAnnotationComposer,
    $$LoansTableCreateCompanionBuilder,
    $$LoansTableUpdateCompanionBuilder,
    (Loan, BaseReferences<_$AppDatabase, $LoansTable, Loan>),
    Loan,
    PrefetchHooks Function()>;

typedef $$LoanPaymentsTableCreateCompanionBuilder = LoanPaymentsCompanion
    Function({
  required String id,
  Value<String?> serverId,
  required String loanId,
  Value<double> amount,
  Value<String> note,
  Value<String> method,
  Value<DateTime?> paidAt,
  Value<DateTime?> createdAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$LoanPaymentsTableUpdateCompanionBuilder = LoanPaymentsCompanion
    Function({
  Value<String> id,
  Value<String?> serverId,
  Value<String> loanId,
  Value<double> amount,
  Value<String> note,
  Value<String> method,
  Value<DateTime?> paidAt,
  Value<DateTime?> createdAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$LoanPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $LoanPaymentsTable> {
  $$LoanPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get loanId => $composableBuilder(
      column: $table.loanId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$LoanPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LoanPaymentsTable> {
  $$LoanPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get loanId => $composableBuilder(
      column: $table.loanId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$LoanPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoanPaymentsTable> {
  $$LoanPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get loanId =>
      $composableBuilder(column: $table.loanId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$LoanPaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LoanPaymentsTable,
    LoanPayment,
    $$LoanPaymentsTableFilterComposer,
    $$LoanPaymentsTableOrderingComposer,
    $$LoanPaymentsTableAnnotationComposer,
    $$LoanPaymentsTableCreateCompanionBuilder,
    $$LoanPaymentsTableUpdateCompanionBuilder,
    (
      LoanPayment,
      BaseReferences<_$AppDatabase, $LoanPaymentsTable, LoanPayment>
    ),
    LoanPayment,
    PrefetchHooks Function()> {
  $$LoanPaymentsTableTableManager(_$AppDatabase db, $LoanPaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoanPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoanPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoanPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<String> loanId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<DateTime?> paidAt = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LoanPaymentsCompanion(
            id: id,
            serverId: serverId,
            loanId: loanId,
            amount: amount,
            note: note,
            method: method,
            paidAt: paidAt,
            createdAt: createdAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> serverId = const Value.absent(),
            required String loanId,
            Value<double> amount = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<DateTime?> paidAt = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LoanPaymentsCompanion.insert(
            id: id,
            serverId: serverId,
            loanId: loanId,
            amount: amount,
            note: note,
            method: method,
            paidAt: paidAt,
            createdAt: createdAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LoanPaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LoanPaymentsTable,
    LoanPayment,
    $$LoanPaymentsTableFilterComposer,
    $$LoanPaymentsTableOrderingComposer,
    $$LoanPaymentsTableAnnotationComposer,
    $$LoanPaymentsTableCreateCompanionBuilder,
    $$LoanPaymentsTableUpdateCompanionBuilder,
    (
      LoanPayment,
      BaseReferences<_$AppDatabase, $LoanPaymentsTable, LoanPayment>
    ),
    LoanPayment,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db, _db.groupMembers);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$ExpenseSharesTableTableManager get expenseShares =>
      $$ExpenseSharesTableTableManager(_db, _db.expenseShares);
  $$ExpensePayersTableTableManager get expensePayers =>
      $$ExpensePayersTableTableManager(_db, _db.expensePayers);
  $$SettlementsTableTableManager get settlements =>
      $$SettlementsTableTableManager(_db, _db.settlements);
  $$PersonalExpensesTableTableManager get personalExpenses =>
      $$PersonalExpensesTableTableManager(_db, _db.personalExpenses);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db, _db.activities);
  $$ReactionsTableTableManager get reactions =>
      $$ReactionsTableTableManager(_db, _db.reactions);
  $$GuestContactsTableTableManager get guestContacts =>
      $$GuestContactsTableTableManager(_db, _db.guestContacts);
  $$LoansTableTableManager get loans =>
      $$LoansTableTableManager(_db, _db.loans);
  $$LoanPaymentsTableTableManager get loanPayments =>
      $$LoanPaymentsTableTableManager(_db, _db.loanPayments);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
}
