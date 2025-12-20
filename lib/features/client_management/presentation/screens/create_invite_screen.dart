import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/invite_code_generator.dart';
import '../../domain/entities/invite_entity.dart';
import '../providers/invite_provider.dart';

/// Screen for trainers to generate client invite codes
class CreateInviteScreen extends ConsumerStatefulWidget {
  const CreateInviteScreen({super.key});

  @override
  ConsumerState<CreateInviteScreen> createState() => _CreateInviteScreenState();
}

class _CreateInviteScreenState extends ConsumerState<CreateInviteScreen> {
  final _emailController = TextEditingController();
  InviteEntity? _generatedInvite;
  bool _isGenerating = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _generateInvite() async {
    setState(() => _isGenerating = true);

    final email = _emailController.text.trim();
    final invite = await ref.read(inviteNotifierProvider.notifier).createInvite(
      clientEmail: email.isNotEmpty ? email : null,
    );

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _generatedInvite = invite;
      });
    }
  }

  void _copyCode() {
    if (_generatedInvite == null) return;
    final code = InviteCodeGenerator.formatForDisplay(_generatedInvite!.invitationCode);
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied to clipboard')),
    );
  }

  void _copyLink() {
    if (_generatedInvite == null) return;
    final link = InviteCodeGenerator.generateDeepLink(_generatedInvite!.invitationCode);
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  void _shareInvite() {
    if (_generatedInvite == null) return;
    final code = InviteCodeGenerator.formatForDisplay(_generatedInvite!.invitationCode);
    final link = InviteCodeGenerator.generateDeepLink(_generatedInvite!.invitationCode);

    Share.share(
      'Join me on FitLog Pro!\n\n'
      'Use this invite code: $code\n\n'
      'Or tap this link: $link',
      subject: 'FitLog Pro Invite',
    );
  }

  void _generateNewCode() {
    setState(() => _generatedInvite = null);
    _emailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Client'),
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.neutralBlack,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _generatedInvite == null
            ? _buildGenerateForm()
            : _buildInviteDisplay(),
      ),
    );
  }

  Widget _buildGenerateForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.person_add_alt_1,
          size: 64,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Invite a Client',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Generate a unique code that your client can use to connect with you.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.neutral700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Client Email (optional)',
            hintText: 'client@example.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            helperText: 'For your reference only',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : _generateInvite,
          icon: _isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.qr_code),
          label: Text(_isGenerating ? 'Generating...' : 'Generate Invite Code'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(AppSpacing.md),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.neutralWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildInviteDisplay() {
    final code = InviteCodeGenerator.formatForDisplay(_generatedInvite!.invitationCode);
    final deepLink = InviteCodeGenerator.generateDeepLink(_generatedInvite!.invitationCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle,
          size: 48,
          color: AppColors.success,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Invite Created!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Share this code with your client',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.neutral700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),

        // QR Code
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.neutralWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.overlayLight,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              QrImageView(
                data: deepLink,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.neutralBlack,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.neutralBlack,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Invite Code Display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: AppColors.primary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    IconButton(
                      onPressed: _copyCode,
                      icon: const Icon(Icons.copy, color: AppColors.primary),
                      tooltip: 'Copy code',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Expiry Notice
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.warning, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'This invite expires in 7 days',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.warning.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyLink,
                icon: const Icon(Icons.link),
                label: const Text('Copy Link'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareInvite,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.neutralWhite,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: _generateNewCode,
          child: const Text('Generate New Code'),
        ),
      ],
    );
  }
}
