import 'package:intl/intl.dart';

class DateFormatter {
  static String formatFullDate(DateTime dateTime) {
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(dateTime);
  }

  static String formatShortDate(DateTime dateTime) {
    return DateFormat('d MMM yyyy', 'fr_FR').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatShortDate(dateTime)} à ${formatTime(dateTime)}';
  }
}
