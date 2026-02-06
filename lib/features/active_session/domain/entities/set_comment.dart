import 'exercise_entity.dart';

/// Categories for set comments
enum SetCommentCategory {
  mistake,     // 흔한 실수
  coachingCue, // 코칭 큐
  condition,   // 컨디션
}

/// Coaching comments/cues for exercise sets
enum SetComment {
  // ============ Mistake (흔한 실수) - 12 items ============
  chestUp,
  backStraight,
  shouldersDown,
  shoulderBlades,
  coreBrace,
  hipsBack,
  kneesOut,
  neutralSpine,
  headNeutral,
  elbowsTucked,
  wristsStraight,
  feetFlat,

  // ============ Coaching Cue (코칭 큐) - 12 items ============
  squeezeTop,
  feelStretch,
  squeezeGlutes,
  driveHeels,
  latTension,
  chestSqueeze,
  mindMuscle,
  controlNegative,
  explosiveUp,
  breatheOut,
  fullRom,
  pauseBottom,

  // ============ Condition (컨디션) - 12 items ============
  painReported,
  fatigueEarly,
  noRhythm,
  formBreakdown,
  coordinationIssue,
  limitedRom,
  weakSide,
  breathingIssue,
  lowEnergy,
  gripWeak,
  balanceOff,
  tensionLoss,
}

extension SetCommentExtension on SetComment {
  /// Korean display name (formal)
  String get displayName {
    switch (this) {
      // Mistake
      case SetComment.chestUp:
        return '가슴을 들어주세요';
      case SetComment.backStraight:
        return '허리를 펴주세요';
      case SetComment.shouldersDown:
        return '어깨를 내려주세요';
      case SetComment.shoulderBlades:
        return '견갑골을 조여주세요';
      case SetComment.coreBrace:
        return '코어를 조여주세요';
      case SetComment.hipsBack:
        return '엉덩이를 뒤로 빼주세요';
      case SetComment.kneesOut:
        return '무릎을 바깥으로 밀어주세요';
      case SetComment.neutralSpine:
        return '척추 중립을 유지해주세요';
      case SetComment.headNeutral:
        return '고개를 중립으로 해주세요';
      case SetComment.elbowsTucked:
        return '팔꿈치를 붙여주세요';
      case SetComment.wristsStraight:
        return '손목을 곧게 해주세요';
      case SetComment.feetFlat:
        return '발바닥을 고정해주세요';
      // Coaching Cue
      case SetComment.squeezeTop:
        return '정점에서 수축해주세요';
      case SetComment.feelStretch:
        return '스트레칭을 느껴주세요';
      case SetComment.squeezeGlutes:
        return '엉덩이를 조여주세요';
      case SetComment.driveHeels:
        return '발뒤꿈치로 밀어주세요';
      case SetComment.latTension:
        return '광배근 긴장을 느껴주세요';
      case SetComment.chestSqueeze:
        return '가슴을 수축해주세요';
      case SetComment.mindMuscle:
        return '타겟 근육에 집중해주세요';
      case SetComment.controlNegative:
        return '네거티브를 천천히 해주세요';
      case SetComment.explosiveUp:
        return '폭발적으로 올려주세요';
      case SetComment.breatheOut:
        return '힘줄 때 내쉬어주세요';
      case SetComment.fullRom:
        return '가동범위 끝까지 해주세요';
      case SetComment.pauseBottom:
        return '바텀에서 멈춰주세요';
      // Condition
      case SetComment.painReported:
        return '통증을 호소함';
      case SetComment.fatigueEarly:
        return '피로가 빨리 옴';
      case SetComment.noRhythm:
        return '리듬을 못 찾음';
      case SetComment.formBreakdown:
        return '폼이 무너짐';
      case SetComment.coordinationIssue:
        return '협응이 안됨';
      case SetComment.limitedRom:
        return '가동범위가 제한됨';
      case SetComment.weakSide:
        return '좌우 불균형';
      case SetComment.breathingIssue:
        return '호흡이 불안정함';
      case SetComment.lowEnergy:
        return '컨디션이 안좋음';
      case SetComment.gripWeak:
        return '그립이 약함';
      case SetComment.balanceOff:
        return '균형이 안잡힘';
      case SetComment.tensionLoss:
        return '긴장이 풀림';
    }
  }

