import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/workout_program.dart';
import '../../../active_session/data/models/session_exercise_input.dart';
import '../../../active_session/presentation/providers/session_provider.dart';
import '../widgets/exercise_detail_sheet.dart';

/// Screen for reviewing AI-generated exercises before starting a session
class AIExerciseReviewScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final String? programId;
  final String? sessionId; // Session already created by edge function
  final List<GeneratedProgramExercise> exercises;
  final String? sessionDescription;

  const AIExerciseReviewScreen({
    required this.clientId,
    required this.clientName,
    this.programId,
    this.sessionId,
    required this.exercises,
    this.sessionDescription,
    super.key,
  });

  @override
  ConsumerState<AIExerciseReviewScreen> createState() =>
      _AIExerciseReviewScreenState();
}

class _AIExerciseReviewScreenState
    extends ConsumerState<AIExerciseReviewScreen> {
  bool _isStarting = false;
  late List<GeneratedProgramExercise> _exercises;

  @override
  void initState() {
    super.initState();
    // Create mutable copy of exercises
    _exercises = List.from(widget.exercises);
  }

  void _handleExerciseSwap(int index, GeneratedProgramExercise newExercise) {
    setState(() {
      _exercises[index] = newExercise;
    });
    debugPrint('🟢 [AI_REVIEW] Swapped exercise at index $index to ${newExercise.name}');
  }

  void _showExerciseDetail(int index) {
    ExerciseDetailSheet.show(
      context: context,
      exercise: _exercises[index],
      onSwap: (newExercise) => _handleExerciseSwap(index, newExercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('AI 추천 운동'),
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
                  // Header
                  _SessionHeader(
                    clientName: widget.clientName,
                    exerciseCount: _exercises.length,
                    sessionDescription: widget.sessionDescription,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Exercises section
                  _SectionCard(
                    title: 'AI 추천 운동 목록',
                    icon: Icons.auto_awesome,
                    subtitle: '운동을 탭하여 상세 정보 및 대체 운동을 확인하세요',
                    child: Column(
                      children: [
                        ..._exercises.asMap().entries.map((entry) {
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
                              onTap: () => _showExerciseDetail(index),
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
      final sessionNotifier = ref.read(activeSessionProvider.notifier);

      // Convert exercises using unified SessionExerciseInput.fromAI factory
      final exercises = _exercises.asMap().entries
          .map((entry) => SessionExerciseInput.fromAI(entry.value, entry.key))
          .toList();

      debugPrint('🟢 [AI_REVIEW] SessionExerciseInput prepared: ${exercises.length} exercises');

      // Use unified createSession method
      final result = await sessionNotifier.createSession(
        clientId: widget.clientId,
        exercises: exercises,
        existingSessionId: widget.sessionId,
        programId: widget.programId,
        aiReasoning: widget.sessionDescription,
      );

      result.fold(
        (failure) {
          debugPrint('🔴 [AI_REVIEW] Session creation failed: ${failure.message}');
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
          debugPrint('🟢 [AI_REVIEW] Session created: ${session.id} with ${session.exercises.length} exercises');
          if (mounted) {
            // Navigate to active session screen
            context.go(
              '/trainer/session/${widget.clientId}?name=${Uri.encodeComponent(widget.clientName)}',
            );
          }
        },
      );
    } catch (e) {
      debugPrint('🔴 [AI_REVIEW] Error: $e');
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
  final String clientName;
  final int exerciseCount;
  final String? sessionDescription;

  const _SessionHeader({
    required this.clientName,
    required this.exerciseCount,
    this.sessionDescription,
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
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            clientName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '오늘의 맞춤 운동',
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
                label: '$exerciseCount개 운동',
              ),
            ],
          ),
          // Session description (AI reasoning)
          if (sessionDescription != null && sessionDescription!.isNotEmpty) ...[
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
                      sessionDescription!,
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
  final IconData icon;
  final Widget child;
  final String? subtitle;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
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
  final GeneratedProgramExercise exercise;
  final int index;
  final VoidCallback? onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            exercise.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutralBlack,
                            ),
                          ),
                        ),
                        // Tap indicator
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppColors.neutral400,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.targetSets}세트 × ${exercise.targetReps}회 | 휴식 ${exercise.restSeconds}초',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral600,
                      ),
                    ),
                    // AI reasoning
                    if (exercise.aiReasoningKo != null &&
                        exercise.aiReasoningKo!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 14,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                exercise.aiReasoningKo!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.info,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
