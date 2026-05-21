import 'package:intl/intl.dart';

String formatInr(double amount, {bool compact = false}) {
  if (compact) {
    if (amount.abs() >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount.abs() >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
  }

  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}
