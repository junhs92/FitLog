import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/exercise_picker_dialog.dart';
import '../../../active_session/data/models/session_exercise_input.dart';
import '../../../active_session/presentation/providers/session_provider.dart';
import '../../../active_session/domain/entities/exercise_entity.dart';
import '../../domain/entities/template_exercise_entity.dart';
import '../../domain/entities/workout_template_entity.dart';
import '../providers/workout_template_provider.dart';

/// Wrapper class to track editable exercise state
class _EditableExercise {
  final String exerciseId;
  final String exerciseName;
  final TemplateExerciseEntity original;
  final ExerciseEntity? newExercise;
  final bool isChanged;

  _EditableExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.original,
    this.newExercise,
    this.isChanged = false,
  });

  _EditableExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    TemplateExerciseEntity? original,
    ExerciseEntity? newExercise,
    bool? isChanged,
  }) {
    return _EditableExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      original: original ?? this.original,
      newExercise: newExercise ?? this.newExercise,
      isChanged: isChanged ?? this.isChanged,
    );
  }
}

/// Screen for reviewing exercises from a template before starting a new session
class TemplateReviewScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final WorkoutTemplateEntity template;

  const TemplateReviewScreen({
    required this.clientId,
    required this.clientName,
    required this.template,
    super.key,
  });

  @override
  ConsumerState<TemplateReviewScreen> createState() =>
      _TemplateReviewScreenState();
}

class _TemplateReviewScreenState extends ConsumerState<TemplateReviewScreen> {
  bool _isStarting = false;
  List<_EditableExercise> _exercises = [];
  bool _initialized = false;

  void _initExercisesIfNeeded() {
    if (!_initialized) {
      _exercises = widget.template.exercises.map((e) => _EditableExercise(
        exerciseId: e.exerciseId,
        exerciseName: e.exercise?.displayName ?? 'Unknown Exercise',
        original: e,
      )).toList();
      _initialized = true;
    }
  }

  Future<void> _changeExercise(int index) async {
    final newExercise = await ExercisePickerDialog.show(context: context);
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

  @override
  Widget build(BuildContext context) {
    _initExercisesIfNeeded();
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('템플릿으로 시작'),
        backgroundColor: AppColors.surfaceLight,
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
                  // Template header
                  _TemplateHeader(
                    template: widget.template,
                    clientName: widget.clientName,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Exercises section
                  _SectionCard(
                    title: '운동 목록',
                    subtitle: '운동을 탭하여 변경할 수 있습니다',
                    icon: Icons.fitness_center,
                    child: Column(
                      children: [
                        ..._exercises
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final exercise = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < _exercises.length - 1
                                  ? AppSpacing.sm
                                  : 0,
                            ),
                            child: _ExerciseCard(
                              exercise: exercise,
                              index: index + 1,
                              onTap: () => _changeExercise(index),
                            ),
                          );
                        }),
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
              color: AppColors.surfaceLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
      // Convert editable exercises to SessionExerciseInput
      final exercises = _exercises.asMap().entries.map((entry) {
        final index = entry.key;
        final e = entry.value;

        // Use new exercise data if changed, otherwise use original template data
        if (e.isChanged && e.newExercise != null) {
          return SessionExerciseInput(
            exerciseId: e.newExercise!.id,
            name: e.newExercise!.displayName,
            orderIndex: index,
            targetSets: e.original.targetSets,
            targetReps: e.original.targetReps,
            targetWeight: e.original.targetWeight,
            targetRpe: e.original.targetRpe,
            restSeconds: e.original.restSeconds,
          );
        } else {
          return SessionExerciseInput(
            exerciseId: e.original.exerciseId,
            name: e.original.exercise?.displayName ?? 'Unknown Exercise',
            orderIndex: index,
            targetSets: e.original.targetSets,
            targetReps: e.original.targetReps,
            targetWeight: e.original.targetWeight,
            targetRpe: e.original.targetRpe,
            restSeconds: e.original.restSeconds,
          );
        }
      }).toList();

      debugPrint(
          '🟢 [TEMPLATE_REVIEW] SessionExerciseInput prepared: ${exercises.length} exercises');

      // Use unified createSession method
      final sessionNotifier = ref.read(activeSessionProvider.notifier);
      final templateMutationNotifier = ref.read(templateMutationProvider.notifier);

      final result = await sessionNotifier.createSession(
        clientId: widget.clientId,
        exercises: exercises,
      );

      // Increment template usage
      await templateMutationNotifier.incrementUsage(widget.template.id);

      result.fold(
        (failure) {
          debugPrint(
              '🔴 [TEMPLATE_REVIEW] Session creation failed: ${failure.message}');
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
          debugPrint(
              '🟢 [TEMPLATE_REVIEW] Session created: ${session.id} with ${session.exercises.length} exercises');
          if (mounted) {
            // Navigate to active session screen
            context.go(
              '/trainer/session/${widget.clientId}?name=${Uri.encodeComponent(widget.clientName)}',
            );
          }
        },
      );
    } catch (e) {
      debugPrint('🔴 [TEMPLATE_REVIEW] Error: $e');
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

class _TemplateHeader extends StatelessWidget {
  final WorkoutTemplateEntity template;
  final String clientName;

  const _TemplateHeader({
    required this.template,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      '템플릿',
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
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            template.displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralBlack,
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
                label: '${template.exercises.length}개 운동',
              ),
              if (template.estimatedDurationMinutes != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _InfoChip(
                  icon: Icons.timer,
                  label: '${template.estimatedDurationMinutes}분',
                ),
              ],
              if (template.focusArea != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _InfoChip(
                  icon: Icons.track_changes,
                  label: template.focusArea!,
                ),
              ],
            ],
          ),
          // Template description
          if (template.description != null &&
              template.description!.isNotEmpty) ...[
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
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      template.description!,
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
        color: AppColors.neutral100,
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
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutralBlack,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.neutral500,
              ),
            ),
          ],
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

  const _ExerciseCard({
    required this.exercise,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: exercise.isChanged
              ? AppColors.success.withValues(alpha: 0.05)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: exercise.isChanged
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.neutral200,
          ),
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: exercise.isChanged
                                ? AppColors.success
                                : AppColors.neutralBlack,
                          ),
                        ),
                      ),
                      if (exercise.isChanged)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '수정됨',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
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
            // Chevron for visual consistency
            Icon(
              Icons.swap_horiz,
              size: 20,
              color: exercise.isChanged
                  ? AppColors.success
                  : AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  String _buildSetRepsInfo() {
    final parts = <String>[];

    // Sets
    final sets = exercise.original.targetSets ?? 3;
    parts.add('${sets}세트');

    // Reps
    if (exercise.original.targetReps != null) {
      parts.add('× ${exercise.original.targetReps}회');
    }

    // Weight
    if (exercise.original.targetWeight != null) {
      parts.add('× ${exercise.original.targetWeight!.toStringAsFixed(1)}kg');
    }

    // Rest
    final rest = exercise.original.restSeconds ?? 90;
    parts.add('| 휴식 ${rest}초');

    return parts.join(' ');
  }
}
