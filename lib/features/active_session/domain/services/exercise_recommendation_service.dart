import 'package:flutter/foundation.dart';
import '../entities/exercise_entity.dart';
import '../entities/session_entity.dart';
import '../../../ai_workout/domain/entities/workout_program.dart';
import '../../../muscle_map/domain/entities/muscle_group.dart';
import '../../data/models/user_preference_model.dart';
import '../../data/models/exercise_relation_model.dart';
import '../../../../core/ontology/ontology_service.dart';

/// Service for generating smart exercise recommendations
/// based on client's goals, recent sessions, movement groups, and training split
class ExerciseRecommendationService {
  /// Muscle groups considered accessory (isolation-dominant small muscles)
  static const Set<String> accessoryMuscleGroups = {
    'biceps', 'triceps', 'forearms', 'calves',
  };

  /// Upper compound muscle groups (presence implies upper accessory opportunity)
  static const Set<String> _upperCompoundMuscles = {
    'chest', 'back', 'shoulders',
  };

  /// Lower compound muscle groups (presence implies lower accessory opportunity)
  static const Set<String> _lowerCompoundMuscles = {
    'quadriceps', 'hamstrings', 'glutes',
  };

  /// Upper accessory muscle groups
  static const Set<String> _upperAccessoryMuscles = {
    'biceps', 'triceps', 'forearms',
  };

  /// Lower accessory muscle groups
  static const Set<String> _lowerAccessoryMuscles = {
    'calves',
  };

  /// Tunable weights for scoring (injected from database or defaults)
  final Map<String, double> _weights;

  /// User preferences for filtering/boosting recommendations
  final UserPreferenceModel? _userPreferences;

  /// Exercise relations indexed by fromExerciseId
  final Map<String, List<ExerciseRelationModel>>? _relations;

  /// Ontology service for muscle-level scoring and recovery awareness
  final OntologyService _ontologyService;

  /// Constructor with optional weight, preferences, and relations injection
  ExerciseRecommendationService({
    Map<String, double>? weights,
    UserPreferenceModel? userPreferences,
    Map<String, List<ExerciseRelationModel>>? relations,
    OntologyService? ontologyService,
  })  : _weights = weights ?? defaultWeights,
        _userPreferences = userPreferences,
        _relations = relations,
        _ontologyService = ontologyService ?? const OntologyService();

  /// Get weight value with fallback to default
  double _getWeight(String key) => _weights[key] ?? defaultWeights[key] ?? 0;

  /// Default weights (fallback when database is not available)
  static const Map<String, double> defaultWeights = {
    // Complementary scoring weights
    'same_group': 40,
    'same_detail': 20,
    'same_prime': 30,
    'same_family': 25,
    'angle_variation': 20,
    'same_equipment': 10,
    'category_match': 10,
    // Supplementary scoring weights
    'supplementary_same_prime': 30,
    'isolation_bonus': 25,
    'secondary_overlap': 20,
    'stable_equipment': 10,
    // General weights
    'difficulty_mismatch_penalty': -15,
  };
  /// Training split focus to movement group mapping
  /// Used to determine which groups to prioritize based on split rotation
  static const Map<String, List<String>> _splitFocusToGroups = {
    // Upper body groups (for upper/lower split)
    'upper': [
      MovementGroup.push,
      MovementGroup.pull,
    ],
    // Lower body groups (for upper/lower split)
    'lower': [
      MovementGroup.legs,
      MovementGroup.core,
    ],
    // Push groups (for PPL split)
    'push': [
      MovementGroup.push,
    ],
    // Pull groups (for PPL split)
    'pull': [
      MovementGroup.pull,
    ],
    // Legs groups (for PPL split)
    'legs': [
      MovementGroup.legs,
      MovementGroup.core,
    ],
    // Full body uses all groups evenly
    'full_body': [
      MovementGroup.push,
      MovementGroup.pull,
      MovementGroup.legs,
      MovementGroup.core,
      MovementGroup.other,
    ],
  };

  /// Get movement groups for a given split focus (e.g. 'push' → ['push'])
  static List<String> getMovementGroupsForFocus(String? focus) {
    if (focus == null) return [];
    return _splitFocusToGroups[focus] ?? [];
  }

  /// Group relationships for complementary training
  /// After training one group, recommend these related groups
  static const Map<String, List<String>> _complementaryGroups = {
    // Push groups complement pull groups
    MovementGroup.push: [
      MovementGroup.pull,
      MovementGroup.core,
    ],
    MovementGroup.pull: [
      MovementGroup.push,
      MovementGroup.core,
    ],
    // Legs complement core and upper body
    MovementGroup.legs: [
      MovementGroup.core,
      MovementGroup.push,
      MovementGroup.pull,
    ],
    // Core complements all
    MovementGroup.core: [
      MovementGroup.legs,
      MovementGroup.push,
      MovementGroup.pull,
    ],
    MovementGroup.other: [
      MovementGroup.core,
      MovementGroup.legs,
    ],
  };

  /// Muscle group to movement group mapping for goal-based recommendations
  static const Map<String, List<String>> _goalToGroups = {
    // Strength goals
    'strength': [
      MovementGroup.push,
      MovementGroup.pull,
      MovementGroup.legs,
    ],
    // Hypertrophy goals
    'hypertrophy': [
      MovementGroup.push,
      MovementGroup.pull,
      MovementGroup.legs,
      MovementGroup.core,
    ],
    // Weight loss - more variety
    'weight_loss': [
      MovementGroup.legs,
      MovementGroup.push,
      MovementGroup.pull,
      MovementGroup.core,
      MovementGroup.other,
    ],
    // Endurance
    'endurance': [
      MovementGroup.legs,
      MovementGroup.core,
      MovementGroup.other,
    ],
    // Mobility/Flexibility
    'mobility': [
      MovementGroup.core,
      MovementGroup.other,
    ],
    // General fitness
    'general': [
      MovementGroup.push,
      MovementGroup.pull,
      MovementGroup.legs,
      MovementGroup.core,
    ],
  };

  /// Upper body movement groups
  static const List<String> _upperBodyGroups = [
    MovementGroup.push,
    MovementGroup.pull,
  ];

  /// Lower body movement groups
  static const List<String> _lowerBodyGroups = [
    MovementGroup.legs,
    MovementGroup.core,
  ];

