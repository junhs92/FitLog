import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/common/error_view.dart';
import '../../../../shared/widgets/common/loading_indicator.dart';
import '../../../active_session/presentation/widgets/program_selection_sheet.dart';
import '../../../calendar/domain/entities/session_package.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../calendar/presentation/widgets/quick_schedule_sheet.dart';
import '../../../muscle_map/muscle_map.dart';
import '../../../trainer_home/presentation/providers/trainer_home_provider.dart';
import '../../domain/entities/client_entity.dart';
import '../providers/client_provider.dart';
import '../widgets/client_form.dart';
import '../widgets/lifestyle_summary_card.dart';
import '../widgets/recent_sessions_card.dart';

/// Screen for viewing and editing client details
class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientDetailScreen({
    required this.clientId,
    super.key,
  });

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientProvider(widget.clientId));
    final mutationState = ref.watch(clientMutationProvider);

    // Listen for mutation results
    ref.listen<ClientMutationState>(clientMutationProvider, (previous, next) {
      if (next.isSuccess && _isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client updated successfully'),
            backgroundColor: Colors.green,
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

    return Scaffold(
      appBar: AppBar(
        title: clientAsync.maybeWhen(
          data: (client) => Text(_isEditing ? 'Edit Client' : client.name),
          orElse: () => Text(_isEditing ? 'Edit Client' : 'Client Details'),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: 'Schedule Lesson',
              onPressed: () => _showScheduleSheet(context),
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (!_isEditing)
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
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: clientAsync.when(
        data: (client) {
          if (_isEditing) {
            return ClientForm(
              initialClient: client,
              isLoading: mutationState.isLoading,
              onSubmit: (formData) async {
                final updatedClient = client.copyWith(
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
            );
          }
          return _buildDetailView(context, client);
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(clientProvider(widget.clientId)),
        ),
      ),
      floatingActionButton: _isEditing
          ? null
          : clientAsync.maybeWhen(
              data: (client) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Schedule lesson FAB
                  SizedBox(
                    width: 130,
                    height: 48,
                    child: FloatingActionButton.extended(
                      heroTag: 'schedule_fab',
                      onPressed: () => _showScheduleSheet(context),
                      backgroundColor: AppColors.neutral100,
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
                      heroTag: 'session_fab',
                      onPressed: () {
                        final trainerIdAsync = ref.read(trainerIdProvider);
                        final trainerId = trainerIdAsync.valueOrNull ?? '';
                        ProgramSelectionSheet.show(
                          context: context,
                          ref: ref,
                          clientId: widget.clientId,
                          clientName: client.name,
                          trainerId: trainerId,
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('세션 시작'),
                    ),
                  ),
                ],
              ),
              orElse: () => null,
            ),
    );
  }

  Widget _buildDetailView(BuildContext context, ClientEntity client) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar
          Center(
            child: Column(
              children: [
                _buildAvatar(client),
                const SizedBox(height: AppSpacing.md),
                Text(
                  client.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (client.age != null)
                  Text(
                    '${client.age} years old',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.neutral700,
                        ),
                  ),
                // Remaining Sessions Display
                _buildSessionsRemaining(ref),
                // Fitness Goals (shown prominently under age)
                if (client.goals.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    alignment: WrapAlignment.center,
                    children: client.goals.map((goal) {
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

          // 7-Day Lifestyle Summary (Flow 0)
          LifestyleSummaryCard(clientId: widget.clientId),
          const SizedBox(height: AppSpacing.xl),

          // 7-Day Muscle Activity Map (Pre-Session Planning)
          Consumer(
            builder: (context, ref, child) {
              final muscleMapAsync = ref.watch(
                clientMuscleMapProvider((clientId: widget.clientId, dayRange: 7)),
              );
              return muscleMapAsync.when(
                data: (muscleMap) => MiniMuscleMap(
                  muscleMap: muscleMap,
                  onTap: () {
                    context.push('/trainer/clients/${widget.clientId}/stats?tab=muscles');
                  },
                ),
                loading: () => Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
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

          // Recent Sessions (3 most recent completed)
          RecentSessionsCard(clientId: widget.clientId),
          const SizedBox(height: AppSpacing.xl),

          // Contact info
          if (client.email != null || client.phone != null)
            _buildSection(
              context,
              'Contact',
              [
                if (client.email != null)
                  _buildInfoRow(Icons.email_outlined, client.email!),
                if (client.phone != null)
                  _buildInfoRow(Icons.phone_outlined, client.phone!),
              ],
            ),

          // Physical info
          if (client.height != null || client.weight != null)
            _buildSection(
              context,
              'Physical Info',
              [
                if (client.height != null)
                  _buildInfoRow(Icons.height, '${client.height} cm'),
                if (client.weight != null)
                  _buildInfoRow(
                    Icons.monitor_weight_outlined,
                    Formatters.weight(client.weight!),
                  ),
                if (client.gender != null)
                  _buildInfoRow(Icons.person_outline, client.gender!),
              ],
            ),

          // Notes (Trainer's private notes)
          if (client.notes != null)
            _buildSection(
              context,
              'Notes',
              [Text(client.notes!)],
            ),

          // Member since
          _buildSection(
            context,
            'Member Since',
            [Text(Formatters.displayDate(client.createdAt))],
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildAvatar(ClientEntity client) {
    const size = 100.0;

    if (client.profilePhotoUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(client.profilePhotoUrl!),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Text(
        client.initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 36,
        ),
      ),
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
                  color: AppColors.neutral700,
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
          Icon(icon, size: 20, color: AppColors.neutral700),
          const SizedBox(width: AppSpacing.sm),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildSessionsRemaining(WidgetRef ref) {
    final packageAsync = ref.watch(clientSessionPackageProvider(widget.clientId));

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

  void _showScheduleSheet(BuildContext context) {
    showQuickScheduleSheet(
      context,
      initialClientId: widget.clientId,
      initialDate: DateTime.now(),
    );
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
                  .deleteClient(widget.clientId);
              if (success && context.mounted) {
                context.pop();
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
