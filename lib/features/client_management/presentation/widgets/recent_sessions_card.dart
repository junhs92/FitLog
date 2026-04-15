import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../active_session/domain/entities/exercise_set_entity.dart';
import '../../../active_session/domain/entities/session_entity.dart';
import '../../../active_session/domain/entities/session_exercise_entity.dart';
import '../../../active_session/presentation/providers/session_provider.dart';

/// Widget displaying 3 most recent completed sessions for a client
/// Used on ClientDetailScreen below LifestyleSummaryCard
class RecentSessionsCard extends ConsumerWidget {
  final String clientId;

  const RecentSessionsCard({
    required this.clientId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(clientRecentSessionsProvider(clientId));

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const SizedBox.shrink();
        }
        final recentSessions = sessions.take(3).toList();
        return _buildSessionsCard(context, recentSessions);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSessionsCard(
      BuildContext context, List<SessionEntity> sessions) {
    return Card(
      elevation: 0,
      color: AppColors.darkSurfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: AppSpacing.md),
            ...sessions.asMap().entries.map((entry) => _SessionCard(
                  session: entry.value,
                  index: entry.key,
                  isLast: entry.key == sessions.length - 1,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.fitness_center_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '최근 운동 기록',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              Text(
                '최근 완료한 세션',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatefulWidget {
  final SessionEntity session;
  final int index;
  final bool isLast;

  const _SessionCard({
    required this.session,
    required this.index,
    required this.isLast,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final focusArea = _getFocusAreaKorean(session.focusArea);
    final focusColor = _getFocusAreaColor(session.focusArea);
    final exerciseCount =
        session.savedTotalExercises ?? session.exercises.length;
    final totalVolume = session.savedTotalVolume ?? session.totalVolume;
    final totalSets = session.savedTotalSets ?? session.totalSetsCount;

    return Container(
      margin: EdgeInsets.only(bottom: widget.isLast ? 0 : AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isExpanded
              ? focusColor.withValues(alpha: 0.3)
              : AppColors.darkBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    // Top row
                    Row(
                      children: [
                        // Focus area badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: focusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            focusArea,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: focusColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Date
                        Text(
                          session.completedAt != null
                              ? _formatKoreanDate(session.completedAt!)
                              : '날짜 없음',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.neutral500,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Stats row - simple and clean
                    Row(
                      children: [
                        _StatItem(
                          value: '$exerciseCount개',
                          label: '운동',
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: AppColors.darkBorder,
                        ),
                        _StatItem(
                          value: '$totalSets',
                          label: '세트',
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: AppColors.darkBorder,
                        ),
                        _StatItem(
                          value: _formatVolume(totalVolume),
                          label: '볼륨',
                        ),
                        if (session.prCount > 0) ...[
                          Container(
                            width: 1,
                            height: 28,
                            color: AppColors.darkBorder,
                          ),
                          _StatItem(
                            value: '${session.prCount}',
                            label: 'PR',
                            isHighlighted: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Expanded content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildExpandedContent(focusColor),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(Color focusColor) {
    final exercisesWithSets =
        widget.session.exercises.where((e) => e.sets.isNotEmpty).toList();

    if (exercisesWithSets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Text(
          '세트 기록 없음',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.neutral500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        children: [
          Divider(
            height: 1,
            color: AppColors.darkBorder,
          ),
          const SizedBox(height: 12),
          ...exercisesWithSets.map((exercise) => _ExerciseRow(
                sessionExercise: exercise,
              )),
        ],
      ),
    );
  }

  String _formatKoreanDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}/${date.day} ($weekday)';
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

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}t';
    }
    return '${volume.toStringAsFixed(0)}kg';
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isHighlighted;

  const _StatItem({
    required this.value,
    required this.label,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isHighlighted
                  ? const Color(0xFFFF9800)
                  : AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isHighlighted
                  ? const Color(0xFFFFB74D)
                  : AppColors.darkTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final SessionExerciseEntity sessionExercise;

  const _ExerciseRow({required this.sessionExercise});

  @override
  Widget build(BuildContext context) {
    final sets = sessionExercise.sets;
    final hasPR = sessionExercise.hasPR;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name
          Row(
            children: [
              if (hasPR)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Text('🏆', style: TextStyle(fontSize: 12)),
                ),
              Expanded(
                child: Text(
                  sessionExercise.exercise.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasPR
                        ? const Color(0xFFE65100)
                        : AppColors.darkTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Sets - simple text format
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: sets.map((set) => _buildSetText(set)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSetText(ExerciseSetEntity set) {
    final isPR = set.isPR;
    final weightStr = set.weight?.toStringAsFixed(0) ?? '-';
    final repsStr = set.reps?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPR
            ? const Color(0xFF2A2518)
            : AppColors.darkSurfaceCard,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${weightStr}kg×$repsStr',
        style: TextStyle(
          fontSize: 12,
          fontWeight: isPR ? FontWeight.w600 : FontWeight.w500,
          color: isPR ? const Color(0xFFE65100) : AppColors.darkTextSecondary,
        ),
      ),
    );
  }
}
