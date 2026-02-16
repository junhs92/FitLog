import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/exercise_picker_content.dart';
import '../providers/exercise_picker_provider.dart';
import '../../data/models/session_exercise_input.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/exercise_entity.dart';
import '../providers/session_provider.dart';
import '../../../ai_workout/presentation/providers/ai_workout_provider.dart';
import '../../../ai_workout/domain/entities/workout_program.dart';
import '../../../ai_workout/presentation/widgets/program_form_fields.dart';
import '../../../workout_templates/presentation/widgets/template_selection_content.dart';
import '../../../workout_templates/domain/entities/workout_template_entity.dart';

/// View states for the program selection sheet
enum _SheetView {
  main, // Main selection view
  exercisePicker, // 빈 세션 시작 - exercise selection
  aiProgram, // AI 세션 제작 - program choice/loading
  templates, // 나의 운동 - template list
  sessionReview, // 이전 운동 - previous session details
  programSetup, // Inline program creation/editing
}

/// Bottom sheet for selecting a workout program before starting a session
class ProgramSelectionSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final String trainerId;

  const ProgramSelectionSheet({
    required this.clientId,
    required this.clientName,
    required this.trainerId,
    super.key,
  });

  /// Show appropriate sheet based on client's session history and active program
  ///
  /// For first-time clients with an active program:
  /// - Shows simplified SessionTypeSelectionSheet (3 options)
  ///
  /// For returning clients or clients without active program:
  /// - Shows full ProgramSelectionSheet (4 options)
  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required String clientId,
    required String clientName,
    required String trainerId,
  }) async {
    debugPrint('🟢 [ProgramSelectionSheet] show() called for clientId: $clientId');

    // Check for first session + active program condition
    try {
      final recentSessions = await ref.read(clientRecentSessionsProvider(clientId).future);
      final activeProgram = await ref.read(activeProgramProvider(clientId).future);

      debugPrint('🟢 [ProgramSelectionSheet] recentSessions: ${recentSessions.length}, activeProgram: ${activeProgram?.id}');

      if (recentSessions.isEmpty && activeProgram != null) {
        // First session with active program → show simplified sheet
        debugPrint('🟢 [ProgramSelectionSheet] First session + active program → SessionTypeSelectionSheet');
        if (!context.mounted) return;
        return SessionTypeSelectionSheet.show(
          context: context,
          ref: ref,
          clientId: clientId,
          clientName: clientName,
          trainerId: trainerId,
          activeProgram: activeProgram,
        );
      }
    } catch (e) {
      debugPrint('🟡 [ProgramSelectionSheet] Error checking conditions: $e - falling back to full sheet');
    }

    // Default: show full sheet
    if (!context.mounted) return;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgramSelectionSheet(
        clientId: clientId,
        clientName: clientName,
        trainerId: trainerId,
      ),
    );
  }

  @override
  ConsumerState<ProgramSelectionSheet> createState() => _ProgramSelectionSheetState();
}

class _ProgramSelectionSheetState extends ConsumerState<ProgramSelectionSheet> {
  _SheetView _currentView = _SheetView.main;
  SessionEntity? _selectedPreviousSession;
  WorkoutProgramEntity? _activeProgram;
  bool _isLoadingAI = false;
  bool _isCheckingProgram = true;

  // Program setup form state
  final _programNameController = TextEditingController();
  final _programDescriptionController = TextEditingController();
  TrainingSplit _programTrainingSplit = TrainingSplit.fullBody;
  final Set<String> _programFocusAreas = {};
  final Set<String> _programPreferredMovementGroups = {};
  bool _isProgramSaving = false;
  String? _editingProgramId; // null = create, non-null = edit

