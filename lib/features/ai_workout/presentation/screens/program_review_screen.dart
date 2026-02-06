import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/workout_program.dart';
import '../providers/ai_workout_provider.dart';
import '../../../active_session/presentation/providers/session_provider.dart';

/// Screen for reviewing workout program details (training direction)
/// In the new structure, programs define training strategy, not specific exercises
/// AI generates exercises dynamically when a session starts
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
        title: const Text('프로그램 상세'),
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
                '활성화',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Program header
          _ProgramHeader(program: program),
          const SizedBox(height: AppSpacing.lg),

          // Training Direction Section
          _SectionCard(
            title: '훈련 방향',
            icon: Icons.flag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: '분할 방식',
                  value: program.trainingSplit.displayName,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Focus Areas
          if (program.focusAreas.isNotEmpty) ...[
            _SectionCard(
              title: '집중 부위',
              icon: Icons.fitness_center,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: program.focusAreas.map((area) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getFocusAreaDisplayName(area),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Preferred Movement Groups
          if (program.preferredMovementGroups.isNotEmpty) ...[
            _SectionCard(
              title: '선호 운동 그룹',
              icon: Icons.sync_alt,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: program.preferredMovementGroups.map((group) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      PreferredMovementGroup.fromString(group).displayName,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Generated Exercises Section
          if (program.generatedExercises.isNotEmpty) ...[
            _SectionCard(
              title: 'AI 추천 운동',
              icon: Icons.auto_awesome,
              child: Column(
                children: [
                  ...program.generatedExercises.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exercise = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < program.generatedExercises.length - 1
                            ? AppSpacing.sm
                            : 0,
                      ),
                      child: _ExerciseCard(
                        exercise: exercise,
                        index: index + 1,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            // Show loading or empty state for exercises
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '운동 목록이 아직 생성되지 않았습니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Session Statistics
          _SectionCard(
            title: '세션 통계',
            icon: Icons.bar_chart,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: '총 세션',
                  value: '${program.totalSessions}회',
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  label: '주간 평균',
                  value: '${program.avgSessionsPerWeek.toStringAsFixed(1)}회',
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  label: '일관성 점수',
                  value: '${(program.consistencyScore * 100).toInt()}%',
                ),
                if (program.suggestedNextFocus != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    label: '다음 추천',
                    value: _getFocusAreaDisplayName(program.suggestedNextFocus!),
                    valueColor: AppColors.info,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Start session button (only if exercises are generated)
          if (program.generatedExercises.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startSessionWithProgram(program),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  '세션 시작 (${program.generatedExercises.length}개 운동)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Info card about exercise generation
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.info),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'AI가 클라이언트의 운동 기록과 프로그램 방향을 분석하여 최적의 운동을 자동으로 구성합니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.info,
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

  void _startSessionWithProgram(WorkoutProgramEntity program) {
    // Navigate to session screen with the generated exercises
    context.push(
      '/trainer/session/${widget.clientId}?programId=${program.id}',
    );
  }

  void _activateProgram() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('프로그램 활성화'),
        content: const Text('이 프로그램을 활성화하시겠습니까? 활성화된 프로그램으로 새 세션을 시작할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(programGenerationProvider.notifier)
                  .updateStatus(ProgramStatus.active);
              // Invalidate providers to refresh data
              ref.invalidate(activeProgramProvider(widget.clientId));
              ref.invalidate(exerciseRecommendationsProvider(widget.clientId));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('프로그램이 활성화되었습니다')),
                );
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('활성화'),
          ),
        ],
      ),
    );
  }

  String _getFocusAreaDisplayName(String focus) {
    switch (focus) {
      case 'full_body':
        return '전신';
      case 'upper':
        return '상체';
      case 'lower':
        return '하체';
      case 'push':
        return '밀기 (가슴/어깨/삼두)';
      case 'pull':
        return '당기기 (등/이두)';
      case 'legs':
        return '하체';
      case 'chest':
        return '가슴';
      case 'back':
        return '등';
      case 'shoulders':
        return '어깨';
      case 'arms':
        return '팔';
      case 'core':
        return '코어';
      default:
        return focus;
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
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'AI',
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
              const Spacer(),
              if (program.isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '만료됨',
                    style: TextStyle(fontSize: 12, color: AppColors.error),
                  ),
                )
              else if (program.daysUntilExpiration != null &&
                  program.daysUntilExpiration! <= 7)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${program.daysUntilExpiration}일 남음',
                    style: const TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
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
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.neutral600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppColors.neutralBlack,
          ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final GeneratedProgramExercise exercise;
  final int index;

  const _ExerciseCard({
    required this.exercise,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.neutral200),
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
                Text(
                  exercise.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exercise.targetSets}세트 × ${exercise.targetReps}회 | 휴식 ${exercise.restSeconds}초',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                ),
                if (exercise.aiReasoningKo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    exercise.aiReasoningKo!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.neutral500,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
