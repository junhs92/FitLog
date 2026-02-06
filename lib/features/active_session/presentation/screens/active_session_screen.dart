import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/common/exercise_video_popup.dart';
import '../../domain/entities/session_exercise_entity.dart';
import '../../domain/entities/exercise_set_entity.dart';
import '../../domain/entities/exercise_entity.dart';
import '../../domain/services/exercise_recommendation_service.dart';
import '../providers/session_provider.dart';
import '../providers/rest_timer_provider.dart';
import '../widgets/weight_adjuster.dart';
import '../widgets/rep_selector.dart';
import '../widgets/rpe_slider.dart';
import '../widgets/set_comment_selector.dart';
import '../widgets/exercise_history_display.dart';
import '../../domain/entities/set_comment.dart';
import '../widgets/session_timer.dart';
import '../widgets/rest_timer_widget.dart';
import '../widgets/countdown_timer.dart';
import '../../../ai_workout/presentation/widgets/difficulty_feedback_widget.dart';
import '../../../ai_workout/domain/entities/session_feedback.dart';
import '../../../ai_workout/presentation/providers/ai_workout_provider.dart';
import '../../../muscle_map/domain/entities/muscle_group.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../widgets/schedule_completion_dialog.dart';

/// Main active session screen for 60-second logging
class ActiveSessionScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final String? programId;

  const ActiveSessionScreen({
    required this.clientId,
    required this.clientName,
    this.programId,
    super.key,
  });

  @override
  ConsumerState<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Start or load session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }

  Future<void> _initializeSession() async {
    debugPrint('🟢 [SESSION_SCREEN] _initializeSession: Starting...');
    debugPrint('🟢 [SESSION_SCREEN] clientId: ${widget.clientId}, programId: ${widget.programId}');

    final notifier = ref.read(activeSessionProvider.notifier);

    // If programId is provided, ALWAYS start a new session with the program exercises
    // This ensures we use the AI-generated exercises from the program
    if (widget.programId != null) {
      debugPrint('🟢 [SESSION_SCREEN] ProgramId provided, starting NEW session with exercises');

      // Get exercises from the program creation provider (held in memory)
      final programState = ref.read(programCreationProvider);
      final generatedExercises = programState.program?.generatedExercises ?? [];

      debugPrint('🟢 [SESSION_SCREEN] Found ${generatedExercises.length} exercises in provider state');

      // Convert to list of maps for session creation
      final exerciseMaps = generatedExercises.map((e) => {
        'exercise_id': e.exerciseId,
        'name': e.name,
        'target_sets': e.targetSets,
        'target_reps': e.targetReps,
        'rest_seconds': e.restSeconds,
      }).toList();

      await notifier.startSession(
        clientId: widget.clientId,
        programId: widget.programId,
        exercises: exerciseMaps,
      );
      debugPrint('🟢 [SESSION_SCREEN] Session with program exercises started');
      return;
    }

    // No programId - try to load existing active session
    await notifier.loadActiveSession(widget.clientId);

    // If no active session, start a new empty one
    final state = ref.read(activeSessionProvider);
    if (!state.hasActiveSession) {
      debugPrint('🟢 [SESSION_SCREEN] No active session, starting new empty session');
      await notifier.startSession(clientId: widget.clientId);
      debugPrint('🟢 [SESSION_SCREEN] Empty session started');
    } else {
      debugPrint('🟢 [SESSION_SCREEN] Active session found: ${state.session?.id}');
    }
  }

  Future<void> _logSet() async {
    debugPrint('🔵 _logSet: Starting...');
    HapticFeedback.mediumImpact();

    final state = ref.read(activeSessionProvider);
    debugPrint('🔵 _logSet: Current exercise: ${state.currentExercise?.exercise.name}');
    debugPrint('🔵 _logSet: Weight: ${state.currentWeight}, Reps: ${state.currentReps}');

    final success = await ref.read(activeSessionProvider.notifier).logSet();
    debugPrint('🔵 _logSet: Success = $success');

    if (success && mounted) {
      debugPrint('🔵 _logSet: Starting rest timer and showing sheet...');

      // Scroll to top of the page
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      // Start rest timer: use user-selected duration if set, else exercise default
      final timerState = ref.read(restTimerProvider);
      final restSeconds = timerState.totalSeconds > 0
          ? timerState.totalSeconds
          : (state.currentExercise?.restSeconds ?? 90);
      ref.read(restTimerProvider.notifier).startTimer(seconds: restSeconds);
    } else if (mounted) {
      debugPrint('🔴 _logSet: Failed or not mounted. success=$success, mounted=$mounted');
      final errorState = ref.read(activeSessionProvider);
      debugPrint('🔴 _logSet: Error: ${errorState.error}');

      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorState.error ?? 'Failed to log set. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showRestTimerSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _RestTimerOverlay(),
    );
  }

  void _showAddExerciseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExercisePickerSheet(clientId: widget.clientId),
    );
  }

  Future<void> _completeSession() async {
    debugPrint('🔵 _completeSession: Starting...');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Session?'),
        content: const Text('Are you sure you want to finish this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    debugPrint('🔵 _completeSession: confirm = $confirm');

    if (confirm == true && mounted) {
      debugPrint('🔵 _completeSession: Calling completeSession on provider...');

      final completedSession = await ref
          .read(activeSessionProvider.notifier)
          .completeSession();

      debugPrint('🔵 _completeSession: completedSession = ${completedSession?.id}');

      if (completedSession != null && mounted) {
        debugPrint('🔵 _completeSession: Session completed successfully');

        // Handle schedule completion (auto-complete existing or prompt to create)
        await _handleScheduleCompletion(
          clientId: widget.clientId,
          sessionStartTime: completedSession.startedAt,
        );

        // Provider handles program focus update automatically
        // Invalidate recent sessions cache
        ref.invalidate(clientRecentSessionsProvider(widget.clientId));

        if (mounted) {
          context.go('/trainer/session-summary/${completedSession.id}');
        }
      } else if (mounted) {
        // Show error if session completion failed
        final errorState = ref.read(activeSessionProvider);
        debugPrint('🔴 _completeSession: Failed - ${errorState.error}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorState.error ?? 'Failed to complete session. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Handle schedule completion when a session is completed
  /// - If a matching schedule exists, auto-complete it
  /// - If no matching schedule, prompt user to add to calendar
  Future<void> _handleScheduleCompletion({
    required String clientId,
    required DateTime? sessionStartTime,
  }) async {
    if (sessionStartTime == null) {
      debugPrint('🔵 _handleScheduleCompletion: No session start time, skipping');
      return;
    }

    final repository = ref.read(scheduleRepositoryProvider);
    if (repository == null) {
      debugPrint('🔵 _handleScheduleCompletion: No repository available, skipping');
      return;
    }

    debugPrint('🔵 _handleScheduleCompletion: Looking for matching schedule...');

    // Try to find a matching schedule
    final findResult = await repository.findScheduleForSession(
      clientId: clientId,
      sessionStartTime: sessionStartTime,
      toleranceMinutes: 30,
    );

    final existingSchedule = findResult.fold((_) => null, (schedule) => schedule);

    if (existingSchedule != null) {
      // Auto-complete the existing schedule
      debugPrint('🔵 _handleScheduleCompletion: Found schedule ${existingSchedule.id}, marking as completed');
      await repository.markAsCompleted(existingSchedule.id);

      // Invalidate calendar cache to reflect the change
      ref.invalidate(schedulesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule marked as completed'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // No matching schedule found - ask user if they want to create one
      debugPrint('🔵 _handleScheduleCompletion: No matching schedule, showing dialog');

      if (!mounted) return;

      final result = await ScheduleCompletionDialog.show(
        context,
        sessionStartTime: sessionStartTime,
        clientName: widget.clientName,
      );

      if (result != null && mounted) {
        debugPrint('🔵 _handleScheduleCompletion: User chose to add schedule');

        final createResult = await repository.createCompletedSchedule(
          clientId: clientId,
          scheduledAt: result.scheduledAt,
          durationMinutes: result.durationMinutes,
        );

        createResult.fold(
          (failure) {
            debugPrint('🔴 _handleScheduleCompletion: Failed to create schedule - ${failure.message}');
          },
          (schedule) {
            debugPrint('🔵 _handleScheduleCompletion: Schedule created ${schedule.id}');
            // Invalidate calendar cache
            ref.invalidate(schedulesProvider);
          },
        );
      } else {
        debugPrint('🔵 _handleScheduleCompletion: User skipped adding schedule');
      }
    }
  }

  Future<void> _showCancelConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('세션 취소'),
        content: const Text('이 세션을 취소하시겠습니까?\n모든 기록이 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속하기'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('세션 취소'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success =
          await ref.read(activeSessionProvider.notifier).cancelSession();
      if (success && mounted) {
        context.go('/trainer');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeSessionProvider);

    if (state.isLoading && state.session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${state.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeSession,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _showCancelConfirmation,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.clientName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (state.session?.startedAt != null)
              SessionTimerCompact(startTime: state.session!.startedAt!),
          ],
        ),
        actions: [
          // Rest Timer in app bar (compact mode)
          RestTimerCompact(
            onTap: () => RestTimerBottomSheet.show(context),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _completeSession,
            child: const Text('Finish'),
          ),
        ],
      ),
      body: state.session?.exercises.isEmpty ?? true
          ? _buildEmptyState()
          : _buildSessionContent(state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExerciseSheet,
        icon: const Icon(Icons.add),
        label: const Text('Exercise'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: AppColors.neutral500,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No exercises yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add an exercise to start logging',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionContent(ActiveSessionState state) {
    final currentExercise = state.currentExercise;
    if (currentExercise == null) return _buildEmptyState();

    // Global completed sets: sum of all sets across ALL exercises in session
    final allExercises = state.session!.exercises;
    final completedSets = allExercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.sets.length,
    );
    // Global target sets: sum of all target sets (null if any exercise has no target)
    final hasAllTargets = allExercises.every((e) => e.targetSets != null);
    final targetSets = hasAllTargets
        ? allExercises.fold<int>(0, (sum, e) => sum + (e.targetSets ?? 0))
        : null;

    return Column(
      children: [
        // Exercise tabs
        _ExerciseTabs(
          exercises: state.session!.exercises,
          currentIndex: state.currentExerciseIndex,
          onTap: (index) {
            ref.read(activeSessionProvider.notifier).goToExercise(index);
          },
          exerciseComments: state.exerciseComments,
          currentComments: state.currentComments,
        ),
        // Main logging area
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Session sets history (all exercises, in order)
                _SessionSetsHistory(
                  exercises: state.session!.exercises,
                ),
                // Sets completed indicator (above exercise name)
                _SetsCompletedHeader(
                  completedSets: completedSets,
                  targetSets: targetSets,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Current exercise header with watch video button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        currentExercise.exercise.displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutralBlack,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (currentExercise.exercise.hasMedia)
                      IconButton(
                        onPressed: () => ExerciseVideoPopup.show(
                          context,
                          exercise: currentExercise.exercise,
                        ),
                        icon: const Icon(
                          Icons.play_circle_outline,
                          color: AppColors.primary,
                        ),
                        iconSize: 28,
                        tooltip: '운동 영상 보기',
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Inline rest timer (below exercise name)
                _InlineRestTimer(
                  onEditTap: () => RestTimerBottomSheet.show(context),
                ),
                const SizedBox(height: AppSpacing.md),
                // Two-column layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT Column (60%) - Comment-related
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Difficulty feedback (AI feature)
                          _DifficultyFeedbackSection(
                            sessionExerciseId: currentExercise.id,
                            exerciseId: currentExercise.exercise.id,
                            clientId: widget.clientId,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Exercise history (PR and last session)
                          ExerciseHistoryDisplay(
                            pr: state.exercisePR,
                            lastSessionSets: state.lastSessionSets,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Rest duration selector
                          _RestDurationSelector(),
                          const SizedBox(height: AppSpacing.md),
                          // Comments (coaching cues)
                          SetCommentSelector(
                            selectedComments: state.currentComments,
                            commentDetails: state.currentCommentDetails,
                            onChanged: (comments) {
                              ref
                                  .read(activeSessionProvider.notifier)
                                  .setComments(comments);
                            },
                            onDetailsChanged: (details) {
                              ref
                                  .read(activeSessionProvider.notifier)
                                  .setCommentDetails(details);
                            },
                            movementGroup:
                                currentExercise.exercise.movementGroup,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // RIGHT Column (40%) - Record-related
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Reps/Timer toggle
                          _RepsTimerToggle(
                            isTimerMode: state.isTimerMode,
                            onToggle: () => ref
                                .read(activeSessionProvider.notifier)
                                .toggleTimerMode(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Conditional: Timer mode or Reps mode
                          if (state.isTimerMode) ...[
                            // Timer mode: CountdownTimer + RPE
                            CountdownTimer(
                              duration: state.currentDuration,
                              remaining: state.countdownRemaining,
                              isRunning: state.isCountdownRunning,
                              onStart: () => ref
                                  .read(activeSessionProvider.notifier)
                                  .startCountdown(),
                              onPause: () => ref
                                  .read(activeSessionProvider.notifier)
                                  .pauseCountdown(),
                              onReset: () => ref
                                  .read(activeSessionProvider.notifier)
                                  .resetCountdown(),
                              onDurationChanged: (duration) => ref
                                  .read(activeSessionProvider.notifier)
                                  .setDuration(duration),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // RPE slider for timer mode
                            const Text(
                              'RPE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            RpeSlider(
                              rpe: state.currentRpe,
                              onChanged: (rpe) {
                                ref
                                    .read(activeSessionProvider.notifier)
                                    .setRpe(rpe);
                              },
                              compact: true,
                            ),
                          ] else ...[
                            // Reps mode: Weight + Reps + RPE
                            // Weight adjuster
                            _WeightLabel(
                              isBodyweight: currentExercise.exercise.isBodyweight,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Opacity(
                              opacity: currentExercise.exercise.isBodyweight
                                  ? 0.6
                                  : 1.0,
                              child: WeightAdjuster(
                                weight: state.currentWeight,
                                onChanged: (weight) {
                                  ref
                                      .read(activeSessionProvider.notifier)
                                      .setWeight(weight);
                                },
                                compact: true,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Rep selector
                            const Text(
                              'Reps',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            RepSelector(
                              reps: state.currentReps,
                              onChanged: (reps) {
                                ref
                                    .read(activeSessionProvider.notifier)
                                    .setReps(reps);
                              },
                              compact: true,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // RPE slider
                            const Text(
                              'RPE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            RpeSlider(
                              rpe: state.currentRpe,
                              onChanged: (rpe) {
                                ref
                                    .read(activeSessionProvider.notifier)
                                    .setRpe(rpe);
                              },
                              compact: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Log set button or Skip rest button
                _SetCompleteOrSkipButton(
                  isLoading: state.isLoading,
                  onSetComplete: _logSet,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Horizontal scrolling exercise tabs
class _ExerciseTabs extends StatelessWidget {
  final List<SessionExerciseEntity> exercises;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Map<String, List<SetComment>> exerciseComments;
  final List<SetComment> currentComments;

  const _ExerciseTabs({
    required this.exercises,
    required this.currentIndex,
    required this.onTap,
    required this.exerciseComments,
    required this.currentComments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          bottom: BorderSide(color: AppColors.neutral300),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          final isSelected = index == currentIndex;
          final isCompleted = exercise.isCompleted;
          // Check if this exercise has comments
          final hasComments = index == currentIndex
              ? currentComments.isNotEmpty
              : (exerciseComments[exercise.id]?.isNotEmpty ?? false);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Material(
              color: isSelected
                  ? AppColors.primary
                  : isCompleted
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCompleted)
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: isSelected
                              ? AppColors.neutralWhite
                              : AppColors.success,
                        ),
                      if (isCompleted) const SizedBox(width: 4),
                      Text(
                        exercise.exercise.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.neutralWhite
                              : AppColors.neutralBlack,
                        ),
                      ),
                      // Comment indicator
                      if (hasComments) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.comment,
                          size: 14,
                          color: isSelected
                              ? AppColors.neutralWhite
                              : AppColors.primary,
                        ),
                      ],
                    ],
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

/// Bottom sheet for adding exercises - grouped by movement pattern with smart recommendations
class _ExercisePickerSheet extends ConsumerStatefulWidget {
  final String clientId;

  const _ExercisePickerSheet({required this.clientId});

  @override
  ConsumerState<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  String _searchQuery = '';
  MuscleGroup? _selectedMuscleGroup;
  bool _isRecommendationsExpanded = false;  // Toggle for expand/collapse recommendations

  /// Get Korean display name for movement group
  String _getGroupDisplayName(String group) {
    return MovementGroup.getDisplayNameKo(group);
  }

  /// Group exercises by movement group
  Map<String, List<ExerciseEntity>> _groupByMovementGroup(List<ExerciseEntity> exercises) {
    final grouped = <String, List<ExerciseEntity>>{};
    for (final exercise in exercises) {
      final group = exercise.movementGroup;
      grouped.putIfAbsent(group, () => []).add(exercise);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseLibraryProvider(_searchQuery.isEmpty ? null : _searchQuery));
    final recommendationsAsync = ref.watch(exerciseRecommendationsProvider(widget.clientId));
    final sessionState = ref.watch(activeSessionProvider);
    final currentExercise = sessionState.currentExercise;
    final currentGroup = currentExercise?.exercise.movementGroup;

    // Get exercise IDs already in session to exclude them from the picker
    final exerciseIdsInSession = sessionState.session?.exercises
        .map((e) => e.exercise.id)
        .toSet() ?? <String>{};

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '운동 추가',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: '운동 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Muscle group navigation chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                // "All" chip
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: const Text('전체'),
                    selected: _selectedMuscleGroup == null,
                    onSelected: (_) => setState(() => _selectedMuscleGroup = null),
                    backgroundColor: AppColors.neutral100,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _selectedMuscleGroup == null ? FontWeight.w600 : FontWeight.w400,
                      color: _selectedMuscleGroup == null ? AppColors.primary : AppColors.neutral700,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    showCheckmark: false,
                  ),
                ),
                // Muscle group chips (주요 그룹만 표시)
                ...[
                  MuscleGroup.chest,
                  MuscleGroup.back,
                  MuscleGroup.shoulders,
                  MuscleGroup.biceps,
                  MuscleGroup.triceps,
                  MuscleGroup.quadriceps,
                  MuscleGroup.hamstrings,
                  MuscleGroup.glutes,
                  MuscleGroup.core,
                ].map((group) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(group.displayNameKo),
                    selected: _selectedMuscleGroup == group,
                    onSelected: (_) => setState(() {
                      _selectedMuscleGroup = _selectedMuscleGroup == group ? null : group;
                    }),
                    backgroundColor: AppColors.neutral100,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _selectedMuscleGroup == group ? FontWeight.w600 : FontWeight.w400,
                      color: _selectedMuscleGroup == group ? AppColors.primary : AppColors.neutral700,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    showCheckmark: false,
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Content - Grouped by movement pattern with recommendations
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (allExercises) {
                if (allExercises.isEmpty) {
                  return const Center(child: Text('운동을 찾을 수 없습니다'));
                }

                // Apply muscle group filter
                var exercises = _selectedMuscleGroup == null
                    ? allExercises
                    : allExercises.where((e) {
                        final muscleGroupStr = e.muscleGroup?.toLowerCase();
                        if (muscleGroupStr == null) return false;
                        return muscleGroupStr == _selectedMuscleGroup!.key ||
                               muscleGroupStr == _selectedMuscleGroup!.name;
                      }).toList();

                // Filter out exercises already in session
                exercises = exercises.where((e) => !exerciseIdsInSession.contains(e.id)).toList();

                if (exercises.isEmpty) {
                  // Show appropriate empty state based on filter
                  final emptyMessage = _selectedMuscleGroup != null
                      ? '${_selectedMuscleGroup!.displayNameKo} 운동이 없습니다'
                      : '추가할 수 있는 운동이 없습니다';

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppColors.neutral400),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          emptyMessage,
                          style: const TextStyle(color: AppColors.neutral500),
                        ),
                        if (_selectedMuscleGroup != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: () => setState(() => _selectedMuscleGroup = null),
                            child: const Text('전체 보기'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // Get recommendations data and filter out exercises already in session
                final recommendationsState = recommendationsAsync.valueOrNull;
                final recommendations = (recommendationsState?.recommendations ?? [])
                    .where((r) => !exerciseIdsInSession.contains(r.exercise.id))
                    .toList();
                final recommendedGroupOrder = recommendationsState?.recommendedGroupOrder ?? MovementGroup.all;

                // Group exercises by movement group
                final grouped = _groupByMovementGroup(exercises);

                // Build sorted groups list (simple: just use recommended order)
                final sortedGroups = _searchQuery.isNotEmpty
                    ? MovementGroup.all
                    : recommendedGroupOrder;

                // Build list with section headers
                final items = <Widget>[];

                // Add contextual recommendations section (only when not searching and no filter)
                if (_searchQuery.isEmpty && _selectedMuscleGroup == null) {
                  // Get contextual recommendations from new provider
                  final contextualRecs = ref.watch(contextualRecommendationsProvider(widget.clientId));

                  if (contextualRecs.hasComplementary || contextualRecs.hasSupplementary) {
                    // Show new 2-section panel (complementary + supplementary)
                    items.add(_buildContextualRecommendationPanel(contextualRecs));
                  } else if (recommendations.isNotEmpty) {
                    // Fallback to existing recommendations for empty sessions
                    items.add(_buildRecommendedSection(recommendations));
                  } else {
                    // Empty state message
                    items.add(_buildEmptyRecommendationState());
                  }
                }

                // Add group-based exercises
                for (final group in sortedGroups) {
                  final groupExercises = grouped[group];
                  if (groupExercises == null || groupExercises.isEmpty) continue;

                  // Check if this group is recommended (top 3)
                  final groupIndex = recommendedGroupOrder.indexOf(group);
                  final isRecommendedGroup = groupIndex >= 0 && groupIndex < 3;

                  // Section header
                  items.add(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: group == currentGroup
                                  ? AppColors.primary
                                  : isRecommendedGroup
                                      ? AppColors.success.withValues(alpha: 0.15)
                                      : AppColors.neutral200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getGroupDisplayName(group),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: group == currentGroup
                                    ? AppColors.neutralWhite
                                    : isRecommendedGroup
                                        ? AppColors.success
                                        : AppColors.neutral700,
                              ),
                            ),
                          ),
                          if (group == currentGroup) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '현재',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else if (isRecommendedGroup && _searchQuery.isEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.thumb_up, size: 10, color: AppColors.success),
                                  SizedBox(width: 3),
                                  Text(
                                    '추천',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            '${groupExercises.length}개',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  // Exercises in this group
                  for (final exercise in groupExercises) {
                    // Check if this exercise is in recommendations
                    final recommendation = recommendations.firstWhere(
                      (r) => r.exercise.id == exercise.id,
                      orElse: () => RecommendedExercise(exercise: exercise, score: 0),
                    );
                    final isRecommended = recommendation.score > 0 && recommendation.reason.isNotEmpty;

                    items.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 2,
                        ),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isRecommended
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.fitness_center,
                              color: isRecommended ? AppColors.success : AppColors.primary,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            exercise.displayName,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            exercise.muscleGroup ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            ref.read(activeSessionProvider.notifier).addExercise(exercise);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  }
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  children: items,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build the recommended exercises section
  Widget _buildRecommendedSection(List<RecommendedExercise> recommendations) {
    // Take top 5 recommendations with reasons
    final topRecommendations = recommendations
        .where((r) => r.reason.isNotEmpty)
        .take(5)
        .toList();

    if (topRecommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.success.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: AppColors.neutralWhite),
                    SizedBox(width: 4),
                    Text(
                      '맞춤 추천',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralWhite,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${topRecommendations.length}개',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
        // Recommended exercises
        ...topRecommendations.map((rec) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 2,
          ),
          child: Material(
            color: AppColors.success.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.success.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              title: Text(
                rec.exercise.displayName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Row(
                children: [
                  Text(
                    rec.exercise.muscleGroup ?? '',
                    style: const TextStyle(fontSize: 11),
                  ),
                  if (rec.reason.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rec.reason,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: const Icon(
                Icons.add_circle,
                color: AppColors.success,
                size: 22,
              ),
              onTap: () {
                ref.read(activeSessionProvider.notifier).addExercise(rec.exercise);
                Navigator.pop(context);
              },
            ),
          ),
        )),
        const Divider(height: 24),
      ],
    );
  }

  /// Build recommended section with same-group exercises (legacy - for fallback)
  Widget _buildSameGroupRecommendedSection(
    List<ExerciseEntity> exercises,
    String group,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header (기존 "맞춤 추천" 스타일 유지)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.success.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: AppColors.neutralWhite),
                    SizedBox(width: 4),
                    Text(
                      '맞춤 추천',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralWhite,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 그룹 배지 추가
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getGroupDisplayName(group),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${exercises.length}개',
                style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
              ),
            ],
          ),
        ),
        // Exercise list (기존 스타일 유지)
        ...exercises.map((exercise) {
          // Determine if this is an isolation exercise based on category
          final isIsolation = exercise.category == 'isolation';
          final tagText = isIsolation ? '고립 운동' : '같은 그룹';

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 2,
            ),
            child: Material(
              color: AppColors.success.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.success.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.success,
                    size: 18,
                  ),
                ),
                title: Text(
                  exercise.displayName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Row(
                  children: [
                    Text(
                      exercise.muscleGroup ?? '',
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tagText,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(
                  Icons.add_circle,
                  color: AppColors.success,
                  size: 22,
                ),
                onTap: () {
                  ref.read(activeSessionProvider.notifier).addExercise(exercise);
                  Navigator.pop(context);
                },
              ),
            ),
          );
        }),
        const Divider(height: 24),
      ],
    );
  }

  /// Build contextual recommendation panel with 2 sections (complementary + supplementary)
  Widget _buildContextualRecommendationPanel(ContextualRecommendationsState state) {
    // Apply display limit based on expanded state
    final displayLimit = _isRecommendationsExpanded ? 10 : 3;
    final complementaryToShow = state.complementary.take(displayLimit).toList();
    final supplementaryToShow = state.supplementary.take(displayLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: Complementary (바로 이어서 하기)
        if (state.hasComplementary) ...[
          _buildRecommendationSection(
            title: '바로 이어서 하기',
            subtitle: '현재 운동과 연계',
            recommendations: complementaryToShow,
            color: AppColors.primary,
            icon: Icons.arrow_forward,
            totalCount: state.complementary.length,
            isExpanded: _isRecommendationsExpanded,
            onToggle: () => setState(() => _isRecommendationsExpanded = !_isRecommendationsExpanded),
          ),
        ],

        // Section 2: Supplementary (보조)
        if (state.hasSupplementary) ...[
          _buildRecommendationSection(
            title: '보조',
            subtitle: '마무리 운동',
            recommendations: supplementaryToShow,
            color: AppColors.success,
            icon: Icons.fitness_center,
            totalCount: state.supplementary.length,
            isExpanded: _isRecommendationsExpanded,
            onToggle: () => setState(() => _isRecommendationsExpanded = !_isRecommendationsExpanded),
          ),
        ],

        const Divider(height: 16),
      ],
    );
  }

  /// Build a single recommendation section
  Widget _buildRecommendationSection({
    required String title,
    required String subtitle,
    required List<LabeledRecommendation> recommendations,
    required Color color,
    required IconData icon,
    required int totalCount,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final hasMore = totalCount > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: AppColors.neutralWhite),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralWhite,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${recommendations.length}${hasMore ? '/$totalCount' : ''}개',
                style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
              ),
              if (hasMore) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isExpanded ? '접기' : '더보기',
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 14,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Recommendation cards
        ...recommendations.map((rec) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 2,
          ),
          child: Material(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: ListTile(
              dense: true,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: color,
                  size: 18,
                ),
              ),
              title: Text(
                rec.exercise.displayName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Row(
                children: [
                  Text(
                    rec.exercise.muscleGroup ?? '',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      rec.labelText,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                Icons.add_circle,
                color: color,
                size: 22,
              ),
              onTap: () {
                ref.read(activeSessionProvider.notifier).addExercise(rec.exercise);
                Navigator.pop(context);
              },
            ),
          ),
        )),
      ],
    );
  }

  /// Build empty recommendation state message
  Widget _buildEmptyRecommendationState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.neutral500,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '운동을 먼저 추가해주세요',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section for alternative exercise button during exercise
class _DifficultyFeedbackSection extends ConsumerWidget {
  final String sessionExerciseId;
  final String exerciseId;
  final String clientId;

  const _DifficultyFeedbackSection({
    required this.sessionExerciseId,
    required this.exerciseId,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlternativeExerciseButton(
      exerciseId: exerciseId,
      onAlternativeSelected: (alt) => _swapExercise(context, ref, alt),
    );
  }

  void _swapExercise(
      BuildContext context, WidgetRef ref, SessionAlternative alt) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('대체 운동으로 변경'),
        content: Text('${alt.displayName}(으)로 변경하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // Perform the swap
              final success = await ref
                  .read(activeSessionProvider.notifier)
                  .swapExercise(newExerciseId: alt.exerciseId);

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${alt.displayName}(으)로 변경되었습니다'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('운동 변경에 실패했습니다'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }
}

/// Rest timer overlay shown after completing a set
class _RestTimerOverlay extends ConsumerWidget {
  const _RestTimerOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(activeSessionProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Success message
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Set ${sessionState.currentSetNumber - 1} complete!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Rest Timer
              const RestTimerWidget(
                showControls: true,
                showPresets: true,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(restTimerProvider.notifier).skipTimer();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Continue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.neutralWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class for a set with its exercise name
class _SessionSetWithExercise {
  final String exerciseName;
  final ExerciseSetEntity set;

  const _SessionSetWithExercise({
    required this.exerciseName,
    required this.set,
  });
}

/// Unified session sets history showing all sets in chronological order
class _SessionSetsHistory extends StatelessWidget {
  final List<SessionExerciseEntity> exercises;

  const _SessionSetsHistory({required this.exercises});

  List<_SessionSetWithExercise> _getAllSetsInOrder() {
    final allSets = <_SessionSetWithExercise>[];

    for (final exercise in exercises) {
      for (final set in exercise.sets) {
        allSets.add(_SessionSetWithExercise(
          exerciseName: exercise.exercise.displayName,
          set: set,
        ));
      }
    }

    // Sort by completedAt timestamp
    allSets.sort((a, b) => a.set.completedAt.compareTo(b.set.completedAt));

    return allSets;
  }

  @override
  Widget build(BuildContext context) {
    final allSets = _getAllSetsInOrder();

    if (allSets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.history,
              size: 16,
              color: AppColors.neutral700,
            ),
            const SizedBox(width: 4),
            Text(
              'Session History',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral700,
              ),
            ),
            const Spacer(),
            Text(
              '${allSets.length} sets',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '#',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Exercise',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Weight',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        'Reps',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 45,
                      child: Text(
                        'RPE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // Set rows
              ...allSets.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == allSets.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: AppColors.neutral200,
                              width: 0.5,
                            ),
                          ),
                  ),
                  child: Row(
                    children: [
                      // Set number
                      SizedBox(
                        width: 28,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: item.set.isWarmup
                                ? AppColors.info.withOpacity(0.1)
                                : item.set.isPR
                                    ? AppColors.warning.withOpacity(0.2)
                                    : AppColors.neutral100,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            item.set.isWarmup ? 'W' : '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.set.isWarmup
                                  ? AppColors.info
                                  : item.set.isPR
                                      ? AppColors.warning
                                      : AppColors.neutral700,
                            ),
                          ),
                        ),
                      ),
                      // Exercise name
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.exerciseName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.neutralBlack,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.set.isPR) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PR',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.neutralWhite,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Weight
                      SizedBox(
                        width: 60,
                        child: Text(
                          item.set.weight != null
                              ? '${item.set.weight!.toStringAsFixed(item.set.weight! % 1 == 0 ? 0 : 1)}'
                              : '-',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutralBlack,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Reps
                      SizedBox(
                        width: 50,
                        child: Text(
                          item.set.reps?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutralBlack,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // RPE
                      SizedBox(
                        width: 45,
                        child: Text(
                          item.set.rpeDisplay,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _getRpeColor(item.set.rpe),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Color _getRpeColor(double? rpe) {
    if (rpe == null) return AppColors.neutral500;
    if (rpe <= 6) return AppColors.success;
    if (rpe <= 7) return AppColors.secondary;
    if (rpe <= 8) return AppColors.warning;
    return AppColors.error;
  }
}

/// Sets completed header widget
class _SetsCompletedHeader extends StatelessWidget {
  final int completedSets;
  final int? targetSets;

  const _SetsCompletedHeader({
    required this.completedSets,
    this.targetSets,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              targetSets != null
                  ? '완료: $completedSets / $targetSets 세트'
                  : '완료: $completedSets 세트',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline rest timer widget shown below exercise title
class _InlineRestTimer extends ConsumerWidget {
  final VoidCallback onEditTap;

  const _InlineRestTimer({required this.onEditTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);

    // Only show when timer is running or paused
    if (!timerState.isRunning && !timerState.isPaused) {
      return const SizedBox.shrink();
    }

    final isWarning = timerState.remainingSeconds <= 10;
    final isComplete = timerState.remainingSeconds == 0 && !timerState.isRunning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.success.withOpacity(0.1)
            : isWarning
                ? AppColors.warning.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? AppColors.success.withOpacity(0.3)
              : isWarning
                  ? AppColors.warning.withOpacity(0.3)
                  : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer icon with progress
          SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: timerState.progress,
                  strokeWidth: 3,
                  backgroundColor: AppColors.neutral200,
                  valueColor: AlwaysStoppedAnimation(
                    isComplete
                        ? AppColors.success
                        : isWarning
                            ? AppColors.warning
                            : AppColors.primary,
                  ),
                ),
                Icon(
                  isComplete ? Icons.check : Icons.timer,
                  size: 12,
                  color: isComplete
                      ? AppColors.success
                      : isWarning
                          ? AppColors.warning
                          : AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Timer text
          Text(
            isComplete ? 'REST DONE' : 'Rest: ${timerState.formattedTime}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isComplete
                  ? AppColors.success
                  : isWarning
                      ? AppColors.warning
                      : AppColors.primary,
            ),
          ),
          const Spacer(),
          // Pause/Resume button
          if (!isComplete)
            IconButton(
              onPressed: () {
                if (timerState.isRunning) {
                  ref.read(restTimerProvider.notifier).pauseTimer();
                } else {
                  ref.read(restTimerProvider.notifier).resumeTimer();
                }
              },
              icon: Icon(
                timerState.isRunning ? Icons.pause : Icons.play_arrow,
                color: isWarning ? AppColors.warning : AppColors.primary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: isWarning
                    ? AppColors.warning.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.2),
                minimumSize: const Size(36, 36),
              ),
            ),
          const SizedBox(width: 4),
          // Skip button
          if (!isComplete)
            IconButton(
              onPressed: () {
                ref.read(restTimerProvider.notifier).skipTimer();
              },
              icon: const Icon(Icons.skip_next),
              tooltip: '건너뛰기',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.neutral200,
                minimumSize: const Size(36, 36),
              ),
            ),
          const SizedBox(width: 4),
          // Edit button
          TextButton(
            onPressed: onEditTap,
            style: TextButton.styleFrom(
              foregroundColor: isComplete
                  ? AppColors.success
                  : isWarning
                      ? AppColors.warning
                      : AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

/// Goal sets indicator widget
class _GoalSetsIndicator extends StatelessWidget {
  final int targetSets;

  const _GoalSetsIndicator({required this.targetSets});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.flag_outlined,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '목표: $targetSets세트',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rest duration selector widget
class _RestDurationSelector extends ConsumerWidget {
  const _RestDurationSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);
    final currentDuration = timerState.totalSeconds;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: AppColors.neutral700,
              ),
              SizedBox(width: 6),
              Text(
                'Rest Duration',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [60, 90, 120, 180].map((seconds) {
              final isSelected = currentDuration == seconds;
              final label = seconds >= 60
                  ? '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
                  : '${seconds}s';

              return GestureDetector(
                onTap: () {
                  ref.read(restTimerProvider.notifier).setDefaultDuration(seconds);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.neutralWhite
                          : AppColors.neutral700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Button that shows "Set complete" or "Skip rest" depending on rest timer state
class _SetCompleteOrSkipButton extends ConsumerWidget {
  final bool isLoading;
  final VoidCallback onSetComplete;

  const _SetCompleteOrSkipButton({
    required this.isLoading,
    required this.onSetComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);
    final isRestTimerRunning = timerState.isRunning || timerState.isPaused;

    if (isRestTimerRunning) {
      return PrimaryButton(
        label: 'Skip rest (${timerState.formattedTime})',
        onPressed: () {
          ref.read(restTimerProvider.notifier).skipTimer();
        },
        icon: Icons.skip_next,
        backgroundColor: AppColors.neutral600,
      );
    }

    return PrimaryButton(
      label: 'Set complete',
      onPressed: onSetComplete,
      isLoading: isLoading,
      icon: Icons.check,
    );
  }
}

/// Toggle switch between Reps mode and Timer mode
class _RepsTimerToggle extends StatelessWidget {
  final bool isTimerMode;
  final VoidCallback onToggle;

  const _RepsTimerToggle({
    required this.isTimerMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Reps',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isTimerMode ? FontWeight.normal : FontWeight.bold,
              color: isTimerMode ? AppColors.neutral500 : AppColors.neutral800,
            ),
          ),
          Switch(
            value: isTimerMode,
            onChanged: (_) => onToggle(),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Icon(
            Icons.timer,
            size: 14,
            color: isTimerMode ? AppColors.neutral800 : AppColors.neutral500,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Timer',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isTimerMode ? FontWeight.bold : FontWeight.normal,
              color: isTimerMode ? AppColors.neutral800 : AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Weight label that shows "(optional)" for bodyweight exercises
class _WeightLabel extends StatelessWidget {
  final bool isBodyweight;

  const _WeightLabel({
    required this.isBodyweight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Weight',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral700,
          ),
        ),
        if (isBodyweight) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '(optional)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.normal,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ],
    );
  }
}
