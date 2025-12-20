import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/invite_code_generator.dart';
import '../../../client_management/domain/entities/invite_entity.dart';
import '../../../client_management/presentation/providers/invite_provider.dart';

/// Screen for clients to accept trainer invites
class AcceptInviteScreen extends ConsumerStatefulWidget {
  final String? code;

  const AcceptInviteScreen({this.code, super.key});

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  final _codeController = TextEditingController();
  bool _isAccepting = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.code != null) {
      _codeController.text = InviteCodeGenerator.formatForDisplay(widget.code!);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String get _normalizedCode {
    return InviteCodeGenerator.normalize(_codeController.text);
  }

  Future<void> _acceptInvite() async {
    final code = _normalizedCode;
    if (!InviteCodeGenerator.isValid(code)) {
      setState(() => _errorMessage = 'Invalid invite code format');
      return;
    }

    setState(() {
      _isAccepting = true;
      _errorMessage = null;
    });

    final success = await ref.read(inviteNotifierProvider.notifier).acceptInvite(code);

    if (mounted) {
      setState(() {
        _isAccepting = false;
        if (success) {
          _isSuccess = true;
        } else {
          _errorMessage = 'Could not accept invite. It may have expired or already been used.';
        }
      });
    }
  }

  void _goToHome() {
    context.go('/client');
  }

  @override
  Widget build(BuildContext context) {
    final inviteAsync = widget.code != null
        ? ref.watch(inviteByCodeProvider(widget.code!))
        : const AsyncValue<InviteEntity?>.data(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accept Invite'),
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.neutralBlack,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _isSuccess
            ? _buildSuccessView()
            : _buildInviteForm(inviteAsync),
      ),
    );
  }

  Widget _buildInviteForm(AsyncValue<InviteEntity?> inviteAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.link,
          size: 64,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Connect with Trainer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Enter the invite code from your trainer',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.neutral700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Show trainer info if code is provided
        if (widget.code != null)
          inviteAsync.when(
            data: (invite) {
              if (invite == null) {
                return _buildErrorCard('Invite not found or expired');
              }
              return _buildTrainerCard(invite);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => _buildErrorCard('Could not load invite details'),
          ),

        const SizedBox(height: AppSpacing.lg),

        // Code input
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            labelText: 'Invite Code',
            hintText: 'ABC-123',
            prefixIcon: const Icon(Icons.vpn_key_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            errorText: _errorMessage,
          ),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
        ),
        const SizedBox(height: AppSpacing.xl),

        // Accept button
        ElevatedButton.icon(
          onPressed: _isAccepting ? null : _acceptInvite,
          icon: _isAccepting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check),
          label: Text(_isAccepting ? 'Connecting...' : 'Accept Invite'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(AppSpacing.md),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.neutralWhite,
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Info card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'By accepting, you allow your trainer to view your fitness logs and progress.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrainerCard(InviteEntity invite) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: invite.trainerAvatarUrl != null
                ? NetworkImage(invite.trainerAvatarUrl!)
                : null,
            child: invite.trainerAvatarUrl == null
                ? const Icon(Icons.person, color: AppColors.primary, size: 30)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invitation from',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral700,
                  ),
                ),
                Text(
                  invite.trainerDisplayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
                const Text(
                  'Personal Trainer',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified,
            color: AppColors.success,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Icon(
          Icons.celebration,
          size: 80,
          color: AppColors.success,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Connected!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'You are now connected with your trainer. They can view your fitness logs and help guide your journey.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.neutral700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl * 2),
        ElevatedButton.icon(
          onPressed: _goToHome,
          icon: const Icon(Icons.home),
          label: const Text('Go to Home'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(AppSpacing.md),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.neutralWhite,
          ),
        ),
      ],
    );
  }
}