  /// Generate recommended group order based on:
  /// 1. Training split rotation (highest priority for split-based training)
  /// 2. Recent sessions (avoid recently trained groups)
  /// 3. Client's goals
  /// 4. Complementary groups
  /// 5. Active program preferences (preferred movement groups, focus areas)
  List<String> getRecommendedGroupOrder({
    required List<SessionEntity> recentSessions,
    required List<String> clientGoals,
    String? currentExerciseGroup,
    List<String>? preferredMovementGroups,
    List<String>? focusAreas,
    TrainingSplit? trainingSplit,
    String? suggestedNextFocus,
  }) {
    // Get recently trained groups from recent sessions
    final recentGroups = _getRecentGroups(recentSessions);

    // Get group scores based on all factors
    final groupScores = <String, double>{};

    for (final group in MovementGroup.all) {
      double score = 0.0;

      // 1. HIGHEST PRIORITY: Training split-based scoring
      score += _getSplitFocusScore(
        group: group,
        trainingSplit: trainingSplit,
        suggestedNextFocus: suggestedNextFocus,
        recentSessions: recentSessions,
        focusAreas: focusAreas,
      );

      // 2. Avoid recently trained groups (negative score)
      // For full body, reduce this penalty to encourage variety
      if (recentGroups.contains(group)) {
        if (trainingSplit == TrainingSplit.fullBody) {
          score -= 30.0; // Lower penalty for full body
        } else {
          score -= 50.0;
        }
      }

      // 3. Boost groups matching client's goals
      score += _getGoalScore(group, clientGoals);

      // 4. Boost complementary groups if current exercise exists
      if (currentExerciseGroup != null) {
        score += _getComplementaryScore(group, currentExerciseGroup);
      }

      // 5. Boost upper/lower alternation (only if not using upper/lower split)
      if (trainingSplit != TrainingSplit.upperLower) {
        score += _getUpperLowerScore(group, recentGroups);
      }

      // 6. Boost groups from active program preferences
      // For full body: lower boost (+30) as preferences are less strict
      // For other splits: higher boost (+50) combined with split rotation
      if (preferredMovementGroups != null && preferredMovementGroups.contains(group)) {
        final index = preferredMovementGroups.indexOf(group);
        final baseBoost = trainingSplit == TrainingSplit.fullBody ? 30.0 : 50.0;
        // Higher score for groups at the beginning of the preferred list
        score += baseBoost + (preferredMovementGroups.length - index) * 5;
      }

      // 7. Boost groups that target focus areas (lower for full body)
      if (focusAreas != null && focusAreas.isNotEmpty) {
        final focusScore = _getFocusAreaScore(group, focusAreas);
        if (trainingSplit == TrainingSplit.fullBody) {
          score += focusScore * 0.5; // Reduced weight for full body
        } else {
          score += focusScore;
        }
      }

      groupScores[group] = score;
    }

    // Sort groups by score (highest first)
    final sortedGroups = MovementGroup.all.toList()
      ..sort((a, b) => (groupScores[b] ?? 0).compareTo(groupScores[a] ?? 0));

    return sortedGroups;
  }

  /// Calculate score based on training split rotation
  /// Upper/Lower and PPL: +100 pts for groups matching suggested focus
  /// Full Body: Even distribution with slight boost for underrepresented groups
  double _getSplitFocusScore({
    required String group,
    TrainingSplit? trainingSplit,
    String? suggestedNextFocus,
    required List<SessionEntity> recentSessions,
    List<String>? focusAreas,
  }) {
    if (trainingSplit == null) return 0.0;

    switch (trainingSplit) {
      case TrainingSplit.upperLower:
      case TrainingSplit.pushPullLegs:
        // CALCULATE focus from recent sessions instead of relying on stored value
        final calculatedFocus = _calculateNextFocusFromRecentSessions(
          recentSessions,
          trainingSplit,
        );
        final effectiveFocus = calculatedFocus ?? suggestedNextFocus;

        if (effectiveFocus != null) {
          final focusGroups = _splitFocusToGroups[effectiveFocus] ?? [];
          if (focusGroups.contains(group)) {
            return 100.0;
          }
          // Penalize groups NOT in the suggested focus
          return -50.0;
        }
        return 0.0;

      case TrainingSplit.fullBody:
        // Even distribution: boost underrepresented groups
        final groupCounts = _getGroupCountsFromSessions(recentSessions);
        final totalGroups = groupCounts.values.fold(0, (sum, count) => sum + count);

        if (totalGroups == 0) {
          // No history, slight random variation
          return 10.0;
        }

        final avgCount = totalGroups / MovementGroup.all.length;
        final groupCount = groupCounts[group] ?? 0;

        // Boost underrepresented groups
        if (groupCount < avgCount) {
          return (avgCount - groupCount) * 15.0;
        }
        // Slight penalty for overrepresented groups
        return -(groupCount - avgCount) * 5.0;
    }
  }

  /// Calculate next focus from recent sessions by analyzing what was last worked
  String? _calculateNextFocusFromRecentSessions(
    List<SessionEntity> recentSessions,
    TrainingSplit trainingSplit,
  ) {
    if (recentSessions.isEmpty) {
      // Default for first session
      return trainingSplit == TrainingSplit.upperLower ? 'upper' : 'push';
    }

    // Get the most recent completed session
    final lastSession = recentSessions.first;

    if (lastSession.exercises.isEmpty) {
      return trainingSplit == TrainingSplit.upperLower ? 'upper' : 'push';
    }

    // Count movement groups in the last session
    int upperCount = 0;
    int lowerCount = 0;
    int pushCount = 0;
    int pullCount = 0;
    int legsCount = 0;

    for (final exercise in lastSession.exercises) {
      final group = exercise.exercise.movementGroup;

      switch (group) {
        case MovementGroup.push:
          upperCount++;
          pushCount++;
          break;
        case MovementGroup.pull:
          upperCount++;
          pullCount++;
          break;
        case MovementGroup.legs:
          lowerCount++;
          legsCount++;
          break;
        case MovementGroup.core:
          lowerCount++;
          break;
        case MovementGroup.other:
          // Check muscle group to determine upper/lower
          final muscle = exercise.exercise.muscleGroup?.toLowerCase() ?? '';
          if (muscle.contains('leg') || muscle.contains('quad') ||
              muscle.contains('ham') || muscle.contains('glute') ||
              muscle.contains('calf') || muscle.contains('calves')) {
            lowerCount++;
          } else {
            upperCount++;
          }
          break;
      }
    }

    // Determine what was LAST worked, then return the OPPOSITE
    switch (trainingSplit) {
      case TrainingSplit.upperLower:
        // If last session was mostly lower, suggest upper (and vice versa)
        final lastFocus = lowerCount > upperCount ? 'lower' : 'upper';
        final nextFocus = lastFocus == 'lower' ? 'upper' : 'lower';
        return nextFocus;

      case TrainingSplit.pushPullLegs:
        // Determine last focus and rotate: push -> pull -> legs -> push
        String lastFocus;
        if (legsCount > pushCount && legsCount > pullCount) {
          lastFocus = 'legs';
        } else if (pushCount >= pullCount) {
          lastFocus = 'push';
        } else {
          lastFocus = 'pull';
        }

        String nextFocus;
        if (lastFocus == 'push') nextFocus = 'pull';
        else if (lastFocus == 'pull') nextFocus = 'legs';
        else nextFocus = 'push';

        return nextFocus;

      case TrainingSplit.fullBody:
        return 'full_body';
    }
  }

