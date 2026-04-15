import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/set_comment.dart';

/// Selector widget for exercise coaching comments
class SetCommentSelector extends StatefulWidget {
  final List<SetComment> selectedComments;
  final Map<SetComment, String> commentDetails;
  final ValueChanged<List<SetComment>> onChanged;
  final ValueChanged<Map<SetComment, String>> onDetailsChanged;
  final String movementGroup;
  final Map<String, int>? usageCounts;
  final int defaultPerCategory;
  final bool compact;

  const SetCommentSelector({
    required this.selectedComments,
    required this.onChanged,
    required this.movementGroup,
    this.commentDetails = const {},
    this.onDetailsChanged = _defaultDetailsChanged,
    this.usageCounts,
    this.defaultPerCategory = 5,
    this.compact = false,
    super.key,
  });

  static void _defaultDetailsChanged(Map<SetComment, String> _) {}

  @override
  State<SetCommentSelector> createState() => _SetCommentSelectorState();
}

class _SetCommentSelectorState extends State<SetCommentSelector> {
  bool _showAllComments = false;
  final Map<SetComment, TextEditingController> _detailControllers = {};

  @override
  void dispose() {
    for (final controller in _detailControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleComment(SetComment comment) {
    HapticFeedback.lightImpact();
    final newComments = List<SetComment>.from(widget.selectedComments);
    if (newComments.contains(comment)) {
      newComments.remove(comment);
      // Clear detail when deselecting condition comment
      if (comment.category == SetCommentCategory.condition) {
        final newDetails = Map<SetComment, String>.from(widget.commentDetails);
        newDetails.remove(comment);
        widget.onDetailsChanged(newDetails);
        _detailControllers[comment]?.clear();
      }
    } else {
      newComments.add(comment);
    }
    widget.onChanged(newComments);
  }

  void _updateDetail(SetComment comment, String detail) {
    final newDetails = Map<SetComment, String>.from(widget.commentDetails);
    if (detail.isEmpty) {
      newDetails.remove(comment);
    } else {
      newDetails[comment] = detail;
    }
    widget.onDetailsChanged(newDetails);
  }

  TextEditingController _getController(SetComment comment) {
    if (!_detailControllers.containsKey(comment)) {
      _detailControllers[comment] = TextEditingController(
        text: widget.commentDetails[comment] ?? '',
      );
    }
    return _detailControllers[comment]!;
  }

  Color _getCategoryColor(SetCommentCategory category) {
    switch (category) {
      case SetCommentCategory.mistake:
        return AppColors.warning;     // Orange/red for mistakes
      case SetCommentCategory.coachingCue:
        return AppColors.primary;     // Blue for coaching
      case SetCommentCategory.condition:
        return AppColors.success;     // Green for condition
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get all comments grouped by category, filtered by movement pattern
    final allComments =
        SetCommentHelper.getCommentsForPattern(widget.movementGroup);

    // Get top comments for default display (more generous default)
    final topComments = SetCommentHelper.getTopCommentsForPattern(
      widget.movementGroup,
      perCategory: widget.defaultPerCategory,
      usageCounts: widget.usageCounts,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.comment_outlined,
                size: 18,
                color: AppColors.neutral700,
              ),
              const SizedBox(width: 6),
              const Text(
                'Comments',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral700,
                ),
              ),
              const Spacer(),
              if (widget.selectedComments.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.selectedComments.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutralWhite,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Categories
          ...SetCommentCategory.values.map((category) {
            final comments = _showAllComments
                ? allComments[category] ?? []
                : topComments[category] ?? [];

            if (comments.isEmpty) return const SizedBox.shrink();

            return _CategorySection(
              category: category,
              comments: comments,
              selectedComments: widget.selectedComments,
              commentDetails: widget.commentDetails,
              onToggle: _toggleComment,
              onDetailChanged: _updateDetail,
              getController: _getController,
              categoryColor: _getCategoryColor(category),
              compact: widget.compact,
            );
          }),
          // Show more/less button
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showAllComments = !_showAllComments),
              icon: Icon(
                _showAllComments ? Icons.expand_less : Icons.expand_more,
                size: 20,
              ),
              label: Text(_showAllComments ? '접기' : '더보기'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.neutral700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final SetCommentCategory category;
  final List<SetComment> comments;
  final List<SetComment> selectedComments;
  final Map<SetComment, String> commentDetails;
  final ValueChanged<SetComment> onToggle;
  final void Function(SetComment, String) onDetailChanged;
  final TextEditingController Function(SetComment) getController;
  final Color categoryColor;
  final bool compact;

  const _CategorySection({
    required this.category,
    required this.comments,
    required this.selectedComments,
    required this.commentDetails,
    required this.onToggle,
    required this.onDetailChanged,
    required this.getController,
    required this.categoryColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    // Get selected condition comments that need detail input
    final selectedConditionComments = category == SetCommentCategory.condition
        ? comments.where((c) => selectedComments.contains(c)).toList()
        : <SetComment>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category.displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: categoryColor,
                ),
              ),
            ],
          ),
        ),
        // Comment chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: comments.map((comment) {
            final isSelected = selectedComments.contains(comment);
            return _CommentChip(
              comment: comment,
              isSelected: isSelected,
              onTap: () => onToggle(comment),
              categoryColor: categoryColor,
              compact: compact,
            );
          }).toList(),
        ),
        // Detail input for selected condition comments
        if (selectedConditionComments.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...selectedConditionComments.map((comment) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ConditionDetailInput(
                comment: comment,
                controller: getController(comment),
                onChanged: (detail) => onDetailChanged(comment, detail),
                categoryColor: categoryColor,
              ),
            );
          }),
        ],
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _ConditionDetailInput extends StatelessWidget {
  final SetComment comment;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Color categoryColor;

  const _ConditionDetailInput({
    required this.comment,
    required this.controller,
    required this.onChanged,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: categoryColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            comment.shortDisplayName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralWhite,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: categoryColor.withOpacity(0.3)),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.darkTextSecondary,
              ),
              decoration: InputDecoration(
                hintText: _getHintText(comment),
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getHintText(SetComment comment) {
    switch (comment) {
      case SetComment.painReported:
        return '부위 입력 (예: 무릎, 허리)';
      case SetComment.fatigueEarly:
        return '상세 내용 (예: 3세트부터)';
      case SetComment.weakSide:
        return '방향 입력 (예: 왼쪽, 오른쪽)';
      case SetComment.limitedRom:
        return '부위 입력 (예: 어깨, 고관절)';
      case SetComment.gripWeak:
        return '상세 내용 (예: 데드리프트)';
      default:
        return '상세 내용 입력';
    }
  }
}

class _CommentChip extends StatelessWidget {
  final SetComment comment;
  final bool isSelected;
  final VoidCallback onTap;
  final Color categoryColor;
  final bool compact;

  const _CommentChip({
    required this.comment,
    required this.isSelected,
    required this.onTap,
    required this.categoryColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? categoryColor : categoryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          child: Text(
            comment.shortDisplayName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.neutralWhite : categoryColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact inline version for displaying selected comments
class SelectedCommentsDisplay extends StatelessWidget {
  final List<SetComment> comments;
  final Map<SetComment, String>? details;
  final VoidCallback? onTap;

  const SelectedCommentsDisplay({
    required this.comments,
    this.details,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: comments.map((comment) {
          final color = _getCategoryColor(comment.category);
          final detail = details?[comment];
          final displayText = detail != null && detail.isNotEmpty
              ? '${comment.shortDisplayName}: $detail'
              : comment.shortDisplayName;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getCategoryColor(SetCommentCategory category) {
    switch (category) {
      case SetCommentCategory.mistake:
        return AppColors.warning;     // Orange/red for mistakes
      case SetCommentCategory.coachingCue:
        return AppColors.primary;     // Blue for coaching
      case SetCommentCategory.condition:
        return AppColors.success;     // Green for condition
    }
  }
}
