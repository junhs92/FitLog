import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../domain/entities/exercise_set_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../providers/session_provider.dart';
import '../widgets/set_row.dart';

/// Session summary screen displayed after completing a session
class SessionSummaryScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionSummaryScreen({
    required this.sessionId,
    super.key,
  });

  @override
  ConsumerState<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends ConsumerState<SessionSummaryScreen> {
  SessionEntity? _session;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final repository = ref.read(sessionRepositoryProvider);
    final result = await repository.getSessionById(widget.sessionId);

    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isLoading = false;
      }),
      (session) => setState(() {
        _session = session;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Summary')),
        body: Center(
          child: Text(_error ?? 'Session not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Session Complete'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success header
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.neutralWhite,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Great Session!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralBlack,
                    ),
                  ),
                  if (_session!.clientName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _session!.clientName!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.neutral700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.timer,
                    label: 'Duration',
                    value: _session!.durationDisplay,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    icon: Icons.fitness_center,
                    label: 'Exercises',
                    value: _session!.exerciseCount.toString(),
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.repeat,
                    label: 'Total Sets',
                    value: _session!.totalSetsCount.toString(),
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    icon: Icons.monitor_weight,
                    label: 'Volume',
                    value: '${_session!.totalVolume.toStringAsFixed(0)} kg',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            if (_session!.prCount > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700),
                      const Color(0xFFFFA500),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${_session!.prCount} PR${_session!.prCount > 1 ? 's' : ''} Today!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            // Exercise breakdown
            const Text(
              'Exercise Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neutralBlack,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._session!.exercises.map((exercise) => _ExerciseSummaryCard(
                  exerciseName: exercise.exercise.displayName,
                  sets: exercise.sets,
                  topSet: exercise.topSet,
                  totalVolume: exercise.totalVolume,
                  hasPR: exercise.hasPR,
                )),
            const SizedBox(height: AppSpacing.xl),
            // Action buttons
            OutlinedButton.icon(
              onPressed: () => context.push('/trainer/report/${widget.sessionId}'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('View AI Report'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: AppColors.info,
                side: const BorderSide(color: AppColors.info),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Back to Home',
              onPressed: () => context.go('/trainer/home'),
              icon: Icons.home,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSummaryCard extends StatelessWidget {
  final String exerciseName;
  final List<ExerciseSetEntity> sets;
  final ExerciseSetEntity? topSet;
  final double totalVolume;
  final bool hasPR;

  const _ExerciseSummaryCard({
    required this.exerciseName,
    required this.sets,
    this.topSet,
    required this.totalVolume,
    required this.hasPR,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: hasPR
            ? Border.all(color: const Color(0xFFFFD700), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exerciseName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
              ),
              if (hasPR)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'PR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '${sets.length} sets',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral700,
                ),
              ),
              const Text(' • ', style: TextStyle(color: AppColors.neutral500)),
              Text(
                '${totalVolume.toStringAsFixed(0)} kg total',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral700,
                ),
              ),
              if (topSet != null) ...[
                const Text(' • ', style: TextStyle(color: AppColors.neutral500)),
                Text(
                  'Top: ${topSet!.weight?.toStringAsFixed(0) ?? '-'} kg × ${topSet!.reps ?? '-'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Show sets
          ...sets.map((set) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SetRow(set: set),
              )),
        ],
      ),
    );
  }
}
