import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../ai_workout/domain/entities/workout_program.dart';
import '../../../ai_workout/presentation/providers/ai_workout_provider.dart';
import '../providers/session_provider.dart';

/// Bottom sheet for selecting a workout program before starting a session
class ProgramSelectionSheet extends ConsumerWidget {
  final String clientId;
  final String clientName;
  final String trainerId;

  const ProgramSelectionSheet({
    required this.clientId,
    required this.clientName,
    required this.trainerId,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required String clientId,
    required String clientName,
    required String trainerId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgramSelectionSheet(
        clientId: clientId,
        clientName: clientName,
        trainerId: trainerId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(clientProgramsProvider(clientId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
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
            child: Column(
              children: [
                Text(
                  '세션 시작',
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
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quick action buttons
                  _QuickActionCard(
                    icon: Icons.psychology,
                    title: 'AI 세션 생성',
                    subtitle: '새로운 AI 기반 운동 프로그램 생성',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                        '/trainer/program/generate/$clientId'
                        '?trainerId=$trainerId&name=${Uri.encodeComponent(clientName)}',
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _QuickActionCard(
                    icon: Icons.add,
                    title: '빈 세션 시작',
                    subtitle: '운동을 직접 추가하며 진행',
                    color: AppColors.neutral600,
                    onTap: () => _startEmptySession(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Past programs section
                  const Text(
                    '이전 프로그램으로 시작',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  programsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => _EmptyProgramsMessage(
                      message: '프로그램을 불러올 수 없습니다',
                    ),
                    data: (programs) {
                      // Filter to show only active or completed programs
                      final usablePrograms = programs.where((p) =>
                          p.status == ProgramStatus.active ||
                          p.status == ProgramStatus.completed).toList();

                      if (usablePrograms.isEmpty) {
                        return const _EmptyProgramsMessage(
                          message: '이전 프로그램이 없습니다\nAI 세션을 생성해보세요',
                        );
                      }

                      return Column(
                        children: usablePrograms
                            .take(10) // Show last 10 programs
                            .map((program) => _ProgramCard(
                                  program: program,
                                  onTap: () => _showDaySelection(
                                    context,
                                    ref,
                                    program,
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startEmptySession(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    context.push('/trainer/session/$clientId?name=${Uri.encodeComponent(clientName)}');
  }

  void _showDaySelection(
    BuildContext context,
    WidgetRef ref,
    WorkoutProgramEntity program,
  ) {
    // Handle empty workoutDays
    if (program.workoutDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이 프로그램에는 운동 일차가 없습니다'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (program.workoutDays.length == 1) {
      // Only one day, start directly
      _startSessionWithProgram(context, ref, program, program.workoutDays.first);
    } else {
      // Show day selection - get refs before showing new sheet
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      final router = GoRouter.of(context);

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _DaySelectionSheet(
          program: program,
          onDaySelected: (day) {
            // Close both sheets at once
            Navigator.pop(ctx); // Close day selection
            Navigator.pop(context); // Close program selection
            // Start session with saved references
            _startSessionWithDaySelection(
              rootNavigator: rootNavigator,
              router: router,
              ref: ref,
              program: program,
              day: day,
            );
          },
        ),
      );
    }
  }

  /// Start session when day is selected from day selection sheet
  /// Uses pre-captured navigator and router references
  Future<void> _startSessionWithDaySelection({
    required NavigatorState rootNavigator,
    required GoRouter router,
    required WidgetRef ref,
    required WorkoutProgramEntity program,
    required WorkoutDayEntity day,
  }) async {
    // Show fullscreen loading overlay
    showDialog(
      context: rootNavigator.context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => PopScope(
        canPop: false,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                '세션 시작 중...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final session = await ref
          .read(activeSessionProvider.notifier)
          .startSessionWithProgram(
            clientId: clientId,
            programId: program.id,
            workoutDayId: day.id,
          );

      // Close loading dialog
      if (rootNavigator.mounted) {
        rootNavigator.pop();
      }

      if (session != null) {
        router.go('/trainer/session/$clientId?name=${Uri.encodeComponent(clientName)}');
      } else if (rootNavigator.mounted) {
        ScaffoldMessenger.of(rootNavigator.context).showSnackBar(
          const SnackBar(
            content: Text('세션을 시작할 수 없습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (rootNavigator.mounted) {
        rootNavigator.pop();
        ScaffoldMessenger.of(rootNavigator.context).showSnackBar(
          SnackBar(
            content: Text('세션 시작 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _startSessionWithProgram(
    BuildContext context,
    WidgetRef ref,
    WorkoutProgramEntity program,
    WorkoutDayEntity day,
  ) async {
    // Get root navigator and router BEFORE closing bottom sheet
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final router = GoRouter.of(context);

    // Close the bottom sheet first
    Navigator.of(context).pop();

    // Show fullscreen loading overlay using root navigator
    showDialog(
      context: rootNavigator.context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => PopScope(
        canPop: false,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                '세션 시작 중...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final session = await ref
          .read(activeSessionProvider.notifier)
          .startSessionWithProgram(
            clientId: clientId,
            programId: program.id,
            workoutDayId: day.id,
          );

      // Close loading dialog
      if (rootNavigator.mounted) {
        rootNavigator.pop();
      }

      if (session != null) {
        router.go('/trainer/session/$clientId?name=${Uri.encodeComponent(clientName)}');
      } else if (rootNavigator.mounted) {
        ScaffoldMessenger.of(rootNavigator.context).showSnackBar(
          const SnackBar(
            content: Text('세션을 시작할 수 없습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (rootNavigator.mounted) {
        rootNavigator.pop();
        ScaffoldMessenger.of(rootNavigator.context).showSnackBar(
          SnackBar(
            content: Text('세션 시작 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final WorkoutProgramEntity program;
  final VoidCallback onTap;

  const _ProgramCard({
    required this.program,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseCount = program.workoutDays
        .fold<int>(0, (sum, day) => sum + day.exercises.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Program icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getGoalColor(program.primaryGoal).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getGoalIcon(program.primaryGoal),
                    color: _getGoalColor(program.primaryGoal),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Program info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              program.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutralBlack,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (program.isAiGenerated)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.psychology,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'AI',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _InfoTag(
                            icon: Icons.flag_outlined,
                            label: program.primaryGoal.displayName,
                          ),
                          const SizedBox(width: 8),
                          _InfoTag(
                            icon: Icons.fitness_center,
                            label: '$exerciseCount 운동',
                          ),
                          const SizedBox(width: 8),
                          _InfoTag(
                            icon: Icons.calendar_today_outlined,
                            label: '${program.workoutDays.length}일',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.play_circle_outline,
                  color: AppColors.primary,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getGoalColor(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.strength:
        return Colors.red;
      case TrainingGoal.hypertrophy:
        return Colors.orange;
      case TrainingGoal.endurance:
        return Colors.green;
      case TrainingGoal.weightLoss:
        return Colors.teal;
      case TrainingGoal.generalFitness:
        return AppColors.primary;
      case TrainingGoal.rehabilitation:
        return Colors.purple;
      case TrainingGoal.athletic:
        return Colors.indigo;
    }
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

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoTag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.neutral500),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }
}

class _EmptyProgramsMessage extends StatelessWidget {
  final String message;

  const _EmptyProgramsMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 48,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySelectionSheet extends StatelessWidget {
  final WorkoutProgramEntity program;
  final Function(WorkoutDayEntity) onDaySelected;

  const _DaySelectionSheet({
    required this.program,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              '운동 일차 선택',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neutralBlack,
              ),
            ),
          ),
          const Divider(height: 1),
          ...program.workoutDays.map((day) => ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'D${day.dayNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                title: Text(day.name),
                subtitle: Text(
                  '${day.exercises.length}개 운동 · ${day.estimatedDurationMinutes}분',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onDaySelected(day),
              )),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
