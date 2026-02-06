import 'dart:math';
import 'package:flutter/foundation.dart';
import '../entities/exercise_entity.dart';
import '../entities/session_entity.dart';
import '../entities/generated_session.dart';
import '../../../ai_workout/domain/entities/workout_program.dart';
import 'exercise_recommendation_service.dart';

/// Service for generating complete workout sessions using rule-based algorithms
/// Replaces LLM-based generation with faster, free, and predictable local logic
class SessionGenerationService {
  final ExerciseRecommendationService _recommendationService;

  SessionGenerationService(this._recommendationService);

  /// Number of exercises to generate per session
  static const int exercisesPerSession = 6;

  /// Exercise distribution by split and focus
  /// Key: focus area, Value: list of movement groups for each slot (6 total)
  static const Map<String, List<String>> _groupDistribution = {
    // Upper/Lower Split
    'upper': [
      MovementGroup.push,
      MovementGroup.pull,
      MovementGroup.push,
      MovementGroup.pull,
      MovementGroup.push,
      MovementGroup.pull,
    ],
    'lower': [
      MovementGroup.legs,
      MovementGroup.legs,
      MovementGroup.legs,
      MovementGroup.legs,
      MovementGroup.core,
      MovementGroup.core,
    ],
    // Push/Pull/Legs Split
    'push': [
      MovementGroup.push,
      MovementGroup.push,
      MovementGroup.push,
      MovementGroup.push,
      MovementGroup.push,
      MovementGroup.push,
    ],
    'pull': [
      MovementGroup.pull,
      MovementGroup.pull,
      MovementGroup.pull,
      MovementGroup.pull,
      MovementGroup.pull,
      MovementGroup.pull,
    ],
    'legs': [
      MovementGroup.legs,
      MovementGroup.legs,
      MovementGroup.legs,
      MovementGroup.legs,
      MovementGroup.core,
      MovementGroup.core,
    ],
    // Full Body Split
    'full_body': [
      MovementGroup.push,
      MovementGroup.pull,
      MovementGroup.legs,
      MovementGroup.push,
      MovementGroup.pull,
      MovementGroup.legs,
    ],
  };

