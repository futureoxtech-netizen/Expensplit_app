import 'package:flutter/services.dart';

/// Restricts a text field to a well-formed monetary amount: digits, an optional
/// single decimal point, at most [maxDecimals] decimal places, and at most
/// [maxIntegerDigits] whole digits. This both blocks non-numeric input and caps
/// the magnitude so absurd values can't break layouts.
class AmountInputFormatter extends TextInputFormatter {
  AmountInputFormatter({this.maxIntegerDigits = 12, this.maxDecimals = 2});

  final int maxIntegerDigits;
  final int maxDecimals;

  late final RegExp _re = RegExp(
    r'^\d{0,' '$maxIntegerDigits' r'}(\.\d{0,' '$maxDecimals' r'}?)?$',
  );

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    // Reject a leading dot like ".5" by requiring a digit first; allow "0.5".
    if (text == '.') {
      return const TextEditingValue(
        text: '0.',
        selection: TextSelection.collapsed(offset: 2),
      );
    }
    if (_re.hasMatch(text)) return newValue;
    // Invalid edit → keep the previous value.
    return oldValue;
  }

  /// Convenience: the formatter list to drop onto an amount field.
  static List<TextInputFormatter> list({int maxIntegerDigits = 12, int maxDecimals = 2}) =>
      [AmountInputFormatter(maxIntegerDigits: maxIntegerDigits, maxDecimals: maxDecimals)];
}
