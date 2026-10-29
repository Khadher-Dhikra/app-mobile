class CurrencyFormatter {
  static String format(num amount) {
    if (amount % 1 == 0) {
      return '${amount.toInt()} TND';
    }
    return '${amount.toStringAsFixed(1)} TND';
  }
}
