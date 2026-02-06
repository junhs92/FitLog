import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/workout_template_entity.dart';

/// Card widget for displaying a workout template
class TemplateCard extends StatelessWidget {
  final WorkoutTemplateEntity template;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const TemplateCard({
    required this.template,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.neutral200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Focus area badge
                  if (template.focusArea != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getFocusAreaColor(template.focusArea)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        template.focusAreaKorean,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getFocusAreaColor(template.focusArea),
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Usage count
                  if (template.usageCount > 0)
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          size: 14,
                          color: AppColors.neutral500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${template.usageCount}회',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  if (showActions) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 20,
                        color: AppColors.neutral500,
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit?.call();
                        } else if (value == 'delete') {
                          onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('수정'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('삭제', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Template name
              Text(
                template.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutralBlack,
                ),
              ),
              const SizedBox(height: 4),

              // Description or exercise preview
              if (template.description != null &&
                  template.description!.isNotEmpty)
                Text(
                  template.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              else if (template.exercises.isNotEmpty)
                Text(
                  template.exercises.take(3).map((e) => e.displayName).join(', ') +
                      (template.exercises.length > 3
                          ? ' 외 ${template.exercises.length - 3}개'
                          : ''),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: AppSpacing.sm),

              // Stats row
              Row(
                children: [
                  _StatBadge(
                    icon: Icons.fitness_center,
                    label: '${template.exerciseCount}개',
                  ),
                  const SizedBox(width: 12),
                  if (template.estimatedDurationMinutes != null)
                    _StatBadge(
                      icon: Icons.timer_outlined,
                      label: '${template.estimatedDurationMinutes}분',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.neutral500),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }
}