  /// English display name
  String get displayNameEn {
    switch (this) {
      // Mistake
      case SetComment.chestUp:
        return 'Chest up';
      case SetComment.backStraight:
        return 'Keep back straight';
      case SetComment.shouldersDown:
        return 'Shoulders down';
      case SetComment.shoulderBlades:
        return 'Squeeze shoulder blades';
      case SetComment.coreBrace:
        return 'Brace your core';
      case SetComment.hipsBack:
        return 'Hips back';
      case SetComment.kneesOut:
        return 'Knees out';
      case SetComment.neutralSpine:
        return 'Neutral spine';
      case SetComment.headNeutral:
        return 'Head neutral';
      case SetComment.elbowsTucked:
        return 'Elbows tucked';
      case SetComment.wristsStraight:
        return 'Wrists straight';
      case SetComment.feetFlat:
        return 'Feet flat';
      // Coaching Cue
      case SetComment.squeezeTop:
        return 'Squeeze at the top';
      case SetComment.feelStretch:
        return 'Feel the stretch';
      case SetComment.squeezeGlutes:
        return 'Squeeze glutes';
      case SetComment.driveHeels:
        return 'Drive through heels';
      case SetComment.latTension:
        return 'Feel lat tension';
      case SetComment.chestSqueeze:
        return 'Squeeze chest';
      case SetComment.mindMuscle:
        return 'Mind-muscle connection';
      case SetComment.controlNegative:
        return 'Control the negative';
      case SetComment.explosiveUp:
        return 'Explosive on the way up';
      case SetComment.breatheOut:
        return 'Breathe out on exertion';
      case SetComment.fullRom:
        return 'Full range of motion';
      case SetComment.pauseBottom:
        return 'Pause at the bottom';
      // Condition
      case SetComment.painReported:
        return 'Pain reported';
      case SetComment.fatigueEarly:
        return 'Fatigues quickly';
      case SetComment.noRhythm:
        return 'Cannot find rhythm';
      case SetComment.formBreakdown:
        return 'Form breaking down';
      case SetComment.coordinationIssue:
        return 'Coordination issues';
      case SetComment.limitedRom:
        return 'Limited range of motion';
      case SetComment.weakSide:
        return 'Weak side imbalance';
      case SetComment.breathingIssue:
        return 'Breathing issues';
      case SetComment.lowEnergy:
        return 'Low energy today';
      case SetComment.gripWeak:
        return 'Weak grip';
      case SetComment.balanceOff:
        return 'Balance issues';
      case SetComment.tensionLoss:
        return 'Losing tension';
    }
  }

  /// Short display name for compact UI
  String get shortDisplayName {
    switch (this) {
      // Mistake
      case SetComment.chestUp:
        return '가슴 들기';
      case SetComment.backStraight:
        return '허리 펴기';
      case SetComment.shouldersDown:
        return '어깨 내리기';
      case SetComment.shoulderBlades:
        return '견갑골 조이기';
      case SetComment.coreBrace:
        return '코어 조이기';
      case SetComment.hipsBack:
        return '엉덩이 빼기';
      case SetComment.kneesOut:
        return '무릎 밀기';
      case SetComment.neutralSpine:
        return '척추 중립';
      case SetComment.headNeutral:
        return '고개 중립';
      case SetComment.elbowsTucked:
        return '팔꿈치 붙이기';
      case SetComment.wristsStraight:
        return '손목 곧게';
      case SetComment.feetFlat:
        return '발바닥 고정';
      // Coaching Cue
      case SetComment.squeezeTop:
        return '정점 수축';
      case SetComment.feelStretch:
        return '스트레칭 느끼기';
      case SetComment.squeezeGlutes:
        return '엉덩이 조이기';
      case SetComment.driveHeels:
        return '발뒤꿈치로 밀기';
      case SetComment.latTension:
        return '광배근 긴장';
      case SetComment.chestSqueeze:
        return '가슴 수축';
      case SetComment.mindMuscle:
        return '근육 집중';
      case SetComment.controlNegative:
        return '천천히 내리기';
      case SetComment.explosiveUp:
        return '폭발적 올리기';
      case SetComment.breatheOut:
        return '호흡 내쉬기';
      case SetComment.fullRom:
        return '전체 가동범위';
      case SetComment.pauseBottom:
        return '바텀 멈추기';
      // Condition
      case SetComment.painReported:
        return '통증';
      case SetComment.fatigueEarly:
        return '빠른 피로';
      case SetComment.noRhythm:
        return '리듬 없음';
      case SetComment.formBreakdown:
        return '폼 붕괴';
      case SetComment.coordinationIssue:
        return '협응 문제';
      case SetComment.limitedRom:
        return '제한된 가동범위';
      case SetComment.weakSide:
        return '좌우 불균형';
      case SetComment.breathingIssue:
        return '호흡 불안정';
      case SetComment.lowEnergy:
        return '컨디션 저하';
      case SetComment.gripWeak:
        return '약한 그립';
      case SetComment.balanceOff:
        return '균형 불안정';
      case SetComment.tensionLoss:
        return '긴장 풀림';
    }
  }

