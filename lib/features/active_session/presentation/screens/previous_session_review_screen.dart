import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/exercise_picker_dialog.dart';
import '../../data/models/session_exercise_input.dart';
import '../providers/exercise_picker_provider.dart';
import '../../domain/entities/exercise_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/session_exercise_entity.dart';
import '../providers/session_provider.dart';

/// Editable exercise wrapper for review screen
class _EditableExercise {
  final String exerciseId;
  final String exerciseName;
  final SessionExerciseEntity? original; // Null for newly added exercises
  final ExerciseEntity? newExercise; // Non-null if changed or newly added
  final bool isChanged;
  final bool isNew; // True for exercises added via "운동 추가"

  _EditableExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.original,
    this.newExercise,
    this.isChanged = false,
    this.isNew = false,
  });

  _EditableExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    ExerciseEntity? newExercise,
    bool? isChanged,
    bool? isNew,
  }) {
    return _EditableExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      original: original,
      newExercise: newExercise ?? this.newExercise,
      isChanged: isChanged ?? this.isChanged,
      isNew: isNew ?? this.isNew,
    );
  }
}

/// Screen for reviewing exercises from a previous session before starting a new session
class PreviousSessionReviewScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final SessionEntity previousSession;

  const PreviousSessionReviewScreen({
    required this.clientId,
    required this.clientName,
    required this.previousSession,
    super.key,
  });

  @override
  ConsumerState<PreviousSessionReviewScreen> createState() =>
      _PreviousSessionReviewScreenState();
}

