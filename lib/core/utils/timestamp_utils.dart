/// Timestamp utilities for consistent local timezone handling
///
/// Supabase interprets ISO8601 strings without timezone offset as UTC.
/// These utilities ensure timestamps include the local timezone offset
/// so times are stored and displayed correctly.

/// Format DateTime with local timezone offset for database storage
///
/// Example output: "2024-12-25T15:30:00.000+09:00"
String toLocalIso8601(DateTime dateTime) {
  final local = dateTime.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  return '${local.toIso8601String()}$sign$hours:$minutes';
}

/// Current time with timezone offset
///
/// Use this instead of `DateTime.now().toIso8601String()` when saving to database
String nowLocalIso8601() => toLocalIso8601(DateTime.now());
