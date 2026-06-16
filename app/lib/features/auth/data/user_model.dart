import '../../payments/data/payment_method_model.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.currency = 'PKR',
    this.locale = 'en-US',
    this.bio = '',
    this.referralCode,
    this.isPlaceholder = false,
    this.groupInvitePolicy = 'anyone',
    this.paymentMethods = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: (j['id'] ?? j['_id']).toString(),
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        avatarUrl: j['avatarUrl'] ?? '',
        currency: j['currency'] ?? 'PKR',
        locale: j['locale'] ?? 'en-US',
        bio: j['bio'] ?? '',
        referralCode: j['referralCode'],
        isPlaceholder: j['isPlaceholder'] == true,
        groupInvitePolicy: (j['groupInvitePolicy'] ?? 'anyone').toString(),
        paymentMethods: ((j['paymentMethods'] ?? const []) as List)
            .whereType<Map>()
            .map((m) => PaymentMethodModel.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
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
        'isPlaceholder': isPlaceholder,
        'groupInvitePolicy': groupInvitePolicy,
        'paymentMethods': paymentMethods
            .map((m) => {'id': m.id, ...m.toInput()})
            .toList(),
      };

  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String currency;
  final String locale;
  final String bio;
  final String? referralCode;

  /// True for "guest" members who aren't on Expensplit — they can be split
  /// with but have no account, email or login. See the backend placeholder
  /// user docs.
  final bool isPlaceholder;

  /// Who may add this user to a group: `'anyone'` (added directly) or
  /// `'approval'` (added as a pending invite they must accept first).
  final String groupInvitePolicy;

  /// Payment methods the user saved on their profile (bank, wallets, etc.).
  final List<PaymentMethodModel> paymentMethods;

  bool get requiresGroupApproval => groupInvitePolicy == 'approval';

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    String? currency,
    String? locale,
    String? bio,
    String? groupInvitePolicy,
    List<PaymentMethodModel>? paymentMethods,
  }) =>
      UserModel(
        id: id,
        email: email,
        referralCode: referralCode,
        isPlaceholder: isPlaceholder,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        currency: currency ?? this.currency,
        locale: locale ?? this.locale,
        bio: bio ?? this.bio,
        groupInvitePolicy: groupInvitePolicy ?? this.groupInvitePolicy,
        paymentMethods: paymentMethods ?? this.paymentMethods,
      );
}
