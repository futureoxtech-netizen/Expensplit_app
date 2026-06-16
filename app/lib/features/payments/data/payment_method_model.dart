import 'package:flutter/material.dart';

/// Metadata for a payment method "type" — drives the icon, colour and label
/// shown wherever payment methods are listed (profile + groups).
class PaymentType {
  const PaymentType(this.id, this.label, this.icon, this.color, {this.hint});

  final String id;
  final String label;
  final IconData icon;
  final Color color;

  /// Placeholder text for the "account number / handle" field, tailored to the
  /// type (an IBAN for a bank, a phone number for a wallet, an email for PayPal…).
  final String? hint;

  static const List<PaymentType> all = [
    PaymentType('bank', 'Bank account', Icons.account_balance_rounded,
        Color(0xFF4C6EF5), hint: 'Account number or IBAN'),
    PaymentType('easypaisa', 'EasyPaisa', Icons.account_balance_wallet_rounded,
        Color(0xFF2E7D32), hint: 'Registered mobile number'),
    PaymentType('jazzcash', 'JazzCash', Icons.account_balance_wallet_rounded,
        Color(0xFFD81B60), hint: 'Registered mobile number'),
    PaymentType('sadapay', 'SadaPay', Icons.credit_card_rounded,
        Color(0xFF00B894), hint: 'Account number or @tag'),
    PaymentType('nayapay', 'NayaPay', Icons.credit_card_rounded,
        Color(0xFF6C5CE7), hint: 'Account number or @tag'),
    PaymentType('raast', 'Raast', Icons.bolt_rounded,
        Color(0xFF0984E3), hint: 'Raast ID (mobile number)'),
    PaymentType('paypal', 'PayPal', Icons.alternate_email_rounded,
        Color(0xFF003087), hint: 'PayPal email'),
    PaymentType('wise', 'Wise', Icons.public_rounded,
        Color(0xFF9FE870), hint: 'Email or account number'),
    PaymentType('upi', 'UPI', Icons.qr_code_rounded,
        Color(0xFFFB8C00), hint: 'UPI ID (name@bank)'),
    PaymentType('card', 'Card', Icons.credit_card_rounded,
        Color(0xFF546E7A), hint: 'Card number'),
    PaymentType('crypto', 'Crypto', Icons.currency_bitcoin,
        Color(0xFFF7931A), hint: 'Wallet address'),
    PaymentType('other', 'Other', Icons.payments_rounded,
        Color(0xFF8E8E93), hint: 'Account details'),
  ];

  static PaymentType of(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.last);
}

/// A saved/shared payment method. The same model is used for both a user's
/// profile methods and the payment info shared inside a group. When it comes
/// from a group, [userId]/[userName]/[userAvatar] identify the member who owns
/// it (null for profile methods).
class PaymentMethodModel {
  const PaymentMethodModel({
    required this.id,
    required this.type,
    this.label = '',
    this.accountName = '',
    this.accountNumber = '',
    this.bankName = '',
    this.note = '',
    this.userId,
    this.userName,
    this.userAvatar,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> j) {
    final user = j['user'];
    return PaymentMethodModel(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      type: (j['type'] ?? 'other').toString(),
      label: (j['label'] ?? '').toString(),
      accountName: (j['accountName'] ?? '').toString(),
      accountNumber: (j['accountNumber'] ?? '').toString(),
      bankName: (j['bankName'] ?? '').toString(),
      note: (j['note'] ?? '').toString(),
      userId: (j['userId'] ?? (user is Map ? user['id'] : null))?.toString(),
      userName: user is Map ? user['name']?.toString() : null,
      userAvatar: user is Map ? user['avatarUrl']?.toString() : null,
    );
  }

  Map<String, dynamic> toInput() => {
        'type': type,
        'label': label,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'bankName': bankName,
        'note': note,
      };

  final String id;
  final String type;
  final String label;
  final String accountName;

  /// The actual "send money here" value — IBAN, wallet number, email, etc.
  final String accountNumber;
  final String bankName;
  final String note;

  // Only set for group-shared payment info.
  final String? userId;
  final String? userName;
  final String? userAvatar;

  PaymentType get typeMeta => PaymentType.of(type);

  /// A friendly one-line title: the custom label if given, otherwise the type.
  String get title => label.trim().isNotEmpty ? label.trim() : typeMeta.label;

  /// Everything a person needs to actually send the money, as copyable text.
  String get copyText {
    final lines = <String>[
      '${typeMeta.label}${bankName.trim().isNotEmpty ? ' · ${bankName.trim()}' : ''}',
      if (accountName.trim().isNotEmpty) 'Name: ${accountName.trim()}',
      'Account: $accountNumber',
      if (note.trim().isNotEmpty) 'Note: ${note.trim()}',
    ];
    return lines.join('\n');
  }

  PaymentMethodModel copyWith({
    String? type,
    String? label,
    String? accountName,
    String? accountNumber,
    String? bankName,
    String? note,
  }) =>
      PaymentMethodModel(
        id: id,
        type: type ?? this.type,
        label: label ?? this.label,
        accountName: accountName ?? this.accountName,
        accountNumber: accountNumber ?? this.accountNumber,
        bankName: bankName ?? this.bankName,
        note: note ?? this.note,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
      );
}
