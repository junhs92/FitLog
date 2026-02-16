import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../active_session/domain/entities/exercise_entity.dart';
import '../../../active_session/domain/services/exercise_recommendation_service.dart';
import '../../../active_session/presentation/providers/session_provider.dart';

/// Widget displaying top 5 recommended exercise families for a client
/// Used on ClientDetailScreen as pre-session planning guidance
class ExerciseRecommendationCard extends ConsumerWidget {
  final String clientId;

  const ExerciseRecommendationCard({
    required this.clientId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(clientRecommendedFamiliesProvider(clientId));

    return recsAsync.when(
      data: (items) {
        if (items.isEmpty) return _buildEmptyState();
        return _buildCard(items);
      },
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildEmptyState(),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      elevation: 0,
      color: AppColors.surfaceElevated,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: AppSpacing.md),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      color: AppColors.surfaceElevated,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: AppColors.neutral500, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    '추천 데이터가 없습니다',
                    style: TextStyle(
                      color: AppColors.neutral500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<FamilyRecommendationItem> items) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceElevated,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '오늘의 추천 운동 패밀리',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (index > 0)
                    Divider(
                      height: 1,
                      color: AppColors.neutral200,
                    ),
                  _FamilyItem(item: item),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Icon(
          Icons.fitness_center,
          size: 18,
          color: AppColors.neutral600,
        ),
        const SizedBox(width: AppSpacing.xs),
        const Expanded(
          child: Text(
            '추천 운동',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralBlack,
            ),
          ),
        ),
      ],
    );
  }
}

class _FamilyItem extends StatelessWidget {
  final FamilyRecommendationItem item;

  const _FamilyItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final family = item.family;
    final muscleTag = family.muscleGroup ??
        MovementGroup.getDisplayNameKo(family.movementGroup);
    final color = _getMovementGroupColor(family.movementGroup);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family name row
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  family.displayNameKo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralBlack,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  muscleTag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          // Reason lines
          if (item.detailedReasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ...item.detailedReasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(
                    left: 22, // align with text after dot
                    top: 2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '· ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Color _getMovementGroupColor(String movementGroup) {
    switch (movementGroup) {
      case MovementGroup.push:
        return const Color(0xFFE53935);
      case MovementGroup.pull:
        return const Color(0xFF1E88E5);
      case MovementGroup.legs:
        return const Color(0xFF43A047);
      case MovementGroup.core:
        return const Color(0xFF6D4C41);
      case MovementGroup.other:
        return const Color(0xFF00ACC1);
      default:
        return AppColors.primary;
    }
  }
}