  /// Generate a complete session with 6 exercises
  GeneratedSession generateSession({
    required List<ExerciseEntity> exerciseLibrary,
    required List<SessionEntity> recentSessions,
    required List<String> clientGoals,
    required TrainingSplit trainingSplit,
    String? suggestedNextFocus,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
  }) {
    debugPrint('🔵 [SESSION_GEN] Starting session generation...');
    debugPrint('🔵 [SESSION_GEN] Split: ${trainingSplit.name}, Goals: $clientGoals');
    debugPrint('🔵 [SESSION_GEN] Exercise library: ${exerciseLibrary.length} exercises');

    // 1. Calculate effective focus from recent sessions
    final effectiveFocus = _calculateEffectiveFocus(
      recentSessions: recentSessions,
      trainingSplit: trainingSplit,
      suggestedNextFocus: suggestedNextFocus,
    );
    debugPrint('🔵 [SESSION_GEN] Effective focus: $effectiveFocus');

    // 2. Get group distribution for this focus
    final groupDistribution = _getGroupDistribution(effectiveFocus);
    debugPrint('🔵 [SESSION_GEN] Group distribution: $groupDistribution');

    // 3. Get prescription template based on primary goal
    final primaryGoal = clientGoals.isNotEmpty ? clientGoals.first : 'general_fitness';
    final prescription = ExercisePrescription.forGoal(primaryGoal);
    debugPrint('🔵 [SESSION_GEN] Prescription for $primaryGoal: sets=${prescription.minSets}-${prescription.maxSets}');

    // 4. Get recently used exercise IDs to avoid repetition
    final recentExerciseIds = _getRecentExerciseIds(recentSessions);

    // 5. Generate exercises for each slot
    final generatedExercises = <GeneratedExercise>[];
    final usedFamilies = <String>{};
    final usedExerciseIds = <String>{};
    final recentEquipment = <String>[];

    for (int slot = 0; slot < exercisesPerSession; slot++) {
      final targetGroup = groupDistribution[slot];
      final isCompoundSlot = slot < 4; // First 4 slots prefer compounds

      debugPrint('🔵 [SESSION_GEN] Slot $slot: group=$targetGroup, compound=$isCompoundSlot');

      // Get candidates for this slot
      var candidates = _getCandidates(
        exerciseLibrary: exerciseLibrary,
        targetGroup: targetGroup,
        preferCompound: isCompoundSlot,
        usedFamilies: usedFamilies,
        usedExerciseIds: usedExerciseIds,
        recentExerciseIds: recentExerciseIds,
        recentEquipment: recentEquipment,
        focusAreas: focusAreas,
        preferredMovementGroups: preferredMovementGroups,
      );

      // Fallback: if no compound candidates exist for compound slots, allow isolation
      if (candidates.isEmpty && isCompoundSlot) {
        debugPrint('🟡 [SESSION_GEN] No compounds for slot $slot, falling back to isolation');
        candidates = _getCandidates(
          exerciseLibrary: exerciseLibrary,
          targetGroup: targetGroup,
          preferCompound: false, // Allow isolation as fallback
          usedFamilies: usedFamilies,
          usedExerciseIds: usedExerciseIds,
          recentExerciseIds: recentExerciseIds,
          recentEquipment: recentEquipment,
          focusAreas: focusAreas,
          preferredMovementGroups: preferredMovementGroups,
        );
      }

      if (candidates.isEmpty) {
        debugPrint('🟡 [SESSION_GEN] No candidates for slot $slot, skipping');
        continue;
      }

      // Score and select best candidate
      final selected = _selectBestCandidate(
        candidates: candidates,
        targetGroup: targetGroup,
        isCompoundSlot: isCompoundSlot,
        clientGoals: clientGoals,
        focusAreas: focusAreas,
      );

      if (selected == null) {
        debugPrint('🟡 [SESSION_GEN] Could not select exercise for slot $slot');
        continue;
      }

      // Generate prescription for this exercise
      final exercisePrescription = _generatePrescription(
        prescription: prescription,
        exercise: selected.exercise,
        isCompoundSlot: isCompoundSlot,
        slotIndex: slot,
      );

      // Generate reasoning label
      final reasoningLabel = _generateReasoningLabel(
        exercise: selected.exercise,
        reason: selected.reason,
        isCompoundSlot: isCompoundSlot,
        effectiveFocus: effectiveFocus,
        trainingSplit: trainingSplit,
      );

      // Create generated exercise
      final generatedExercise = GeneratedExercise(
        exercise: selected.exercise,
        orderIndex: generatedExercises.length,
        targetSets: exercisePrescription['sets'] as int,
        targetReps: exercisePrescription['reps'] as String,
        targetRpe: exercisePrescription['rpe'] as int,
        restSeconds: exercisePrescription['rest'] as int,
        reasoningLabel: reasoningLabel,
        reasoningDetail: _generateReasoningDetail(
          exercise: selected.exercise,
          reason: selected.reason,
          isCompoundSlot: isCompoundSlot,
        ),
      );

      generatedExercises.add(generatedExercise);

      // Update tracking sets
      usedExerciseIds.add(selected.exercise.id);
      if (selected.exercise.family != null) {
        usedFamilies.add(selected.exercise.family!);
      }
      if (selected.exercise.equipment != null) {
        recentEquipment.add(selected.exercise.equipment!);
        if (recentEquipment.length > 3) {
          recentEquipment.removeAt(0);
        }
      }

      debugPrint('🔵 [SESSION_GEN] Selected: ${selected.exercise.displayName} (${selected.reason})');
    }

    // 6. Create session description
    final sessionDescription = _generateSessionDescription(
      effectiveFocus: effectiveFocus,
      trainingSplit: trainingSplit,
      exerciseCount: generatedExercises.length,
    );

    debugPrint('🔵 [SESSION_GEN] Generated ${generatedExercises.length} exercises');

    return GeneratedSession(
      focusArea: effectiveFocus,
      trainingSplit: trainingSplit,
      exercises: generatedExercises,
      generatedAt: DateTime.now(),
      sessionDescription: sessionDescription['en'],
      sessionDescriptionKo: sessionDescription['ko'],
    );
  }

