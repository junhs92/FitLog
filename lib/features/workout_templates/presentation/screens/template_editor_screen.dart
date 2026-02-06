import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/exercise_picker_dialog.dart';
import '../providers/workout_template_provider.dart';

/// Screen for creating and editing workout templates
class TemplateEditorScreen extends ConsumerStatefulWidget {
  final String? templateId;

  const TemplateEditorScreen({
    this.templateId,
    super.key,
  });

  @override
  ConsumerState<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedFocusArea;
  int? _estimatedDuration;
  List<_TemplateExerciseItem> _exercises = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  bool get isEditMode => widget.templateId != null;

  static const List<Map<String, String>> _focusAreaOptions = [
    {'value': 'chest', 'label': '가슴'},
    {'value': 'back', 'label': '등'},
    {'value': 'shoulders', 'label': '어깨'},
    {'value': 'arms', 'label': '팔'},
    {'value': 'legs', 'label': '하체'},
    {'value': 'core', 'label': '코어'},
    {'value': 'full_body', 'label': '전신'},
    {'value': 'upper', 'label': '상체'},
    {'value': 'lower', 'label': '하체'},
    {'value': 'push', 'label': '밀기'},
    {'value': 'pull', 'label': '당기기'},
  ];

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadTemplate();
    }
  }

  Future<void> _loadTemplate() async {
    if (_isInitialized) return;

    setState(() => _isLoading = true);

    final templateAsync = await ref.read(templateByIdProvider(widget.templateId!).future);

    if (templateAsync != null && mounted) {
      setState(() {
        _nameController.text = templateAsync.name;
        _descriptionController.text = templateAsync.description ?? '';
        _selectedFocusArea = templateAsync.focusArea;
        _estimatedDuration = templateAsync.estimatedDurationMinutes;
        _exercises = templateAsync.exercises.map((e) => _TemplateExerciseItem(
          exerciseId: e.exerciseId,
          exerciseName: e.exercise?.displayName ?? 'Unknown',
          targetSets: e.targetSets,
          targetReps: e.targetReps,
          targetWeight: e.targetWeight,
          targetRpe: e.targetRpe,
          restSeconds: e.restSeconds,
          notes: e.notes,
        )).toList();
        _isLoading = false;
        _isInitialized = true;
      });
    } else {
      setState(() => _isLoading = false);
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
    final mutationState = ref.watch(templateMutationProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(isEditMode ? '템플릿 수정' : '새 템플릿'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutralBlack,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          TextButton(
            onPressed: mutationState.isLoading ? null : _saveTemplate,
            child: Text(
              '저장',
              style: TextStyle(
                color: mutationState.isLoading
                    ? AppColors.neutral400
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Template name
                  _buildSectionTitle('템플릿 이름 *'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('예: 가슴/삼두 루틴'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '템플릿 이름을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Description
                  _buildSectionTitle('설명'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: _inputDecoration('템플릿에 대한 간단한 설명'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Focus area
                  _buildSectionTitle('운동 부위'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildFocusAreaSelector(),
                  const SizedBox(height: AppSpacing.lg),

                  // Estimated duration
                  _buildSectionTitle('예상 시간 (분)'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDurationSelector(),
                  const SizedBox(height: AppSpacing.lg),

                  // Exercises
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('운동 목록'),
                      TextButton.icon(
                        onPressed: _addExercise,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('운동 추가'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildExerciseList(),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.neutral700,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.neutral400),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.neutral200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.neutral200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    );
  }

  Widget _buildFocusAreaSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _focusAreaOptions.map((option) {
        final isSelected = _selectedFocusArea == option['value'];
        return FilterChip(
          label: Text(option['label']!),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedFocusArea = selected ? option['value'] : null;
            });
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.neutral200,
          ),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.neutral700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDurationSelector() {
    return Row(
      children: [
        for (final duration in [30, 45, 60, 90])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$duration분'),
              selected: _estimatedDuration == duration,
              onSelected: (selected) {
                setState(() {
                  _estimatedDuration = selected ? duration : null;
                });
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: _estimatedDuration == duration
                    ? AppColors.primary
                    : AppColors.neutral200,
              ),
              labelStyle: TextStyle(
                color: _estimatedDuration == duration
                    ? AppColors.primary
                    : AppColors.neutral700,
                fontWeight: _estimatedDuration == duration
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExerciseList() {
    if (_exercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.neutral200, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.fitness_center,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '운동을 추가해주세요',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text('운동 추가'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _exercises.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _exercises.removeAt(oldIndex);
          _exercises.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return _ExerciseListItem(
          key: ValueKey('${exercise.exerciseId}_$index'),
          exercise: exercise,
          index: index,
          onEdit: () => _editExercise(index),
          onDelete: () => _removeExercise(index),
        );
      },
    );
  }

  Future<void> _addExercise() async {
    final selectedExercise = await ExercisePickerDialog.show(context: context);

    if (selectedExercise != null && mounted) {
      setState(() {
        _exercises.add(_TemplateExerciseItem(
          exerciseId: selectedExercise.id,
          exerciseName: selectedExercise.displayName,
          targetSets: 3,
          targetReps: '8-12',
        ));
      });
    }
  }

  Future<void> _editExercise(int index) async {
    final exercise = _exercises[index];
    final result = await _showExerciseEditDialog(exercise);

    if (result != null && mounted) {
      setState(() {
        _exercises[index] = result;
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  Future<_TemplateExerciseItem?> _showExerciseEditDialog(
    _TemplateExerciseItem exercise,
  ) async {
    final setsController = TextEditingController(
      text: exercise.targetSets?.toString() ?? '',
    );
    final repsController = TextEditingController(
      text: exercise.targetReps ?? '',
    );
    final weightController = TextEditingController(
      text: exercise.targetWeight?.toString() ?? '',
    );
    final rpeController = TextEditingController(
      text: exercise.targetRpe?.toString() ?? '',
    );
    final restController = TextEditingController(
      text: exercise.restSeconds?.toString() ?? '',
    );
    final notesController = TextEditingController(
      text: exercise.notes ?? '',
    );

    return showDialog<_TemplateExerciseItem>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(exercise.exerciseName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: setsController,
                      decoration: const InputDecoration(
                        labelText: '세트',
                        hintText: '3',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: repsController,
                      decoration: const InputDecoration(
                        labelText: '반복',
                        hintText: '8-12',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      decoration: const InputDecoration(
                        labelText: '무게 (kg)',
                        hintText: '20',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: rpeController,
                      decoration: const InputDecoration(
                        labelText: 'RPE',
                        hintText: '7',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: restController,
                decoration: const InputDecoration(
                  labelText: '휴식 시간 (초)',
                  hintText: '90',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: '메모',
                  hintText: '주의사항 등',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                _TemplateExerciseItem(
                  exerciseId: exercise.exerciseId,
                  exerciseName: exercise.exerciseName,
                  targetSets: int.tryParse(setsController.text),
                  targetReps: repsController.text.isEmpty ? null : repsController.text,
                  targetWeight: double.tryParse(weightController.text),
                  targetRpe: int.tryParse(rpeController.text),
                  restSeconds: int.tryParse(restController.text),
                  notes: notesController.text.isEmpty ? null : notesController.text,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 하나의 운동을 추가해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final notifier = ref.read(templateMutationProvider.notifier);

    final exerciseInputs = _exercises.asMap().entries.map((entry) {
      final index = entry.key;
      final e = entry.value;
      return TemplateExerciseInput(
        exerciseId: e.exerciseId,
        orderIndex: index,
        targetSets: e.targetSets,
        targetReps: e.targetReps,
        targetWeight: e.targetWeight,
        targetRpe: e.targetRpe,
        restSeconds: e.restSeconds,
        notes: e.notes,
      );
    }).toList();

    final result = isEditMode
        ? await notifier.updateTemplate(
            templateId: widget.templateId!,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            exercises: exerciseInputs,
            estimatedDurationMinutes: _estimatedDuration,
            focusArea: _selectedFocusArea,
          )
        : await notifier.createTemplate(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            exercises: exerciseInputs,
            estimatedDurationMinutes: _estimatedDuration,
            focusArea: _selectedFocusArea,
          );

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? '템플릿이 수정되었습니다' : '템플릿이 생성되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        final state = ref.read(templateMutationProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage ?? '저장에 실패했습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Internal class for managing exercise items in the editor
class _TemplateExerciseItem {
  final String exerciseId;
  final String exerciseName;
  final int? targetSets;
  final String? targetReps;
  final double? targetWeight;
  final int? targetRpe;
  final int? restSeconds;
  final String? notes;

  _TemplateExerciseItem({
    required this.exerciseId,
    required this.exerciseName,
    this.targetSets,
    this.targetReps,
    this.targetWeight,
    this.targetRpe,
    this.restSeconds,
    this.notes,
  });
}

/// Widget for displaying an exercise item in the list
class _ExerciseListItem extends StatelessWidget {
  final _TemplateExerciseItem exercise;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseListItem({
    required super.key,
    required this.exercise,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.neutral200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 32,
          height: 32,
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
          exercise.exerciseName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.neutralBlack,
          ),
        ),
        subtitle: Text(
          _buildSubtitle(),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.neutral600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: AppColors.neutral500,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: AppColors.error,
              onPressed: onDelete,
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(
                Icons.drag_handle,
                color: AppColors.neutral400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (exercise.targetSets != null) {
      parts.add('${exercise.targetSets}세트');
    }
    if (exercise.targetReps != null) {
      parts.add('${exercise.targetReps}회');
    }
    if (exercise.targetWeight != null) {
      parts.add('${exercise.targetWeight}kg');
    }
    if (exercise.targetRpe != null) {
      parts.add('RPE ${exercise.targetRpe}');
    }
    return parts.isEmpty ? '설정 없음' : parts.join(' · ');
  }
}
