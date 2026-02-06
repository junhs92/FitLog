import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/workout_template_entity.dart';
import '../providers/workout_template_provider.dart';
import '../widgets/template_card.dart';

/// Screen for managing workout templates
class MyTemplatesScreen extends ConsumerWidget {
  const MyTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(trainerTemplatesProvider);
    final mutationState = ref.watch(templateMutationProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('나의 운동'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutralBlack,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: templatesAsync.when(
        data: (templates) => templates.isEmpty
            ? _buildEmptyState(context)
            : _buildTemplateList(context, ref, templates, mutationState.isLoading),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, ref, error.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trainer/templates/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '템플릿 만들기',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 64,
                color: AppColors.neutral400,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              '저장된 템플릿이 없습니다',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => context.push('/trainer/templates/create'),
              icon: const Icon(Icons.add),
              label: const Text('첫 템플릿 만들기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateList(
    BuildContext context,
    WidgetRef ref,
    List<WorkoutTemplateEntity> templates,
    bool isDeleting,
  ) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TemplateCard(
                template: template,
                showActions: true,
                onTap: () => context.push('/trainer/templates/edit/${template.id}'),
                onEdit: () => context.push('/trainer/templates/edit/${template.id}'),
                onDelete: () => _showDeleteDialog(context, ref, template),
              ),
            );
          },
        ),
        if (isDeleting)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppSpacing.md),
                      Text('삭제 중...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              '템플릿을 불러오는데 실패했습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neutralBlack,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(trainerTemplatesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    WorkoutTemplateEntity template,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('템플릿 삭제'),
        content: Text('"${template.displayName}" 템플릿을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final notifier = ref.read(templateMutationProvider.notifier);
              final success = await notifier.deleteTemplate(template.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? '템플릿이 삭제되었습니다' : '삭제에 실패했습니다',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
