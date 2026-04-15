import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../active_session/domain/entities/exercise_set_entity.dart';
import '../../../active_session/domain/entities/session_entity.dart';
import '../../../active_session/domain/entities/session_exercise_entity.dart';
import '../../../active_session/domain/entities/set_comment.dart';

/// Maximum number of exercises to display in the card
const int _maxExercisesToShow = 4;

/// Tappable session card for the History tab in Stats screen
/// Shows session summary: focus area, date, exercises, sets, volume, PR count
/// Now includes exercise details with set summaries and comments
class SessionHistoryCard extends StatelessWidget {
  final SessionEntity session;
  final VoidCallback onTap;

  const SessionHistoryCard({
    required this.session,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final focusArea = _getFocusAreaKorean(session.focusArea);
    final focusColor = _getFocusAreaColor(session.focusArea);
    final exerciseCount =
        session.savedTotalExercises ?? session.exercises.length;
    final totalVolume = session.savedTotalVolume ?? session.totalVolume;
    final totalSets = session.savedTotalSets ?? session.totalSetsCount;
    final prCount = session.prCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: focusColor.withValues(alpha: 0.1),
        highlightColor: focusColor.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focusColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // Focus area badge with gradient
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            focusColor,
                            focusColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: focusColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getFocusIcon(session.focusArea),
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            focusArea,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Date with icon
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: AppColors.neutral500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            session.completedAt != null
                                ? _formatDate(session.completedAt!)
                                : '날짜 없음',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // PR badge (prominent with bold numbers)
                    if (prCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFF8C00),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '🏆',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$prCount',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Color(0x40000000),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'PR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Arrow indicator
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: focusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: focusColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Stats row - right aligned
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _IntenseStatChip(
                      icon: Icons.fitness_center_rounded,
                      value: '$exerciseCount',
                      label: '운동',
                      color: const Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 8),
                    _IntenseStatChip(
                      icon: Icons.repeat_rounded,
                      value: '$totalSets',
                      label: '세트',
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    _IntenseStatChip(
                      icon: Icons.local_fire_department_rounded,
                      value: _formatVolume(totalVolume),
                      label: '볼륨',
                      color: const Color(0xFFF59E0B),
                      isWide: true,
                    ),
                  ],
                ),
              ),