class _PreviousSessionReviewScreenState
    extends ConsumerState<PreviousSessionReviewScreen> {
  bool _isStarting = false;
  List<_EditableExercise> _exercises = [];
  bool _initialized = false;

  void _initExercisesIfNeeded() {
    if (!_initialized) {
      _exercises = widget.previousSession.exercises.map((e) => _EditableExercise(
        exerciseId: e.exercise.id,
        exerciseName: e.exercise.displayName,
        original: e,
      )).toList();
      _initialized = true;
    }
  }

  Future<void> _changeExercise(int index) async {
    final newExercise = await ExercisePickerDialog.show(
      context: context,
      clientId: widget.clientId,
    );
    if (newExercise != null && mounted) {
      setState(() {
        _exercises[index] = _exercises[index].copyWith(
          exerciseId: newExercise.id,
          exerciseName: newExercise.displayName,
          newExercise: newExercise,
          isChanged: true,
        );
      });
    }
  }

  Future<void> _addExercise() async {
    ref.read(exercisePickerProvider.notifier).reset();
    final exercise = await ExercisePickerDialog.show(
      context: context,
      clientId: widget.clientId,
      ref: ref,
    );
    if (exercise != null && mounted) {
      setState(() {
        _exercises.add(_EditableExercise(
          exerciseId: exercise.id,
          exerciseName: exercise.displayName,
          newExercise: exercise,
          isNew: true,
        ));
      });
    }
  }

  void _removeExercise(int index) {
    if (_exercises.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1개의 운동이 필요합니다'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() {
      _exercises.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    _initExercisesIfNeeded();
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('이전 운동 복사'),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Session header
                  _SessionHeader(
                    session: widget.previousSession,
                    clientName: widget.clientName,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Exercises section
                  _SectionCard(
                    title: '운동 목록',
                    subtitle: '운동을 탭하여 변경하거나 추가/삭제할 수 있습니다',
                    icon: Icons.fitness_center,
                    child: Column(
                      children: [
                        ..._exercises.asMap().entries.map((entry) {
                          final index = entry.key;
                          final exercise = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _ExerciseCard(
                              exercise: exercise,
                              index: index + 1,
                              onTap: () => _changeExercise(index),
                              onRemove: () => _removeExercise(index),
                            ),
                          );
                        }),
                        // Add exercise button
                        OutlinedButton.icon(
                          onPressed: _addExercise,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('운동 추가'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: const Size(double.infinity, 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom button
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.015),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isStarting ? null : _startSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  icon: _isStarting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    _isStarting
                        ? '세션 시작 중...'
                        : '세션 시작 (${_exercises.length}개 운동)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession() async {
    setState(() => _isStarting = true);

    try {
      // Convert exercises using the editable list
      final exercises = _exercises.asMap().entries.map((entry) {
        final index = entry.key;
        final editable = entry.value;

        if (editable.isNew) {
          // Newly added exercise — use defaults
          return SessionExerciseInput(
            exerciseId: editable.newExercise!.id,
            name: editable.newExercise!.displayName,
            orderIndex: index,
            targetSets: 3,
            targetReps: '10',
            restSeconds: 90,
          );
        } else if (editable.isChanged && editable.newExercise != null) {
          // Swapped exercise — keep original set/rep info
          return SessionExerciseInput(
            exerciseId: editable.newExercise!.id,
            name: editable.newExercise!.displayName,
            orderIndex: index,
            targetSets: editable.original!.targetSets ?? 3,
            targetReps: editable.original!.recommendedReps.toString(),
            restSeconds: editable.original!.restSeconds ?? 90,
          );
        } else {
          // Use original exercise with historical data
          return SessionExerciseInput.fromPrevious(editable.original!, index);
        }
      }).toList();

      debugPrint('🟢 [REVIEW] SessionExerciseInput prepared: ${exercises.length} exercises');

      // Use unified createSession method
      final sessionNotifier = ref.read(activeSessionProvider.notifier);
      final result = await sessionNotifier.createSession(
        clientId: widget.clientId,
        exercises: exercises,
      );

      result.fold(
        (failure) {
          debugPrint('🔴 [REVIEW] Session creation failed: ${failure.message}');
          if (mounted) {
            setState(() => _isStarting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('세션 생성 실패: ${failure.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        (session) {
          debugPrint('🟢 [REVIEW] Session created: ${session.id} with ${session.exercises.length} exercises');
          if (mounted) {
            // Navigate to active session screen
            context.go(
              '/trainer/session/${widget.clientId}?name=${Uri.encodeComponent(widget.clientName)}',
            );
          }
        },
      );
    } catch (e) {
      debugPrint('🔴 [REVIEW] Error: $e');
      if (mounted) {
        setState(() => _isStarting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _SessionHeader extends StatelessWidget {
  final SessionEntity session;
  final String clientName;

  const _SessionHeader({
    required this.session,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 14, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      '이전 운동',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              // Show AI badge if session has AI reasoning
              if (session.aiReasoning != null && session.aiReasoning!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'AI 생성',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            Formatters.displayDate(session.completedAt ?? session.createdAt),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            clientName,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _InfoChip(
                icon: Icons.fitness_center,
                label: '${session.exercises.length}개 운동',
              ),
              if (session.duration != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _InfoChip(
                  icon: Icons.timer,
                  label: Formatters.duration(session.duration!),
                ),
              ],
            ],
          ),
          // Session AI description
          if (session.aiReasoning != null && session.aiReasoning!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _extractSessionDescription(session.aiReasoning!),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.info,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.neutral600),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final _EditableExercise exercise;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ExerciseCard({
    required this.exercise,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = exercise.isNew
        ? AppColors.success.withValues(alpha: 0.3)
        : exercise.isChanged
            ? AppColors.primary.withValues(alpha: 0.3)
            : AppColors.darkBorder;
    final bgColor = exercise.isNew
        ? AppColors.success.withValues(alpha: 0.05)
        : exercise.isChanged
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.darkSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Order number
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Exercise details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.exerciseName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                      ),
                      if (exercise.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '추가됨',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else if (exercise.isChanged)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '수정됨',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildSetRepsInfo(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Remove button
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 18,
              color: AppColors.error,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: '삭제',
            ),
            // Edit indicator
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  String _buildSetRepsInfo() {
    if (exercise.original == null) {
      return '3세트 × 10회 | 휴식 90초';
    }
    final original = exercise.original!;
    // Get working sets (exclude warmup)
    final workingSets = original.sets.where((s) => !s.isWarmup).toList();

    if (workingSets.isEmpty) {
      // No working sets - show target info if available
      final targetSets = original.targetSets ?? 3;
      final targetReps = original.recommendedReps;
      return '${targetSets}세트 × ${targetReps}회 | 휴식 ${original.restSeconds ?? 90}초';
    }

    // Get average weight and reps from working sets
    final setsWithWeight = workingSets.where((s) => s.weight != null).toList();
    final setsWithReps = workingSets.where((s) => s.reps != null).toList();

    String weightStr = '';
    if (setsWithWeight.isNotEmpty) {
      final avgWeight = setsWithWeight.map((s) => s.weight!).fold(0.0, (a, b) => a + b) / setsWithWeight.length;
      weightStr = ' × ${avgWeight.toStringAsFixed(1)}kg';
    }

    String repsStr = '';
    if (setsWithReps.isNotEmpty) {
      final avgReps = setsWithReps.map((s) => s.reps!).fold(0, (a, b) => a + b) ~/ setsWithReps.length;
      repsStr = ' × ${avgReps}회';
    }

    return '${workingSets.length}세트$repsStr$weightStr | 휴식 ${original.restSeconds ?? 90}초';
  }
}

/// Extract sessionDescription from ai_reasoning JSON string
/// Falls back to raw string if JSON parsing fails
String _extractSessionDescription(String aiReasoning) {
  try {
    final json = jsonDecode(aiReasoning) as Map<String, dynamic>;
    return json['sessionDescription'] as String? ?? aiReasoning;
  } catch (e) {
    // Fallback to raw string if not valid JSON
    return aiReasoning;
  }
}
