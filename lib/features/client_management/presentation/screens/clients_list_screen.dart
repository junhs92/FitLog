import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/common/error_view.dart';
import '../../../../shared/widgets/common/loading_indicator.dart';
import '../../../active_session/presentation/widgets/program_selection_sheet.dart';
import '../../../trainer_home/presentation/providers/trainer_home_provider.dart';
import '../providers/client_provider.dart';
import '../widgets/client_card.dart';

/// Screen displaying list of all clients
class ClientsListScreen extends ConsumerWidget {
  const ClientsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(filteredClientsProvider);
    final searchQuery = ref.watch(clientSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            tooltip: 'Connect with Client',
            onPressed: () => context.push('/trainer/clients/connect'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search indicator
          if (searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.sm,
              ),
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Text(
                    'Searching: "$searchQuery"',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      ref.read(clientSearchQueryProvider.notifier).state = '';
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Client list
          Expanded(
            child: clientsAsync.when(
              data: (clients) {
                if (clients.isEmpty) {
                  return _buildEmptyState(context, searchQuery.isNotEmpty);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(clientsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return ClientCard(
                        client: client,
                        onTap: () {
                          context.push('/trainer/clients/${client.id}');
                        },
                        onSessionTap: () {
                          final trainerIdAsync = ref.read(trainerIdProvider);
                          final trainerId = trainerIdAsync.valueOrNull ?? '';
                          ProgramSelectionSheet.show(
                            context: context,
                            ref: ref,
                            clientId: client.id,
                            clientName: client.name,
                            trainerId: trainerId,
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(clientsProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClientOptions(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Client'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    if (isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No clients found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral700,
                  ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No clients yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Connect with existing users or add a new client to get started',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.push('/trainer/clients/connect'),
              icon: const Icon(Icons.person_search),
              label: const Text('Connect with Client'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddClientOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.person_search,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Connect with Existing User',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Send a connection request to someone who already has an account',
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/trainer/clients/connect');
                },
              ),
              const Divider(height: AppSpacing.lg),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: AppColors.secondary,
                  ),
                ),
                title: const Text(
                  'Create New Client',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Add a new client profile manually',
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/trainer/clients/add');
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: ref.read(clientSearchQueryProvider),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Clients'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter client name',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            ref.read(clientSearchQueryProvider.notifier).state = value;
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(clientSearchQueryProvider.notifier).state = '';
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(clientSearchQueryProvider.notifier).state =
                  controller.text;
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