              // Exercise details section
              if (session.exercises.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Divider(
                    height: 1,
                    color: AppColors.neutral200,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _buildExerciseList(session.exercises, focusColor),
                ),
              ] else if (exerciseCount > 0) ...[
                // Session has saved exercise count but no exercise details loaded
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: focusColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$exerciseCount개 운동 완료',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: focusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

            ],
          ),
        ),
      ),
    );
  }

  /// Build the list of exercise rows
  Widget _buildExerciseList(
    List<SessionExerciseEntity> exercises,
    Color accentColor,
  ) {
    final displayExercises = exercises.take(_maxExercisesToShow).toList();
    final remainingCount = exercises.length - _maxExercisesToShow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayExercises
            .asMap()
            .entries
            .map((e) => _buildExerciseRow(e.value, e.key, accentColor)),
        if (remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+ $remainingCount개 더 보기',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build a single exercise row with name, set summary, and comment chips
  Widget _buildExerciseRow(
    SessionExerciseEntity exercise,
    int index,
    Color accentColor,
  ) {
    final name = exercise.exercise.nameKo ?? exercise.exercise.name;
    final setSummary = _formatSetSummaryRich(exercise.sets);
    final hasPR = exercise.hasPR;
    final comments = _extractExerciseComments(exercise);
    final memo = _extractExerciseMemo(exercise);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: hasPR
            ? const Color(0xFFFFF8E1).withValues(alpha: 0.8)
            : AppColors.neutral100,
        borderRadius: BorderRadius.circular(10),
        border: hasPR
            ? Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Exercise number indicator
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: hasPR
                      ? const Color(0xFFFFD700)
                      : accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: hasPR
                      ? const Text(
                          '🏆',
                          style: TextStyle(fontSize: 11),
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              // Exercise name - prominent and visible
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: hasPR
                        ? const Color(0xFFB8860B)
                        : const Color(0xFF1F2937),
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 12),
              // Set summary - right aligned
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hasPR
                      ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasPR
                        ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                        : AppColors.neutral200,
                    width: 1,
                  ),
                ),
                child: setSummary,
              ),
            ],
          ),
          // Comment chips inline below exercise name
          if (comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 6),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children:
                    comments.map((c) => _buildCommentChip(c)).toList(),
              ),
            ),
          // Free-form memo below comments
          if (memo != null && memo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, size: 12, color: AppColors.neutral500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      memo,
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.neutral600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Format set summary with rich text styling for emphasis on numbers
  Widget _formatSetSummaryRich(List<ExerciseSetEntity> sets) {
    final workingSets = sets.where((s) => !s.isWarmup).toList();
    if (workingSets.isEmpty) {
      final warmupCount = sets.where((s) => s.isWarmup).length;
      return Text(
        warmupCount > 0 ? '워밍업 $warmupCount세트' : '세트 없음',
        style: TextStyle(
          fontSize: 11,
          color: AppColors.neutral500,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.right,
      );
    }

    // Check if all sets are identical (same weight and reps)
    final firstSet = workingSets.first;
    final allIdentical = workingSets.every(
      (s) => s.weight == firstSet.weight && s.reps == firstSet.reps,
    );

    if (allIdentical && workingSets.length > 1) {
      // Format: "40×10 × 3세트"
      return _buildCompactSetDisplay(
        weight: _formatWeight(firstSet.weight),
        reps: '${firstSet.reps ?? 0}',
        setCount: workingSets.length,
      );
    }

    // Check if weights are progressively increasing
    bool isProgressive = true;
    for (int i = 1; i < workingSets.length; i++) {
      if ((workingSets[i].weight ?? 0) <= (workingSets[i - 1].weight ?? 0)) {
        isProgressive = false;
        break;
      }
    }

    // Build progressive or varied display
    return _buildProgressiveSetDisplay(
      workingSets,
      isProgressive: isProgressive,
    );
  }

  /// Build compact display for identical sets: "40×10 × 3세트"
  Widget _buildCompactSetDisplay({
    required String weight,
    required String reps,
    required int setCount,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          weight,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F2937),
            fontFeatures: [FontFeature.tabularFigures()],
            letterSpacing: -0.5,
          ),
        ),
        Text(
          '×',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.neutral500,
          ),
        ),
        Text(
          reps,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF374151),
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.neutral200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '×$setCount',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral600,
            ),
          ),
        ),
      ],
    );
  }

  /// Build progressive/varied display: "30×12 → 35×10 → 40×8"
  Widget _buildProgressiveSetDisplay(
    List<ExerciseSetEntity> sets, {
    required bool isProgressive,
  }) {
    final separator = isProgressive ? ' → ' : ', ';

    // Limit display to 3 sets max for space
    final displaySets = sets.take(3).toList();
    final hasMore = sets.length > 3;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                for (int i = 0; i < displaySets.length; i++) ...[
                  if (i > 0)
                    TextSpan(
                      text: separator,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isProgressive
                            ? const Color(0xFF10B981)
                            : AppColors.neutral400,
                      ),
                    ),
                  TextSpan(
                    text: _formatWeight(displaySets[i].weight),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2937),
                      fontFeatures: [FontFeature.tabularFigures()],
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextSpan(
                    text: '×',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutral400,
                    ),
                  ),
                  TextSpan(
                    text: '${displaySets[i].reps ?? 0}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                if (hasMore)
                  TextSpan(
                    text: ' +${sets.length - 3}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral500,
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// Format weight value (removes .0 for whole numbers)
  String _formatWeight(double? weight) {
    if (weight == null) return '0';
    if (weight == weight.roundToDouble()) {
      return weight.toInt().toString();
    }
    return weight.toStringAsFixed(1);
  }

  /// Extract free-form memo from exercise notes JSON
  String? _extractExerciseMemo(SessionExerciseEntity exercise) {
    if (exercise.notes == null || exercise.notes!.isEmpty) return null;
    try {
      final json = jsonDecode(exercise.notes!);
      if (json is Map) return json['trainerMemo'] as String?;
    } catch (_) {}
    return null;
  }

  /// Extract SetComment enums from exercise notes JSON using database keys
  List<SetComment> _extractExerciseComments(SessionExerciseEntity exercise) {
    if (exercise.notes == null || exercise.notes!.isEmpty) return [];

    try {
      final json = jsonDecode(exercise.notes!);
      if (json is Map) {
        final trainerComments = json['trainerComments'] as List?;
        if (trainerComments != null) {
          return trainerComments
              .map((c) => SetCommentExtension.fromDatabaseKey(
                  c['key'] as String? ?? ''))
              .whereType<SetComment>()
              .toList();
        }
      }
    } catch (_) {
      // Not valid JSON – no comments to extract
    }
    return [];
  }

  /// Build a small colored chip for a single SetComment
  Widget _buildCommentChip(SetComment comment) {
    final Color chipColor;
    switch (comment.category) {
      case SetCommentCategory.mistake:
        chipColor = AppColors.warning;
      case SetCommentCategory.coachingCue:
        chipColor = AppColors.primary;
      case SetCommentCategory.condition:
        chipColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        comment.shortDisplayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: chipColor.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(sessionDate).inDays;

    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];

    if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '어제';
    } else if (difference < 7) {
      return '$difference일 전 ($weekday)';
    } else {
      return '${date.month}/${date.day} ($weekday)';
    }
  }

  String _getFocusAreaKorean(String? focusArea) {
    if (focusArea == null || focusArea.isEmpty) return '운동';
    switch (focusArea.toLowerCase()) {
      case 'chest':
        return '가슴';
      case 'push':
        return '푸시';
      case 'back':
        return '등';
      case 'pull':
        return '풀';
      case 'legs':
      case 'lower':
        return '하체';
      case 'shoulders':
        return '어깨';
      case 'arms':
        return '팔';
      case 'full_body':
        return '전신';
      case 'upper':
        return '상체';
      case 'core':
        return '코어';
      default:
        return focusArea;
    }
  }

  Color _getFocusAreaColor(String? focusArea) {
    if (focusArea == null || focusArea.isEmpty) return AppColors.primary;
    switch (focusArea.toLowerCase()) {
      case 'chest':
      case 'push':
        return const Color(0xFFE53935);
      case 'back':
      case 'pull':
        return const Color(0xFF1E88E5);
      case 'legs':
      case 'lower':
        return const Color(0xFF43A047);
      case 'shoulders':
        return const Color(0xFFFF9800);
      case 'arms':
        return const Color(0xFF8E24AA);
      case 'full_body':
        return const Color(0xFF00ACC1);
      case 'upper':
        return const Color(0xFFD81B60);
      case 'core':
        return const Color(0xFF6D4C41);
      default:
        return AppColors.primary;
    }
  }

  IconData _getFocusIcon(String? focusArea) {
    if (focusArea == null || focusArea.isEmpty) return Icons.fitness_center;
    switch (focusArea.toLowerCase()) {
      case 'chest':
      case 'push':
      case 'upper':
        return Icons.fitness_center;
      case 'back':
      case 'pull':
        return Icons.fitness_center;
      case 'legs':
      case 'lower':
        return Icons.directions_run;
      case 'full_body':
        return Icons.accessibility_new;
      case 'core':
        return Icons.swap_vert;
      default:
        return Icons.fitness_center;
    }
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}t';
    }
    return '${volume.toStringAsFixed(0)}kg';
  }
}

/// Stat chip with icon, value, and label - bold numbers, no gradient
class _IntenseStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isWide;

  const _IntenseStatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1.0,
                  letterSpacing: -0.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.7),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
