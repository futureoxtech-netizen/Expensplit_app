import 'package:intl/intl.dart';

class Money {
  Money._();
  static String format(num amount, {String code = 'USD'}) {
    final f = NumberFormat.currency(symbol: symbolOf(code), decimalDigits: 2);
    return f.format(amount);
  }

  static String symbolOf(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'PKR':
        return '₨';
      case 'JPY':
        return '¥';
      case 'CAD':
        return r'C$';
      case 'AUD':
        return r'A$';
      default:
        return '$code ';
    }
  }
}

class DateFmt {
  DateFmt._();
  static String relative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(dt);
  }

  static String medium(DateTime dt) => DateFormat('MMM d, y').format(dt);
  static String monthShort(int m) =>
      DateFormat.MMM().format(DateTime(2000, m));
}
