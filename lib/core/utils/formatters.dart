import 'package:intl/intl.dart';

/// Data formatting utilities
class Formatters {
  Formatters._();

  // Date formatters
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _displayDateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _displayTimeFormat = DateFormat('h:mm a');
  static final DateFormat _koreanDateFormat = DateFormat('yyyy년 M월 d일');

  /// Format date as yyyy-MM-dd
  static String date(DateTime dateTime) => _dateFormat.format(dateTime);

  /// Format time as HH:mm
  static String time(DateTime dateTime) => _timeFormat.format(dateTime);

  /// Format datetime as yyyy-MM-dd HH:mm
  static String dateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  /// Format date for display (e.g., "Dec 5, 2025")
  static String displayDate(DateTime dateTime) =>
      _displayDateFormat.format(dateTime);

  /// Format time for display (e.g., "3:30 PM")
  static String displayTime(DateTime dateTime) =>
      _displayTimeFormat.format(dateTime);

  /// Format date in Korean (e.g., "2025년 12월 5일")
  static String koreanDate(DateTime dateTime) =>
      _koreanDateFormat.format(dateTime);

  /// Format duration as "Xh Ym"
  static String duration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Format weight with unit
  static String weight(double value, {String unit = 'kg'}) {
    if (value == value.roundToDouble()) {
      return '${value.round()}$unit';
    }
    return '${value.toStringAsFixed(1)}$unit';
  }

  /// Format reps
  static String reps(int value) => '$value reps';

  /// Format sets
  static String sets(int value) => '$value sets';

  /// Format relative time (e.g., "2 hours ago")
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return displayDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