  @override
  void initState() {
    super.initState();
    // Check for active program immediately when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndInitializeProgram();
    });
  }

  @override
  void dispose() {
    _programNameController.dispose();
    _programDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkAndInitializeProgram() async {
    final repository = ref.read(aiWorkoutRepositoryProvider);
    debugPrint('🟢 [ProgramSelectionSheet] Checking active program on modal open');
    final activeProgram = await checkActiveProgram(repository, widget.clientId);

    if (!mounted) return;

    if (activeProgram == null) {
      // No active program - start on program setup view
      debugPrint('🟡 [ProgramSelectionSheet] No active program - showing inline setup');
      _initializeProgramForm(null);
      setState(() {
        _isCheckingProgram = false;
        _currentView = _SheetView.programSetup;
      });
    } else {
      // Has active program - store it and show main view
      debugPrint('🟢 [ProgramSelectionSheet] Active program found: ${activeProgram.id}');
      setState(() {
        _activeProgram = activeProgram;
        _isCheckingProgram = false;
      });
    }
  }

  void _initializeProgramForm(WorkoutProgramEntity? program) {
    if (program != null) {
      // Edit mode
      _editingProgramId = program.id;
      _programNameController.text = program.name;
      _programDescriptionController.text = program.description ?? '';
      _programTrainingSplit = program.trainingSplit;
      _programFocusAreas..clear()..addAll(program.focusAreas);
      _programPreferredMovementGroups..clear()..addAll(program.preferredMovementGroups);
    } else {
      // Create mode
      _editingProgramId = null;
      _programNameController.text = '${widget.clientName}의 프로그램';
      _programDescriptionController.clear();
      _programTrainingSplit = TrainingSplit.fullBody;
      _programFocusAreas.clear();
      _programPreferredMovementGroups.clear();
    }
  }

  void _switchToEditProgram(WorkoutProgramEntity program) {
    _initializeProgramForm(program);
    setState(() => _currentView = _SheetView.programSetup);
  }

  @override
  Widget build(BuildContext context) {
    final recentSessionsAsync = ref.watch(clientRecentSessionsProvider(widget.clientId));
    final activeProgramAsync = ref.watch(activeProgramProvider(widget.clientId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _isCheckingProgram
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 60),
                Center(child: CircularProgressIndicator()),
                SizedBox(height: 16),
                Text('프로그램 확인 중...'),
                SizedBox(height: 60),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHandleBar(),
                _buildHeader(activeProgramAsync),
                const Divider(height: 1),
                Flexible(
                  child: _buildContent(recentSessionsAsync, activeProgramAsync),
                ),
              ],
            ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.neutral300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<WorkoutProgramEntity?> activeProgramAsync) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Back button (only when not on main view)
          if (_currentView != _SheetView.main) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: _goBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: AppColors.neutral700,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: _currentView == _SheetView.main
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
                // Program goal badge (only on main view)
                if (_currentView == _SheetView.main) ...[
                  activeProgramAsync.when(
                    data: (program) => program != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildProgramBadge(program),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.clientName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Close button (only on sub-views)
          if (_currentView != _SheetView.main)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              color: AppColors.neutral500,
            ),
        ],
      ),
    );
  }

  Widget _buildProgramBadge(WorkoutProgramEntity program) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _switchToEditProgram(program),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.flag,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                program.focusAreas.isNotEmpty
                    ? '집중: ${program.focusAreas.take(2).join(', ')}'
                    : '분할: ${program.trainingSplit.displayName}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.edit,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goBack() {
    if (_currentView == _SheetView.programSetup) {
      if (_editingProgramId != null) {
        // Was editing existing program → return to main
        setState(() => _currentView = _SheetView.main);
      } else {
        // Was creating new program (no program exists) → close modal
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _currentView = _SheetView.main;
        _selectedPreviousSession = null;
        _isLoadingAI = false;
      });
    }
  }

  String _getTitle() {
    switch (_currentView) {
      case _SheetView.main:
        return '세션 시작';
      case _SheetView.exercisePicker:
        return '운동 선택';
      case _SheetView.aiProgram:
        return 'AI 세션';
      case _SheetView.templates:
        return '나의 운동';
      case _SheetView.sessionReview:
        return '이전 운동';
      case _SheetView.programSetup:
        return _editingProgramId != null ? '프로그램 수정' : '프로그램 만들기';
    }
  }

  Widget _buildContent(
    AsyncValue<List<SessionEntity>> recentSessionsAsync,
    AsyncValue<WorkoutProgramEntity?> activeProgramAsync,
  ) {
    switch (_currentView) {
      case _SheetView.main:
        return _buildMainSelection(recentSessionsAsync, activeProgramAsync);
      case _SheetView.exercisePicker:
        return _buildExercisePickerView();
      case _SheetView.aiProgram:
        return _buildAIProgramView();
      case _SheetView.templates:
        return _buildTemplatesView();
      case _SheetView.sessionReview:
        return _buildSessionReviewView();
      case _SheetView.programSetup:
        return _buildProgramSetupView();
    }
  }

  // ==================== Main Selection View ====================

  Widget _buildMainSelection(
    AsyncValue<List<SessionEntity>> recentSessionsAsync,
    AsyncValue<WorkoutProgramEntity?> activeProgramAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Empty session
          _QuickActionCard(
            icon: Icons.flash_on,
            title: '빈 세션 시작',
            subtitle: '운동을 직접 추가하며 진행',
            color: AppColors.secondary,
            onTap: () {
              ref.read(exercisePickerProvider.notifier).reset();
              setState(() => _currentView = _SheetView.exercisePicker);
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // 2. AI session creation
          _QuickActionCard(
            icon: Icons.auto_awesome,
            title: 'AI 세션 제작',
            subtitle: 'AI가 맞춤 운동을 생성합니다',
            color: AppColors.primary,
            onTap: () => _handleAISessionTap(),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 3. My workout templates
          _QuickActionCard(
            icon: Icons.bookmark,
            title: '나의 운동',
            subtitle: '저장된 운동 템플릿에서 선택',
            color: AppColors.warning,
            onTap: () => setState(() => _currentView = _SheetView.templates),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. Previous sessions section
          const Text(
            '이전 운동',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralBlack,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '이전 세션의 운동을 복사하여 시작합니다',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          recentSessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Center(
                    child: Text(
                      '이전 세션이 없습니다',
                      style: TextStyle(color: AppColors.neutral500),
                    ),
                  ),
                );
              }

              return Column(
                children: sessions
                    .map((session) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _PreviousSessionCard(
                            session: session,
                            onTap: () {
                              setState(() {
                                _selectedPreviousSession = session;
                                _currentView = _SheetView.sessionReview;
                              });
                            },
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Text(
                '이전 세션을 불러오는데 실패했습니다',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Exercise Picker View ====================

  Widget _buildExercisePickerView() {
    return ExercisePickerContent(
      clientId: widget.clientId,
      onExerciseSelected: (exercise) => _startSessionWithExercise(exercise),
    );
  }

  Future<void> _startSessionWithExercise(ExerciseEntity exercise) async {
    debugPrint('🟢 Exercise selected: ${exercise.displayName}');

    // Capture refs BEFORE closing bottom sheet
    final sessionNotifier = ref.read(activeSessionProvider.notifier);
    final router = GoRouter.of(context);

    // Close popup
    Navigator.pop(context);

    // Create session with selected exercise
    final exerciseInput = SessionExerciseInput(
      exerciseId: exercise.id,
      name: exercise.name,
      orderIndex: 0,
      targetSets: 3,
    );

    final result = await sessionNotifier.createSession(
      clientId: widget.clientId,
      exercises: [exerciseInput],
    );

    result.fold(
      (failure) {
        debugPrint('🔴 Session creation failed: ${failure.message}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      (session) {
        debugPrint('🟢 Session created: ${session.id}');
        final route = '/trainer/session/${widget.clientId}?name=${Uri.encodeComponent(widget.clientName)}';
        router.push(route);
      },
    );
  }

  // ==================== AI Program View ====================

  Future<void> _handleAISessionTap() async {
    // Program already checked at modal open
    if (_activeProgram != null) {
      setState(() => _currentView = _SheetView.aiProgram);
    } else {
      // Should not happen as we show programSetup if no program, but handle gracefully
      _initializeProgramForm(null);
      setState(() => _currentView = _SheetView.programSetup);
    }
  }

  Widget _buildAIProgramView() {
    if (_isLoadingAI) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.md),
              Text('프로그램 확인 중...'),
            ],
          ),
        ),
      );
    }

    if (_activeProgram != null) {
      return _buildProgramChoiceContent(_activeProgram!);
    }

    // No program - show message (shouldn't happen as we navigate away)
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text('프로그램을 찾을 수 없습니다'),
      ),
    );
  }

  Widget _buildProgramChoiceContent(WorkoutProgramEntity activeProgram) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Program info card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '활성 프로그램 발견',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neutralBlack,
                            ),
                          ),
                          Text(
                            activeProgram.name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Program details
                _buildProgramDetail(
                  '분할',
                  activeProgram.trainingSplit.displayName,
                ),
                if (activeProgram.focusAreas.isNotEmpty)
                  _buildProgramDetail(
                    '집중 부위',
                    activeProgram.focusAreas.join(', '),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const Text(
            '어떻게 진행하시겠습니까?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.neutralBlack,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Keep current program button
          ElevatedButton.icon(
            onPressed: () => _startSessionWithActiveProgram(activeProgram),
            icon: const Icon(Icons.play_arrow),
            label: const Text('현재 프로그램으로 시작'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Edit program button
          OutlinedButton.icon(
            onPressed: () => _navigateToEditProgram(activeProgram),
            icon: const Icon(Icons.edit),
            label: const Text('목표 변경'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.neutral600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.neutralBlack,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToNewProgram() {
    final router = GoRouter.of(context);
    final route = '/trainer/program/generate/${widget.clientId}?name=${Uri.encodeComponent(widget.clientName)}&trainerId=${widget.trainerId}';
    debugPrint('🟢 Route: $route');

    Navigator.pop(context);
    router.push(route);
  }

  void _navigateToEditProgram(WorkoutProgramEntity program) {
    final router = GoRouter.of(context);
    final route = '/trainer/program/edit/${program.id}?clientId=${widget.clientId}&name=${Uri.encodeComponent(widget.clientName)}&trainerId=${widget.trainerId}';
    debugPrint('🟢 [EDIT] Route: $route');

    Navigator.pop(context);
    router.push(route);
  }

  Future<void> _startSessionWithActiveProgram(WorkoutProgramEntity activeProgram) async {
    debugPrint('🟢 _startSessionWithActiveProgram: Starting (LLM-Based)');
    debugPrint('🟢 Program: ${activeProgram.id}, Split: ${activeProgram.trainingSplit.id}');

    // Capture refs and navigator BEFORE any async operations
    final router = GoRouter.of(context);
    final rootNav = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(aiWorkoutRepositoryProvider);

    // Close bottom sheet FIRST
    Navigator.pop(context);

    // Show loading dialog using root navigator
    showDialog<void>(
      context: rootNav.context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSpacing.md),
                Text('AI가 운동을 생성 중...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Generate exercises using LLM edge function
      debugPrint('🟢 Generating exercises using LLM...');
      final result = await repository.generateExercisesForProgram(
        clientId: widget.clientId,
        programId: activeProgram.id,
        trainerId: widget.trainerId,
        trainingSplit: activeProgram.trainingSplit,
        focusAreas: activeProgram.focusAreas,
        preferredMovementGroups: activeProgram.preferredMovementGroups,
      );

      result.fold(
        (failure) {
          debugPrint('🔴 LLM generation failed: ${failure.message}');
          rootNav.pop(); // Close loading dialog
          messenger.showSnackBar(
            SnackBar(
              content: Text('운동 생성 실패: ${failure.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        },
        (sessionData) {
          debugPrint('🟢 Generated ${sessionData.exercises.length} exercises via LLM');
          debugPrint('🟢 Session description: ${sessionData.sessionDescriptionKo ?? sessionData.sessionDescription}');

          // Close loading dialog
          rootNav.pop();
          debugPrint('🟢 Loading dialog closed');

          // Navigate to review screen to show exercises
          final route = '/trainer/ai-exercises/review/${widget.clientId}?name=${Uri.encodeComponent(widget.clientName)}&programId=${activeProgram.id}&sessionId=';
          debugPrint('🟢 Navigating to review: $route');
          router.push(route, extra: sessionData);
        },
      );
    } catch (e, stackTrace) {
      debugPrint('🔴 ERROR: $e');
      debugPrint('🔴 STACK: $stackTrace');
      rootNav.pop(); // Close loading dialog
      messenger.showSnackBar(
        SnackBar(
          content: Text('오류: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ==================== Templates View ====================

  Widget _buildTemplatesView() {
    return TemplateSelectionContent(
      clientId: widget.clientId,
      clientName: widget.clientName,
      showManageButton: false,
      onTemplateSelected: (template) => _startSessionWithTemplate(template),
    );
  }

  void _startSessionWithTemplate(WorkoutTemplateEntity template) {
    Navigator.pop(context);
    // Navigate to template review screen
    context.push(
      '/trainer/templates/review/${widget.clientId}?name=${Uri.encodeComponent(widget.clientName)}',
      extra: template,
    );
  }

  // ==================== Session Review View ====================

  Widget _buildSessionReviewView() {
    final session = _selectedPreviousSession;
    if (session == null) {
      return const Center(
        child: Text('세션 정보를 찾을 수 없습니다'),
      );
    }

    return Column(
      children: [
        // Session info header
        Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.displayDate(session.completedAt ?? session.createdAt),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    Text(
                      '${session.exercises.length}개 운동',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Exercise list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: session.exercises.length,
            itemBuilder: (context, index) {
              final sessionExercise = session.exercises[index];
              final setCount = sessionExercise.sets.length;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  sessionExercise.exercise.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutralBlack,
                  ),
                ),
                subtitle: Text(
                  '$setCount세트',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                ),
              );
            },
          ),
        ),

        // Start button
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startSessionFromPrevious(session),
              icon: const Icon(Icons.play_arrow),
              label: const Text('이 운동으로 시작'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startSessionFromPrevious(SessionEntity previousSession) {
    debugPrint('🟢 Navigating to review: ${previousSession.exercises.length} exercises');

    // Close bottom sheet
    Navigator.pop(context);

    // Navigate to review screen with session data
    final route = '/trainer/session/review/${widget.clientId}?name=${Uri.encodeComponent(widget.clientName)}';
    context.push(route, extra: previousSession);
  }

  // ==================== Program Setup View ====================

  Widget _buildProgramSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Program name
          _buildSectionTitle('프로그램 이름', required: true),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _programNameController,
            decoration: InputDecoration(
              hintText: '예: 근력 향상 프로그램',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Training Split
          _buildSectionTitle('훈련 분할', required: true),
          const SizedBox(height: AppSpacing.sm),
          ProgramSplitSelector(
            selectedSplit: _programTrainingSplit,
            onSplitSelected: (split) {
              setState(() => _programTrainingSplit = split);
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Focus areas (optional)
          _buildSectionTitle('집중 부위', required: false),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '선택한 부위의 운동이 추가로 추천됩니다',
            style: TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgramFocusAreaSelector(
            selectedAreas: _programFocusAreas,
            onAreaToggled: (area) {
              setState(() {
                if (_programFocusAreas.contains(area)) {
                  _programFocusAreas.remove(area);
                } else {
                  _programFocusAreas.add(area);
                }
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Movement group preferences (optional)
          _buildSectionTitle('선호하는 운동 유형', required: false),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'AI가 이 유형의 운동을 우선적으로 선택합니다',
            style: TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgramMovementGroupSelectorCompact(
            selectedGroups: _programPreferredMovementGroups,
            onGroupToggled: (group) {
              setState(() {
                if (_programPreferredMovementGroups.contains(group)) {
                  _programPreferredMovementGroups.remove(group);
                } else {
                  _programPreferredMovementGroups.add(group);
                }
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Description (optional)
          _buildSectionTitle('설명', required: false),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _programDescriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: '프로그램에 대한 추가 설명...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Save button
          ElevatedButton(
            onPressed: _isProgramSaving ? null : _saveProgram,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProgramSaving
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
                      const Icon(Icons.save, color: AppColors.neutralWhite),
                      const SizedBox(width: 8),
                      Text(
                        _editingProgramId != null ? '프로그램 수정하기' : '프로그램 저장하기',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutralWhite,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required bool required}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
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

  Future<void> _saveProgram() async {
    if (_programNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로그램 이름을 입력해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProgramSaving = true);

    try {
      final success = await ref.read(programCreationProvider.notifier).saveProgramPreferencesOnly(
        clientId: widget.clientId,
        trainerId: widget.trainerId,
        name: _programNameController.text.trim(),
        description: _programDescriptionController.text.trim().isEmpty
            ? null
            : _programDescriptionController.text.trim(),
        trainingSplit: _programTrainingSplit,
        focusAreas: _programFocusAreas.isNotEmpty ? _programFocusAreas.toList() : null,
        preferredMovementGroups: _programPreferredMovementGroups.isNotEmpty
            ? _programPreferredMovementGroups.toList()
            : null,
        existingProgramId: _editingProgramId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingProgramId != null ? '프로그램이 수정되었습니다' : '프로그램이 저장되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );

        // Invalidate providers to refresh data
        ref.invalidate(activeProgramProvider(widget.clientId));

        // Reload active program and switch to main view
        final repository = ref.read(aiWorkoutRepositoryProvider);
        final newProgram = await checkActiveProgram(repository, widget.clientId);

        if (mounted) {
          setState(() {
            _activeProgram = newProgram;
            _currentView = _SheetView.main;
            _isProgramSaving = false;
          });
        }
      } else if (mounted) {
        setState(() => _isProgramSaving = false);
      }
    } catch (e) {
      debugPrint('🔴 Error saving program: $e');
      if (mounted) {
        setState(() => _isProgramSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로그램 저장 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Simplified bottom sheet for first-time clients with an active program
///
/// Shows 3 options:
/// 1. AI 세션 - Uses active program to generate exercises
/// 2. 빈 세션 - Empty session with manual exercise selection
/// 3. 나의 운동 - Select from saved templates
class SessionTypeSelectionSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final String trainerId;
  final WorkoutProgramEntity activeProgram;
  final WidgetRef ref;

  const SessionTypeSelectionSheet({
    required this.clientId,
    required this.clientName,
    required this.trainerId,
    required this.activeProgram,
    required this.ref,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required String clientId,
    required String clientName,
    required String trainerId,
    required WorkoutProgramEntity activeProgram,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SessionTypeSelectionSheet(
        clientId: clientId,
        clientName: clientName,
        trainerId: trainerId,
        activeProgram: activeProgram,
        ref: ref,
      ),
    );
  }

  @override
  ConsumerState<SessionTypeSelectionSheet> createState() =>
      _SessionTypeSelectionSheetState();
}

class _SessionTypeSelectionSheetState
    extends ConsumerState<SessionTypeSelectionSheet> {
  _SheetView _currentView = _SheetView.main;
  WorkoutProgramEntity? _activeProgram;

  // Program setup form state
  final _programNameController = TextEditingController();
  final _programDescriptionController = TextEditingController();
  TrainingSplit _programTrainingSplit = TrainingSplit.fullBody;
  final Set<String> _programFocusAreas = {};
  final Set<String> _programPreferredMovementGroups = {};
  bool _isProgramSaving = false;
  String? _editingProgramId; // null = create, non-null = edit

  @override
  void initState() {
    super.initState();
    _activeProgram = widget.activeProgram;
  }

  @override
  void dispose() {
    _programNameController.dispose();
    _programDescriptionController.dispose();
    super.dispose();
  }

  void _initializeProgramForm(WorkoutProgramEntity? program) {
    if (program != null) {
      // Edit mode
      _editingProgramId = program.id;
      _programNameController.text = program.name;
      _programDescriptionController.text = program.description ?? '';
      _programTrainingSplit = program.trainingSplit;
      _programFocusAreas..clear()..addAll(program.focusAreas);
      _programPreferredMovementGroups..clear()..addAll(program.preferredMovementGroups);
    } else {
      // Create mode
      _editingProgramId = null;
      _programNameController.text = '${widget.clientName}의 프로그램';
      _programDescriptionController.clear();
      _programTrainingSplit = TrainingSplit.fullBody;
      _programFocusAreas.clear();
      _programPreferredMovementGroups.clear();
    }
  }

  void _switchToEditProgram(WorkoutProgramEntity program) {
    _initializeProgramForm(program);
    setState(() => _currentView = _SheetView.programSetup);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandleBar(),
          _buildHeader(),
          const Divider(height: 1),
          Flexible(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.neutral300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Back button (only when not on main view)
          if (_currentView != _SheetView.main) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: _goBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: AppColors.neutral700,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: _currentView == _SheetView.main
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
                if (_currentView == _SheetView.main) ...[
                  // Program goal badge (tappable to edit)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildProgramBadge(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.clientName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Close button (only on sub-views)
          if (_currentView != _SheetView.main)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              color: AppColors.neutral500,
            ),
        ],
      ),
    );
  }

  Widget _buildProgramBadge() {
    final program = _activeProgram ?? widget.activeProgram;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _switchToEditProgram(program),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.flag,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                program.focusAreas.isNotEmpty
                    ? '집중: ${program.focusAreas.take(2).join(', ')}'
                    : '분할: ${program.trainingSplit.displayName}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.edit,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goBack() {
    if (_currentView == _SheetView.programSetup) {
      // Always return to main view since this sheet requires an active program
      setState(() => _currentView = _SheetView.main);
    } else {
      setState(() => _currentView = _SheetView.main);
    }
  }

  String _getTitle() {
    switch (_currentView) {
      case _SheetView.main:
        return '첫 세션 시작';
      case _SheetView.exercisePicker:
        return '운동 선택';
      case _SheetView.templates:
        return '나의 운동';
      case _SheetView.programSetup:
        return '프로그램 수정';
      default:
        return '세션 시작';
    }
  }

  Widget _buildContent() {
    switch (_currentView) {
      case _SheetView.main:
        return _buildMainSelection();
      case _SheetView.exercisePicker:
        return _buildExercisePickerView();
      case _SheetView.templates:
        return _buildTemplatesView();
      case _SheetView.programSetup:
        return _buildProgramSetupView();
      default:
        return _buildMainSelection();
    }
  }

  Widget _buildMainSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. AI Session (uses active program)
          _QuickActionCard(
            icon: Icons.auto_awesome,
            title: 'AI 세션',
            subtitle: '프로그램 기반 맞춤 운동 생성',
            color: AppColors.primary,
            onTap: () => _startSessionWithActiveProgram(),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 2. Empty session
          _QuickActionCard(
            icon: Icons.flash_on,
            title: '빈 세션',
            subtitle: '운동을 직접 추가하며 진행',
            color: AppColors.secondary,
            onTap: () {
              ref.read(exercisePickerProvider.notifier).reset();
              setState(() => _currentView = _SheetView.exercisePicker);
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // 3. My workout templates
          _QuickActionCard(
            icon: Icons.bookmark,
            title: '나의 운동',
            subtitle: '저장된 운동 템플릿에서 선택',
            color: AppColors.warning,
            onTap: () => setState(() => _currentView = _SheetView.templates),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildExercisePickerView() {
    return ExercisePickerContent(
      clientId: widget.clientId,
      onExerciseSelected: (exercise) => _startEmptySessionWithExercise(exercise),
    );
  }

  Widget _buildTemplatesView() {
    return TemplateSelectionContent(
      clientId: widget.clientId,
      clientName: widget.clientName,
      showManageButton: false,
      onTemplateSelected: (template) => _startSessionWithTemplate(template),
    );
  }

  Future<void> _startSessionWithActiveProgram() async {
    debugPrint('🟢 [SessionTypeSelectionSheet] _startSessionWithActiveProgram (LLM-Based)');

    // Capture refs and navigator BEFORE any async operations
    final router = GoRouter.of(context);
    final rootNav = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final repository = widget.ref.read(aiWorkoutRepositoryProvider);

    // Close bottom sheet FIRST
    Navigator.pop(context);

    // Show loading dialog using root navigator
    showDialog<void>(
      context: rootNav.context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSpacing.md),
                Text('AI가 운동을 생성 중...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Generate exercises using LLM edge function
      debugPrint('🟢 Generating exercises using LLM...');
      final result = await repository.generateExercisesForProgram(
        clientId: widget.clientId,
        programId: widget.activeProgram.id,
        trainerId: widget.trainerId,
        trainingSplit: widget.activeProgram.trainingSplit,
        focusAreas: widget.activeProgram.focusAreas,
        preferredMovementGroups: widget.activeProgram.preferredMovementGroups,
      );

      result.fold(
        (failure) {
          debugPrint('🔴 LLM generation failed: ${failure.message}');
          rootNav.pop(); // Close loading dialog
          messenger.showSnackBar(
            SnackBar(
              content: Text('운동 생성 실패: ${failure.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        },
        (sessionData) {
          debugPrint('🟢 Generated ${sessionData.exercises.length} exercises via LLM');
          debugPrint('🟢 Session description: ${sessionData.sessionDescriptionKo ?? sessionData.sessionDescription}');

          // Close loading dialog
          rootNav.pop();

          // Navigate to review screen
          final route = '/trainer/ai-exercises/review/${widget.clientId}?name=${Uri.encodeComponent(widget.clientName)}&programId=${widget.activeProgram.id}&sessionId=';
          debugPrint('🟢 Navigating to review: $route');
          router.push(route, extra: sessionData);
        },
      );
    } catch (e, stackTrace) {
      debugPrint('🔴 ERROR: $e');
      debugPrint('🔴 STACK: $stackTrace');
      rootNav.pop(); // Close loading dialog
      messenger.showSnackBar(
        SnackBar(
          content: Text('오류: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _startEmptySessionWithExercise(ExerciseEntity exercise) async {
    debugPrint('🟢 [SessionTypeSelectionSheet] _startEmptySession');

    // Capture refs BEFORE closing bottom sheet
    final sessionNotifier = widget.ref.read(activeSessionProvider.notifier);
    final router = GoRouter.of(context);

    // Close sheet
    Navigator.pop(context);

    debugPrint('🟢 Exercise selected: ${exercise.displayName}');

    // Create session with selected exercise
    final exerciseInput = SessionExerciseInput(
      exerciseId: exercise.id,
      name: exercise.name,
      orderIndex: 0,
      targetSets: 3,
    );

    final result = await sessionNotifier.createSession(
      clientId: widget.clientId,
      exercises: [exerciseInput],
    );

    result.fold(
      (failure) {
        debugPrint('🔴 Session creation failed: ${failure.message}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      (session) {
        debugPrint('🟢 Session created: ${session.id}');
        final route = '/trainer/session/${widget.clientId}?name=${Uri.encodeComponent(widget.clientName)}';
        router.push(route);
      },
    );
  }

  void _startSessionWithTemplate(WorkoutTemplateEntity template) {
    Navigator.pop(context);
    // Navigate to template review screen
    context.push(
      '/trainer/templates/review/${widget.clientId}?name=${Uri.encodeComponent(widget.clientName)}',
      extra: template,
    );
  }

  // ==================== Program Setup View ====================

  Widget _buildProgramSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Program name
          _buildSectionTitle('프로그램 이름', required: true),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _programNameController,
            decoration: InputDecoration(
              hintText: '예: 근력 향상 프로그램',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Training Split
          _buildSectionTitle('훈련 분할', required: true),
          const SizedBox(height: AppSpacing.sm),
          ProgramSplitSelector(
            selectedSplit: _programTrainingSplit,
            onSplitSelected: (split) {
              setState(() => _programTrainingSplit = split);
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Focus areas (optional)
          _buildSectionTitle('집중 부위', required: false),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '선택한 부위의 운동이 추가로 추천됩니다',
            style: TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgramFocusAreaSelector(
            selectedAreas: _programFocusAreas,
            onAreaToggled: (area) {
              setState(() {
                if (_programFocusAreas.contains(area)) {
                  _programFocusAreas.remove(area);
                } else {
                  _programFocusAreas.add(area);
                }
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Movement group preferences (optional)
          _buildSectionTitle('선호하는 운동 유형', required: false),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'AI가 이 유형의 운동을 우선적으로 선택합니다',
            style: TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgramMovementGroupSelectorCompact(
            selectedGroups: _programPreferredMovementGroups,
            onGroupToggled: (group) {
              setState(() {
                if (_programPreferredMovementGroups.contains(group)) {
                  _programPreferredMovementGroups.remove(group);
                } else {
                  _programPreferredMovementGroups.add(group);
                }
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Description (optional)
          _buildSectionTitle('설명', required: false),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _programDescriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: '프로그램에 대한 추가 설명...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Save button
          ElevatedButton(
            onPressed: _isProgramSaving ? null : _saveProgram,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProgramSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.neutralWhite,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, color: AppColors.neutralWhite),
                      SizedBox(width: 8),
                      Text(
                        '프로그램 수정하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutralWhite,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required bool required}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
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

  Future<void> _saveProgram() async {
    if (_programNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로그램 이름을 입력해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProgramSaving = true);

    try {
      final success = await ref.read(programCreationProvider.notifier).saveProgramPreferencesOnly(
        clientId: widget.clientId,
        trainerId: widget.trainerId,
        name: _programNameController.text.trim(),
        description: _programDescriptionController.text.trim().isEmpty
            ? null
            : _programDescriptionController.text.trim(),
        trainingSplit: _programTrainingSplit,
        focusAreas: _programFocusAreas.isNotEmpty ? _programFocusAreas.toList() : null,
        preferredMovementGroups: _programPreferredMovementGroups.isNotEmpty
            ? _programPreferredMovementGroups.toList()
            : null,
        existingProgramId: _editingProgramId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로그램이 수정되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );

        // Invalidate providers to refresh data
        ref.invalidate(activeProgramProvider(widget.clientId));

        // Reload active program and switch to main view
        final repository = ref.read(aiWorkoutRepositoryProvider);
        final newProgram = await checkActiveProgram(repository, widget.clientId);

        if (mounted) {
          setState(() {
            _activeProgram = newProgram;
            _currentView = _SheetView.main;
            _isProgramSaving = false;
          });
        }
      } else if (mounted) {
        setState(() => _isProgramSaving = false);
      }
    } catch (e) {
      debugPrint('🔴 Error saving program: $e');
      if (mounted) {
        setState(() => _isProgramSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로그램 저장 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviousSessionCard extends StatelessWidget {
  final SessionEntity session;
  final VoidCallback onTap;

  const _PreviousSessionCard({
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseNames = session.exercises
        .take(3)
        .map((e) => e.exercise.displayName)
        .join(', ');
    final remainingCount = session.exercises.length - 3;

    return Card(
      elevation: 0,
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.neutral200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.history,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.displayDate(session.completedAt ?? session.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.exercises.length}개 운동',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remainingCount > 0
                          ? '$exerciseNames 외 $remainingCount개'
                          : exerciseNames,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.neutral400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
