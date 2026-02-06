/// Training split options for dynamic session generation
enum TrainingSplit {
  fullBody('full_body', 'Full Body', '전신'),
  upperLower('upper_lower', 'Upper/Lower', '상체/하체'),
  pushPullLegs('push_pull_legs', 'Push/Pull/Legs', '밀기/당기기/하체');

  final String id;
  final String name;
  final String nameKo;

  const TrainingSplit(this.id, this.name, this.nameKo);

  String get displayName => nameKo;

  /// Parse from string, handling legacy values (bro_split, custom) by mapping to fullBody
  static TrainingSplit fromString(String value) {
    // Handle legacy values by mapping to fullBody
    if (value == 'bro_split' || value == 'custom') {
      return TrainingSplit.fullBody;
    }
    return TrainingSplit.values.firstWhere(
      (s) => s.id == value,
      orElse: () => TrainingSplit.fullBody,
    );
  }
}

/// Training goal for program generation
/// Note: This is fetched from ClientEntity.goals (accounts.fitness_goals) for AI workout generation
/// Programs no longer store goals directly - they store preferences for exercise selection
enum TrainingGoal {
  strength('strength', 'Strength', '근력 향상'),
  hypertrophy('hypertrophy', 'Muscle Building', '근비대'),
  endurance('endurance', 'Endurance', '근지구력'),
  weightLoss('weight_loss', 'Weight Loss', '체중 감량'),
  generalFitness('general_fitness', 'General Fitness', '전반적 체력'),
  rehabilitation('rehabilitation', 'Rehabilitation', '재활'),
  athletic('athletic', 'Athletic Performance', '운동 능력');

  final String id;
  final String name;
  final String nameKo;

  const TrainingGoal(this.id, this.name, this.nameKo);

  String get displayName => nameKo;

  static TrainingGoal fromString(String value) {
    return TrainingGoal.values.firstWhere(
      (g) => g.id == value,
      orElse: () => TrainingGoal.generalFitness,
    );
  }
}

/// Movement group preferences for exercise selection
/// AI will prioritize exercises matching these groups when generating workouts
enum PreferredMovementGroup {
  push('push', 'Push', '밀기'),
  pull('pull', 'Pull', '당기기'),
  legs('legs', 'Legs', '하체'),
  core('core', 'Core', '코어'),
  other('other', 'Other', '기타');

  final String id;
  final String name;
  final String nameKo;

  const PreferredMovementGroup(this.id, this.name, this.nameKo);

  String get displayName => nameKo;

  /// Parse from string, handling legacy movement pattern values
  static PreferredMovementGroup fromString(String value) {
    // Handle legacy movement pattern values
    switch (value) {
      case 'horizontal_push':
      case 'vertical_push':
        return PreferredMovementGroup.push;
      case 'horizontal_pull':
      case 'vertical_pull':
        return PreferredMovementGroup.pull;
      case 'squat':
      case 'hinge':
        return PreferredMovementGroup.legs;
      case 'functional':
      case 'carry':
      case 'rotation':
        return PreferredMovementGroup.core;
      case 'isolation':
      case 'cardio':
        return PreferredMovementGroup.other;
    }
    // Direct match for new values
    return PreferredMovementGroup.values.firstWhere(
      (p) => p.id == value,
      orElse: () => PreferredMovementGroup.other,
    );
  }

  static List<PreferredMovementGroup> fromStringList(List<String> values) {
    return values.map((v) => fromString(v)).toSet().toList();
  }

  static List<String> toStringList(List<PreferredMovementGroup> groups) {
    return groups.map((g) => g.id).toList();
  }
}

/// Program status
enum ProgramStatus {
  draft('draft', 'Draft', '초안'),
  active('active', 'Active', '활성'),
  completed('completed', 'Completed', '완료'),
  archived('archived', 'Archived', '보관');

  final String id;
  final String name;
  final String nameKo;

  const ProgramStatus(this.id, this.name, this.nameKo);

  String get displayName => nameKo;

  static ProgramStatus fromString(String value) {
    return ProgramStatus.values.firstWhere(
      (s) => s.id == value,
      orElse: () => ProgramStatus.draft,
    );
  }
}

/// Wrapper class for generated session data including exercises and session description
class GeneratedSessionData {
  /// The session ID if the session was created in the database
  final String? sessionId;
  final List<GeneratedProgramExercise> exercises;
  final String? sessionDescription;
  final String? sessionDescriptionKo;

  const GeneratedSessionData({
    this.sessionId,
    required this.exercises,
    this.sessionDescription,
    this.sessionDescriptionKo,
  });
}

/// Generated exercise for a program
class GeneratedProgramExercise {
  final String exerciseId;
  final String name;
  final String? nameKo;
  final int orderIndex;
  final int targetSets;
  final String targetReps; // e.g., "8-12" or "10"
  final int? targetRpe; // RPE if prescribed by AI
  final int restSeconds;
  final String? aiReasoning;
  final String? aiReasoningKo;

  const GeneratedProgramExercise({
    required this.exerciseId,
    required this.name,
    this.nameKo,
    required this.orderIndex,
    this.targetSets = 3,
    this.targetReps = '10',
    this.targetRpe,
    this.restSeconds = 90,
    this.aiReasoning,
    this.aiReasoningKo,
  });

  String get displayName => nameKo ?? name;

