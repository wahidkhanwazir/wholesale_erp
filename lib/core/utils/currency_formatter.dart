import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Formats double as PKR currency string: "Rs. 1,25,000"
  static String format(double amount, {bool showSymbol = true}) {
    final formatted = NumberFormat('#,##0', 'en_US').format(amount.round());
    if (showSymbol) {
      return 'Rs. $formatted';
    }
    return formatted;
  }

  /// Compact format for dashboard stat cards: "Rs. 1.45M" or "Rs. 450K"
  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      return 'Rs. ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return 'Rs. ${(amount / 100000).toStringAsFixed(2)} Lakh';
    } else if (amount >= 1000) {
      return 'Rs. ${(amount / 1000).toStringAsFixed(1)}k';
    }
    return format(amount);
  }
}
