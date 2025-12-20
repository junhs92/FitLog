import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../active_session/presentation/providers/session_provider.dart';
import '../../domain/entities/workout_program.dart';
import '../providers/ai_workout_provider.dart';
import '../widgets/exercise_swap_sheet.dart';
import '../widgets/ai_reasoning_card.dart';

/// Screen for reviewing and customizing AI-generated workout programs
class ProgramReviewScreen extends ConsumerStatefulWidget {
  final String programId;
  final String clientId;

  const ProgramReviewScreen({
    required this.programId,
    required this.clientId,
    super.key,
  });

  @override
  ConsumerState<ProgramReviewScreen> createState() => _ProgramReviewScreenState();
}

class _ProgramReviewScreenState extends ConsumerState<ProgramReviewScreen> {
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load program
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(programGenerationProvider.notifier).loadProgram(widget.programId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(programGenerationProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('프로그램 검토'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.program != null &&
              state.program!.status == ProgramStatus.draft)
            TextButton(
              onPressed: _activateProgram,
              child: const Text(
                '적용',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!))
              : state.program == null
                  ? const Center(child: Text('프로그램을 불러올 수 없습니다'))
                  : _buildContent(state.program!),
    );
  }

  Widget _buildContent(WorkoutProgramEntity program) {
    return Column(
      children: [
        // Program header
        _ProgramHeader(program: program),
        // Day tabs
        _DayTabs(
          days: program.workoutDays,
          selectedIndex: _selectedDayIndex,
          onDaySelected: (index) {
            setState(() {
              _selectedDayIndex = index;
            });
          },
        ),
        // Exercise list
        Expanded(
          child: _ExerciseList(
            day: program.workoutDays[_selectedDayIndex],
            clientId: widget.clientId,
            goal: program.primaryGoal,
            onSwap: _handleExerciseSwap,
          ),
        ),
      ],
    );
  }

  void _handleExerciseSwap(
    String programExerciseId,
    String newExerciseId,
    String? reason,
  ) {
    ref.read(programGenerationProvider.notifier).swapExercise(
          programExerciseId: programExerciseId,
          newExerciseId: newExerciseId,
          reason: reason,
        );
  }

  void _activateProgram() {
    final program = ref.read(programGenerationProvider).program;
    if (program == null || program.workoutDays.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('세션 시작'),
        content: const Text('이 프로그램으로 트레이닝 세션을 시작하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _startSessionWithProgram(program);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('세션 시작'),
          ),
        ],
      ),
    );
  }

  Future<void> _startSessionWithProgram(WorkoutProgramEntity program) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Use the first workout day for the session
      final workoutDay = program.workoutDays.first;

      // Start session with program exercises
      final session = await ref
          .read(activeSessionProvider.notifier)
          .startSessionWithProgram(
            clientId: widget.clientId,
            programId: program.id,
            workoutDayId: workoutDay.id,
          );

      // Update program status to active
      await ref
          .read(programGenerationProvider.notifier)
          .updateStatus(ProgramStatus.active);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (session != null && mounted) {
        // Navigate to active session screen
        // Pop the review screen and go to session
        context.go('/trainer/session/${widget.clientId}?name=${Uri.encodeComponent(program.name)}');
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('세션 시작 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _ProgramHeader extends StatelessWidget {
  final WorkoutProgramEntity program;

  const _ProgramHeader({required this.program});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (program.isAiGenerated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.psychology,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      const Text(
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
              _StatusBadge(status: program.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            program.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralBlack,
            ),
          ),
          if (program.description != null) ...[
            const SizedBox(height: 4),
            Text(
              program.description!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _InfoChip(
                icon: Icons.flag,
                label: program.primaryGoal.displayName,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.calendar_today,
                label: '${program.durationWeeks}주',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.fitness_center,
                label: '주 ${program.sessionsPerWeek}회',
              ),
              if (program.isCustomized) ...[
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.edit,
                  label: '${program.customizationCount}회 수정',
                  color: AppColors.warning,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ProgramStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ProgramStatus.draft:
        color = AppColors.neutral500;
        break;
      case ProgramStatus.active:
        color = AppColors.success;
        break;
      case ProgramStatus.completed:
        color = AppColors.primary;
        break;
      case ProgramStatus.archived:
        color = AppColors.neutral400;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.neutral700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTabs extends StatelessWidget {
  final List<WorkoutDayEntity> days;
  final int selectedIndex;
  final Function(int) onDaySelected;

  const _DayTabs({
    required this.days,
    required this.selectedIndex,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: AppColors.surfaceElevated,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onDaySelected(index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Day ${days[index].dayNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.neutralWhite : AppColors.neutral700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExerciseList extends StatelessWidget {
  final WorkoutDayEntity day;
  final String clientId;
  final TrainingGoal goal;
  final Function(String, String, String?) onSwap;

  const _ExerciseList({
    required this.day,
    required this.clientId,
    required this.goal,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: day.exercises.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
                if (day.focusArea != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '집중 부위: ${day.focusArea}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral700,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '예상 시간: ${day.estimatedDurationMinutes}분 · ${day.exercises.length}개 운동',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          );
        }

        final exercise = day.exercises[index - 1];
        return _ExerciseCard(
          exercise: exercise,
          index: index,
          clientId: clientId,
          goal: goal,
          onSwap: onSwap,
        );
      },
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ProgramExerciseEntity exercise;
  final int index;
  final String clientId;
  final TrainingGoal goal;
  final Function(String, String, String?) onSwap;

  const _ExerciseCard({
    required this.exercise,
    required this.index,
    required this.clientId,
    required this.goal,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: () => _showSwapSheet(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Order number
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
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
                    // Exercise name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                exercise.displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neutralBlack,
                                ),
                              ),
                              if (exercise.isSwapped) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '변경됨',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${exercise.targetSets}세트 × ${exercise.targetReps}회 · 휴식 ${exercise.restSeconds}초',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.neutral700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Swap icon
                    IconButton(
                      icon: const Icon(
                        Icons.swap_horiz,
                        color: AppColors.neutral400,
                      ),
                      onPressed: () => _showSwapSheet(context),
                    ),
                  ],
                ),
                // AI Reasoning (compact)
                if (exercise.aiReasoning != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AIReasoningCompact(reasoning: exercise.aiReasoning!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSwapSheet(BuildContext context) {
    ExerciseSwapSheet.show(
      context: context,
      exercise: exercise,
      clientId: clientId,
      goal: goal,
      onSwap: (newExerciseId, reason) {
        onSwap(exercise.id, newExerciseId, reason);
      },
    );
  }
}
