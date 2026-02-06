import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/entities/workout_program.dart';

/// Shared widget for selecting training split
class ProgramSplitSelector extends StatelessWidget {
  final TrainingSplit selectedSplit;
  final ValueChanged<TrainingSplit> onSplitSelected;

  const ProgramSplitSelector({
    required this.selectedSplit,
    required this.onSplitSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TrainingSplit.values.map((split) {
        final isSelected = selectedSplit == split;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSplitSelected(split),
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
              child: Text(
                split.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.neutralWhite : AppColors.neutral700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Shared widget for selecting focus areas (muscle groups)
/// Always shows all muscle groups regardless of training split.
/// Focus areas provide bonus scoring (+25pts) for exercises targeting these muscles.
class ProgramFocusAreaSelector extends StatelessWidget {
  final Set<String> selectedAreas;
  final ValueChanged<String> onAreaToggled;

  const ProgramFocusAreaSelector({
    required this.selectedAreas,
    required this.onAreaToggled,
    super.key,
  });

  /// All available muscle groups for focus area selection
  static const List<String> allMuscleGroups = [
    'chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms',
    'quadriceps', 'hamstrings', 'glutes', 'adductors', 'calves', 'core'
  ];

  /// Get Korean display name for a muscle group
  static String getDisplayName(String area) {
    switch (area) {
      case 'chest': return '가슴';
      case 'back': return '등';
      case 'shoulders': return '어깨';
      case 'biceps': return '이두';
      case 'triceps': return '삼두';
      case 'forearms': return '전완근';
      case 'quadriceps': return '대퇴사두';
      case 'hamstrings': return '햄스트링';
      case 'glutes': return '둔근';
      case 'adductors': return '내전근';
      case 'calves': return '종아리';
      case 'core': return '코어';
      default: return area;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allMuscleGroups.map((area) {
        final isSelected = selectedAreas.contains(area);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onAreaToggled(area),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondary.withValues(alpha: 0.2)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.secondary : AppColors.neutral200,
                ),
              ),
              child: Text(
                getDisplayName(area),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.secondary : AppColors.neutral700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Shared widget for selecting preferred movement groups
class ProgramMovementGroupSelector extends StatelessWidget {
  final Set<String> selectedGroups;
  final ValueChanged<String> onGroupToggled;

  const ProgramMovementGroupSelector({
    required this.selectedGroups,
    required this.onGroupToggled,
    super.key,
  });

  static const List<({String id, String name, IconData icon})> movementGroups = [
    (id: 'push', name: '밀기 (가슴/어깨/삼두)', icon: Icons.arrow_forward),
    (id: 'pull', name: '당기기 (등/이두)', icon: Icons.arrow_back),
    (id: 'legs', name: '하체 (스쿼트/힌지/런지)', icon: Icons.fitness_center),
    (id: 'core', name: '코어', icon: Icons.sports_gymnastics),
    (id: 'other', name: '기타 (유산소 등)', icon: Icons.directions_run),
  ];

  /// Compact version for inline forms (shorter labels)
  static const List<({String id, String name, IconData icon})> movementGroupsCompact = [
    (id: 'push', name: '밀기', icon: Icons.arrow_forward),
    (id: 'pull', name: '당기기', icon: Icons.arrow_back),
    (id: 'legs', name: '하체', icon: Icons.fitness_center),
    (id: 'core', name: '코어', icon: Icons.sports_gymnastics),
    (id: 'other', name: '기타', icon: Icons.directions_run),
  ];

  @override
  Widget build(BuildContext context) {
    return _buildSelector(movementGroups);
  }

  Widget _buildSelector(List<({String id, String name, IconData icon})> groups) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: groups.map((group) {
        final isSelected = selectedGroups.contains(group.id);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onGroupToggled(group.id),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.neutral200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    group.icon,
                    size: 16,
                    color: isSelected ? AppColors.primary : AppColors.neutral600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.neutral700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Compact version of movement group selector for inline forms
class ProgramMovementGroupSelectorCompact extends StatelessWidget {
  final Set<String> selectedGroups;
  final ValueChanged<String> onGroupToggled;

  const ProgramMovementGroupSelectorCompact({
    required this.selectedGroups,
    required this.onGroupToggled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ProgramMovementGroupSelector.movementGroupsCompact.map((group) {
        final isSelected = selectedGroups.contains(group.id);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onGroupToggled(group.id),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.neutral200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    group.icon,
                    size: 16,
                    color: isSelected ? AppColors.primary : AppColors.neutral600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.neutral700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