  /// Count how many times each group appears in recent sessions
  Map<String, int> _getGroupCountsFromSessions(List<SessionEntity> sessions) {
    final counts = <String, int>{};
    for (final session in sessions) {
      for (final exercise in session.exercises) {
        final group = exercise.exercise.movementGroup;
        counts[group] = (counts[group] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Get recommended exercises from the library
  /// Returns exercises sorted by recommendation score
  List<RecommendedExercise> getRecommendedExercises({
    required List<ExerciseEntity> allExercises,
    required List<SessionEntity> recentSessions,
    required List<String> clientGoals,
    List<String>? preferredMovementGroups,
    List<String>? focusAreas,
    TrainingSplit? trainingSplit,
    String? suggestedNextFocus,
    int limit = 10,
  }) {
    // Calculate effective focus from recent sessions (not from stored value)
    // This is the authoritative focus that should be used for all scoring
    final effectiveFocus = trainingSplit != null
        ? (_calculateNextFocusFromRecentSessions(recentSessions, trainingSplit)
            ?? suggestedNextFocus)
        : suggestedNextFocus;

    debugPrint('🔵 [RECOMMENDATION] Split: $trainingSplit, stored: $suggestedNextFocus, calculated: $effectiveFocus');

    // Get group order for recommendations (using program preferences and split)
    final groupOrder = getRecommendedGroupOrder(
      recentSessions: recentSessions,
      clientGoals: clientGoals,
      preferredMovementGroups: preferredMovementGroups,
      focusAreas: focusAreas,
      trainingSplit: trainingSplit,
      suggestedNextFocus: effectiveFocus,  // Pass calculated focus
    );

    // Get recently performed exercises to avoid repetition
    final recentExerciseIds = _getRecentExerciseIds(recentSessions);

    // Score each exercise
    final scoredExercises = <RecommendedExercise>[];

    for (final exercise in allExercises) {
      double score = 0.0;
      String reason = '';

      // Group-based score
      final groupIndex = groupOrder.indexOf(exercise.movementGroup);
      if (groupIndex >= 0) {
        // Higher score for groups at the beginning of the list
        score += (5 - groupIndex) * 20;

        if (groupIndex < 3) {
          reason = _getReasonForGroup(
            exercise.movementGroup,
            clientGoals,
            preferredMovementGroups: preferredMovementGroups,
            focusAreas: focusAreas,
            trainingSplit: trainingSplit,
            suggestedNextFocus: effectiveFocus,  // Use calculated focus
          );
        }
      }

      // Split-based scoring: boost exercises matching the calculated effective focus
      if (trainingSplit != null && effectiveFocus != null) {
        final focusGroups = _splitFocusToGroups[effectiveFocus] ?? [];
        if (focusGroups.contains(exercise.movementGroup)) {
          // Significant boost for exercises in the current split focus
          score += 50.0;
          if (reason.isEmpty) {
            reason = _getSplitReasonText(trainingSplit, effectiveFocus);
          }
        }
      }

      // Avoid recently performed exercises
      if (recentExerciseIds.contains(exercise.id)) {
        score -= 30.0;
      }

      // Boost compound exercises for strength/hypertrophy goals
      if (exercise.category == ExerciseCategory.compound &&
          (clientGoals.contains('strength') || clientGoals.contains('hypertrophy'))) {
        score += 15.0;
      }

      // Boost cardio for weight loss goals
      if (exercise.category == ExerciseCategory.cardio &&
          clientGoals.contains('weight_loss')) {
        score += 20.0;
      }

      // Boost exercises matching focus areas (muscle groups)
      if (focusAreas != null && focusAreas.isNotEmpty) {
        final muscleGroup = exercise.muscleGroup?.toLowerCase() ?? '';
        for (final focus in focusAreas) {
          if (muscleGroup.contains(focus.toLowerCase())) {
            // Lower boost for full body to encourage variety
            score += trainingSplit == TrainingSplit.fullBody ? 15.0 : 25.0;
            if (reason.isEmpty) {
              reason = '프로그램 집중 부위';
            }
            break;
          }
        }
      }

      // Boost exercises with preferred movement groups
      if (preferredMovementGroups != null &&
          preferredMovementGroups.contains(exercise.movementGroup)) {
        // Lower boost for full body to encourage variety
        score += trainingSplit == TrainingSplit.fullBody ? 15.0 : 20.0;
        if (reason.isEmpty) {
          reason = '선호 동작 그룹';
        }
      }

      scoredExercises.add(RecommendedExercise(
        exercise: exercise,
        score: score,
        reason: reason,
      ));
    }

    // Sort by score
    scoredExercises.sort((a, b) => b.score.compareTo(a.score));

    // Prioritize compound exercises for main recommendations
    // Isolation exercises only appear if we don't have enough compounds
    final compounds = scoredExercises
        .where((e) => e.exercise.category == ExerciseCategory.compound)
        .take(limit)
        .toList();

    // Only add isolation if we don't have enough compounds
    if (compounds.length < limit) {
      final isolations = scoredExercises
          .where((e) => e.exercise.category != ExerciseCategory.compound)
          .take(limit - compounds.length);
      compounds.addAll(isolations);
    }

    return compounds;
  }

  /// Get human-readable reason text for split rotation
  String _getSplitReasonText(TrainingSplit trainingSplit, String suggestedNextFocus) {
    switch (trainingSplit) {
      case TrainingSplit.upperLower:
        return suggestedNextFocus == 'upper' ? '오늘은 상체 운동일' : '오늘은 하체 운동일';
      case TrainingSplit.pushPullLegs:
        if (suggestedNextFocus == 'push') return '오늘은 밀기 운동일';
        if (suggestedNextFocus == 'pull') return '오늘은 당기기 운동일';
        return '오늘은 하체 운동일';
      case TrainingSplit.fullBody:
        return '전신 균형 훈련';
    }
  }

  /// Get the list of groups trained in recent sessions
  Set<String> _getRecentGroups(List<SessionEntity> recentSessions) {
    final groups = <String>{};

    for (final session in recentSessions) {
      for (final exercise in session.exercises) {
        groups.add(exercise.exercise.movementGroup);
      }
    }

    return groups;
  }

  /// Get IDs of exercises performed in recent sessions
  Set<String> _getRecentExerciseIds(List<SessionEntity> recentSessions) {
    final ids = <String>{};

    for (final session in recentSessions) {
      for (final exercise in session.exercises) {
        ids.add(exercise.exercise.id);
      }
    }

    return ids;
  }

  /// Calculate score based on client's goals
  double _getGoalScore(String group, List<String> goals) {
    double score = 0.0;

    for (final goal in goals) {
      final goalGroups = _goalToGroups[goal] ?? [];
      if (goalGroups.contains(group)) {
        // Higher score if group appears earlier in goal's group list
        final index = goalGroups.indexOf(group);
        score += (5 - index) * 5;
      }
    }

    return score;
  }

  /// Calculate score based on complementary groups
  double _getComplementaryScore(String group, String currentGroup) {
    final complementary = _complementaryGroups[currentGroup] ?? [];

    if (complementary.contains(group)) {
      final index = complementary.indexOf(group);
      return (3 - index) * 10; // First complementary group gets highest score
    }

    return 0.0;
  }

  /// Calculate score for upper/lower alternation
  double _getUpperLowerScore(String group, Set<String> recentGroups) {
    // Check if recent sessions were mostly upper or lower body
    int upperCount = 0;
    int lowerCount = 0;

    for (final recentGroup in recentGroups) {
      if (_upperBodyGroups.contains(recentGroup)) {
        upperCount++;
      } else if (_lowerBodyGroups.contains(recentGroup)) {
        lowerCount++;
      }
    }

    // Recommend opposite body region
    if (upperCount > lowerCount && _lowerBodyGroups.contains(group)) {
      return 25.0; // Boost lower body if recently did upper
    } else if (lowerCount > upperCount && _upperBodyGroups.contains(group)) {
      return 25.0; // Boost upper body if recently did lower
    }

    return 0.0;
  }

  /// Focus area to movement group mapping
  static const Map<String, List<String>> _focusAreaToGroups = {
    // Upper body focus areas
    'chest': [MovementGroup.push],
    '가슴': [MovementGroup.push],
    'back': [MovementGroup.pull],
    '등': [MovementGroup.pull],
    'shoulders': [MovementGroup.push],
    '어깨': [MovementGroup.push],
    'arms': [MovementGroup.push, MovementGroup.pull],
    '팔': [MovementGroup.push, MovementGroup.pull],
    'biceps': [MovementGroup.pull],
    '이두': [MovementGroup.pull],
    'triceps': [MovementGroup.push],
    '삼두': [MovementGroup.push],
    // Lower body focus areas
    'legs': [MovementGroup.legs],
    '하체': [MovementGroup.legs],
    '다리': [MovementGroup.legs],
    'glutes': [MovementGroup.legs],
    '엉덩이': [MovementGroup.legs],
    'hamstrings': [MovementGroup.legs],
    '햄스트링': [MovementGroup.legs],
    'quadriceps': [MovementGroup.legs],
    '대퇴사두': [MovementGroup.legs],
    // Core
    'core': [MovementGroup.core],
    '코어': [MovementGroup.core],
    'abs': [MovementGroup.core],
    '복근': [MovementGroup.core],
  };

  /// Calculate score based on focus areas
  double _getFocusAreaScore(String group, List<String> focusAreas) {
    double score = 0.0;

    for (final focus in focusAreas) {
      final focusLower = focus.toLowerCase();
      final groups = _focusAreaToGroups[focusLower] ?? [];
      if (groups.contains(group)) {
        final index = groups.indexOf(group);
        // Higher score for primary groups
        score += (groups.length - index) * 15;
      }
    }

    return score;
  }

  /// Generate human-readable reason for group recommendation
  String _getReasonForGroup(
    String group,
    List<String> goals, {
    List<String>? preferredMovementGroups,
    List<String>? focusAreas,
    TrainingSplit? trainingSplit,
    String? suggestedNextFocus,
  }) {
    // First check if group matches training split rotation
    if (trainingSplit != null && suggestedNextFocus != null) {
      final focusGroups = _splitFocusToGroups[suggestedNextFocus] ?? [];
      if (focusGroups.contains(group)) {
        switch (trainingSplit) {
          case TrainingSplit.upperLower:
            return suggestedNextFocus == 'upper' ? '오늘은 상체 운동일' : '오늘은 하체 운동일';
          case TrainingSplit.pushPullLegs:
            if (suggestedNextFocus == 'push') return '오늘은 밀기 운동일';
            if (suggestedNextFocus == 'pull') return '오늘은 당기기 운동일';
            return '오늘은 하체 운동일';
          case TrainingSplit.fullBody:
            return '전신 균형 훈련';
        }
      }
    }

    // Check if group is from program preferences
    if (preferredMovementGroups != null && preferredMovementGroups.contains(group)) {
      return '프로그램 선호 그룹';
    }

    // Check if group matches focus areas
    if (focusAreas != null && focusAreas.isNotEmpty) {
      for (final focus in focusAreas) {
        final focusLower = focus.toLowerCase();
        final groups = _focusAreaToGroups[focusLower] ?? [];
        if (groups.contains(group)) {
          return '프로그램 집중 부위';
        }
      }
    }
    // Check if group matches goals
    for (final goal in goals) {
      final goalGroups = _goalToGroups[goal] ?? [];
      if (goalGroups.contains(group)) {
        return _getGoalBasedReason(goal, group);
      }
    }

    return _getGroupDescription(group);
  }

  /// Get reason text based on goal
  String _getGoalBasedReason(String goal, String group) {
    switch (goal) {
      case 'strength':
        return '근력 향상에 효과적';
      case 'hypertrophy':
        return '근비대에 최적화';
      case 'weight_loss':
        return '체지방 감소에 도움';
      case 'endurance':
        return '지구력 향상';
      case 'mobility':
        return '유연성 개선';
      default:
        return '전반적인 체력 향상';
    }
  }

  /// Get group description
  String _getGroupDescription(String group) {
    switch (group) {
      case MovementGroup.push:
        return '밀기 운동';
      case MovementGroup.pull:
        return '당기기 운동';
      case MovementGroup.legs:
        return '하체 운동';
      case MovementGroup.core:
        return '코어 운동';
      case MovementGroup.other:
        return '기타 운동';
      default:
        return '';
    }
  }

  /// Generate detailed, user-friendly reason list for a movement group.
  /// Unlike _getReasonForGroup() which returns one label, this collects
  /// ALL applicable reasons as readable Korean sentences.
  List<String> getDetailedReasons({
    required String movementGroup,
    required List<String> clientGoals,
    required List<SessionEntity> recentSessions,
    TrainingSplit? trainingSplit,
    String? suggestedNextFocus,
    List<String>? preferredMovementGroups,
    List<String>? focusAreas,
  }) {
    final reasons = <String>[];

    // 1. Training split rotation
    if (trainingSplit != null && suggestedNextFocus != null) {
      final focusGroups = _splitFocusToGroups[suggestedNextFocus] ?? [];
      if (focusGroups.contains(movementGroup)) {
        switch (trainingSplit) {
          case TrainingSplit.upperLower:
            reasons.add(suggestedNextFocus == 'upper'
                ? '상/하 분할 루틴에 따라 오늘은 상체 운동일입니다'
                : '상/하 분할 루틴에 따라 오늘은 하체 운동일입니다');
          case TrainingSplit.pushPullLegs:
            if (suggestedNextFocus == 'push') {
              reasons.add('PPL 루틴에 따라 오늘은 밀기 운동일입니다');
            } else if (suggestedNextFocus == 'pull') {
              reasons.add('PPL 루틴에 따라 오늘은 당기기 운동일입니다');
            } else {
              reasons.add('PPL 루틴에 따라 오늘은 하체 운동일입니다');
            }
          case TrainingSplit.fullBody:
            reasons.add('전신 균형 훈련을 위해 추천됩니다');
        }
      }
    }

    // 2. Recent session avoidance / balance
    final recentGroups = _getRecentGroups(recentSessions);
    if (!recentGroups.contains(movementGroup) && recentSessions.isNotEmpty) {
      reasons.add('최근 세션에서 훈련하지 않아 균형 잡힌 발달에 도움이 됩니다');
    }

    // 3. Goal alignment
    for (final goal in clientGoals) {
      final goalGroups = _goalToGroups[goal] ?? [];
      if (goalGroups.contains(movementGroup)) {
        switch (goal) {
          case 'strength':
            reasons.add('근력 향상 목표에 효과적인 운동 그룹입니다');
          case 'hypertrophy':
            reasons.add('근비대 목표에 최적화된 운동 그룹입니다');
          case 'weight_loss':
            reasons.add('체지방 감소 목표에 도움이 되는 운동입니다');
          case 'endurance':
            reasons.add('지구력 향상에 적합한 운동 그룹입니다');
          case 'mobility':
            reasons.add('유연성 및 가동성 개선에 도움됩니다');
          default:
            reasons.add('전반적인 체력 향상에 기여합니다');
        }
        break; // Only add one goal reason
      }
    }

    // 4. Program preferred movement groups
    if (preferredMovementGroups != null &&
        preferredMovementGroups.contains(movementGroup)) {
      reasons.add('현재 프로그램의 선호 동작 그룹에 포함됩니다');
    }

    // 5. Focus area targeting
    if (focusAreas != null && focusAreas.isNotEmpty) {
      for (final focus in focusAreas) {
        final groups = _focusAreaToGroups[focus.toLowerCase()] ?? [];
        if (groups.contains(movementGroup)) {
          reasons.add('프로그램 집중 부위($focus)를 타겟하는 운동입니다');
          break;
        }
      }
    }

    // Fallback if no specific reasons found
    if (reasons.isEmpty) {
      reasons.add('${_getGroupDescription(movementGroup)} 그룹으로 추천됩니다');
    }

    return reasons;
  }

  // ============================================================
  // CONTEXTUAL RECOMMENDATIONS (Exercise Picker)
  // ============================================================

  /// Equipment types considered "stable" for supplementary recommendations
  static const List<String> _stableEquipment = [
    'machine',
    'cable',
    'smith_machine',
  ];

  /// Get complementary recommendations (바로 이어서 하기)
  /// These are exercises that continue the same movement pattern
  List<LabeledRecommendation> getComplementaryRecommendations({
    required List<ExerciseEntity> allExercises,
    required RecommendationContext context,
    int limit = 3,
  }) {
    if (!context.hasContext) return [];

    final lastExercise = context.lastExercise!;
    final scored = <_ScoredWithLabel>[];

    for (final exercise in allExercises) {
      // Skip exercises already in session
      if (context.exerciseIdsInSession.contains(exercise.id)) continue;

      final result = _scoreComplementary(exercise, lastExercise);
      if (result.score > 0) {
        scored.add(result);
      }
    }

    // Sort by score (highest first)
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.take(limit).map((s) => LabeledRecommendation(
      exercise: s.exercise,
      score: s.score,
      labelText: s.label,
      type: RecommendationType.complementary,
    )).toList();
  }

  /// Get supplementary recommendations (보조)
  /// These are isolation/finisher exercises for the same muscle
  List<LabeledRecommendation> getSupplementaryRecommendations({
    required List<ExerciseEntity> allExercises,
    required RecommendationContext context,
    int limit = 3,
  }) {
    if (!context.hasContext) return [];

    final lastExercise = context.lastExercise!;
    final scored = <_ScoredWithLabel>[];

    for (final exercise in allExercises) {
      // Skip exercises already in session
      if (context.exerciseIdsInSession.contains(exercise.id)) continue;

      final result = _scoreSupplementary(exercise, lastExercise);
      if (result.score > 0) {
        scored.add(result);
      }
    }

    // Sort by score (highest first)
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.take(limit).map((s) => LabeledRecommendation(
      exercise: s.exercise,
      score: s.score,
      labelText: s.label,
      type: RecommendationType.supplementary,
    )).toList();
  }

  /// Score exercise for complementary recommendation
  /// Returns score and label
  _ScoredWithLabel _scoreComplementary(
    ExerciseEntity candidate,
    ExerciseEntity reference,
  ) {
    double score = 0;
    String? labelPriority;
    int labelWeight = 0;

    // ============================================================
    // User Preferences: Filter exercises based on avoided equipment/muscles
    // ============================================================
    final prefs = _userPreferences;
    if (prefs != null) {
      // Filter: Return 0 if exercise uses avoided equipment
      if (candidate.equipment != null &&
          prefs.avoidEquipment.any(
              (eq) => candidate.equipment!.toLowerCase().contains(eq.toLowerCase()))) {
        return _ScoredWithLabel(candidate, 0, '');
      }
      // Filter: Penalize if targets avoided muscle group
      if (candidate.muscleGroup != null &&
          prefs.avoidMuscleGroups.any(
              (mg) => candidate.muscleGroup!.toLowerCase().contains(mg.toLowerCase()))) {
        return _ScoredWithLabel(candidate, 0, '');
      }
    }

    // ============================================================
    // Exercise Relations: Check explicit relations BEFORE manual scoring
    // ============================================================
    final rels = _relations;
    if (rels != null && rels.containsKey(reference.id)) {
      final relations = rels[reference.id]!;
      final relation = relations.where(
        (r) => r.toExerciseId == candidate.id &&
               r.relationType == ExerciseRelationType.complementary,
      ).firstOrNull;

      if (relation != null) {
        // Use relation strength as base score (0-100)
        score = relation.strength.toDouble();
        // Use reasonTags for label
        labelPriority = relation.reasonTags.isNotEmpty
            ? _mapReasonTagToLabel(relation.reasonTags.first)
            : '추천';
        labelWeight = 50; // High priority for explicit relations

        // Still apply preference boosts
        final userPrefs = _userPreferences;
        if (userPrefs != null &&
            candidate.equipment != null &&
            userPrefs.preferredEquipment.any(
                (eq) => candidate.equipment!.toLowerCase().contains(eq.toLowerCase()))) {
          score += 15;
        }

        return _ScoredWithLabel(candidate, score, labelPriority);
      }
    }

    // ============================================================
    // Manual Scoring (fallback when no explicit relation exists)
    // ============================================================

    // same_group: use tunable weight
    if (candidate.movementGroup == reference.movementGroup) {
      score += _getWeight('same_group');
      if (labelWeight < 10) {
        labelPriority = '같은 ${MovementGroup.getDisplayNameKo(candidate.movementGroup)}';
        labelWeight = 10;
      }
    } else {
      // Different movement group - not complementary
      return _ScoredWithLabel(candidate, 0, '');
    }

    // same_detail: use tunable weight (e.g., horizontal push -> horizontal push)
    if (candidate.movementDetail != null &&
        candidate.movementDetail == reference.movementDetail) {
      score += _getWeight('same_detail');
      if (labelWeight < 20) {
        final groupKo = MovementGroup.getDisplayNameKo(candidate.movementGroup);
        final detailKo = MovementDetail.getDisplayNameKo(candidate.movementDetail!);
        labelPriority = '$groupKo-$detailKo 유지';
        labelWeight = 20;
      }
    }

    // same_prime (muscle): use tunable weight
    if (candidate.muscleGroup != null &&
        candidate.muscleGroup == reference.muscleGroup) {
      score += _getWeight('same_prime');
    }

    // same_family: use tunable weight (e.g., bench variations)
    if (candidate.family != null && candidate.family == reference.family) {
      score += _getWeight('same_family');
    }

    // angle_variation: use tunable weight (different angle, same muscle)
    if (candidate.angle != null &&
        reference.angle != null &&
        candidate.angle != reference.angle &&
        candidate.muscleGroup == reference.muscleGroup) {
      score += _getWeight('angle_variation');
      if (labelWeight < 30) {
        labelPriority = '각도 변형';
        labelWeight = 30;
      }
    }

    // same_equipment: use tunable weight
    if (candidate.equipment != null && candidate.equipment == reference.equipment) {
      score += _getWeight('same_equipment');
    }

    // equipment_substitute: label only (different equipment, same muscle)
    if (candidate.equipment != null &&
        reference.equipment != null &&
        candidate.equipment != reference.equipment &&
        candidate.muscleGroup == reference.muscleGroup &&
        labelWeight < 15) {
      labelPriority = '장비 대체';
      labelWeight = 15;
    }

    // category_match: use tunable weight
    if (candidate.category == reference.category) {
      score += _getWeight('category_match');
    }

    // ============================================================
    // User Preferences: Boost preferred equipment
    // ============================================================
    final preferenceBoost = _userPreferences;
    if (preferenceBoost != null &&
        candidate.equipment != null &&
        preferenceBoost.preferredEquipment.any(
            (eq) => candidate.equipment!.toLowerCase().contains(eq.toLowerCase()))) {
      score += 15;
    }

    return _ScoredWithLabel(
      candidate,
      score,
      labelPriority ?? '같은 ${MovementGroup.getDisplayNameKo(candidate.movementGroup)}',
    );
  }

  /// Map relation reason tags to user-friendly Korean labels
  String _mapReasonTagToLabel(String reasonTag) {
    switch (reasonTag.toLowerCase()) {
      case 'same_muscle':
        return '같은 근육';
      case 'angle_variation':
        return '각도 변형';
      case 'equipment_variation':
        return '장비 변형';
      case 'intensity_progression':
        return '강도 진행';
      case 'superset':
        return '슈퍼세트';
      case 'pre_exhaust':
        return '사전 피로';
      case 'compound_to_isolation':
        return '복합→단관절';
      default:
        return '추천';
    }
  }

  /// Score exercise for supplementary recommendation
  /// Returns score and label
  _ScoredWithLabel _scoreSupplementary(
    ExerciseEntity candidate,
    ExerciseEntity reference,
  ) {
    double score = 0;
    String? labelPriority;
    int labelWeight = 0;

    // Supplementary = accessory/isolation exercises only
    // Compound exercises belong in complementary recommendations
    if (candidate.category == ExerciseCategory.compound) {
      return _ScoredWithLabel(candidate, 0, '');
    }

    // ============================================================
    // User Preferences: Filter exercises based on avoided equipment/muscles
    // ============================================================
    final prefs = _userPreferences;
    if (prefs != null) {
      // Filter: Return 0 if exercise uses avoided equipment
      if (candidate.equipment != null &&
          prefs.avoidEquipment.any(
              (eq) => candidate.equipment!.toLowerCase().contains(eq.toLowerCase()))) {
        return _ScoredWithLabel(candidate, 0, '');
      }
      // Filter: Penalize if targets avoided muscle group
      if (candidate.muscleGroup != null &&
          prefs.avoidMuscleGroups.any(
              (mg) => candidate.muscleGroup!.toLowerCase().contains(mg.toLowerCase()))) {
        return _ScoredWithLabel(candidate, 0, '');
      }
    }

    // ============================================================
    // Exercise Relations: Check explicit relations BEFORE manual scoring
    // ============================================================
    final rels = _relations;
    if (rels != null && rels.containsKey(reference.id)) {
      final relations = rels[reference.id]!;
      final relation = relations.where(
        (r) => r.toExerciseId == candidate.id &&
               r.relationType == ExerciseRelationType.supplementary,
      ).firstOrNull;

      if (relation != null) {
        // Use relation strength as base score (0-100)
        score = relation.strength.toDouble();
        // Use reasonTags for label
        labelPriority = relation.reasonTags.isNotEmpty
            ? _mapReasonTagToLabel(relation.reasonTags.first)
            : '보조';
        labelWeight = 50; // High priority for explicit relations

        // Still apply preference boosts
        final userPrefs = _userPreferences;
        if (userPrefs != null &&
            candidate.equipment != null &&
            userPrefs.preferredEquipment.any(
                (eq) => candidate.equipment!.toLowerCase().contains(eq.toLowerCase()))) {
          score += 15;
        }

        return _ScoredWithLabel(candidate, score, labelPriority);
      }
    }

    // ============================================================
    // Manual Scoring (fallback when no explicit relation exists)
    // ============================================================

    // Prefer isolation exercises
    final isIsolation = candidate.category == ExerciseCategory.isolation;

    // same_prime (muscle): use tunable weight
    final sameMuscle = candidate.muscleGroup != null &&
        candidate.muscleGroup == reference.muscleGroup;

    if (sameMuscle) {
      score += _getWeight('supplementary_same_prime');
      if (labelWeight < 20) {
        final muscleKo = _getMuscleDisplayKo(candidate.muscleGroup!);
        labelPriority = '보조($muscleKo 마무리)';
        labelWeight = 20;
      }
    }

    // isolation_bonus: use tunable weight (if isolation and targets same/related muscle)
    if (isIsolation && sameMuscle) {
      score += _getWeight('isolation_bonus');
    }

    // secondary_overlap: use tunable weight
    // Check if candidate's primary muscle is in reference's secondary muscles
    if (candidate.muscleGroup != null &&
        reference.secondaryMuscles.contains(candidate.muscleGroup!.toLowerCase())) {
      score += _getWeight('secondary_overlap');
      if (labelWeight < 15) {
        final muscleKo = _getMuscleDisplayKo(candidate.muscleGroup!);
        labelPriority = '보조($muscleKo 자극)';
        labelWeight = 15;
      }
    }
    // Or candidate targets a secondary muscle of reference (half the weight)
    if (reference.muscleGroup != null &&
        candidate.secondaryMuscles.contains(reference.muscleGroup!.toLowerCase())) {
      score += _getWeight('secondary_overlap') / 2;
    }

    // stable_equipment: use tunable weight
    if (candidate.equipment != null &&
        _stableEquipment.contains(candidate.equipment!.toLowerCase())) {
      score += _getWeight('stable_equipment');
      if (labelWeight < 10 && score > 20) {
        labelPriority = '안정성(머신)';
        labelWeight = 10;
      }
    }

    // ============================================================
    // User Preferences: Boost preferred equipment
    // ============================================================
    final preferenceBoost = _userPreferences;
    if (preferenceBoost != null &&
        candidate.equipment != null &&
        preferenceBoost.preferredEquipment.any(
            (eq) => candidate.equipment!.toLowerCase().contains(eq.toLowerCase()))) {
      score += 15;
    }

    // Must have some relevance (muscle overlap)
    if (score < 20) {
      return _ScoredWithLabel(candidate, 0, '');
    }

    return _ScoredWithLabel(
      candidate,
      score,
      labelPriority ?? '보조',
    );
  }

  /// Get Korean display name for muscle group
  String _getMuscleDisplayKo(String muscle) {
    final lower = muscle.toLowerCase();
    switch (lower) {
      case 'chest':
        return '가슴';
      case 'back':
        return '등';
      case 'shoulders':
        return '어깨';
      case 'biceps':
        return '이두';
      case 'triceps':
        return '삼두';
      case 'quadriceps':
        return '대퇴사두';
      case 'hamstrings':
        return '햄스트링';
      case 'glutes':
        return '둔근';
      case 'calves':
        return '종아리';
      case 'core':
      case 'abs':
        return '코어';
      case 'forearms':
        return '전완';
      case 'traps':
      case 'trapezius':
        return '승모근';
      case 'lats':
      case 'latissimus':
        return '광배근';
      default:
        return muscle;
    }
  }

  /// Aggregate exercise-level scores to family-level scores for the hierarchical picker.
  /// Uses max-score strategy: one good exercise surfaces the entire family.
  /// Also boosts families that appear in contextual recommendations.
  List<ScoredFamily> aggregateToFamilyScores({
    required List<RecommendedExercise> scoredExercises,
    ContextualRecommendationsState? contextualRecs,
    required List<ExerciseEntity> allExercises,
    required Set<String> exerciseIdsInSession,
  }) {
    // Group exercises by family (null family = individual entries)
    final familyGroups = <String, List<RecommendedExercise>>{};
    final ungrouped = <RecommendedExercise>[];

    for (final scored in scoredExercises) {
      // Skip exercises already in session
      if (exerciseIdsInSession.contains(scored.exercise.id)) continue;

      final family = scored.exercise.family;
      if (family != null && family.isNotEmpty) {
        familyGroups.putIfAbsent(family, () => []).add(scored);
      } else {
        ungrouped.add(scored);
      }
    }

    // Build contextual recommendation exercise IDs for boosting
    final contextualExerciseIds = <String>{};
    if (contextualRecs != null) {
      for (final rec in contextualRecs.complementary) {
        contextualExerciseIds.add(rec.exercise.id);
      }
      for (final rec in contextualRecs.supplementary) {
        contextualExerciseIds.add(rec.exercise.id);
      }
    }

    final families = <ScoredFamily>[];

    // Score each family using max-score strategy
    for (final entry in familyGroups.entries) {
      final familyKey = entry.key;
      final exercises = entry.value;

      // Max score among exercises in this family
      double maxScore = 0;
      String bestReason = '';
      for (final ex in exercises) {
        if (ex.score > maxScore) {
          maxScore = ex.score;
          bestReason = ex.reason;
        }
      }

      // Boost if any exercise in this family appears in contextual recs
      bool hasContextualRec = false;
      RecommendationType? contextualType;
      for (final ex in exercises) {
        if (contextualExerciseIds.contains(ex.exercise.id)) {
          hasContextualRec = true;
          // Determine type
          if (contextualRecs != null) {
            for (final rec in contextualRecs.complementary) {
              if (rec.exercise.id == ex.exercise.id) {
                contextualType = RecommendationType.complementary;
                break;
              }
            }
            contextualType ??= RecommendationType.supplementary;
          }
          maxScore += 30;
          break;
        }
      }

      // Get all exercises in this family (including those already in session, for count)
      final totalInFamily = allExercises.where((e) => e.family == familyKey).length;

      // Representative exercise (highest scored)
      final representative = exercises.reduce(
        (a, b) => a.score >= b.score ? a : b,
      ).exercise;

      families.add(ScoredFamily(
        familyKey: familyKey,
        displayNameKo: ExerciseFamily.getDisplayNameKo(familyKey),
        score: maxScore,
        reason: bestReason,
        exerciseCount: totalInFamily,
        availableCount: exercises.length,
        movementGroup: representative.movementGroup,
        muscleGroup: representative.muscleGroup,
        isCustom: false,
        familyCategory: representative.category,
        hasContextualRecommendation: hasContextualRec,
        contextualType: contextualType,
      ));
    }

    // Add ungrouped exercises as single-exercise families
    for (final scored in ungrouped) {
      families.add(ScoredFamily(
        familyKey: scored.exercise.id, // Use exercise ID as key
        displayNameKo: scored.exercise.displayName,
        score: scored.score,
        reason: scored.reason,
        exerciseCount: 1,
        availableCount: 1,
        movementGroup: scored.exercise.movementGroup,
        muscleGroup: scored.exercise.muscleGroup,
        isCustom: scored.exercise.isCustom,
        familyCategory: scored.exercise.category,
        hasContextualRecommendation: contextualExerciseIds.contains(scored.exercise.id),
        contextualType: null,
      ));
    }

    // Sort by score descending
    families.sort((a, b) => b.score.compareTo(a.score));

    return families;
  }

  /// Detect which accessory muscle groups the client has neglected.
  /// Returns set of muscleGroup strings (e.g. {'biceps', 'calves'}).
  /// "Neglected" = client trained the parent region (upper/lower compounds)
  /// in recent sessions but did NOT include the accessory group.
  Set<String> getNeglectedAccessoryGroups({
    required List<SessionEntity> recentSessions,
    int sessionLookback = 5,
  }) {
    final sessions = recentSessions.take(sessionLookback).toList();
    if (sessions.isEmpty) return {};

    // Collect all muscle groups trained across recent sessions
    bool hasUpperCompound = false;
    bool hasLowerCompound = false;
    final trainedMuscles = <String>{};

    for (final session in sessions) {
      for (final exercise in session.exercises) {
        final muscle = exercise.exercise.muscleGroup?.toLowerCase();
        if (muscle == null) continue;
        trainedMuscles.add(muscle);
        if (_upperCompoundMuscles.contains(muscle)) hasUpperCompound = true;
        if (_lowerCompoundMuscles.contains(muscle)) hasLowerCompound = true;
      }
    }

    final neglected = <String>{};

    // If client did upper compound work but skipped upper accessories
    if (hasUpperCompound) {
      for (final accessory in _upperAccessoryMuscles) {
        if (!trainedMuscles.contains(accessory)) {
          neglected.add(accessory);
        }
      }
    }

    // If client did lower compound work but skipped lower accessories
    if (hasLowerCompound) {
      for (final accessory in _lowerAccessoryMuscles) {
        if (!trainedMuscles.contains(accessory)) {
          neglected.add(accessory);
        }
      }
    }

    return neglected;
  }
}

/// A scored family for the hierarchical picker
class ScoredFamily {
  final String familyKey;
  final String displayNameKo;
  final double score;
  final String reason;
  final int exerciseCount; // Total exercises in family
  final int availableCount; // Exercises not yet in session
  final String movementGroup;
  final String? muscleGroup;
  final bool isCustom;
  final String familyCategory;
  final bool hasContextualRecommendation;
  final RecommendationType? contextualType;

  const ScoredFamily({
    required this.familyKey,
    required this.displayNameKo,
    required this.score,
    required this.reason,
    required this.exerciseCount,
    required this.availableCount,
    required this.movementGroup,
    this.muscleGroup,
    this.isCustom = false,
    this.familyCategory = ExerciseCategory.compound,
    this.hasContextualRecommendation = false,
    this.contextualType,
  });

  bool get isCompound => familyCategory == ExerciseCategory.compound;
  bool get isAccessory => familyCategory == ExerciseCategory.isolation;
  bool get isMobility => familyCategory == ExerciseCategory.mobility ||
      familyCategory == ExerciseCategory.warmup ||
      familyCategory == ExerciseCategory.cooldown;
}

/// Internal helper for scoring with label
class _ScoredWithLabel {
  final ExerciseEntity exercise;
  final double score;
  final String label;

  _ScoredWithLabel(this.exercise, this.score, this.label);
}

/// Recommended exercise with score and reason
class RecommendedExercise {
  final ExerciseEntity exercise;
  final double score;
  final String reason;

  const RecommendedExercise({
    required this.exercise,
    required this.score,
    this.reason = '',
  });
}

/// Types of contextual recommendations
enum RecommendationType {
  complementary, // 바로 이어서 하기 (continue same pattern)
  supplementary, // 보조 (isolation/finisher)
}

/// Labeled recommendation with context-aware description
class LabeledRecommendation {
  final ExerciseEntity exercise;
  final double score;
  final String labelText; // "같은 Push 계속", "보조(가슴 마무리)", "각도 변형"
  final RecommendationType type;

  const LabeledRecommendation({
    required this.exercise,
    required this.score,
    required this.labelText,
    required this.type,
  });
}

/// Context for generating recommendations
class RecommendationContext {
  final ExerciseEntity? lastExercise;
  final ExerciseEntity? secondLastExercise;
  final Set<String> exerciseIdsInSession;
  final String? sessionGoal;

  const RecommendationContext({
    this.lastExercise,
    this.secondLastExercise,
    this.exerciseIdsInSession = const {},
    this.sessionGoal,
  });

  /// Whether there's a valid exercise to base recommendations on
  bool get hasContext => lastExercise != null;
}

/// Exercise prescription based on goals
class ExercisePrescription {
  final int minSets;
  final int maxSets;
  final int minReps;
  final int maxReps;
  final int minRestSeconds;
  final int maxRestSeconds;
  final int minRpe;
  final int maxRpe;

  const ExercisePrescription({
    required this.minSets,
    required this.maxSets,
    required this.minReps,
    required this.maxReps,
    required this.minRestSeconds,
    required this.maxRestSeconds,
    required this.minRpe,
    required this.maxRpe,
  });

  /// Goal-based prescription templates
  static const Map<String, ExercisePrescription> goalPrescriptions = {
    'weight_loss': ExercisePrescription(
      minSets: 3, maxSets: 5,
      minReps: 8, maxReps: 12,
      minRestSeconds: 45, maxRestSeconds: 90,
      minRpe: 7, maxRpe: 8,
    ),
    'muscle_gain': ExercisePrescription(
      minSets: 3, maxSets: 5,
      minReps: 6, maxReps: 12,
      minRestSeconds: 90, maxRestSeconds: 150,
      minRpe: 7, maxRpe: 9,
    ),
    'general_fitness': ExercisePrescription(
      minSets: 2, maxSets: 4,
      minReps: 8, maxReps: 12,
      minRestSeconds: 60, maxRestSeconds: 120,
      minRpe: 6, maxRpe: 8,
    ),
    'strength': ExercisePrescription(
      minSets: 3, maxSets: 6,
      minReps: 2, maxReps: 6,
      minRestSeconds: 120, maxRestSeconds: 240,
      minRpe: 7, maxRpe: 9,
    ),
    'flexibility': ExercisePrescription(
      minSets: 2, maxSets: 4,
      minReps: 6, maxReps: 10,
      minRestSeconds: 30, maxRestSeconds: 60,
      minRpe: 4, maxRpe: 6,
    ),
    'endurance': ExercisePrescription(
      minSets: 2, maxSets: 4,
      minReps: 12, maxReps: 20,
      minRestSeconds: 30, maxRestSeconds: 75,
      minRpe: 6, maxRpe: 8,
    ),
    'rehabilitation': ExercisePrescription(
      minSets: 2, maxSets: 4,
      minReps: 6, maxReps: 12,
      minRestSeconds: 60, maxRestSeconds: 120,
      minRpe: 4, maxRpe: 7,
    ),
    'sports_performance': ExercisePrescription(
      minSets: 3, maxSets: 6,
      minReps: 2, maxReps: 5,
      minRestSeconds: 120, maxRestSeconds: 240,
      minRpe: 6, maxRpe: 8,
    ),
  };

  // Midpoint convenience getters
  int get midReps => (minReps + maxReps) ~/ 2;
  double get midRpe => (minRpe + maxRpe) / 2;
  int get midRestSeconds => (minRestSeconds + maxRestSeconds) ~/ 2;

  /// Normalize display goal name ('Weight Loss') to key ('weight_loss')
  static String _normalizeGoal(String goal) =>
      goal.toLowerCase().replaceAll(' ', '_');

  /// Get prescription for a goal (defaults to general_fitness)
  static ExercisePrescription forGoal(String? goal) {
    return goalPrescriptions[goal] ?? goalPrescriptions['general_fitness']!;
  }

  /// Get prescription for a client goal (handles display name format)
  static ExercisePrescription forClientGoal(String? goal) {
    if (goal == null) return goalPrescriptions['general_fitness']!;
    return goalPrescriptions[_normalizeGoal(goal)] ??
        goalPrescriptions['general_fitness']!;
  }
}

/// Contextual recommendations state for the exercise picker
class ContextualRecommendationsState {
  final List<LabeledRecommendation> complementary;
  final List<LabeledRecommendation> supplementary;

  const ContextualRecommendationsState({
    this.complementary = const [],
    this.supplementary = const [],
  });

  bool get isEmpty => complementary.isEmpty && supplementary.isEmpty;
  bool get hasComplementary => complementary.isNotEmpty;
  bool get hasSupplementary => supplementary.isNotEmpty;
}
