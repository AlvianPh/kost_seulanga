import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final DateFormat _humanReadableDateFormatter = DateFormat('d MMM yyyy', 'id_ID');

  /// Formats a number to Rupiah currency format without decimal digits.
  /// Example: 700000 -> "Rp 700.000"
  static String formatCurrency(double amount) {
    return _rupiahFormatter.format(amount);
  }

  /// Formats a DateTime object into a human-readable string.
  /// Example: DateTime(2026, 6, 17) -> "17 Jun 2026"
  static String formatDate(DateTime date) {
    return _humanReadableDateFormatter.format(date);
  }
}

extension CurrencyFormattingExtension on num {
  /// Formats this number to Rupiah currency layout.
  /// Example: `room.monthlyRentPrice.toRupiah()` -> `"Rp 700.000"`
  String toRupiah() => AppFormatters.formatCurrency(toDouble());
}

extension DateFormattingExtension on DateTime {
  /// Formats this DateTime to a human-readable Indonesian layout.
  /// Example: `DateTime.now().toHumanReadable()` -> `"18 Jun 2026"`
  String toHumanReadable() => AppFormatters.formatDate(this);
}
