import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/workout_template_entity.dart';
import '../providers/workout_template_provider.dart';
import 'template_card.dart';

/// Extracted content widget for template selection
/// Can be embedded in dialogs or sheets without its own container/header
class TemplateSelectionContent extends ConsumerWidget {
  final String clientId;
  final String clientName;
  final void Function(WorkoutTemplateEntity template) onTemplateSelected;
  /// Whether to show the "Manage" button in empty state that navigates away
  final bool showManageButton;

  const TemplateSelectionContent({
    required this.clientId,
    required this.clientName,
    required this.onTemplateSelected,
    this.showManageButton = true,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(trainerTemplatesProvider);

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildTemplateList(context, templates);
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.neutral100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_border,
              size: 48,
              color: AppColors.neutral400,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            '저장된 템플릿이 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralBlack,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '자주 사용하는 운동 조합을 템플릿으로\n저장해두면 빠르게 세션을 시작할 수 있습니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.neutral600,
            ),
          ),
          if (showManageButton) ...[
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/trainer/templates/create');
              },
              icon: const Icon(Icons.add),
              label: const Text('첫 템플릿 만들기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateList(
      BuildContext context, List<WorkoutTemplateEntity> templates) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: TemplateCard(
            template: template,
            onTap: () => onTemplateSelected(template),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '템플릿을 불러오는데 실패했습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralBlack,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}
