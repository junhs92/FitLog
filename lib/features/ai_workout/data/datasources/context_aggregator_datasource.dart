import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/generation_context.dart';
import '../models/generation_context_model.dart';

/// Datasource for aggregating comprehensive client context
/// Used by AI workout generation to personalize programs
class ContextAggregatorDataSource {
  final SupabaseClient _client;

  ContextAggregatorDataSource(this._client);

  /// Fetch complete generation context for a client
  /// Aggregates: client profile, workout history (30 days), session feedback
  Future<GenerationContext> getGenerationContext(String clientId) async {
    // Fetch all three context sources in parallel
    final results = await Future.wait([
      _fetchClientContext(clientId),
      _fetchWorkoutHistory(clientId),
      _fetchSessionFeedback(clientId),
    ]);

    return GenerationContext(
      clientContext: results[0] as ClientContext,
      workoutHistory: results[1] as WorkoutHistory,
      sessionFeedback: results[2] as SessionFeedbackSummary,
    );
  }

  /// Fetch client profile from ai_generation_context table
  Future<ClientContext> _fetchClientContext(String clientId) async {
    try {
      final response = await _client
          .from('ai_generation_context')
          .select()
          .eq('client_id', clientId)
          .maybeSingle();

      if (response == null) {
        return ClientContext.empty();
      }

      return ClientContextModel.fromJson(response);
    } catch (e) {
      // Return empty context if table doesn't exist or error occurs
      return ClientContext.empty();
    }
  }

