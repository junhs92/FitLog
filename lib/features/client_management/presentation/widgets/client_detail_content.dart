import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../calendar/domain/entities/session_package.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../calendar/presentation/widgets/quick_schedule_sheet.dart';
import '../../../muscle_map/muscle_map.dart';
import '../../../muscle_map/presentation/providers/muscle_activity_provider.dart';
import '../../domain/entities/client_entity.dart';
import '../providers/client_provider.dart';
import 'client_form.dart';
import 'exercise_recommendation_card.dart';
import 'recent_sessions_card.dart';

/// Reusable client detail content widget.
/// Used in both the full-screen ClientDetailScreen and the
/// master-detail layout's detail panel.
class ClientDetailContent extends ConsumerStatefulWidget {
  final ClientEntity client;
  final VoidCallback? onStartSession;
  final bool showAppBar;

  const ClientDetailContent({
    required this.client,
    this.onStartSession,
    this.showAppBar = true,
    super.key,
  });

  @override
  ConsumerState<ClientDetailContent> createState() =>
      _ClientDetailContentState();
}

class _ClientDetailContentState extends ConsumerState<ClientDetailContent> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(clientMutationProvider);

    // Listen for mutation results
    ref.listen<ClientMutationState>(clientMutationProvider, (previous, next) {
      if (next.isSuccess && _isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _isEditing = false);
      } else if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Operation failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    if (_isEditing) {
      return Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: const Text('Edit Client'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _isEditing = false),
                  ),
                ],
              )
            : null,
        body: ClientForm(
          initialClient: widget.client,
          isLoading: mutationState.isLoading,
          onSubmit: (formData) async {
            final updatedClient = widget.client.copyWith(
              name: formData.name,
              email: formData.email,
              phone: formData.phone,
              dateOfBirth: formData.dateOfBirth,
              gender: formData.gender,
              height: formData.height,
              weight: formData.weight,
              goals: formData.goals,
              notes: formData.notes,
            );
            await ref
                .read(clientMutationProvider.notifier)
                .updateClient(updatedClient);
          },
        ),
      );
    }

    return Scaffold(
      appBar: widget.showAppBar ? _buildAppBar(context) : null,
      body: _buildDetailView(context),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Schedule lesson FAB
          SizedBox(
            width: 130,
            height: 48,
            child: FloatingActionButton.extended(
              heroTag: 'schedule_fab_${widget.client.id}',
              onPressed: () => _showScheduleSheet(context),
              backgroundColor: AppColors.darkSurfaceCard,
              foregroundColor: AppColors.primary,
              elevation: 2,
              icon: const Icon(Icons.add),
              label: const Text('예약'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Start session FAB
          SizedBox(
            width: 130,
            height: 48,
            child: FloatingActionButton.extended(
              heroTag: 'session_fab_${widget.client.id}',
              onPressed: () => _handleStartSession(context),
              icon: const Icon(Icons.play_arrow),
              label: const Text('세션 시작'),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(widget.client.name),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month),
          tooltip: 'Schedule Lesson',
          onPressed: () => _showScheduleSheet(context),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => setState(() => _isEditing = true),
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              _showDeleteConfirmation(context, ref);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.error),
                  SizedBox(width: AppSpacing.sm),
                  Text('Delete Client'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar
          Center(
            child: Column(
              children: [
                _buildAvatar(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.client.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (widget.client.age != null)
                  Text(
                    '${widget.client.age} years old',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkTextSecondary,
                        ),
                  ),
                // Remaining Sessions Display
                _buildSessionsRemaining(ref),
                // Fitness Goals (shown prominently under age)
                if (widget.client.goals.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    alignment: WrapAlignment.center,
                    children: widget.client.goals.map((goal) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          goal,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Exercise Recommendations (Pre-Session Planning)
          ExerciseRecommendationCard(clientId: widget.client.id),
          const SizedBox(height: AppSpacing.xl),

          // 7-Day Muscle Activity Map (Pre-Session Planning)
          Consumer(
            builder: (context, ref, child) {
              final muscleMapAsync = ref.watch(
                clientMuscleMapProvider((clientId: widget.client.id, dayRange: 7)),
              );
              return muscleMapAsync.when(
                data: (muscleMap) => MiniMuscleMap(
                  muscleMap: muscleMap,
                  onTap: () {
                    context.push('/trainer/clients/${widget.client.id}/stats?tab=muscles');
                  },
                ),
                loading: () => Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceElevated,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Recent Sessions
          RecentSessionsCard(clientId: widget.client.id),
          const SizedBox(height: AppSpacing.xl),

          // Contact info
          if (widget.client.email != null || widget.client.phone != null)
            _buildSection(
              context,
              'Contact',
              [
                if (widget.client.email != null)
                  _buildInfoRow(Icons.email_outlined, widget.client.email!),
                if (widget.client.phone != null)
                  _buildInfoRow(Icons.phone_outlined, widget.client.phone!),
              ],
            ),

          // Physical info
          if (widget.client.height != null || widget.client.weight != null)
            _buildSection(
              context,
              'Physical Info',
              [
                if (widget.client.height != null)
                  _buildInfoRow(Icons.height, '${widget.client.height} cm'),
                if (widget.client.weight != null)
                  _buildInfoRow(
                    Icons.monitor_weight_outlined,
                    Formatters.weight(widget.client.weight!),
                  ),
                if (widget.client.gender != null)
                  _buildInfoRow(Icons.person_outline, widget.client.gender!),
              ],
            ),

          // Notes
          if (widget.client.notes != null)
            _buildSection(
              context,
              'Notes',
              [Text(widget.client.notes!)],
            ),

          // Member since
          _buildSection(
            context,
            'Member Since',
            [Text(Formatters.displayDate(widget.client.createdAt))],
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    const size = 100.0;

    if (widget.client.profilePhotoUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(widget.client.profilePhotoUrl!),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Text(
        widget.client.initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 36,
        ),
      ),
    );
  }

  Widget _buildSessionsRemaining(WidgetRef ref) {
    final packageAsync = ref.watch(clientSessionPackageProvider(widget.client.id));

    return packageAsync.when(
      data: (package) {
        if (package == null) {
          return const SizedBox(height: AppSpacing.xs);
        }

        final remaining = package.sessionsRemaining;
        final total = package.totalSessions;
        final warningLevel = package.warningLevel;

        // Choose color based on warning level
        Color textColor;
        Color bgColor;
        switch (warningLevel) {
          case PackageWarningLevel.critical:
          case PackageWarningLevel.expired:
            textColor = AppColors.error;
            bgColor = AppColors.error.withValues(alpha: 0.1);
            break;
          case PackageWarningLevel.low:
            textColor = AppColors.warning;
            bgColor = AppColors.warning.withValues(alpha: 0.1);
            break;
          case PackageWarningLevel.none:
            textColor = AppColors.success;
            bgColor = AppColors.success.withValues(alpha: 0.1);
            break;
        }

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  size: 16,
                  color: textColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '남은 세션: $remaining / $total회',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: AppSpacing.sm),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox(height: AppSpacing.xs),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.darkTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(text),
        ],
      ),
    );
  }

  void _showScheduleSheet(BuildContext context) {
    showQuickScheduleSheet(
      context,
      initialClientId: widget.client.id,
      initialDate: DateTime.now(),
    );
  }

  void _handleStartSession(BuildContext context) {
    final package =
        ref.read(clientSessionPackageProvider(widget.client.id)).valueOrNull;
    if (package != null && package.sessionsRemaining <= 0) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('세션 잔여 횟수 부족'),
          content: const Text(
            '남은 세션이 0회입니다. 그래도 세션을 시작하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onStartSession?.call();
              },
              child: const Text('시작'),
            ),
          ],
        ),
      );
      return;
    }
    widget.onStartSession?.call();
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: const Text(
          'Are you sure you want to delete this client? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(clientMutationProvider.notifier)
                  .deleteClient(widget.client.id);
              if (success && context.mounted) {
                // Clear selection and go back if in full screen
                ref.read(selectedClientIdProvider.notifier).state = null;
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