  /// Category of the comment
  SetCommentCategory get category {
    switch (this) {
      case SetComment.chestUp:
      case SetComment.backStraight:
      case SetComment.shouldersDown:
      case SetComment.shoulderBlades:
      case SetComment.coreBrace:
      case SetComment.hipsBack:
      case SetComment.kneesOut:
      case SetComment.neutralSpine:
      case SetComment.headNeutral:
      case SetComment.elbowsTucked:
      case SetComment.wristsStraight:
      case SetComment.feetFlat:
        return SetCommentCategory.mistake;
      case SetComment.squeezeTop:
      case SetComment.feelStretch:
      case SetComment.squeezeGlutes:
      case SetComment.driveHeels:
      case SetComment.latTension:
      case SetComment.chestSqueeze:
      case SetComment.mindMuscle:
      case SetComment.controlNegative:
      case SetComment.explosiveUp:
      case SetComment.breatheOut:
      case SetComment.fullRom:
      case SetComment.pauseBottom:
        return SetCommentCategory.coachingCue;
      case SetComment.painReported:
      case SetComment.fatigueEarly:
      case SetComment.noRhythm:
      case SetComment.formBreakdown:
      case SetComment.coordinationIssue:
      case SetComment.limitedRom:
      case SetComment.weakSide:
      case SetComment.breathingIssue:
      case SetComment.lowEnergy:
      case SetComment.gripWeak:
      case SetComment.balanceOff:
      case SetComment.tensionLoss:
        return SetCommentCategory.condition;
    }
  }

  /// Movement groups this comment applies to ('all' means all groups)
  List<String> get movementGroups {
    switch (this) {
      // Mistake - specific groups
      case SetComment.chestUp:
        return [MovementGroup.legs, MovementGroup.pull];
      case SetComment.backStraight:
        return [MovementGroup.legs, MovementGroup.pull];
      case SetComment.shoulderBlades:
        return [MovementGroup.push, MovementGroup.pull];
      case SetComment.hipsBack:
        return [MovementGroup.legs];
      case SetComment.kneesOut:
        return [MovementGroup.legs];
      case SetComment.elbowsTucked:
        return [MovementGroup.push];
      case SetComment.wristsStraight:
        return [MovementGroup.push];
      case SetComment.feetFlat:
        return [MovementGroup.legs, MovementGroup.push];
      // Coaching Cue - specific groups
      case SetComment.squeezeTop:
        return [MovementGroup.other, MovementGroup.pull];
      case SetComment.squeezeGlutes:
        return [MovementGroup.legs];
      case SetComment.driveHeels:
        return [MovementGroup.legs];
      case SetComment.latTension:
        return [MovementGroup.pull, MovementGroup.legs];
      case SetComment.chestSqueeze:
        return [MovementGroup.push];
      case SetComment.mindMuscle:
        return [MovementGroup.other];
      case SetComment.explosiveUp:
        return [MovementGroup.legs, MovementGroup.push];
      case SetComment.pauseBottom:
        return [MovementGroup.legs, MovementGroup.push];
      // Condition - specific groups
      case SetComment.gripWeak:
        return [MovementGroup.legs, MovementGroup.pull];
      case SetComment.balanceOff:
        return [MovementGroup.legs, MovementGroup.core];
      // All groups
      case SetComment.shouldersDown:
      case SetComment.coreBrace:
      case SetComment.neutralSpine:
      case SetComment.headNeutral:
      case SetComment.feelStretch:
      case SetComment.controlNegative:
      case SetComment.breatheOut:
      case SetComment.fullRom:
      case SetComment.painReported:
      case SetComment.fatigueEarly:
      case SetComment.noRhythm:
      case SetComment.formBreakdown:
      case SetComment.coordinationIssue:
      case SetComment.limitedRom:
      case SetComment.weakSide:
      case SetComment.breathingIssue:
      case SetComment.lowEnergy:
      case SetComment.tensionLoss:
        return MovementGroup.all;
    }
  }

