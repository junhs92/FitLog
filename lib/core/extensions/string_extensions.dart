/// String extensions for common operations
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalized {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Capitalize each word
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalized).join(' ');
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(this);
  }

  /// Check if string is a valid phone number (Korean)
  bool get isValidKoreanPhone {
    return RegExp(r'^01[0-9]{8,9}$').hasMatch(replaceAll('-', ''));
  }

  /// Check if string is numeric
  bool get isNumeric {
    return double.tryParse(this) != null;
  }

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Truncate with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Get initials (first letter of each word)
  String get initials {
    if (isEmpty) return '';
    return split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase())
        .take(2)
        .join();
  }

  /// Convert to nullable (returns null if empty)
  String? get nullIfEmpty => isEmpty ? null : this;

  /// Parse as DateTime or return null
  DateTime? toDateTime() => DateTime.tryParse(this);

  /// Parse as int or return null
  int? toInt() => int.tryParse(this);

  /// Parse as double or return null
  double? toDouble() => double.tryParse(this);
}
