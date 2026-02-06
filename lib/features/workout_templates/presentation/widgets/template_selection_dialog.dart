import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import 'template_selection_content.dart';

/// Bottom sheet dialog for selecting a workout template to start a session
class TemplateSelectionDialog extends ConsumerWidget {
  final String clientId;
  final String clientName;

  const TemplateSelectionDialog({
    required this.clientId,
    required this.clientName,
    super.key,
  });

  /// Show the template selection dialog
  static Future<void> show({
    required BuildContext context,
    required String clientId,
    required String clientName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TemplateSelectionDialog(
        clientId: clientId,
        clientName: clientName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '나의 운동',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutralBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '저장된 템플릿으로 세션 시작',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Manage templates button
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/trainer/templates');
                  },
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('관리'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content - using extracted widget
          Flexible(
            child: TemplateSelectionContent(
              clientId: clientId,
              clientName: clientName,
              onTemplateSelected: (template) {
                Navigator.pop(context);
                // Navigate to template review screen
                context.push(
                  '/trainer/templates/review/$clientId?name=${Uri.encodeComponent(clientName)}',
                  extra: template,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