  factory GeneratedProgramExercise.fromJson(Map<String, dynamic> json) {
    return GeneratedProgramExercise(
      exerciseId: json['exercise_id'] as String,
      name: json['name'] as String,
      nameKo: json['name_ko'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
      targetSets: json['target_sets'] as int? ?? 3,
      targetReps: json['target_reps'] as String? ?? '10',
      targetRpe: json['target_rpe'] as int?,
      restSeconds: json['rest_seconds'] as int? ?? 90,
      aiReasoning: json['ai_reasoning'] as String?,
      aiReasoningKo: json['ai_reasoning_ko'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'name': name,
      'name_ko': nameKo,
      'order_index': orderIndex,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_rpe': targetRpe,
      'rest_seconds': restSeconds,
      'ai_reasoning': aiReasoning,
      'ai_reasoning_ko': aiReasoningKo,
    };
  }
}

/// Muscle group history entry
class MuscleGroupHistoryEntry {
  final String muscleGroup;
  final DateTime workedAt;

  const MuscleGroupHistoryEntry({
    required this.muscleGroup,
    required this.workedAt,
  });

  factory MuscleGroupHistoryEntry.fromJson(Map<String, dynamic> json) {
    // Handle both camelCase (from edge function) and snake_case (legacy) field names
    final muscleGroupValue = json['muscleGroup'] ?? json['muscle_group'];
    final dateValue = json['date'] ?? json['worked_at'];

    return MuscleGroupHistoryEntry(
      muscleGroup: muscleGroupValue as String? ?? 'unknown',
      workedAt: dateValue != null
          ? DateTime.parse(dateValue as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'muscle_group': muscleGroup,
      'worked_at': workedAt.toIso8601String(),
    };
  }
}

/// A workout program representing a training DIRECTION (not detailed workout plan)
///
/// The AI generates exercises dynamically per session based on:
/// - Gap since last session (recovery time)
/// - Client's workout frequency and consistency patterns
/// - Recent muscle groups worked
/// - Program's training split preference
/// - Client's fitness goals (from accounts.fitness_goals)
/// - Client's preferred movement groups (stored in this entity)
class WorkoutProgramEntity {
  final String id;
  final String clientId;
  final String trainerId;
  final String name;
  final String? description;

  // Training preferences
  final TrainingSplit trainingSplit;
  final List<String> focusAreas; // Priority muscle groups (body parts to prioritize)
  final List<String> preferredMovementGroups; // Movement groups client prefers

  // Session tracking metrics
  final int totalSessions;
  final double avgSessionsPerWeek;
  final double consistencyScore; // 0-1
  final String? lastSessionFocus;
  final List<MuscleGroupHistoryEntry> muscleGroupHistory;

  // Program lifecycle
  final ProgramStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  // AI metadata
  final bool isAiGenerated;
  final String? aiModelVersion;

  // AI-generated exercises for this program
  final List<GeneratedProgramExercise> generatedExercises;

  const WorkoutProgramEntity({
    required this.id,
    required this.clientId,
    required this.trainerId,
    required this.name,
    this.description,
    required this.trainingSplit,
    this.focusAreas = const [],
    this.preferredMovementGroups = const [],
    this.totalSessions = 0,
    this.avgSessionsPerWeek = 0,
    this.consistencyScore = 0,
    this.lastSessionFocus,
    this.muscleGroupHistory = const [],
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.startedAt,
    this.completedAt,
    this.isAiGenerated = true,
    this.aiModelVersion,
    this.generatedExercises = const [],
  });

  /// Check if program is expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Check if program is active and not expired
  bool get isActiveAndValid => status == ProgramStatus.active && !isExpired;

  /// Get days until expiration
  int? get daysUntilExpiration {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  /// Determine next focus area based on split and history
  String? get suggestedNextFocus {
    if (muscleGroupHistory.isEmpty) {
      // First session - use split default
      switch (trainingSplit) {
        case TrainingSplit.fullBody:
          return 'full_body';
        case TrainingSplit.upperLower:
          return 'upper';
        case TrainingSplit.pushPullLegs:
          return 'push';
      }
    }

    // Based on last session, suggest next
    switch (trainingSplit) {
      case TrainingSplit.fullBody:
        return 'full_body';
      case TrainingSplit.upperLower:
        return lastSessionFocus == 'upper' ? 'lower' : 'upper';
      case TrainingSplit.pushPullLegs:
        if (lastSessionFocus == 'push') return 'pull';
        if (lastSessionFocus == 'pull') return 'legs';
        return 'push';
    }
  }

  WorkoutProgramEntity copyWith({
    String? id,
    String? clientId,
    String? trainerId,
    String? name,
    String? description,
    TrainingSplit? trainingSplit,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
    int? totalSessions,
    double? avgSessionsPerWeek,
    double? consistencyScore,
    String? lastSessionFocus,
    List<MuscleGroupHistoryEntry>? muscleGroupHistory,
    ProgramStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? isAiGenerated,
    String? aiModelVersion,
    List<GeneratedProgramExercise>? generatedExercises,
  }) {
    return WorkoutProgramEntity(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      trainerId: trainerId ?? this.trainerId,
      name: name ?? this.name,
      description: description ?? this.description,
      trainingSplit: trainingSplit ?? this.trainingSplit,
      focusAreas: focusAreas ?? this.focusAreas,
      preferredMovementGroups: preferredMovementGroups ?? this.preferredMovementGroups,
      totalSessions: totalSessions ?? this.totalSessions,
      avgSessionsPerWeek: avgSessionsPerWeek ?? this.avgSessionsPerWeek,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      lastSessionFocus: lastSessionFocus ?? this.lastSessionFocus,
      muscleGroupHistory: muscleGroupHistory ?? this.muscleGroupHistory,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiModelVersion: aiModelVersion ?? this.aiModelVersion,
      generatedExercises: generatedExercises ?? this.generatedExercises,
    );
  }
}
