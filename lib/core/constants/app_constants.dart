/// Application-wide constants
class AppConstants {
  AppConstants._();

  // User roles
  static const String roleTrainer = 'trainer';
  static const String roleClient = 'client';

  // Trainer verification code
  static const String trainerVerificationCode = 'fitlogcertified';

  // Session status
  static const String sessionStatusActive = 'active';
  static const String sessionStatusCompleted = 'completed';
  static const String sessionStatusCancelled = 'cancelled';

  // Exercise difficulty feedback
  static const String difficultyTooEasy = 'too_easy';
  static const String difficultyOptimal = 'optimal';
  static const String difficultyTooHard = 'too_hard';

  // Movement groups
  static const List<String> movementGroups = [
    'push',
    'pull',
    'legs',
    'core',
    'other',
  ];

  // RPE scale
  static const int rpeMin = 1;
  static const int rpeMax = 10;

  // Lifestyle logging
  static const List<String> moodOptions = [
    'great',
    'good',
    'okay',
    'tired',
    'stressed',
  ];

  static const List<String> energyLevels = [
    'high',
    'moderate',
    'low',
  ];

  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxNotesLength = 500;
}