  /// Calculate effective focus based on recent sessions and training split
  String _calculateEffectiveFocus({
    required List<SessionEntity> recentSessions,
    required TrainingSplit trainingSplit,
    String? suggestedNextFocus,
  }) {
    // For full body, always return full_body
    if (trainingSplit == TrainingSplit.fullBody) {
      return 'full_body';
    }

    // If no recent sessions, use default for split
    if (recentSessions.isEmpty) {
      switch (trainingSplit) {
        case TrainingSplit.upperLower:
          return 'upper';
        case TrainingSplit.pushPullLegs:
          return 'push';
        case TrainingSplit.fullBody:
          return 'full_body';
      }
    }

    // Analyze last session to determine rotation
    final lastSession = recentSessions.first;
    if (lastSession.exercises.isEmpty) {
      return suggestedNextFocus ?? 'upper';
    }

    // Count movement groups in last session
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
        default:
          // Check muscle for upper/lower
          final muscle = exercise.exercise.muscleGroup?.toLowerCase() ?? '';
          if (_isLowerBodyMuscle(muscle)) {
            lowerCount++;
          } else {
            upperCount++;
          }
      }
    }

    // Determine next focus based on what was last worked
    switch (trainingSplit) {
      case TrainingSplit.upperLower:
        return lowerCount > upperCount ? 'upper' : 'lower';
      case TrainingSplit.pushPullLegs:
        if (legsCount > pushCount && legsCount > pullCount) return 'push';
        if (pushCount >= pullCount) return 'pull';
        return 'legs';
      case TrainingSplit.fullBody:
        return 'full_body';
    }
  }

  /// Check if muscle is lower body
  bool _isLowerBodyMuscle(String muscle) {
    return muscle.contains('leg') ||
        muscle.contains('quad') ||
        muscle.contains('ham') ||
        muscle.contains('glute') ||
        muscle.contains('calf') ||
        muscle.contains('calves');
  }

  /// Get group distribution for a focus area
  List<String> _getGroupDistribution(String focus) {
    return _groupDistribution[focus] ?? _groupDistribution['full_body']!;
  }

  /// Get recent exercise IDs from sessions
  Set<String> _getRecentExerciseIds(List<SessionEntity> recentSessions) {
    final ids = <String>{};
    // Only look at the last 2 sessions to avoid over-restricting
    for (final session in recentSessions.take(2)) {
      for (final exercise in session.exercises) {
        ids.add(exercise.exercise.id);
      }
    }
    return ids;
  }

  /// Get candidate exercises for a slot
  List<_ScoredCandidate> _getCandidates({
    required List<ExerciseEntity> exerciseLibrary,
    required String targetGroup,
    required bool preferCompound,
    required Set<String> usedFamilies,
    required Set<String> usedExerciseIds,
    required Set<String> recentExerciseIds,
    required List<String> recentEquipment,
    List<String>? focusAreas,
    List<String>? preferredMovementGroups,
  }) {
    final candidates = <_ScoredCandidate>[];

    for (final exercise in exerciseLibrary) {
      // Skip if already used in this session
      if (usedExerciseIds.contains(exercise.id)) continue;

      // Skip if not in target group
      if (exercise.movementGroup != targetGroup) continue;

      // Hard filter: In compound slots, skip isolation exercises
      // Only allow isolation if we find no compounds (handled by fallback in generateSession)
      if (preferCompound && exercise.category != ExerciseCategory.compound) {
        continue;
      }

      // Skip if same family already used (diversity constraint)
      if (exercise.family != null && usedFamilies.contains(exercise.family)) {
        continue;
      }

      // Calculate score
      double score = 100.0; // Base score
      String reason = 'split_focus';

      // Compound preference for early slots
      final isCompound = exercise.category == ExerciseCategory.compound;
      if (preferCompound) {
        if (isCompound) {
          score += 50.0;
          reason = 'compound_priority';
        } else {
          score -= 30.0;
        }
      } else {
        // Isolation preference for later slots
        if (!isCompound) {
          score += 30.0;
          reason = 'isolation_finisher';
        }
      }

      // Penalize recently used exercises (not in this session, but recent sessions)
      if (recentExerciseIds.contains(exercise.id)) {
        score -= 40.0;
      }

      // Equipment variety bonus
      if (exercise.equipment != null) {
        final equipmentCount = recentEquipment.where(
          (e) => e == exercise.equipment,
        ).length;
        if (equipmentCount >= 2) {
          score -= 20.0; // Penalize same equipment 3 times in a row
        }
      }

      // Focus area bonus
      if (focusAreas != null && focusAreas.isNotEmpty) {
        final muscleGroup = exercise.muscleGroup?.toLowerCase() ?? '';
        for (final focus in focusAreas) {
          if (muscleGroup.contains(focus.toLowerCase())) {
            score += 25.0;
            reason = 'focus_area';
            break;
          }
        }
      }

      // Preferred movement group bonus
      if (preferredMovementGroups != null &&
          preferredMovementGroups.contains(exercise.movementGroup)) {
        score += 15.0;
      }

      if (score > 0) {
        candidates.add(_ScoredCandidate(exercise, score, reason));
      }
    }

    // Sort by score descending
    candidates.sort((a, b) => b.score.compareTo(a.score));

    return candidates;
  }

  /// Select the best candidate from scored list
  _ScoredCandidate? _selectBestCandidate({
    required List<_ScoredCandidate> candidates,
    required String targetGroup,
    required bool isCompoundSlot,
    required List<String> clientGoals,
    List<String>? focusAreas,
  }) {
    if (candidates.isEmpty) return null;

    // Return top candidate (already sorted by score)
    // Add small random factor for variety (top 3 candidates)
    if (candidates.length >= 3) {
      final topCandidates = candidates.take(3).toList();
      final random = Random();
      // Weighted random: 60% top, 30% second, 10% third
      final roll = random.nextDouble();
      if (roll < 0.6) return topCandidates[0];
      if (roll < 0.9) return topCandidates[1];
      return topCandidates[2];
    }

    return candidates.first;
  }

  /// Generate prescription (sets, reps, rest, RPE) for an exercise
  Map<String, dynamic> _generatePrescription({
    required ExercisePrescription prescription,
    required ExerciseEntity exercise,
    required bool isCompoundSlot,
    required int slotIndex,
  }) {
    final random = Random();

    // Calculate sets (compounds get more sets in early slots)
    int sets;
    if (isCompoundSlot) {
      sets = prescription.minSets +
          random.nextInt(prescription.maxSets - prescription.minSets + 1);
      // Ensure at least 3 sets for compounds
      sets = max(sets, 3);
    } else {
      // Isolation exercises get fewer sets
      sets = prescription.minSets;
    }

    // Calculate rep range based on exercise category
    String reps;
    if (exercise.category == ExerciseCategory.compound) {
      // Compounds tend toward lower rep range
      final minReps = prescription.minReps;
      final maxReps = min(prescription.maxReps, 10);
      reps = '$minReps-$maxReps';
    } else {
      // Isolation toward higher rep range
      final minReps = max(prescription.minReps, 8);
      final maxReps = prescription.maxReps;
      reps = '$minReps-$maxReps';
    }

    // Calculate rest (compounds need more rest)
    int rest;
    if (isCompoundSlot) {
      rest = prescription.maxRestSeconds;
    } else {
      rest = (prescription.minRestSeconds + prescription.maxRestSeconds) ~/ 2;
    }

    // Calculate RPE (use middle of range)
    final rpe = (prescription.minRpe + prescription.maxRpe) ~/ 2;

    return {
      'sets': sets,
      'reps': reps,
      'rest': rest,
      'rpe': rpe,
    };
  }

  /// Generate Korean reasoning label for UI
  String _generateReasoningLabel({
    required ExerciseEntity exercise,
    required String reason,
    required bool isCompoundSlot,
    required String effectiveFocus,
    required TrainingSplit trainingSplit,
  }) {
    // Build label based on primary reason
    switch (reason) {
      case 'compound_priority':
        return ReasoningLabels.compoundPriority;
      case 'isolation_finisher':
        return ReasoningLabels.isolationFinisher;
      case 'focus_area':
        return ReasoningLabels.focusArea;
      case 'split_focus':
        return _getSplitFocusLabel(effectiveFocus, trainingSplit);
      default:
        return ReasoningLabels.goalAlignment;
    }
  }

  /// Get split focus label in Korean
  String _getSplitFocusLabel(String focus, TrainingSplit split) {
    switch (split) {
      case TrainingSplit.upperLower:
        return focus == 'upper' ? '상체 운동일' : '하체 운동일';
      case TrainingSplit.pushPullLegs:
        if (focus == 'push') return '밀기 운동일';
        if (focus == 'pull') return '당기기 운동일';
        return '하체 운동일';
      case TrainingSplit.fullBody:
        return '전신 균형 훈련';
    }
  }

  /// Generate detailed reasoning for expanded view
  String? _generateReasoningDetail({
    required ExerciseEntity exercise,
    required String reason,
    required bool isCompoundSlot,
  }) {
    final parts = <String>[];

    if (isCompoundSlot && exercise.category == ExerciseCategory.compound) {
      parts.add('복합 운동으로 여러 근육을 동시에 자극합니다.');
    } else if (!isCompoundSlot) {
      parts.add('마무리 운동으로 특정 근육을 집중적으로 자극합니다.');
    }

    if (exercise.muscleGroup != null) {
      final muscleKo = _getMuscleKo(exercise.muscleGroup!);
      parts.add('주요 타겟: $muscleKo');
    }

    return parts.isNotEmpty ? parts.join(' ') : null;
  }

  /// Get Korean name for muscle group
  String _getMuscleKo(String muscle) {
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

  /// Generate session description
  Map<String, String> _generateSessionDescription({
    required String effectiveFocus,
    required TrainingSplit trainingSplit,
    required int exerciseCount,
  }) {
    String en;
    String ko;

    switch (trainingSplit) {
      case TrainingSplit.upperLower:
        if (effectiveFocus == 'upper') {
          en = 'Upper body workout focusing on push and pull movements';
          ko = '상체 운동 - 밀기와 당기기 동작 중심';
        } else {
          en = 'Lower body workout focusing on legs and core';
          ko = '하체 운동 - 다리와 코어 중심';
        }
        break;
      case TrainingSplit.pushPullLegs:
        if (effectiveFocus == 'push') {
          en = 'Push day focusing on chest, shoulders, and triceps';
          ko = '밀기 운동일 - 가슴, 어깨, 삼두 중심';
        } else if (effectiveFocus == 'pull') {
          en = 'Pull day focusing on back and biceps';
          ko = '당기기 운동일 - 등과 이두 중심';
        } else {
          en = 'Leg day focusing on quadriceps, hamstrings, and glutes';
          ko = '하체 운동일 - 대퇴사두, 햄스트링, 둔근 중심';
        }
        break;
      case TrainingSplit.fullBody:
        en = 'Full body workout with balanced push, pull, and leg movements';
        ko = '전신 운동 - 밀기, 당기기, 하체 균형 훈련';
        break;
    }

    return {'en': en, 'ko': ko};
  }
}

/// Internal scored candidate class
class _ScoredCandidate {
  final ExerciseEntity exercise;
  final double score;
  final String reason;

  _ScoredCandidate(this.exercise, this.score, this.reason);
}
