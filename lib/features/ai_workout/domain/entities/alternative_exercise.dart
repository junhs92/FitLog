import 'session_feedback.dart';

/// Result container for alternative exercises grouped by type
class AlternativeExercisesResult {
  /// Alternatives with different equipment (same movement pattern)
  final List<EquipmentGroup> equipmentAlternatives;

  /// Alternatives with same equipment (pattern variations)
  final List<SessionAlternative> patternAlternatives;

  /// Accessory/isolation exercises in the same movement group
  final List<SessionAlternative> accessoryExercises;

  const AlternativeExercisesResult({
    this.equipmentAlternatives = const [],
    this.patternAlternatives = const [],
    this.accessoryExercises = const [],
  });

  /// Check if there are no alternatives available
  bool get isEmpty =>
      equipmentAlternatives.isEmpty &&
      patternAlternatives.isEmpty &&
      accessoryExercises.isEmpty;

  /// Check if there are alternatives available
  bool get isNotEmpty => !isEmpty;

  /// Create an empty result
  static AlternativeExercisesResult empty() =>
      const AlternativeExercisesResult();
}

/// Group of exercises with the same equipment type
class EquipmentGroup {
  /// Equipment identifier (e.g., 'dumbbell', 'barbell', 'cable')
  final String equipment;

  /// Korean display label for the equipment
  final String equipmentLabel;

  /// Exercises using this equipment
  final List<SessionAlternative> exercises;

  const EquipmentGroup({
    required this.equipment,
    required this.equipmentLabel,
    required this.exercises,
  });
}

/// Equipment label mapping utility
class EquipmentLabels {
  static const Map<String, String> _labels = {
    'dumbbell': '덤벨',
    'barbell': '바벨',
    'cable': '케이블',
    'machine': '머신',
    'bodyweight': '맨몸',
    'smith_machine': '스미스머신',
    'kettlebell': '케틀벨',
    'resistance_band': '밴드',
    'ez_bar': 'EZ바',
    'other': '기타',
  };

  /// Equipment priority order for alternative exercise display
  /// 맨몸 → 머신 → 바벨 → 덤벨 → 기타
  static const List<String> priorityOrder = [
    'bodyweight',
    'machine',
    'barbell',
    'dumbbell',
    'cable',
    'smith_machine',
    'kettlebell',
    'resistance_band',
    'ez_bar',
    'other',
  ];

  /// Get Korean label for equipment
  static String getLabel(String? equipment) {
    if (equipment == null) return '기타';
    return _labels[equipment.toLowerCase()] ?? equipment;
  }

  /// Get all available equipment types
  static List<String> get allTypes => _labels.keys.toList();

  /// Get priority index for sorting equipment groups
  /// Lower index = higher priority
  static int getPriorityIndex(String? equipment) {
    if (equipment == null) return priorityOrder.length;
    final index = priorityOrder.indexOf(equipment.toLowerCase());
    return index == -1 ? priorityOrder.length : index;
  }
}
