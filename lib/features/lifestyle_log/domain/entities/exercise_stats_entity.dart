import 'package:equatable/equatable.dart';

/// Entity representing aggregated exercise performance statistics
class ExerciseStatsEntity extends Equatable {
  final String exerciseId;
  final String exerciseName;
  final String exerciseNameKo;
  final String muscleGroup;
  final int timesPerformed; // session count
  final int totalSets;
  final double? maxWeight;
  final double? bestVolume; // single set volume (weight × reps)
  final double? estimated1RM;
  final DateTime? lastPerformedAt;

  const ExerciseStatsEntity({
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseNameKo,
    required this.muscleGroup,
    required this.timesPerformed,
    required this.totalSets,
    this.maxWeight,
    this.bestVolume,
    this.estimated1RM,
    this.lastPerformedAt,
  });

  /// Korean display name with fallback to English
  String get displayName => exerciseNameKo.isNotEmpty ? exerciseNameKo : exerciseName;

  /// Formatted max weight display
  String get maxWeightDisplay => maxWeight != null
      ? '${maxWeight!.toStringAsFixed(1)} kg'
      : '-';

  /// Formatted estimated 1RM display
  String get estimated1RMDisplay => estimated1RM != null
      ? '${estimated1RM!.toStringAsFixed(1)} kg'
      : '-';

  /// Formatted best volume display
  String get bestVolumeDisplay => bestVolume != null
      ? '${bestVolume!.toStringAsFixed(0)} kg'
      : '-';

  /// Format last performed date relative to now
  String get lastPerformedDisplay {
    if (lastPerformedAt == null) return '-';

    final now = DateTime.now();
    final diff = now.difference(lastPerformedAt!);

    if (diff.inDays == 0) {
      return '오늘';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks주 전';
    } else {
      final months = (diff.inDays / 30).floor();
      return '$months개월 전';
    }
  }

  @override
  List<Object?> get props => [
        exerciseId,
        exerciseName,
        exerciseNameKo,
        muscleGroup,
        timesPerformed,
        totalSets,
        maxWeight,
        bestVolume,
        estimated1RM,
        lastPerformedAt,
      ];
}
