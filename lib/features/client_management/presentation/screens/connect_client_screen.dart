import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../providers/connection_request_provider.dart';

/// Screen for trainers to search and connect with clients
class ConnectClientScreen extends ConsumerStatefulWidget {
  const ConnectClientScreen({super.key});

  @override
  ConsumerState<ConnectClientScreen> createState() => _ConnectClientScreenState();
}

class _ConnectClientScreenState extends ConsumerState<ConnectClientScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    // Load available clients immediately when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectionRequestProvider.notifier).loadAvailableClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      ref.read(connectionRequestProvider.notifier).searchClients(query);
    });
  }

  Future<void> _sendRequest(ClientSearchResult client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Connection Request'),
        content: Text(
          'Send a connection request to ${client.name}?\n\n'
          'They will need to accept before you can access their data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(connectionRequestProvider.notifier)
        .sendRequest(client.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Request sent to ${client.name}'
                : 'Failed to send request',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionRequestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect with Client'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(connectionRequestProvider.notifier).clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                filled: true,
                fillColor: AppColors.surfaceElevated,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Results or instructions
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.searchResults.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsList(state.searchResults),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final state = ref.watch(connectionRequestProvider);

    // Show error if there's one
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Error loading clients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  ref.read(connectionRequestProvider.notifier).loadAvailableClients();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // No clients available (not a search result issue)
    if (_searchController.text.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: AppColors.neutral500,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No clients available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No clients with accounts are available to connect.\nThey may already be connected to you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(connectionRequestProvider.notifier).loadAvailableClients();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    // Search returned no results
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No clients found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No matches for "${_searchController.text}".\nTry a different search term.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(List<ClientSearchResult> results) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final client = results[index];
        return _ClientSearchTile(
          client: client,
          onSendRequest: () => _sendRequest(client),
          onCancelRequest: client.hasPendingRequest
              ? () => _cancelRequest(client)
              : null,
        );
      },
    );
  }

  Future<void> _cancelRequest(ClientSearchResult client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: Text(
          'Cancel connection request to ${client.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(connectionRequestProvider.notifier)
        .cancelRequestByClientId(client.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Request cancelled'
                : 'Failed to cancel request',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

class _ClientSearchTile extends StatelessWidget {
  final ClientSearchResult client;
  final VoidCallback onSendRequest;
  final VoidCallback? onCancelRequest;

  const _ClientSearchTile({
    required this.client,
    required this.onSendRequest,
    this.onCancelRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage:
                client.avatarUrl != null ? NetworkImage(client.avatarUrl!) : null,
            child: client.avatarUrl == null
                ? Text(
                    client.initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name.isNotEmpty ? client.name : 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  client.email,
                  style: TextStyle(
                    color: AppColors.neutral600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          client.hasPendingRequest
              ? OutlinedButton(
                  onPressed: onCancelRequest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 16, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : FilledButton(
                  onPressed: onSendRequest,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Connect'),
                ),
        ],
      ),
    );
  }
}

/// Simple debouncer for search
class Debouncer {
  final int milliseconds;
  VoidCallback? _action;
  bool _isRunning = false;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _action = action;
    if (!_isRunning) {
      _isRunning = true;
      Future.delayed(Duration(milliseconds: milliseconds), () {
        _isRunning = false;
        _action?.call();
      });
    }
  }
}
