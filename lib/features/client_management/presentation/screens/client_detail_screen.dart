import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/common/error_view.dart';
import '../../../../shared/widgets/common/loading_indicator.dart';
import '../../domain/entities/client_entity.dart';
import '../providers/client_provider.dart';
import '../widgets/client_form.dart';

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
        title: Text(_isEditing ? 'Edit Client' : 'Client Details'),
        actions: [
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
                  healthHistory: formData.healthHistory,
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
          : FloatingActionButton.extended(
              onPressed: () {
                context.push('/trainer/session/${widget.clientId}');
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Session'),
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
              ],
            ),
          ),
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

          // Goals
          if (client.goals.isNotEmpty)
            _buildSection(
              context,
              'Fitness Goals',
              [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: client.goals
                      .map((goal) => Chip(label: Text(goal)))
                      .toList(),
                ),
              ],
            ),

          // Health history
          if (client.healthHistory != null)
            _buildSection(
              context,
              'Health History',
              [Text(client.healthHistory!)],
            ),

          // Notes
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
