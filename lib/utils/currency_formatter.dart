import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _lkrFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'LKR ',
    decimalDigits: 2,
  );

  static String formatLkr(num amount) {
    return _lkrFormatter.format(amount);
  }
}
