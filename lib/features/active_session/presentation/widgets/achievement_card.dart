import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/auto_achievement.dart';
import '../../domain/entities/detected_achievement.dart';

/// Widget to display achievements in the session summary
class AchievementSection extends StatelessWidget {
  final List<DetectedAchievement> achievements;

  const AchievementSection({
    required this.achievements,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF9DB), // Light gold
            const Color(0xFFFFEC99), // Bright gold
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                '🏆',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                '오늘의 성과',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutralBlack,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${achievements.length}개',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Achievement list
          ...achievements.map((achievement) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AchievementCard(achievement: achievement),
              )),
        ],
      ),
    );
  }
}

/// Individual achievement card
class AchievementCard extends StatelessWidget {
  final DetectedAchievement achievement;

  const AchievementCard({
    required this.achievement,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.neutralWhite.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getIconBackgroundColor(),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                achievement.type.icon,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      achievement.type.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    if (achievement.subtitle != null) ...[
                      const Text(
                        ' - ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.neutral700,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          achievement.subtitle!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getIconBackgroundColor() {
    switch (achievement.type.category) {
      case AchievementCategory.performance:
        return const Color(0xFFFFD700).withOpacity(0.3); // Gold
      case AchievementCategory.consistency:
        return const Color(0xFFFF6B35).withOpacity(0.3); // Orange
      case AchievementCategory.effort:
        return const Color(0xFFE53935).withOpacity(0.3); // Red
      case AchievementCategory.milestone:
        return const Color(0xFF9C27B0).withOpacity(0.3); // Purple
    }
  }
}

/// Compact achievement badge for use in exercise tabs
class AchievementBadge extends StatelessWidget {
  final AutoAchievement type;
  final bool mini;

  const AchievementBadge({
    required this.type,
    this.mini = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (mini) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            type.icon,
            style: const TextStyle(fontSize: 10),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type.icon,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 2),
          Text(
            'PR',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralBlack,
            ),
          ),
        ],
      ),
    );
  }
}
