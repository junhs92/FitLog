import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/workout_program.dart';
import '../providers/ai_workout_provider.dart';
import '../widgets/program_form_fields.dart';
import '../../../active_session/presentation/providers/session_provider.dart';

/// Screen for creating/editing AI workout programs
/// Programs store client PREFERENCES for exercise selection
/// Goals come from client's account (accounts.fitness_goals)
class GenerateProgramScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String trainerId;
  final String clientName;
  final String? programId; // If provided, edit mode is enabled

  const GenerateProgramScreen({
    required this.clientId,
    required this.trainerId,
    required this.clientName,
    this.programId,
    super.key,
  });

  bool get isEditMode => programId != null;

  @override
  ConsumerState<GenerateProgramScreen> createState() =>
      _GenerateProgramScreenState();
}

class _GenerateProgramScreenState extends ConsumerState<GenerateProgramScreen> {
  // Form state
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  TrainingSplit _trainingSplit = TrainingSplit.fullBody;
  final Set<String> _focusAreas = {};
  final Set<String> _preferredMovementGroups = {};

  // Edit mode state
  bool _isLoadingExistingProgram = false;
  WorkoutProgramEntity? _existingProgram;

  @override
  void initState() {
    super.initState();
    // Clear any previous program state so listener can detect new creation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(programCreationProvider.notifier).clear();
      debugPrint('🟢 [INIT] Cleared previous program state');
    });

    if (widget.isEditMode) {
      _loadExistingProgram();
    } else {
      // Default program name
      _nameController.text = '${widget.clientName}의 프로그램';
    }
  }

  Future<void> _loadExistingProgram() async {
    if (widget.programId == null) return;

    setState(() => _isLoadingExistingProgram = true);

    try {
      final repository = ref.read(aiWorkoutRepositoryProvider);
      final result = await repository.getProgram(widget.programId!);

      result.fold(
        (failure) {
          debugPrint('🔴 [EDIT] Failed to load program: $failure');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('프로그램을 불러올 수 없습니다'),
                backgroundColor: AppColors.error,
              ),
            );
            context.pop();
          }
        },
        (program) {
          if (mounted) {
            setState(() {
              _existingProgram = program;
              _nameController.text = program.name;
              _descriptionController.text = program.description ?? '';
              _trainingSplit = program.trainingSplit;
              _focusAreas.addAll(program.focusAreas);
              _preferredMovementGroups.addAll(program.preferredMovementGroups);
              _isLoadingExistingProgram = false;
            });
            debugPrint('🟢 [EDIT] Loaded program: ${program.name}');
          }
        },
      );
    } catch (e) {
      debugPrint('🔴 [EDIT] Error loading program: $e');
      if (mounted) {
        setState(() => _isLoadingExistingProgram = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(programCreationProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(widget.isEditMode ? '프로그램 수정하기' : '프로그램 만들기'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
      ),
      body: _isLoadingExistingProgram
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Client info
                  _ClientInfoCard(clientName: widget.clientName),
                  const SizedBox(height: AppSpacing.lg),

                  // Program name
                  _SectionTitle(title: '프로그램 이름', required: true),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: '예: 근력 향상 프로그램',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Training Split
                  _SectionTitle(title: '훈련 분할', required: true),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '세션 구조를 결정합니다 (전신, 상체/하체 교대, PPL 로테이션)',
                    style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ProgramSplitSelector(
                    selectedSplit: _trainingSplit,
                    onSplitSelected: (split) {
                      setState(() {
                        _trainingSplit = split;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Focus areas - always show all muscle groups regardless of split
                  _SectionTitle(title: '집중 부위 (선택)', required: false),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '선택한 부위의 운동이 추가로 추천됩니다',
                    style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ProgramFocusAreaSelector(
                    selectedAreas: _focusAreas,
                    onAreaToggled: (area) {
                      setState(() {
                        if (_focusAreas.contains(area)) {
                          _focusAreas.remove(area);
                        } else {
                          _focusAreas.add(area);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Movement group preferences
                  _SectionTitle(title: '선호하는 운동 유형 (선택)', required: false),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'AI가 이 유형의 운동을 우선적으로 선택합니다',
                    style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ProgramMovementGroupSelector(
                    selectedGroups: _preferredMovementGroups,
                    onGroupToggled: (group) {
                      setState(() {
                        if (_preferredMovementGroups.contains(group)) {
                          _preferredMovementGroups.remove(group);
                        } else {
                          _preferredMovementGroups.add(group);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Description (optional)
                  _SectionTitle(title: '설명 (선택)', required: false),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '프로그램에 대한 추가 설명...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Info card about client goals
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.info),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'AI가 클라이언트의 목표와 선호하는 운동 유형에 맞춰 운동을 생성합니다. 목표는 클라이언트 프로필에서 가져옵니다.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Create/Update button
                  ElevatedButton(
                    onPressed: state.isLoading ? null : _createProgram,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.neutralWhite,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.psychology, color: AppColors.neutralWhite),
                              const SizedBox(width: 8),
                              Text(
                                widget.isEditMode ? '프로그램 수정하기' : '프로그램 만들기',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neutralWhite,
                                ),
                              ),
                            ],
                          ),
                  ),

                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Future<void> _createProgram() async {
    debugPrint('🟢 [CREATE] _createProgram called');

    if (_nameController.text.trim().isEmpty) {
      debugPrint('🔴 [CREATE] Name is empty, showing error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로그램 이름을 입력해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Save program preferences directly (no exercise generation)
    final success = await ref.read(programCreationProvider.notifier).saveProgramPreferencesOnly(
      clientId: widget.clientId,
      trainerId: widget.trainerId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      trainingSplit: _trainingSplit,
      focusAreas: _focusAreas.isNotEmpty ? _focusAreas.toList() : null,
      preferredMovementGroups: _preferredMovementGroups.isNotEmpty
          ? _preferredMovementGroups.toList()
          : null,
      existingProgramId: widget.programId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditMode ? '프로그램이 수정되었습니다' : '프로그램이 저장되었습니다'),
          backgroundColor: AppColors.success,
        ),
      );
      // Invalidate providers to refresh data
      ref.invalidate(clientProgramsProvider(widget.clientId));
      ref.invalidate(activeProgramProvider(widget.clientId));
      // Also invalidate exercise recommendations so they reflect new program preferences
      ref.invalidate(exerciseRecommendationsProvider(widget.clientId));
      context.pop();
    }
  }
}

class _ClientInfoCard extends StatelessWidget {
  final String clientName;

  const _ClientInfoCard({required this.clientName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '프로그램 대상',
                style: TextStyle(fontSize: 12, color: AppColors.neutral500),
              ),
              Text(
                clientName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutralBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool required;

  const _SectionTitle({required this.title, required this.required});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}
