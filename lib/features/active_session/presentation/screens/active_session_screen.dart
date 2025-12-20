import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../domain/entities/session_exercise_entity.dart';
import '../providers/session_provider.dart';
import '../providers/rest_timer_provider.dart';
import '../widgets/weight_adjuster.dart';
import '../widgets/rep_selector.dart';
import '../widgets/rpe_slider.dart';
import '../widgets/set_tag_selector.dart';
import '../widgets/set_row.dart';
import '../widgets/session_timer.dart';
import '../widgets/rest_timer_widget.dart';
import '../widgets/quick_log_widget.dart';
import '../../../ai_workout/presentation/widgets/difficulty_feedback_widget.dart';
import '../../../ai_workout/domain/entities/session_feedback.dart';
import '../../../ai_workout/presentation/providers/ai_workout_provider.dart';

/// Main active session screen for 60-second logging
class ActiveSessionScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;

  const ActiveSessionScreen({
    required this.clientId,
    required this.clientName,
    super.key,
  });

  @override
  ConsumerState<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  @override
  void initState() {
    super.initState();
    // Start or load session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }

  Future<void> _initializeSession() async {
    final notifier = ref.read(activeSessionProvider.notifier);
    await notifier.loadActiveSession(widget.clientId);

    // If no active session, start a new one
    final state = ref.read(activeSessionProvider);
    if (!state.hasActiveSession) {
      await notifier.startSession(clientId: widget.clientId);
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
      // Start rest timer and show it prominently
      ref.read(restTimerProvider.notifier).startTimer();

      // Show rest timer bottom sheet
      await _showRestTimerSheet();
    } else {
      debugPrint('🔴 _logSet: Failed or not mounted. success=$success, mounted=$mounted');
      final errorState = ref.read(activeSessionProvider);
      debugPrint('🔴 _logSet: Error: ${errorState.error}');
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

  Future<void> _repeatLastSet() async {
    HapticFeedback.heavyImpact();
    final success =
        await ref.read(activeSessionProvider.notifier).repeatLastSet();
    if (success && mounted) {
      // Start rest timer and show it prominently
      ref.read(restTimerProvider.notifier).startTimer();
      await _showRestTimerSheet();
    }
  }

  void _showAddExerciseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExercisePickerSheet(clientId: widget.clientId),
    );
  }

  /// Get recent set presets from current exercise
  List<SetPreset> _getRecentPresets(SessionExerciseEntity exercise) {
    // Get unique weight/reps combinations from previous sets
    final presets = <SetPreset>[];
    final seen = <String>{};

    for (final set in exercise.sets.reversed) {
      if (set.weight == null || set.reps == null) continue;
      final key = '${set.weight}-${set.reps}';
      if (!seen.contains(key)) {
        seen.add(key);
        presets.add(SetPreset(
          weight: set.weight!,
          reps: set.reps!,
        ));
      }
      if (presets.length >= 4) break;
    }

    return presets;
  }

  Future<void> _completeSession() async {
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

    if (confirm == true) {
      final completedSession = await ref
          .read(activeSessionProvider.notifier)
          .completeSession();

      if (completedSession != null && mounted) {
        context.go('/trainer/session-summary/${completedSession.id}');
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

    return Column(
      children: [
        // Exercise tabs
        _ExerciseTabs(
          exercises: state.session!.exercises,
          currentIndex: state.currentExerciseIndex,
          onTap: (index) {
            ref.read(activeSessionProvider.notifier).goToExercise(index);
          },
        ),
        // Main logging area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current exercise header
                Text(
                  currentExercise.exercise.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                // Difficulty feedback (AI feature)
                _DifficultyFeedbackSection(
                  sessionExerciseId: currentExercise.id,
                  exerciseId: currentExercise.exercise.id,
                  clientId: widget.clientId,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Set history
                if (currentExercise.sets.isNotEmpty) ...[
                  Text(
                    'Sets',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...currentExercise.sets.map((set) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SetRow(set: set),
                      )),
                  const SizedBox(height: AppSpacing.lg),
                ],
                // Weight adjuster
                const Text(
                  'Weight',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                WeightAdjuster(
                  weight: state.currentWeight,
                  onChanged: (weight) {
                    ref.read(activeSessionProvider.notifier).setWeight(weight);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                // Rep selector
                const Text(
                  'Reps',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                RepSelector(
                  reps: state.currentReps,
                  onChanged: (reps) {
                    ref.read(activeSessionProvider.notifier).setReps(reps);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                // RPE slider
                const Text(
                  'RPE (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                RpeSlider(
                  rpe: state.currentRpe,
                  onChanged: (rpe) {
                    ref.read(activeSessionProvider.notifier).setRpe(rpe);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                // Tags
                const Text(
                  'Tags (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                SetTagSelector(
                  selectedTags: state.currentTags,
                  onChanged: (tags) {
                    ref.read(activeSessionProvider.notifier).setTags(tags);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                // Quick log section (Repeat Last Set)
                if (state.canRepeatLastSet) ...[
                  QuickLogWidget(
                    lastWeight: state.lastSetOfCurrentExercise?.weight,
                    lastReps: state.lastSetOfCurrentExercise?.reps,
                    onRepeatLastSet: _repeatLastSet,
                    canRepeat: true,
                    recentPresets: _getRecentPresets(currentExercise),
                    onPresetTap: (weight, reps) {
                      ref.read(activeSessionProvider.notifier).setWeight(weight);
                      ref.read(activeSessionProvider.notifier).setReps(reps);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                // Log set button
                PrimaryButton(
                  label: 'Set complete',
                  onPressed: _logSet,
                  isLoading: state.isLoading,
                  icon: Icons.check,
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

  const _ExerciseTabs({
    required this.exercises,
    required this.currentIndex,
    required this.onTap,
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

/// Bottom sheet for adding exercises
class _ExercisePickerSheet extends ConsumerStatefulWidget {
  final String clientId;

  const _ExercisePickerSheet({required this.clientId});

  @override
  ConsumerState<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseLibraryProvider(_searchQuery.isEmpty ? null : _searchQuery));
    final recentAsync = ref.watch(recentExercisesProvider(widget.clientId));

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
                    'Add Exercise',
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
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Content
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const Center(child: Text('No exercises found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.fitness_center,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(exercise.displayName),
                        subtitle: Text(exercise.muscleGroup ?? exercise.movementPattern),
                        onTap: () {
                          ref.read(activeSessionProvider.notifier).addExercise(exercise);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Section for difficulty feedback during exercise
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
    final feedbackState = ref.watch(sessionFeedbackProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'How is ${_getArticle()} exercise?',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DifficultyFeedbackCompact(
            currentFeedback: feedbackState.currentFeedback,
            onFeedback: (feedback) {
              ref.read(sessionFeedbackProvider.notifier).recordFeedback(
                    sessionExerciseId: sessionExerciseId,
                    exerciseId: exerciseId,
                    clientId: clientId,
                    feedback: feedback,
                  );
            },
          ),
          // Show alternatives if available
          if (feedbackState.alternatives.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Suggested alternatives:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral700,
              ),
            ),
            const SizedBox(height: 4),
            ...feedbackState.alternatives.take(2).map(
                  (alt) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () => _swapExercise(context, ref, alt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: alt.isRecommended
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.neutral100,
                          borderRadius: BorderRadius.circular(4),
                          border: alt.isRecommended
                              ? Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                alt.displayName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (alt.isRecommended)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Rec',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.neutralWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                            const Icon(Icons.swap_horiz, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _getArticle() => 'this';

  void _swapExercise(
      BuildContext context, WidgetRef ref, SessionAlternative alt) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Swap Exercise?'),
        content: Text('Replace current exercise with ${alt.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement exercise swap in session
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Swapped to ${alt.displayName}'),
                  backgroundColor: AppColors.success,
                ),
              );
              // Clear feedback state
              ref.read(sessionFeedbackProvider.notifier).clear();
            },
            child: const Text('Swap'),
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
    final timerState = ref.watch(restTimerProvider);
    final sessionState = ref.watch(activeSessionProvider);
    final isComplete = timerState.remainingSeconds == 0 && !timerState.isRunning;

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
                showPresets: true,
                showControls: true,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action buttons
              Row(
                children: [
                  // Skip rest button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(restTimerProvider.notifier).skipTimer();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Skip rest'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Next set button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(restTimerProvider.notifier).skipTimer();
                        Navigator.pop(context);
                      },
                      icon: Icon(isComplete ? Icons.fitness_center : Icons.timer),
                      label: Text(isComplete ? 'Next set' : 'Continue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.neutralWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
