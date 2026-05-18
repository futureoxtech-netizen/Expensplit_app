class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.currency = 'USD',
    this.locale = 'en-US',
    this.bio = '',
    this.referralCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: (j['id'] ?? j['_id']).toString(),
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        avatarUrl: j['avatarUrl'] ?? '',
        currency: j['currency'] ?? 'USD',
        locale: j['locale'] ?? 'en-US',
        bio: j['bio'] ?? '',
        referralCode: j['referralCode'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'currency': currency,
        'locale': locale,
        'bio': bio,
        'referralCode': referralCode,
      };

  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String currency;
  final String locale;
  final String bio;
  final String? referralCode;

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    String? currency,
    String? locale,
    String? bio,
  }) =>
      UserModel(
        id: id,
        email: email,
        referralCode: referralCode,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        currency: currency ?? this.currency,
        locale: locale ?? this.locale,
        bio: bio ?? this.bio,
      );
}
