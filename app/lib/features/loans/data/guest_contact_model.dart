class GuestContactModel {
  GuestContactModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.avatarColor = '#6C5CE7',
  });

  factory GuestContactModel.fromJson(Map<String, dynamic> j) => GuestContactModel(
        id: (j['_id'] ?? j['id']).toString(),
        name: j['name']?.toString() ?? '',
        phone: j['phone']?.toString(),
        email: j['email']?.toString(),
        avatarColor: j['avatarColor']?.toString() ?? '#6C5CE7',
      );

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String avatarColor;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        'avatarColor': avatarColor,
        'isGuest': true,
      };
}
