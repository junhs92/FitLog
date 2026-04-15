import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/common/error_view.dart';
import '../../../../shared/widgets/common/loading_indicator.dart';
import '../../../active_session/presentation/widgets/program_selection_sheet.dart';
import '../../../calendar/domain/entities/session_package.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../trainer_home/presentation/providers/trainer_home_provider.dart';
import '../../domain/entities/client_entity.dart';
import '../providers/client_provider.dart';
import '../widgets/client_detail_content.dart';

/// Master-detail layout for clients on tablet/desktop screens.
/// Shows client list on left panel and detail view on right panel
/// with Apple-style smooth transitions. The master panel collapses
/// to a mini avatar strip when a client is selected.
class ClientsMasterDetailScreen extends ConsumerStatefulWidget {
  const ClientsMasterDetailScreen({super.key});

  @override
  ConsumerState<ClientsMasterDetailScreen> createState() =>
      _ClientsMasterDetailScreenState();
}

class _ClientsMasterDetailScreenState
    extends ConsumerState<ClientsMasterDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _selectionController;
  late Animation<double> _selectionScale;

  @override
  void initState() {
    super.initState();
    _selectionController = AnimationController(
      duration: ResponsiveAnimations.selectionFeedback,
      vsync: this,
    );
    _selectionScale = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _selectionController,
        curve: ResponsiveAnimations.selectionCurve,
      ),
    );
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCollapsed = ref.watch(masterPanelCollapsedProvider);

    return Scaffold(
      body: Row(
        children: [
          // Master panel (client list)
          _MasterPanel(
            selectionScale: _selectionScale,
            onSelectionStart: () => _selectionController.forward(),
            onSelectionEnd: () => _selectionController.reverse(),
            isCollapsed: isCollapsed,
            onToggleCollapse: () {
              ref.read(masterPanelCollapsedProvider.notifier).state =
                  !isCollapsed;
            },
            onClientTapCollapse: () {
              ref.read(masterPanelCollapsedProvider.notifier).state = true;
            },
          ),

          // Divider with subtle shadow
          Container(
            width: 1,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.02),
                  offset: const Offset(1, 0),
                  blurRadius: 3,
                ),
              ],
            ),
          ),

          // Detail panel
          const Expanded(
            child: _DetailPanel(),
          ),
        ],
      ),
    );
  }
}

/// Master panel showing the client list with search and selection.
/// Supports collapsing to a narrow mini-avatar strip.
class _MasterPanel extends ConsumerWidget {
  final Animation<double> selectionScale;
  final VoidCallback onSelectionStart;
  final VoidCallback onSelectionEnd;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onClientTapCollapse;

