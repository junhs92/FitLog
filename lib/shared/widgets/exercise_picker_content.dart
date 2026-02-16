import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../features/active_session/domain/entities/exercise_entity.dart';
import '../../features/active_session/domain/entities/exercise_set_entity.dart';
import '../../features/active_session/domain/services/exercise_recommendation_service.dart';
import '../../features/active_session/presentation/providers/session_provider.dart';
import '../../features/active_session/presentation/providers/exercise_picker_provider.dart';
import 'common/exercise_gif_image.dart';

/// Extracted content widget for exercise picker
/// Can be embedded in dialogs or sheets without its own container/header
/// Uses family-based hierarchical flow: Family → Variation Filter → Final Selection
class ExercisePickerContent extends ConsumerStatefulWidget {
  final String? clientId;
  final void Function(ExerciseEntity exercise) onExerciseSelected;

  const ExercisePickerContent({
    super.key,
    this.clientId,
    required this.onExerciseSelected,
  });

  @override
  ConsumerState<ExercisePickerContent> createState() =>
      _ExercisePickerContentState();
}

class _ExercisePickerContentState extends ConsumerState<ExercisePickerContent> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedExerciseIds = {};

  void _toggleExpanded(String exerciseId) {
    setState(() {
      if (_expandedExerciseIds.contains(exerciseId)) {
        _expandedExerciseIds.clear();
      } else {
        _expandedExerciseIds.clear();
        _expandedExerciseIds.add(exerciseId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Equipment Korean display names
  String _getEquipmentDisplayKo(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'barbell': return '바벨';
      case 'dumbbell': return '덤벨';
      case 'cable': return '케이블';
      case 'machine': return '머신';
      case 'smith_machine': return '스미스 머신';
      case 'bodyweight': return '맨몸';
      case 'kettlebell': return '케틀벨';
      case 'band': return '밴드';
      case 'ez_bar': return 'EZ 바';
      case 'trap_bar': return '트랩 바';
      case 'plate': return '플레이트';
      case 'sled': return '슬레드';
      case 'rope': return '로프';
      case 'bench': return '벤치';
      case 'box': return '박스';
      default: return equipment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickerState = ref.watch(exercisePickerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with back button (when drilled down)
        if (pickerState.step != PickerStep.familySelection && _searchQuery.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.md, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => ref.read(exercisePickerProvider.notifier).goBack(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pickerState.selectedFamilyDisplayName ?? '운동 선택',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: '운동 검색...',
              prefixIcon: const Icon(Icons.search, color: AppColors.neutral400),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.neutral100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1),
        // Content: flat search OR drill-down steps
        Flexible(
          child: _searchQuery.isNotEmpty
              ? _buildFlatSearchList()
              : _buildDrillDownContent(pickerState),
        ),
      ],
    );
  }

  // =============================================================
  // Flat search (when user types in search bar)
  // =============================================================
  Widget _buildFlatSearchList() {
    final exercisesAsync = ref.watch(exerciseLibraryProvider(_searchQuery));

    return exercisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (exercises) {
        if (exercises.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48, color: AppColors.neutral400),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '"$_searchQuery" 검색 결과가 없습니다',
                  style: const TextStyle(color: AppColors.neutral500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          itemCount: exercises.length,
          itemBuilder: (context, index) => _buildExerciseTile(exercises[index]),
        );
      },
    );
  }

  // =============================================================
  // Drill-down content dispatcher
  // =============================================================
  Widget _buildDrillDownContent(ExercisePickerState pickerState) {
    switch (pickerState.step) {
      case PickerStep.familySelection:
        return _buildStep1FamilySelection();
      case PickerStep.variationFilter:
        return _buildStep2VariationFilter(pickerState);
      case PickerStep.finalSelection:
        return _buildStep3FinalSelection(pickerState);
    }
  }

  // =============================================================
  // STEP 1: Family Selection
  // =============================================================
  Widget _buildStep1FamilySelection() {
    final clientId = widget.clientId;

    // If no clientId, show flat exercise list as fallback
    if (clientId == null) {
      return _buildFlatFallback();
    }

    final families = ref.watch(familyScoredListProvider(clientId));
    final contextualRecs = ref.watch(contextualRecommendationsProvider(clientId));

    if (families.isEmpty) {
      // Fallback while loading
      final exercisesAsync = ref.watch(exerciseLibraryProvider(null));
      return exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Separate custom exercises
    final standardFamilies = families.where((f) => !f.isCustom).toList();
    final customFamilies = families.where((f) => f.isCustom).toList();

    // Group contextual rec families at top
    final contextualFamilies = standardFamilies
        .where((f) => f.hasContextualRecommendation)
        .toList();
    final otherFamilies = standardFamilies
        .where((f) => !f.hasContextualRecommendation)
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        // Contextual recommendations section (only shows when session is active)
        if (contextualFamilies.isNotEmpty || contextualRecs.hasComplementary || contextualRecs.hasSupplementary) ...[
          _buildContextualSection(contextualRecs),
        ],

        // All families sorted by score
        if (otherFamilies.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
            child: Text(
              '전체 운동',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral600,
              ),
            ),
          ),
          ...otherFamilies.map((family) => _buildFamilyCard(family)),
        ],

        // Custom exercises section
        if (customFamilies.isNotEmpty) ...[
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
            child: Text(
              '내 운동',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral600,
              ),
            ),
          ),
          ...customFamilies.map((family) => _buildFamilyCard(family)),
        ],
      ],
    );
  }

  /// Fallback flat exercise list when no clientId
  Widget _buildFlatFallback() {
    final exercisesAsync = ref.watch(exerciseLibraryProvider(null));
    return exercisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (exercises) {
        if (exercises.isEmpty) {
          return const Center(child: Text('운동이 없습니다'));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          itemCount: exercises.length,
          itemBuilder: (context, index) => _buildExerciseTile(exercises[index]),
        );
      },
    );
  }

  /// Contextual recommendations section (complementary/supplementary)
  Widget _buildContextualSection(ContextualRecommendationsState contextualRecs) {
    final items = <Widget>[];

    if (contextualRecs.hasComplementary) {
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_forward, size: 14, color: AppColors.neutralWhite),
                    SizedBox(width: 4),
                    Text('바로 이어서 하기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutralWhite)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('현재 운동과 연계', style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
      for (final rec in contextualRecs.complementary.take(3)) {
        items.add(_buildContextualRecTile(rec, AppColors.primary));
      }
    }

    if (contextualRecs.hasSupplementary) {
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.success, AppColors.success.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fitness_center, size: 14, color: AppColors.neutralWhite),
                    SizedBox(width: 4),
                    Text('보조', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutralWhite)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('마무리 운동', style: TextStyle(fontSize: 11, color: AppColors.success.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
      for (final rec in contextualRecs.supplementary.take(3)) {
        items.add(_buildContextualRecTile(rec, AppColors.success));
      }
    }

    if (items.isNotEmpty) {
      items.add(const Divider(height: 16));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _buildContextualRecTile(LabeledRecommendation rec, Color color) {
    final clientId = widget.clientId;
    final isExpanded = _expandedExerciseIds.contains(rec.exercise.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
      child: Material(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Column(
          children: [
            ListTile(
              dense: true,
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.fitness_center, color: color, size: 18),
              ),
              title: Text(rec.exercise.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Row(
                children: [
                  Text(rec.exercise.muscleGroup ?? '', style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(rec.labelText, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.add_circle, color: color, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => widget.onExerciseSelected(rec.exercise),
              ),
              onTap: clientId != null ? () => _toggleExpanded(rec.exercise.id) : () => widget.onExerciseSelected(rec.exercise),
            ),
            _buildInlineHistory(rec.exercise.id, clientId, isExpanded),
          ],
        ),
      ),
    );
  }

  /// Family card for Step 1
  Widget _buildFamilyCard(ScoredFamily family) {
    final isRecommended = family.score > 50;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
      child: Material(
        color: isRecommended
            ? AppColors.success.withValues(alpha: 0.04)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () {
            // Single exercise family: select directly
            if (family.availableCount == 1) {
              final exercises = ref.read(exerciseLibraryProvider(null)).valueOrNull ?? [];
              final exercise = exercises.where(
                (e) => e.family == family.familyKey || e.id == family.familyKey,
              ).firstOrNull;
              if (exercise == null) return;
              widget.onExerciseSelected(exercise);
              return;
            }
            ref.read(exercisePickerProvider.notifier).selectFamily(
              family.familyKey,
              family.displayNameKo,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: isRecommended
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: isRecommended ? AppColors.success : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        family.displayNameKo,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            family.muscleGroup ?? MovementGroup.getDisplayNameKo(family.movementGroup),
                            style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
                          ),
                          if (family.reason.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                family.reason,
                                style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${family.availableCount}개',
                    style: const TextStyle(fontSize: 11, color: AppColors.neutral600, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  family.availableCount == 1 ? Icons.add_circle_outline : Icons.chevron_right,
                  color: AppColors.neutral400,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // STEP 2: Variation Filters
  // =============================================================
  Widget _buildStep2VariationFilter(ExercisePickerState pickerState) {
    final pickerNotifier = ref.read(exercisePickerProvider.notifier);
    final filteredExercises = pickerNotifier.getFilteredExercises();

    final showAngle = pickerNotifier.hasMultipleOptions('angle');
    final showEquipment = pickerNotifier.hasMultipleOptions('equipment');
    final showGrip = pickerNotifier.hasMultipleOptions('grip');

    return Column(
      children: [
        if (showAngle) _buildFilterChipRow(
          label: '각도',
          axis: 'angle',
          selectedValue: pickerState.selectedAngle,
          onSelected: (v) => pickerNotifier.setAngleFilter(v),
          getDisplayName: (v) => ExerciseAngle.getDisplayNameKo(v),
        ),
        if (showEquipment) _buildFilterChipRow(
          label: '장비',
          axis: 'equipment',
          selectedValue: pickerState.selectedEquipment,
          onSelected: (v) => pickerNotifier.setEquipmentFilter(v),
          getDisplayName: (v) => _getEquipmentDisplayKo(v),
        ),
        if (showGrip) _buildFilterChipRow(
          label: '그립',
          axis: 'grip',
          selectedValue: pickerState.selectedGripOrientation,
          onSelected: (v) => pickerNotifier.setGripFilter(v),
          getDisplayName: (v) => GripOrientation.getDisplayNameKo(v),
        ),
        const Divider(height: 1),
        Expanded(
          child: filteredExercises.isEmpty
              ? const Center(child: Text('조건에 맞는 운동이 없습니다', style: TextStyle(color: AppColors.neutral500)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) => _buildExerciseTile(filteredExercises[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChipRow({
    required String label,
    required String axis,
    required String? selectedValue,
    required void Function(String?) onSelected,
    required String Function(String) getDisplayName,
  }) {
    final pickerNotifier = ref.read(exercisePickerProvider.notifier);
    final options = pickerNotifier.getAvailableOptions(axis);

    // Filter out 'na' from display
    final displayOptions = Map.fromEntries(
      options.entries.where((e) => e.key != 'na'),
    );

    if (displayOptions.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutral600),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // "All" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('전체'),
                      selected: selectedValue == null,
                      onSelected: (_) => onSelected(null),
                      backgroundColor: AppColors.neutral100,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: selectedValue == null ? FontWeight.w600 : FontWeight.w400,
                        color: selectedValue == null ? AppColors.primary : AppColors.neutral700,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      visualDensity: VisualDensity.compact,
                      showCheckmark: false,
                    ),
                  ),
                  // Value chips
                  ...displayOptions.entries.map((entry) {
                    final value = entry.key;
                    final isValid = entry.value;
                    final isSelected = selectedValue == value;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Opacity(
                        opacity: isValid ? 1.0 : 0.4,
                        child: FilterChip(
                          label: Text(getDisplayName(value)),
                          selected: isSelected,
                          onSelected: isValid ? (_) => onSelected(isSelected ? null : value) : null,
                          backgroundColor: AppColors.neutral100,
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.primary : AppColors.neutral700,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          visualDensity: VisualDensity.compact,
                          showCheckmark: false,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // STEP 3: Final Selection
  // =============================================================
  Widget _buildStep3FinalSelection(ExercisePickerState pickerState) {
    final pickerNotifier = ref.read(exercisePickerProvider.notifier);
    final exercises = pickerNotifier.getFilteredExercises();

    if (exercises.isEmpty) {
      return const Center(child: Text('선택 가능한 운동이 없습니다', style: TextStyle(color: AppColors.neutral500)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: exercises.length,
      itemBuilder: (context, index) => _buildFinalExerciseCard(exercises[index]),
    );
  }

  Widget _buildFinalExerciseCard(ExerciseEntity exercise) {
    final clientId = widget.clientId;
    final isExpanded = _expandedExerciseIds.contains(exercise.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: clientId != null ? () => _toggleExpanded(exercise.id) : () => widget.onExerciseSelected(exercise),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fitness_center, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.displayName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (exercise.equipment != null)
                                _buildBadge(_getEquipmentDisplayKo(exercise.equipment!), AppColors.neutral500),
                              if (exercise.angle != null && exercise.angle != 'na' && exercise.angle != 'neutral')
                                _buildBadge(ExerciseAngle.getDisplayNameKo(exercise.angle!), AppColors.primary),
                              if (exercise.gripOrientation != null && exercise.gripOrientation != 'na')
                                _buildBadge(GripOrientation.getDisplayNameKo(exercise.gripOrientation!), AppColors.neutral600),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => widget.onExerciseSelected(exercise),
                    ),
                  ],
                ),
                _buildInlineHistory(exercise.id, clientId, isExpanded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Inline expandable history section for exercise cards/tiles
  Widget _buildInlineHistory(String exerciseId, String? clientId, bool isExpanded) {
    if (clientId == null) return const SizedBox.shrink();

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox.shrink(),
      secondChild: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Consumer(builder: (context, ref, _) {
          final historyAsync = ref.watch(
            exercisePickerHistoryProvider((clientId: clientId, exerciseId: exerciseId)),
          );
          return historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('기록을 불러올 수 없습니다', style: TextStyle(fontSize: 12, color: AppColors.neutral500)),
            ),
            data: (data) => _PickerHistoryContent(data: data),
          );
        }),
      ),
    );
  }

  /// Simple exercise list tile used in flat search and step 2
  Widget _buildExerciseTile(ExerciseEntity exercise) {
    final clientId = widget.clientId;
    final isExpanded = _expandedExerciseIds.contains(exercise.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: exercise.hasGif
                ? ExerciseGifThumbnail(
                    imageUrl: exercise.imageUrl,
                    size: 36,
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.fitness_center, color: AppColors.primary, size: 18),
                  ),
            title: Text(exercise.displayName, style: const TextStyle(fontSize: 14)),
            subtitle: Row(
              children: [
                Text(exercise.muscleGroup ?? '', style: const TextStyle(fontSize: 12)),
                if (exercise.equipment != null) ...[
                  const SizedBox(width: 6),
                  Text(_getEquipmentDisplayKo(exercise.equipment!),
                    style: TextStyle(fontSize: 10, color: AppColors.neutral500)),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => widget.onExerciseSelected(exercise),
            ),
            onTap: clientId != null ? () => _toggleExpanded(exercise.id) : () => widget.onExerciseSelected(exercise),
          ),
          _buildInlineHistory(exercise.id, clientId, isExpanded),
        ],
      ),
    );
  }
}

/// Compact multi-session history display for the exercise picker.
/// Visually structured so trainers can scan weight progression at a glance.
class _PickerHistoryContent extends StatelessWidget {
  final ExercisePickerHistoryData data;

  const _PickerHistoryContent({required this.data});

  static const _sessionAccentOpacities = [1.0, 0.55, 0.3];

  @override
  Widget build(BuildContext context) {
    if (!data.hasData) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 15, color: AppColors.neutral400),
            const SizedBox(width: 6),
            const Text(
              '이 운동의 기록이 없습니다',
              style: TextStyle(fontSize: 12, color: AppColors.neutral500),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PR banner
        if (data.pr != null) _buildPrBanner(data.pr!),

        // Recent sessions
        if (data.recentSessions.isNotEmpty) ...[
          if (data.pr != null) const SizedBox(height: 8),
          for (int i = 0; i < data.recentSessions.length; i++)
            _buildSessionBlock(data.recentSessions[i], i),
        ],
      ],
    );
  }

  Widget _buildPrBanner(ExerciseSetEntity pr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.warning.withValues(alpha: 0.15),
          AppColors.warning.withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.emoji_events, size: 15, color: AppColors.warning),
          ),
          const SizedBox(width: 8),
          const Text('PR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.warning)),
          const Spacer(),
          _buildWeightReps(pr, large: true),
        ],
      ),
    );
  }

  Widget _buildSessionBlock(SessionSetsGroup session, int index) {
    final accent = _sessionAccentOpacities[index.clamp(0, 2)];
    final dateStr = _formatDate(session.date);

    return Padding(
      padding: EdgeInsets.only(top: index > 0 ? 2 : 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: accent),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr, style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary.withValues(alpha: accent),
                      letterSpacing: 0.2,
                    )),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: session.sets.take(6).map(_buildSetChip).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetChip(ExerciseSetEntity set) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: _buildWeightReps(set, large: false),
    );
  }

  Widget _buildWeightReps(ExerciseSetEntity set, {required bool large}) {
    final weight = set.weight?.toStringAsFixed(set.weight! % 1 == 0 ? 0 : 1);
    final reps = set.reps;

    if (weight != null && reps != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(weight, style: TextStyle(
            fontSize: large ? 16 : 12,
            fontWeight: FontWeight.w700,
            color: AppColors.neutralBlack,
          )),
          Text('kg', style: TextStyle(
            fontSize: large ? 11 : 9,
            fontWeight: FontWeight.w500,
            color: AppColors.neutral600,
          )),
          Text(large ? ' x $reps회' : ' x$reps', style: TextStyle(
            fontSize: large ? 14 : 11,
            fontWeight: FontWeight.w500,
            color: AppColors.neutral700,
          )),
        ],
      );
    }
    if (weight != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(weight, style: TextStyle(fontSize: large ? 16 : 12, fontWeight: FontWeight.w700, color: AppColors.neutralBlack)),
          Text('kg', style: TextStyle(fontSize: large ? 11 : 9, fontWeight: FontWeight.w500, color: AppColors.neutral600)),
        ],
      );
    }
    if (reps != null) {
      return Text('$reps회', style: TextStyle(fontSize: large ? 16 : 12, fontWeight: FontWeight.w700, color: AppColors.neutralBlack));
    }
    return Text('-', style: TextStyle(fontSize: large ? 16 : 12, color: AppColors.neutral500));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    if (diff < 7) return '$diff일 전';
    return '${date.month}/${date.day}';
  }
}
