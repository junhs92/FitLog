import 'package:equatable/equatable.dart';

/// Entity representing a single session's volume for an exercise
class ExerciseSessionVolumeEntity extends Equatable {
  final String sessionId;
  final DateTime sessionDate;
  final double totalVolume;
  final int setCount;
  final bool hasPR;
  final String? prType; // 'weight', 'volume', 'reps'
  final List<String> comments; // Raw comment strings from DB
  final DateTime? completedAt; // Timestamp for when comments were given

  const ExerciseSessionVolumeEntity({
    required this.sessionId,
    required this.sessionDate,
    required this.totalVolume,
    required this.setCount,
    this.hasPR = false,
    this.prType,
    this.comments = const [],
    this.completedAt,
  });

  /// Formatted volume display
  String get volumeDisplay {
    if (totalVolume >= 1000) {
      return '${(totalVolume / 1000).toStringAsFixed(1)}t';
    }
    return '${totalVolume.toStringAsFixed(0)} kg';
  }

  /// PR type display in Korean
  String get prTypeDisplayKo {
    switch (prType) {
      case 'weight':
        return '최고중량 PR';
      case 'volume':
        return '볼륨 PR';
      case 'reps':
        return '최대횟수 PR';
      default:
        return 'PR';
    }
  }

  /// Check if session has any comments
  bool get hasComments => comments.isNotEmpty;

  @override
  List<Object?> get props => [
        sessionId,
        sessionDate,
        totalVolume,
        setCount,
        hasPR,
        prType,
        comments,
        completedAt,
      ];
}

/// Entity representing aggregated comment frequency for an exercise
class ExerciseCommentSummaryEntity extends Equatable {
  final String commentKey; // e.g., 'chest_up'
  final String? detail; // e.g., 'knee area' for 'pain_reported:knee area'
  final int count; // Frequency across all sessions
  final DateTime? lastUsedAt; // Most recent occurrence

  const ExerciseCommentSummaryEntity({
    required this.commentKey,
    this.detail,
    required this.count,
    this.lastUsedAt,
  });

  @override
  List<Object?> get props => [commentKey, detail, count, lastUsedAt];
}

/// Entity representing the complete volume history for an exercise
class ExerciseVolumeHistoryEntity extends Equatable {
  final String exerciseId;
  final String exerciseName;
  final String exerciseNameKo;
  final List<ExerciseSessionVolumeEntity> sessions;
  final List<ExerciseCommentSummaryEntity> commentSummary; // Aggregated comments sorted by frequency

  const ExerciseVolumeHistoryEntity({
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseNameKo,
    required this.sessions,
    this.commentSummary = const [],
  });

  /// Display name with Korean fallback
  String get displayName =>
      exerciseNameKo.isNotEmpty ? exerciseNameKo : exerciseName;

  /// Check if there's any data
  bool get isEmpty => sessions.isEmpty;

  /// Check if there's only one session
  bool get isSingleSession => sessions.length == 1;

  /// Get sessions with PR achievements
  List<ExerciseSessionVolumeEntity> get sessionsWithPR =>
      sessions.where((s) => s.hasPR).toList();

  /// Get total session count
  int get sessionCount => sessions.length;

  /// Get average volume per session
  double get averageVolume {
    if (sessions.isEmpty) return 0;
    return sessions.fold(0.0, (sum, s) => sum + s.totalVolume) / sessions.length;
  }

  /// Get maximum volume in a single session
  double get maxSessionVolume {
    if (sessions.isEmpty) return 0;
    return sessions.map((s) => s.totalVolume).reduce((a, b) => a > b ? a : b);
  }

  /// Get minimum volume in a single session
  double get minSessionVolume {
    if (sessions.isEmpty) return 0;
    return sessions.map((s) => s.totalVolume).reduce((a, b) => a < b ? a : b);
  }

  /// Check if there are any comments across all sessions
  bool get hasComments => commentSummary.isNotEmpty;

  @override
  List<Object?> get props => [
        exerciseId,
        exerciseName,
        exerciseNameKo,
        sessions,
        commentSummary,
      ];
}
