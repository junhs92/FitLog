import 'dart:math';

/// Generates secure invite codes for trainer-client connections
class InviteCodeGenerator {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _random = Random.secure();

  /// Generate a 6-character alphanumeric code
  /// Format: ABC123 (no ambiguous chars like 0/O, 1/I/L)
  static String generate() {
    return List.generate(6, (_) => _chars[_random.nextInt(_chars.length)])
        .join();
  }

  /// Format code for display: ABC-123
  static String formatForDisplay(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 3)}-${code.substring(3)}';
  }

  /// Normalize code input (remove dashes, uppercase)
  static String normalize(String input) {
    return input.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
  }

  /// Validate code format
  static bool isValid(String code) {
    final normalized = normalize(code);
    if (normalized.length != 6) return false;
    return normalized.split('').every((c) => _chars.contains(c));
  }

  /// Generate deep link URL for invite
  static String generateDeepLink(String code) {
    return 'fitlogpro://invite?code=$code';
  }

  /// Generate web fallback URL (for when app not installed)
  static String generateWebLink(String code) {
    return 'https://fitlogpro.app/invite/$code';
  }
}