  /// Fetch workout history from the last 30 days
  Future<WorkoutHistory> _fetchWorkoutHistory(String clientId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      // Note: sets are stored as JSONB in session_exercises.sets, not a separate table
      final response = await _client
          .from('sessions')
          .select('''
            id,
            started_at,
            duration_seconds,
            session_exercises (
              id,
              sets,
              exercises (name, name_ko)
            )
          ''')
          .eq('client_id', clientId)
          .eq('status', 'completed')
          .gte('started_at', thirtyDaysAgo.toIso8601String())
          .order('started_at', ascending: false)
          .limit(20);

      final sessions = (response as List<dynamic>)
          .map((s) => _parseSessionSummary(s))
          .toList();

      final personalRecords = _extractPersonalRecords(sessions);
      final volumeTrends = _calculateVolumeTrends(sessions);

      return WorkoutHistory(
        recentSessions: sessions,
        personalRecords: personalRecords,
        volumeTrends: volumeTrends,
      );
    } catch (e) {
      return WorkoutHistory.empty();
    }
  }

  /// Fetch session feedback (difficulty ratings and exercise swaps)
  Future<SessionFeedbackSummary> _fetchSessionFeedback(String clientId) async {
    try {
      // Fetch difficulty feedback
      final feedbackResponse = await _client
          .from('session_exercise_feedback')
          .select('''
            feedback,
            exercises (name, name_ko)
          ''')
          .limit(100);

      // Fetch swap history
      final swapResponse = await _client
          .from('exercise_swap_history')
          .select('''
            feedback_reason,
            custom_reason,
            original_exercise:exercises!exercise_swap_history_original_exercise_id_fkey (name, name_ko),
            replacement_exercise:exercises!exercise_swap_history_replacement_exercise_id_fkey (name, name_ko)
          ''')
          .eq('client_id', clientId)
          .order('swapped_at', ascending: false)
          .limit(20);

      final difficultyFeedback = _aggregateDifficultyFeedback(
        feedbackResponse as List<dynamic>,
      );

      final swapHistory = (swapResponse as List<dynamic>)
          .map((s) => ExerciseSwap(
                originalExercise: s['original_exercise']?['name_ko'] ??
                    s['original_exercise']?['name'] ??
                    'Unknown',
                replacementExercise: s['replacement_exercise']?['name_ko'] ??
                    s['replacement_exercise']?['name'] ??
                    'Unknown',
                reason: s['custom_reason'] ?? s['feedback_reason'],
              ))
          .toList();

      return SessionFeedbackSummary(
        difficultyFeedback: difficultyFeedback,
        swapHistory: swapHistory,
        rpePatterns: const RpePattern(), // TODO: Calculate from actual data
      );
    } catch (e) {
      return SessionFeedbackSummary.empty();
    }
  }

  /// Save or update client context
  Future<void> saveClientContext({
    required String clientId,
    required ClientContext context,
  }) async {
    final data = {
      'client_id': clientId,
      'fitness_goals': (context as ClientContextModel).fitnessGoals,
      'available_equipment': context.availableEquipment,
      'experience_level': context.experienceLevel,
      'injury_history': context.injuryHistory
          .map((e) => InjuryRecordModel.fromEntity(e).toJson())
          .toList(),
      'limitations': context.limitations,
      'preferences': context.preferences,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client.from('ai_generation_context').upsert(data);
  }

  // Helper methods

  SessionSummary _parseSessionSummary(Map<String, dynamic> data) {
    // Note: sets are stored as JSONB in session_exercises.sets column
    final exercises = (data['session_exercises'] as List<dynamic>?)
            ?.map((se) => ExerciseSummary(
                  name: se['exercises']?['name_ko'] ??
                      se['exercises']?['name'] ??
                      'Unknown',
                  sets: (se['sets'] as List<dynamic>?)
                          ?.map((set) => SetSummary(
                                weight: (set['weight'] as num?)?.toDouble() ?? 0,
                                reps: set['reps'] as int? ?? 0,
                                rpe: (set['rpe'] as num?)?.toDouble(),
                              ))
                          .toList() ??
                      [],
                ))
            .toList() ??
        [];

    final durationSeconds = data['duration_seconds'] as int? ?? 0;
    return SessionSummary(
      date: DateTime.parse(data['started_at'] as String),
      exercises: exercises,
      durationMinutes: (durationSeconds / 60).round(),
    );
  }

  List<PersonalRecord> _extractPersonalRecords(List<SessionSummary> sessions) {
    final records = <String, PersonalRecord>{};

    for (final session in sessions) {
      for (final exercise in session.exercises) {
        for (final set in exercise.sets) {
          final volume = set.weight * set.reps;
          final existing = records[exercise.name];

          if (existing == null ||
              (set.weight * set.reps > existing.weight * existing.reps)) {
            records[exercise.name] = PersonalRecord(
              exerciseName: exercise.name,
              weight: set.weight,
              reps: set.reps,
              date: session.date,
            );
          }
        }
      }
    }

    return records.values.toList();
  }

  VolumeTrend _calculateVolumeTrends(List<SessionSummary> sessions) {
    if (sessions.isEmpty) {
      return const VolumeTrend();
    }

    // Group sessions by week and calculate weekly volume
    final weeklyVolumes = <double>[];
    DateTime? currentWeekStart;
    double currentWeekVolume = 0;

    for (final session in sessions) {
      final weekStart = _getWeekStart(session.date);

      if (currentWeekStart == null || weekStart != currentWeekStart) {
        if (currentWeekStart != null) {
          weeklyVolumes.add(currentWeekVolume);
        }
        currentWeekStart = weekStart;
        currentWeekVolume = 0;
      }

      for (final exercise in session.exercises) {
        currentWeekVolume += exercise.totalVolume;
      }
    }

    if (currentWeekVolume > 0) {
      weeklyVolumes.add(currentWeekVolume);
    }

    // Determine trend
    TrendDirection trend = TrendDirection.stable;
    if (weeklyVolumes.length >= 2) {
      final diff = weeklyVolumes[0] - weeklyVolumes[1];
      final threshold = weeklyVolumes[1] * 0.1;

      if (diff > threshold) {
        trend = TrendDirection.increasing;
      } else if (diff < -threshold) {
        trend = TrendDirection.decreasing;
      }
    }

    return VolumeTrend(
      weeklyVolume: weeklyVolumes,
      trend: trend,
    );
  }

  DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day - date.weekday);
  }

  List<ExerciseFeedback> _aggregateDifficultyFeedback(List<dynamic> feedbackData) {
    final feedbackMap = <String, Map<DifficultyLevel, int>>{};

    for (final f in feedbackData) {
      final exerciseName =
          f['exercises']?['name_ko'] ?? f['exercises']?['name'] ?? 'Unknown';
      final feedbackStr = f['feedback'] as String? ?? 'just_right';
      final difficulty = _parseDifficultyLevel(feedbackStr);

      feedbackMap.putIfAbsent(exerciseName, () => {});
      feedbackMap[exerciseName]![difficulty] =
          (feedbackMap[exerciseName]![difficulty] ?? 0) + 1;
    }

    return feedbackMap.entries.map((entry) {
      final mostCommon = entry.value.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      return ExerciseFeedback(
        exerciseName: entry.key,
        feedback: mostCommon.key,
        frequency: mostCommon.value,
      );
    }).toList();
  }

  DifficultyLevel _parseDifficultyLevel(String value) {
    switch (value) {
      case 'too_easy':
        return DifficultyLevel.tooEasy;
      case 'just_right':
        return DifficultyLevel.justRight;
      case 'challenging':
        return DifficultyLevel.challenging;
      case 'struggling':
        return DifficultyLevel.struggling;
      default:
        return DifficultyLevel.justRight;
    }
  }
}