  /// Check if comment applies to a given movement group
  bool appliesTo(String movementGroup) {
    final groups = movementGroups;
    return groups == MovementGroup.all || groups.contains(movementGroup);
  }

  /// Database key for storage
  String get databaseKey {
    switch (this) {
      case SetComment.chestUp:
        return 'chest_up';
      case SetComment.backStraight:
        return 'back_straight';
      case SetComment.shouldersDown:
        return 'shoulders_down';
      case SetComment.shoulderBlades:
        return 'shoulder_blades';
      case SetComment.coreBrace:
        return 'core_brace';
      case SetComment.hipsBack:
        return 'hips_back';
      case SetComment.kneesOut:
        return 'knees_out';
      case SetComment.neutralSpine:
        return 'neutral_spine';
      case SetComment.headNeutral:
        return 'head_neutral';
      case SetComment.elbowsTucked:
        return 'elbows_tucked';
      case SetComment.wristsStraight:
        return 'wrists_straight';
      case SetComment.feetFlat:
        return 'feet_flat';
      case SetComment.squeezeTop:
        return 'squeeze_top';
      case SetComment.feelStretch:
        return 'feel_stretch';
      case SetComment.squeezeGlutes:
        return 'squeeze_glutes';
      case SetComment.driveHeels:
        return 'drive_heels';
      case SetComment.latTension:
        return 'lat_tension';
      case SetComment.chestSqueeze:
        return 'chest_squeeze';
      case SetComment.mindMuscle:
        return 'mind_muscle';
      case SetComment.controlNegative:
        return 'control_negative';
      case SetComment.explosiveUp:
        return 'explosive_up';
      case SetComment.breatheOut:
        return 'breathe_out';
      case SetComment.fullRom:
        return 'full_rom';
      case SetComment.pauseBottom:
        return 'pause_bottom';
      case SetComment.painReported:
        return 'pain_reported';
      case SetComment.fatigueEarly:
        return 'fatigue_early';
      case SetComment.noRhythm:
        return 'no_rhythm';
      case SetComment.formBreakdown:
        return 'form_breakdown';
      case SetComment.coordinationIssue:
        return 'coordination_issue';
      case SetComment.limitedRom:
        return 'limited_rom';
      case SetComment.weakSide:
        return 'weak_side';
      case SetComment.breathingIssue:
        return 'breathing_issue';
      case SetComment.lowEnergy:
        return 'low_energy';
      case SetComment.gripWeak:
        return 'grip_weak';
      case SetComment.balanceOff:
        return 'balance_off';
      case SetComment.tensionLoss:
        return 'tension_loss';
    }
  }

