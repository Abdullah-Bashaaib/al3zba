import 'package:intl/intl.dart';

class EzbaFormatters {
  static final NumberFormat _numberFormat = NumberFormat('#,##0.##', 'en_US');
  static final DateFormat _dateFormat = DateFormat('yyyy/MM/dd', 'ar');

  static String formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return NumberFormat('#,##0', 'en_US').format(amount);
    }
    return _numberFormat.format(amount);
  }

  static String formatCurrency(double amount, [String currency = 'YER']) {
    return '${formatAmount(amount)} $currency';
  }

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }
}
