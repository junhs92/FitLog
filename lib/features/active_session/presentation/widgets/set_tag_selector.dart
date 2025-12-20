import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/exercise_set_entity.dart';

/// Quick tag selector for sets (PR, Form Issue, Pain, etc.)
class SetTagSelector extends StatelessWidget {
  final List<SetTag> selectedTags;
  final ValueChanged<List<SetTag>> onChanged;
  final List<SetTag>? availableTags;

  const SetTagSelector({
    required this.selectedTags,
    required this.onChanged,
    this.availableTags,
    super.key,
  });

  static const List<SetTag> _defaultTags = [
    SetTag.pr,
    SetTag.warmup,
    SetTag.goodCondition,
    SetTag.fatigue,
    SetTag.formIssue,
    SetTag.pain,
  ];

  List<SetTag> get _tags => availableTags ?? _defaultTags;

  void _toggleTag(SetTag tag) {
    HapticFeedback.lightImpact();
    final newTags = List<SetTag>.from(selectedTags);
    if (newTags.contains(tag)) {
      newTags.remove(tag);
    } else {
      newTags.add(tag);
    }
    onChanged(newTags);
  }

  Color _getTagColor(SetTag tag) {
    switch (tag) {
      case SetTag.pr:
        return const Color(0xFFFFD700); // Gold
      case SetTag.formIssue:
        return AppColors.warning;
      case SetTag.pain:
        return AppColors.error;
      case SetTag.fatigue:
        return AppColors.neutral700;
      case SetTag.goodCondition:
        return AppColors.success;
      case SetTag.warmup:
        return AppColors.info;
      case SetTag.dropSet:
        return AppColors.secondary;
      case SetTag.failureSet:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: _tags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return _TagChip(
          tag: tag,
          isSelected: isSelected,
          color: _getTagColor(tag),
          onTap: () => _toggleTag(tag),
        );
      }).toList(),
    );
  }
}

class _TagChip extends StatelessWidget {
  final SetTag tag;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TagChip({
    required this.tag,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tag.emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                tag.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.neutralWhite : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
