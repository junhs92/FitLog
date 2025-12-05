/// Application configuration constants and environment handling
class AppConfig {
  AppConfig._();

  // App info
  static const String appName = 'FitLog Pro';
  static const String appVersion = '1.0.0';

  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  // Feature flags
  static const bool enableOfflineMode = true;
  static const bool enableVoiceInput = true;
  static const bool enableAIFeatures = true;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration syncInterval = Duration(minutes: 5);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Session
  static const Duration sessionLoggingTimeout = Duration(seconds: 60);
}
