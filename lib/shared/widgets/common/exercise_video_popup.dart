import 'package:flutter/material.dart';
import '../../../features/active_session/domain/entities/exercise_entity.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import 'exercise_video_player.dart';

/// Modal popup for displaying exercise demonstration video
///
/// Shows a large video player with exercise details (name, equipment, muscles).
/// Uses video URL stored in Supabase for testing purposes.
/// TODO: After testing, implement real-time ExerciseDB API fetching to comply
/// with their policy against storing/caching video URLs.
class ExerciseVideoPopup extends StatelessWidget {
  final ExerciseEntity exercise;

  const ExerciseVideoPopup({
    required this.exercise,
    super.key,
  });

  /// Show the popup as a modal bottom sheet
  static Future<void> show(BuildContext context, {required ExerciseEntity exercise}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseVideoPopup(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar and close button
          _buildHeader(context),
          // Video player
          _buildVideoPlayer(),
          // Exercise details
          _buildExerciseDetails(),
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Handle bar (visual indicator)
          Expanded(
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            color: AppColors.neutral600,
            iconSize: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ExerciseVideoPlayer(
        videoUrl: exercise.videoUrl,
        fallbackImageUrl: exercise.imageUrl,
        height: 280,
        borderRadius: 16,
      ),
    );
  }

  Widget _buildExerciseDetails() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name
          Text(
            exercise.displayName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralBlack,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Equipment info
          if (exercise.equipment != null && exercise.equipment!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.fitness_center,
              label: '장비',
              value: _formatEquipment(exercise.equipment!),
            ),
          // Primary muscle group
          if (exercise.muscleGroup != null && exercise.muscleGroup!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.accessibility_new,
              label: '주동근',
              value: _formatMuscle(exercise.muscleGroup!),
            ),
          // Secondary muscles
          if (exercise.secondaryMuscles.isNotEmpty)
            _buildInfoRow(
              icon: Icons.people_outline,
              label: '협응근',
              value: exercise.secondaryMuscles.map(_formatMuscle).join(', '),
            ),
          // Movement pattern
          _buildInfoRow(
            icon: Icons.category_outlined,
            label: '움직임',
            value: '${MovementGroup.getDisplayNameKo(exercise.movementGroup)}'
                '${exercise.movementDetail != null ? ' - ${MovementDetail.getDisplayNameKo(exercise.movementDetail!)}' : ''}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.neutral500),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.neutralBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format equipment name for display
  String _formatEquipment(String equipment) {
    const equipmentKo = {
      'barbell': '바벨',
      'dumbbell': '덤벨',
      'cable': '케이블',
      'machine': '머신',
      'bodyweight': '맨몸',
      'kettlebell': '케틀벨',
      'band': '밴드',
      'ez_bar': 'EZ바',
      'smith_machine': '스미스 머신',
      'medicine_ball': '메디신볼',
      'stability_ball': '짐볼',
      'foam_roller': '폼롤러',
    };
    return equipmentKo[equipment.toLowerCase()] ?? equipment;
  }

  /// Format muscle name for display
  String _formatMuscle(String muscle) {
    const muscleKo = {
      'chest': '가슴',
      'back': '등',
      'shoulders': '어깨',
      'biceps': '이두',
      'triceps': '삼두',
      'forearms': '전완',
      'abs': '복근',
      'obliques': '옆구리',
      'lower_back': '허리',
      'glutes': '둔근',
      'quads': '대퇴사두',
      'hamstrings': '햄스트링',
      'calves': '종아리',
      'hip_flexors': '고관절굴곡근',
      'traps': '승모근',
      'lats': '광배근',
      'rhomboids': '능형근',
      'delts': '삼각근',
      'pecs': '대흉근',
      'serratus': '전거근',
    };
    return muscleKo[muscle.toLowerCase()] ?? muscle;
  }
}
