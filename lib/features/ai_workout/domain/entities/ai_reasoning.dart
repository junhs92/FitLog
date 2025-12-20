/// AI reasoning categories for exercise selection
enum ReasoningCategory {
  goalAlignment('goal_alignment', 'Goal Alignment', '목표 적합성'),
  historyBased('history_based', 'History Based', '운동 이력'),
  safety('safety', 'Safety', '안전성'),
  formReadiness('form_readiness', 'Form Readiness', '자세 준비도'),
  progressiveOverload('progressive_overload', 'Progressive Overload', '점진적 과부하'),
  recovery('recovery', 'Recovery', '회복'),
  equipment('equipment', 'Equipment', '장비'),
  timeEfficiency('time_efficiency', 'Time Efficiency', '시간 효율');

  final String id;
  final String name;
  final String nameKo;

  const ReasoningCategory(this.id, this.name, this.nameKo);

  String get displayName => nameKo;

  static ReasoningCategory fromString(String value) {
    return ReasoningCategory.values.firstWhere(
      (r) => r.id == value,
      orElse: () => ReasoningCategory.goalAlignment,
    );
  }
}

/// Single AI reasoning point for exercise selection
class AIReasoningPoint {
  final ReasoningCategory category;
  final String explanation;
  final String? explanationKo;
  final double confidence; // 0.0 to 1.0

  const AIReasoningPoint({
    required this.category,
    required this.explanation,
    this.explanationKo,
    this.confidence = 0.8,
  });

  String get displayExplanation => explanationKo ?? explanation;

  AIReasoningPoint copyWith({
    ReasoningCategory? category,
    String? explanation,
    String? explanationKo,
    double? confidence,
  }) {
    return AIReasoningPoint(
      category: category ?? this.category,
      explanation: explanation ?? this.explanation,
      explanationKo: explanationKo ?? this.explanationKo,
      confidence: confidence ?? this.confidence,
    );
  }
}

/// Complete AI reasoning for an exercise selection
class AIExerciseReasoning {
  final String exerciseId;
  final List<AIReasoningPoint> reasons;
  final double overallScore; // 0.0 to 1.0
  final DateTime generatedAt;

  const AIExerciseReasoning({
    required this.exerciseId,
    required this.reasons,
    required this.overallScore,
    required this.generatedAt,
  });

  /// Get top N reasons
  List<AIReasoningPoint> getTopReasons([int count = 3]) {
    final sorted = List<AIReasoningPoint>.from(reasons)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return sorted.take(count).toList();
  }

  AIExerciseReasoning copyWith({
    String? exerciseId,
    List<AIReasoningPoint>? reasons,
    double? overallScore,
    DateTime? generatedAt,
  }) {
    return AIExerciseReasoning(
      exerciseId: exerciseId ?? this.exerciseId,
      reasons: reasons ?? this.reasons,
      overallScore: overallScore ?? this.overallScore,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

/// Reasoning for why an alternative exercise is suggested
class AlternativeReasoning {
  final String originalExerciseId;
  final String alternativeExerciseId;
  final String reason;
  final String? reasonKo;
  final AlternativeType type;

  const AlternativeReasoning({
    required this.originalExerciseId,
    required this.alternativeExerciseId,
    required this.reason,
    this.reasonKo,
    required this.type,
  });

  String get displayReason => reasonKo ?? reason;
}

/// Types of alternatives
enum AlternativeType {
  easier('easier', 'Easier Option', '쉬운 대안'),
  harder('harder', 'Harder Option', '어려운 대안'),
  equipmentBased('equipment', 'Equipment Alternative', '장비 대안'),
  injuryFriendly('injury_friendly', 'Injury Friendly', '부상 친화적'),
  samePattern('same_pattern', 'Same Movement Pattern', '동일 패턴');

  final String id;
  final String name;
  final String nameKo;

  const AlternativeType(this.id, this.name, this.nameKo);

  String get displayName => nameKo;
}
