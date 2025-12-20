import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/workout_program.dart';
import '../providers/ai_workout_provider.dart';

/// Screen for generating new AI workout programs
class GenerateProgramScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String trainerId;
  final String clientName;

  const GenerateProgramScreen({
    required this.clientId,
    required this.trainerId,
    required this.clientName,
    super.key,
  });

  @override
  ConsumerState<GenerateProgramScreen> createState() =>
      _GenerateProgramScreenState();
}

class _GenerateProgramScreenState extends ConsumerState<GenerateProgramScreen> {
  TrainingGoal _primaryGoal = TrainingGoal.generalFitness;
  TrainingGoal? _secondaryGoal;
  TrainingGoal? _previousGoal;
  bool _isLoadingPreviousGoal = true;

  @override
  void initState() {
    super.initState();
    _loadPreviousGoal();
  }

  Future<void> _loadPreviousGoal() async {
    try {
      final previousGoal = await ref
          .read(aiWorkoutRepositoryProvider)
          .getPreviousGoal(widget.clientId);
      if (mounted) {
        setState(() {
          _previousGoal = previousGoal;
          if (previousGoal != null) {
            _primaryGoal = previousGoal;
          }
          _isLoadingPreviousGoal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPreviousGoal = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(programGenerationProvider);

    ref.listen<ProgramGenerationState>(programGenerationProvider, (prev, next) {
      print('[GenerateScreen] State changed - isLoading: ${next.isLoading}, hasProgram: ${next.program != null}, error: ${next.error}');
      print('[GenerateScreen] Previous program was null: ${prev?.program == null}');

      if (next.program != null && prev?.program == null) {
        print('[GenerateScreen] ====== NAVIGATING TO REVIEW ======');
        print('[GenerateScreen] Program ID: ${next.program!.id}');
        print('[GenerateScreen] Route: /trainer/program/review/${next.program!.id}?clientId=${widget.clientId}');
        context.push(
          '/trainer/program/review/${next.program!.id}?clientId=${widget.clientId}',
        );
      } else if (next.program != null) {
        print('[GenerateScreen] Program exists but prev was not null - skipping navigation');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('AI 세션 생성'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
      ),
      body: _isLoadingPreviousGoal
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Client info
                  _ClientInfoCard(clientName: widget.clientName),
                  const SizedBox(height: AppSpacing.lg),

                  // Previous goal indicator (if exists)
                  if (_previousGoal != null) ...[
                    _PreviousGoalIndicator(goal: _previousGoal!),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Primary goal
                  _SectionTitle(title: '훈련 목표', required: true),
                  const SizedBox(height: AppSpacing.sm),
                  _GoalSelector(
                    goals: TrainingGoal.values,
                    selectedGoal: _primaryGoal,
                    onGoalSelected: (goal) {
                      setState(() {
                        _primaryGoal = goal;
                        if (_secondaryGoal == goal) {
                          _secondaryGoal = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Secondary goal (optional)
                  _SectionTitle(title: '보조 목표', required: false),
                  const SizedBox(height: AppSpacing.sm),
                  _GoalSelector(
                    goals: TrainingGoal.values,
                    selectedGoal: _secondaryGoal,
                    excludeGoal: _primaryGoal,
                    allowDeselect: true,
                    onGoalSelected: (goal) {
                      setState(() {
                        _secondaryGoal = _secondaryGoal == goal ? null : goal;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Generate button
                  ElevatedButton(
                    onPressed: state.isLoading ? null : _generateProgram,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.neutralWhite,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.psychology, color: AppColors.neutralWhite),
                              const SizedBox(width: 8),
                              const Text(
                                'AI 세션 생성',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neutralWhite,
                                ),
                              ),
                            ],
                          ),
                  ),

                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  void _generateProgram() {
    ref.read(programGenerationProvider.notifier).generateProgram(
          clientId: widget.clientId,
          trainerId: widget.trainerId,
          primaryGoal: _primaryGoal,
          secondaryGoal: _secondaryGoal,
        );
  }
}

class _PreviousGoalIndicator extends StatelessWidget {
  final TrainingGoal goal;

  const _PreviousGoalIndicator({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '이전 목표: ',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.neutral600,
            ),
          ),
          Text(
            goal.displayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Text(
            '(자동 선택됨)',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientInfoCard extends StatelessWidget {
  final String clientName;

  const _ClientInfoCard({required this.clientName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '프로그램 대상',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
              Text(
                clientName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutralBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool required;

  const _SectionTitle({
    required this.title,
    required this.required,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

class _GoalSelector extends StatelessWidget {
  final List<TrainingGoal> goals;
  final TrainingGoal? selectedGoal;
  final TrainingGoal? excludeGoal;
  final bool allowDeselect;
  final Function(TrainingGoal) onGoalSelected;

  const _GoalSelector({
    required this.goals,
    this.selectedGoal,
    this.excludeGoal,
    this.allowDeselect = false,
    required this.onGoalSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: goals
          .where((g) => g != excludeGoal)
          .map((goal) => _GoalChip(
                goal: goal,
                isSelected: selectedGoal == goal,
                onTap: () => onGoalSelected(goal),
              ))
          .toList(),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final TrainingGoal goal;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalChip({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.neutral200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getGoalIcon(goal),
                size: 18,
                color: isSelected ? AppColors.neutralWhite : AppColors.neutral700,
              ),
              const SizedBox(width: 6),
              Text(
                goal.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.neutralWhite : AppColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGoalIcon(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.strength:
        return Icons.fitness_center;
      case TrainingGoal.hypertrophy:
        return Icons.trending_up;
      case TrainingGoal.endurance:
        return Icons.directions_run;
      case TrainingGoal.weightLoss:
        return Icons.monitor_weight;
      case TrainingGoal.generalFitness:
        return Icons.favorite;
      case TrainingGoal.rehabilitation:
        return Icons.healing;
      case TrainingGoal.athletic:
        return Icons.sports;
    }
  }
}

// Duration and session selectors removed - now always generates single session
