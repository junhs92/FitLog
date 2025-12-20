/// API-related constants
class ApiConstants {
  ApiConstants._();

  // Supabase table names
  static const String accountsTable = 'accounts';
  static const String trainerClientRelationshipsTable = 'trainer_client_relationships';
  static const String sessionsTable = 'sessions';
  static const String exercisesTable = 'exercises';
  static const String setsTable = 'sets';
  static const String lifestyleLogsTable = 'lifestyle_logs';
  static const String mealLogsTable = 'meal_logs';
  static const String bodyPhotosTable = 'body_photos';

  // Storage buckets
  static const String mediaBucket = 'media';
  static const String profilePhotosBucket = 'profile-photos';
  static const String bodyPhotosBucket = 'body-photos';
  static const String mealPhotosBucket = 'meal-photos';

  // Edge function names
  static const String generateWorkoutFunction = 'generate-workout';
  static const String generateReportFunction = 'generate-report';
  static const String analyzeNutritionFunction = 'analyze-nutrition';
}
