import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// General helper utilities
class Helpers {
  Helpers._();

  /// Trigger light haptic feedback
  static void lightHaptic() => HapticFeedback.lightImpact();

  /// Trigger medium haptic feedback
  static void mediumHaptic() => HapticFeedback.mediumImpact();

  /// Trigger heavy haptic feedback
  static void heavyHaptic() => HapticFeedback.heavyImpact();

  /// Trigger selection haptic feedback
  static void selectionHaptic() => HapticFeedback.selectionClick();

  /// Dismiss keyboard
  static void dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Generate a unique ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Delay execution
  static Future<void> delay([Duration duration = const Duration(milliseconds: 300)]) {
    return Future.delayed(duration);
  }
}
