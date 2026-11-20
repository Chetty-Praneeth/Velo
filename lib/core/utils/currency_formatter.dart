import 'package:intl/intl.dart';

/// Utility for formatting currency values.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrDecimalFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format as ₹10,000 (no decimals).
  static String format(double amount) {
    return _inrFormat.format(amount);
  }

  /// Format as ₹10,000.50 (with decimals).
  static String formatDecimal(double amount) {
    return _inrDecimalFormat.format(amount);
  }

  /// Format as ₹10,000/day.
  static String formatPerDay(double amount) {
    return '${_inrFormat.format(amount)}/day';
  }

  /// Format as compact: ₹10K, ₹1.5L.
  static String formatCompact(double amount) {
    if (amount.abs() >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount.abs() >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return _inrFormat.format(amount);
  }

  /// Format with sign: +₹500 or -₹300.
  static String formatWithSign(double amount) {
    final prefix = amount >= 0 ? '+' : '';
    return '$prefix${_inrFormat.format(amount)}';
  }
}
