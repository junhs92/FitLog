import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/meal_log_entity.dart';
import '../../domain/entities/sleep_log_entity.dart';
import '../../domain/entities/mood_log_entity.dart';
import '../providers/lifestyle_provider.dart';
import '../widgets/meal_card.dart';
import '../widgets/water_tracker.dart';
import '../widgets/sleep_input.dart';
import '../widgets/mood_selector.dart';

/// Client record screen for daily lifestyle logging
class ClientRecordScreen extends ConsumerWidget {
  final String clientId;

  const ClientRecordScreen({
    required this.clientId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLogState = ref.watch(dailyLogProvider(clientId));
    final notifier = ref.read(dailyLogProvider(clientId).notifier);
    final log = dailyLogState.log;
    final selectedDate = dailyLogState.selectedDate;
    final isToday = _isToday(selectedDate);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Record'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Date Navigator
          _DateNavigator(
            date: selectedDate,
            onPrevious: notifier.previousDay,
            onNext: isToday ? null : notifier.nextDay,
            onToday: notifier.goToToday,
          ),
          // Content
          Expanded(
            child: dailyLogState.isLoading && log == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => notifier.refresh(),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Meals Section
                          _SectionHeader(title: 'Meals', emoji: '🍽️'),
                          const SizedBox(height: AppSpacing.sm),
                          MealCardGrid(
                            meals: log?.meals ?? [],
                            onMealTap: (mealType) => _showMealDialog(
                              context,
                              ref,
                              mealType,
                              log?.getMealByType(mealType),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Water Section
                          _SectionHeader(title: 'Hydration', emoji: '💧'),
                          const SizedBox(height: AppSpacing.sm),
                          WaterTracker(
                            summary: log?.waterSummary,
                            onAddWater: (amount) => notifier.logWater(amount),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Sleep Section
                          _SectionHeader(title: 'Sleep', emoji: '😴'),
                          const SizedBox(height: AppSpacing.sm),
                          SleepInput(
                            sleep: log?.sleep,
                            onTap: () => _showSleepDialog(context, ref, log?.sleep),
                            onQualityChanged: log?.sleep != null
                                ? (quality) => notifier.updateSleepQuality(quality)
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Mood Section
                          _SectionHeader(title: 'Mood & Energy', emoji: '😊'),
                          const SizedBox(height: AppSpacing.sm),
                          MoodSelector(
                            mood: log?.mood,
                            onTap: () => _showMoodDialog(context, ref, log?.mood),
                            onMoodChanged: (mood) => notifier.updateMood(mood: mood),
                            onEnergyChanged: (energy) =>
                                notifier.updateMood(energy: energy),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Weight Section
                          _SectionHeader(title: 'Body', emoji: '⚖️'),
                          const SizedBox(height: AppSpacing.sm),
                          _WeightInput(
                            weight: log?.weight,
                            onTap: () => _showWeightDialog(context, ref, log?.weight),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _showMealDialog(
    BuildContext context,
    WidgetRef ref,
    MealType mealType,
    MealLogEntity? existingMeal,
  ) {
    final descriptionController =
        TextEditingController(text: existingMeal?.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                existingMeal != null ? 'Update ${mealType.name}' : 'Log ${mealType.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: 'What did you eat?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              // Photo button
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement photo picker
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Add Photo'),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () {
                  ref.read(dailyLogProvider(clientId).notifier).logMeal(
                        mealType: mealType,
                        description: descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                      );
                  Navigator.pop(context);
                },
                child: Text(existingMeal != null ? 'Update' : 'Log Meal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepDialog(
    BuildContext context,
    WidgetRef ref,
    SleepLogEntity? existingSleep,
  ) {
    TimeOfDay bedtime = existingSleep?.bedtime != null
        ? TimeOfDay.fromDateTime(existingSleep!.bedtime!)
        : const TimeOfDay(hour: 22, minute: 0);
    TimeOfDay wakeTime = existingSleep?.wakeTime != null
        ? TimeOfDay.fromDateTime(existingSleep!.wakeTime!)
        : const TimeOfDay(hour: 7, minute: 0);
    SleepQuality? quality = existingSleep?.quality;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Log Sleep',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerButton(
                        label: 'Bedtime',
                        time: bedtime,
                        icon: Icons.bedtime,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: bedtime,
                          );
                          if (picked != null) {
                            setState(() => bedtime = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _TimePickerButton(
                        label: 'Wake up',
                        time: wakeTime,
                        icon: Icons.wb_sunny,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: wakeTime,
                          );
                          if (picked != null) {
                            setState(() => wakeTime = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Sleep Quality',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SleepQualitySelector(
                  selected: quality,
                  onChanged: (q) => setState(() => quality = q),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    final bedtimeDateTime = DateTime(
                      now.year,
                      now.month,
                      now.day - 1,
                      bedtime.hour,
                      bedtime.minute,
                    );
                    final wakeDateTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      wakeTime.hour,
                      wakeTime.minute,
                    );

                    ref.read(dailyLogProvider(clientId).notifier).logSleep(
                          bedtime: bedtimeDateTime,
                          wakeTime: wakeDateTime,
                          quality: quality,
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Log Sleep'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoodDialog(
    BuildContext context,
    WidgetRef ref,
    MoodLogEntity? existingMood,
  ) {
    MoodLevel? mood = existingMood?.mood;
    EnergyLevel? energy = existingMood?.energy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'How are you feeling?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Mood',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                MoodLevelSelector(
                  selected: mood,
                  onChanged: (m) => setState(() => mood = m),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Energy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                EnergyLevelSelector(
                  selected: energy,
                  onChanged: (e) => setState(() => energy = e),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () {
                    ref.read(dailyLogProvider(clientId).notifier).logMood(
                          mood: mood,
                          energy: energy,
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWeightDialog(
    BuildContext context,
    WidgetRef ref,
    double? existingWeight,
  ) {
    final controller =
        TextEditingController(text: existingWeight?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Log Weight',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Enter weight',
                  suffixText: 'kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () {
                  final weight = double.tryParse(controller.text);
                  if (weight != null) {
                    ref
                        .read(dailyLogProvider(clientId).notifier)
                        .logWeight(weight);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onToday;

  const _DateNavigator({
    required this.date,
    required this.onPrevious,
    this.onNext,
    required this.onToday,
  });

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          bottom: BorderSide(color: AppColors.neutral200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          GestureDetector(
            onTap: onToday,
            child: Column(
              children: [
                Text(
                  _isToday ? 'Today' : _formatDate(date),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutralBlack,
                  ),
                ),
                if (!_isToday)
                  Text(
                    'Tap for today',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(
              Icons.chevron_right,
              color: onNext != null ? null : AppColors.neutral300,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String emoji;

  const _SectionHeader({
    required this.title,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.neutralBlack,
          ),
        ),
      ],
    );
  }
}

class _WeightInput extends StatelessWidget {
  final double? weight;
  final VoidCallback onTap;

  const _WeightInput({
    this.weight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Center(
                  child: Text('⚖️', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weight',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutralBlack,
                      ),
                    ),
                    Text(
                      weight != null
                          ? '${weight!.toStringAsFixed(1)} kg'
                          : 'Tap to log',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            weight != null ? AppColors.warning : AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              if (weight != null)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 24,
                )
              else
                Icon(
                  Icons.add_circle_outline,
                  color: AppColors.neutral400,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final IconData icon;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutral100,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, color: AppColors.neutral700),
              const SizedBox(height: 4),
              Text(
                time.format(context),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutralBlack,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