  const _MasterPanel({
    required this.selectionScale,
    required this.onSelectionStart,
    required this.onSelectionEnd,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onClientTapCollapse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedWidth = ResponsiveBreakpoints.getMasterPanelWidth(context);
    const collapsedWidth = ResponsiveBreakpoints.railWidth;
    final panelWidth = isCollapsed ? collapsedWidth : expandedWidth;

    return AnimatedContainer(
      duration: ResponsiveAnimations.panelResize,
      curve: ResponsiveAnimations.springCurve,
      width: panelWidth,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: AnimatedSwitcher(
        duration: ResponsiveAnimations.contentFade,
        switchInCurve: ResponsiveAnimations.fadeCurve,
        switchOutCurve: ResponsiveAnimations.fadeCurve,
        child: isCollapsed
            ? _buildCollapsedContent(context, ref)
            : _buildExpandedContent(context, ref),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(filteredClientsProvider);
    final searchQuery = ref.watch(clientSearchQueryProvider);
    final selectedClientId = ref.watch(selectedClientIdProvider);

    return Column(
      key: const ValueKey('expanded'),
      children: [
        // Header with title and actions
        _buildHeader(context, ref),

        // Search indicator
        if (searchQuery.isNotEmpty)
          _buildSearchIndicator(context, ref, searchQuery),

        // Client list
        Expanded(
          child: clientsAsync.when(
            data: (clients) {
              if (clients.isEmpty) {
                return _buildEmptyState(context, searchQuery.isNotEmpty);
              }

              // Auto-select first client if none selected (tablet UX)
              // Does NOT collapse the panel on auto-select
              if (selectedClientId == null && clients.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(selectedClientIdProvider.notifier).state =
                      clients.first.id;
                });
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(clientsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    final isSelected = client.id == selectedClientId;

                    return _SelectableClientTile(
                      client: client,
                      isSelected: isSelected,
                      selectionScale: selectionScale,
                      onTap: () {
                        onSelectionStart();
                        ref.read(selectedClientIdProvider.notifier).state =
                            client.id;
                        Future.delayed(
                          ResponsiveAnimations.selectionFeedback,
                          onSelectionEnd,
                        );
                        // Collapse panel after selecting a client
                        onClientTapCollapse();
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

        // Add client FAB
        _buildAddClientButton(context),
      ],
    );
  }

  Widget _buildCollapsedContent(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(filteredClientsProvider);
    final selectedClientId = ref.watch(selectedClientIdProvider);

    return Column(
      key: const ValueKey('collapsed'),
      children: [
        // Collapsed header with expand button
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: const Border(
              bottom: BorderSide(color: AppColors.darkBorder),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Expand panel',
                  onPressed: onToggleCollapse,
                ),
              ),
            ),
          ),
        ),

        // Mini avatar list
        Expanded(
          child: clientsAsync.when(
            data: (clients) => ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                final isSelected = client.id == selectedClientId;

                return _MiniClientAvatar(
                  client: client,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(selectedClientIdProvider.notifier).state =
                        client.id;
                  },
                );
              },
            ),
            loading: () => const LoadingIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(
          bottom: BorderSide(color: AppColors.darkBorder),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Text(
              'Clients',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Collapse panel',
              onPressed: onToggleCollapse,
            ),
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
      ),
    );
  }

  Widget _buildSearchIndicator(
    BuildContext context,
    WidgetRef ref,
    String query,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Searching: "$query"',
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.people_outline,
              size: 48,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isSearching ? 'No clients found' : 'No clients yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!isSearching) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add your first client',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral700,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddClientButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _showAddClientOptions(context),
          icon: const Icon(Icons.person_add),
          label: const Text('Add Client'),
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
                subtitle: const Text('Send a connection request'),
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
                subtitle: const Text('Add a new client profile'),
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
}

/// Mini client avatar for the collapsed panel strip
class _MiniClientAvatar extends StatelessWidget {
  final ClientEntity client;
  final bool isSelected;
  final VoidCallback onTap;

  const _MiniClientAvatar({
    required this.client,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Center(
        child: Tooltip(
          message: client.name,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: ResponsiveAnimations.selectionFeedback,
              curve: ResponsiveAnimations.selectionCurve,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: _buildAvatar(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (client.profilePhotoUrl != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(client.profilePhotoUrl!),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Text(
        client.initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Selectable client tile with animation for master panel
class _SelectableClientTile extends ConsumerWidget {
  final ClientEntity client;
  final bool isSelected;
  final Animation<double> selectionScale;
  final VoidCallback onTap;
  final VoidCallback onSessionTap;

  const _SelectableClientTile({
    required this.client,
    required this.isSelected,
    required this.selectionScale,
    required this.onTap,
    required this.onSessionTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: selectionScale,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected ? selectionScale.value : 1.0,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: ResponsiveAnimations.selectionFeedback,
        curve: ResponsiveAnimations.selectionCurve,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Avatar with selection ring
                  _buildAvatar(),
                  const SizedBox(width: AppSpacing.md),

                  // Client info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : null,
                                  ),
                        ),
                        if (client.goals.isNotEmpty)
                          Text(
                            client.goalsText,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        _buildSessionsBadge(ref),
                      ],
                    ),
                  ),

                  // Quick session button
                  IconButton(
                    onPressed: onSessionTap,
                    icon: const Icon(Icons.play_circle_outline, size: 22),
                    color: AppColors.primary,
                    tooltip: 'Start Session',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsBadge(WidgetRef ref) {
    final packageAsync = ref.watch(
      clientSessionPackageProvider(client.id),
    );

    return packageAsync.when(
      data: (package) {
        if (package == null) return const SizedBox.shrink();

        final remaining = package.sessionsRemaining;
        final total = package.totalSessions;
        final warningLevel = package.warningLevel;

        Color textColor;
        switch (warningLevel) {
          case PackageWarningLevel.critical:
          case PackageWarningLevel.expired:
            textColor = AppColors.error;
            break;
          case PackageWarningLevel.low:
            textColor = AppColors.warning;
            break;
          case PackageWarningLevel.none:
            textColor = AppColors.neutral700;
            break;
        }

        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            remaining <= 0
                ? '남은 세션 없음'
                : '남은 세션: $remaining / $total회',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAvatar() {
    Widget avatar;
    if (client.profilePhotoUrl != null) {
      avatar = CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(client.profilePhotoUrl!),
      );
    } else {
      avatar = CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Text(
          client.initials,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      );
    }

    // Wrap with selection indicator
    return AnimatedContainer(
      duration: ResponsiveAnimations.selectionFeedback,
      padding: EdgeInsets.all(isSelected ? 2 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: avatar,
    );
  }
}

/// Detail panel showing selected client's details
class _DetailPanel extends ConsumerWidget {
  const _DetailPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedClientId = ref.watch(selectedClientIdProvider);

    if (selectedClientId == null) {
      return _buildEmptySelection(context);
    }

    final clientAsync = ref.watch(clientProvider(selectedClientId));

    return AnimatedSwitcher(
      duration: ResponsiveAnimations.contentFade,
      switchInCurve: ResponsiveAnimations.fadeCurve,
      switchOutCurve: ResponsiveAnimations.fadeCurve,
      child: clientAsync.when(
        data: (client) => ClientDetailContent(
          key: ValueKey(client.id),
          client: client,
          onStartSession: () {
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
        ),
        loading: () => const LoadingIndicator(key: ValueKey('loading')),
        error: (error, _) => ErrorView(
          key: ValueKey('error'),
          message: error.toString(),
          onRetry: () => ref.invalidate(clientProvider(selectedClientId)),
        ),
      ),
    );
  }

  Widget _buildEmptySelection(BuildContext context) {
    return Container(
      color: AppColors.darkSurfaceCard,
      child: Center(
        child: Card(
          elevation: 0,
          color: AppColors.darkSurfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.darkBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Select a client',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Choose a client from the list\nto view their details',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.neutral700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