  /// Parse from database key
  static SetComment? fromDatabaseKey(String key) {
    switch (key.toLowerCase()) {
      case 'chest_up':
        return SetComment.chestUp;
      case 'back_straight':
        return SetComment.backStraight;
      case 'shoulders_down':
        return SetComment.shouldersDown;
      case 'shoulder_blades':
        return SetComment.shoulderBlades;
      case 'core_brace':
        return SetComment.coreBrace;
      case 'hips_back':
        return SetComment.hipsBack;
      case 'knees_out':
        return SetComment.kneesOut;
      case 'neutral_spine':
        return SetComment.neutralSpine;
      case 'head_neutral':
        return SetComment.headNeutral;
      case 'elbows_tucked':
        return SetComment.elbowsTucked;
      case 'wrists_straight':
        return SetComment.wristsStraight;
      case 'feet_flat':
        return SetComment.feetFlat;
      case 'squeeze_top':
        return SetComment.squeezeTop;
      case 'feel_stretch':
        return SetComment.feelStretch;
      case 'squeeze_glutes':
        return SetComment.squeezeGlutes;
      case 'drive_heels':
        return SetComment.driveHeels;
      case 'lat_tension':
        return SetComment.latTension;
      case 'chest_squeeze':
        return SetComment.chestSqueeze;
      case 'mind_muscle':
        return SetComment.mindMuscle;
      case 'control_negative':
        return SetComment.controlNegative;
      case 'explosive_up':
        return SetComment.explosiveUp;
      case 'breathe_out':
        return SetComment.breatheOut;
      case 'full_rom':
        return SetComment.fullRom;
      case 'pause_bottom':
        return SetComment.pauseBottom;
      case 'pain_reported':
        return SetComment.painReported;
      case 'fatigue_early':
        return SetComment.fatigueEarly;
      case 'no_rhythm':
        return SetComment.noRhythm;
      case 'form_breakdown':
        return SetComment.formBreakdown;
      case 'coordination_issue':
        return SetComment.coordinationIssue;
      case 'limited_rom':
        return SetComment.limitedRom;
      case 'weak_side':
        return SetComment.weakSide;
      case 'breathing_issue':
        return SetComment.breathingIssue;
      case 'low_energy':
        return SetComment.lowEnergy;
      case 'grip_weak':
        return SetComment.gripWeak;
      case 'balance_off':
        return SetComment.balanceOff;
      case 'tension_loss':
        return SetComment.tensionLoss;
      default:
        return null;
    }
  }
}

extension SetCommentCategoryExtension on SetCommentCategory {
  /// Display name in Korean
  String get displayName {
    switch (this) {
      case SetCommentCategory.mistake:
        return '흔한 실수';
      case SetCommentCategory.coachingCue:
        return '코칭 큐';
      case SetCommentCategory.condition:
        return '컨디션';
    }
  }

  /// Display name in English
  String get displayNameEn {
    switch (this) {
      case SetCommentCategory.mistake:
        return 'Common Mistakes';
      case SetCommentCategory.coachingCue:
        return 'Coaching Cues';
      case SetCommentCategory.condition:
        return 'Condition';
    }
  }

  /// Get all comments in this category
  List<SetComment> get comments {
    return SetComment.values.where((c) => c.category == this).toList();
  }
}

/// Helper to get comments filtered by movement group
class SetCommentHelper {
  /// Get all comments applicable to a movement group, grouped by category
  static Map<SetCommentCategory, List<SetComment>> getCommentsForPattern(
    String movementGroup,
  ) {
    final result = <SetCommentCategory, List<SetComment>>{};

    for (final category in SetCommentCategory.values) {
      result[category] = SetComment.values
          .where((c) => c.category == category && c.appliesTo(movementGroup))
          .toList();
    }

    return result;
  }

  /// Get top N comments per category for a movement group
  static Map<SetCommentCategory, List<SetComment>> getTopCommentsForPattern(
    String movementGroup, {
    int perCategory = 4,
    Map<String, int>? usageCounts,
  }) {
    final all = getCommentsForPattern(movementGroup);
    final result = <SetCommentCategory, List<SetComment>>{};

    for (final entry in all.entries) {
      var comments = entry.value;

      // Sort by usage count if provided
      if (usageCounts != null && usageCounts.isNotEmpty) {
        comments = List.from(comments)
          ..sort((a, b) {
            final countA = usageCounts[a.databaseKey] ?? 0;
            final countB = usageCounts[b.databaseKey] ?? 0;
            return countB.compareTo(countA);
          });
      }

      result[entry.key] = comments.take(perCategory).toList();
    }

    return result;
  }
}
