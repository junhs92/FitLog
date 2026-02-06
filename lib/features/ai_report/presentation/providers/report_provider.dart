import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/entities/session_report.dart';
import '../../domain/repositories/report_repository.dart';

/// Provider for Supabase client
final _supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for report remote datasource
final _reportDataSourceProvider = Provider<ReportRemoteDataSource>((ref) {
  return ReportRemoteDataSource(ref.read(_supabaseClientProvider));
});

/// Provider for report repository
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.read(_reportDataSourceProvider));
});

/// State for report generation
class ReportGenerationState {
  final SessionReportEntity? report;
  final bool isLoading;
  final String? error;
  final String? htmlContent;

  const ReportGenerationState({
    this.report,
    this.isLoading = false,
    this.error,
    this.htmlContent,
  });

  ReportGenerationState copyWith({
    SessionReportEntity? report,
    bool? isLoading,
    String? error,
    String? htmlContent,
  }) {
    return ReportGenerationState(
      report: report ?? this.report,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      htmlContent: htmlContent ?? this.htmlContent,
    );
  }
}

/// Notifier for report generation
class ReportGenerationNotifier extends StateNotifier<ReportGenerationState> {
  final ReportRepository _repository;

  ReportGenerationNotifier(this._repository)
      : super(const ReportGenerationState());

  /// Generate a new report
  Future<void> generateReport({
    required String sessionId,
    required ReportType type,
    String? trainerComment,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.generateReport(
      sessionId: sessionId,
      type: type,
      trainerComment: trainerComment,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (report) => state = state.copyWith(
        report: report,
        isLoading: false,
      ),
    );
  }

  /// Load existing report
  Future<void> loadReport(String reportId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getReport(reportId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (report) => state = state.copyWith(
        report: report,
        isLoading: false,
      ),
    );
  }

  /// Update trainer comment
  Future<void> updateComment(String comment) async {
    if (state.report == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _repository.updateTrainerComment(
      reportId: state.report!.id,
      comment: comment,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (report) => state = state.copyWith(
        report: report,
        isLoading: false,
      ),
    );
  }

  /// Send report to client
  Future<void> sendReport(String channel) async {
    if (state.report == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _repository.sendReport(
      reportId: state.report!.id,
      channel: channel,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (report) => state = state.copyWith(
        report: report,
        isLoading: false,
      ),
    );
  }

  /// Clear current report
  void clear() {
    state = const ReportGenerationState();
  }

  /// Generate PDF from current report (stub - requires backend implementation)
  Future<String?> generatePdf() async {
    if (state.report == null) {
      throw Exception('No report to generate PDF from');
    }

    // TODO: Implement PDF generation with backend
    // For now, return null to indicate PDF not available
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  /// Send report via email (stub - requires backend implementation)
  Future<void> sendReportEmail({
    String? trainerNotes,
    String? pdfUrl,
  }) async {
    if (state.report == null) {
      throw Exception('No report to send');
    }

    // TODO: Implement email sending with backend
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Generate shareable HTML report
  /// Returns the HTML URL, also stores HTML content in state for in-app display
  Future<String?> generateHtmlReport() async {
    if (state.report == null) {
      throw Exception('No report to generate HTML from');
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.generateHtmlReport(
      reportId: state.report!.id,
      sessionId: state.report!.sessionId,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return null;
      },
      (data) {
        final htmlUrl = data['htmlUrl']!;
        final htmlContent = data['htmlContent']!;
        // Update state with both URL and content
        state = state.copyWith(
          report: state.report!.copyWith(htmlUrl: htmlUrl),
          htmlContent: htmlContent,
          isLoading: false,
        );
        return htmlUrl;
      },
    );
  }
}

/// Provider for report generation
final reportGenerationProvider =
    StateNotifierProvider<ReportGenerationNotifier, ReportGenerationState>(
  (ref) => ReportGenerationNotifier(ref.read(reportRepositoryProvider)),
);

/// Provider for session reports list
final sessionReportsProvider = FutureProvider.family<
    List<SessionReportEntity>, String>(
  (ref, sessionId) async {
    final repository = ref.read(reportRepositoryProvider);
    final result = await repository.getSessionReports(sessionId);
    return result.fold((_) => [], (reports) => reports);
  },
);

/// Provider for client reports list
final clientReportsProvider = FutureProvider.family<
    List<SessionReportEntity>,
    ({String clientId, DateTime? fromDate, DateTime? toDate})>(
  (ref, params) async {
    final repository = ref.read(reportRepositoryProvider);
    final result = await repository.getClientReports(
      clientId: params.clientId,
      fromDate: params.fromDate,
      toDate: params.toDate,
    );
    return result.fold((_) => [], (reports) => reports);
  },
);

/// Data class for trainer comment in visual report
class VisualReportTrainerComment {
  final String key;
  final String displayName;
  final String? detail;

  const VisualReportTrainerComment({
    required this.key,
    required this.displayName,
    this.detail,
  });

  factory VisualReportTrainerComment.fromJson(Map<String, dynamic> json) {
    return VisualReportTrainerComment(
      key: json['key'] as String,
      displayName: json['displayName'] as String,
      detail: json['detail'] as String?,
    );
  }
}

/// Data class for session exercise in visual report
class VisualReportExercise {
  final String name;
  final String? nameKo;
  final List<VisualReportSet> sets;
  final double totalVolume;
  final double? previousVolume;
  final double? previousMaxWeight;
  final List<VisualReportTrainerComment> trainerComments;

  const VisualReportExercise({
    required this.name,
    this.nameKo,
    required this.sets,
    required this.totalVolume,
    this.previousVolume,
    this.previousMaxWeight,
    this.trainerComments = const [],
  });

  String get displayName => nameKo ?? name;

  double get maxWeight {
    if (sets.isEmpty) return 0;
    return sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  }

  int get totalReps {
    return sets.fold(0, (sum, s) => sum + s.reps);
  }

  double? get volumeChange {
    if (previousVolume == null || previousVolume == 0) return null;
    return ((totalVolume - previousVolume!) / previousVolume!) * 100;
  }

  double? get maxWeightChange {
    if (previousMaxWeight == null || previousMaxWeight == 0) return null;
    return maxWeight - previousMaxWeight!;
  }

  bool get hasTrainerComments => trainerComments.isNotEmpty;
}

/// Data class for individual set
class VisualReportSet {
  final int setNumber;
  final double weight;
  final int reps;
  final double? rpe;
  final List<String> tags;

  const VisualReportSet({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.rpe,
    this.tags = const [],
  });

  bool get isPR => tags.contains('pr');
}

/// Data class for visual report stats
class VisualReportStats {
  final int exerciseCount;
  final int totalSets;
  final int totalReps;
  final double totalVolume;
  final int durationMinutes;
  final DateTime sessionDate;

  const VisualReportStats({
    required this.exerciseCount,
    required this.totalSets,
    required this.totalReps,
    required this.totalVolume,
    required this.durationMinutes,
    required this.sessionDate,
  });
}

/// Data class for complete visual report data
class VisualReportData {
  final VisualReportStats stats;
  final List<VisualReportExercise> exercises;
  final String? clientName;

  const VisualReportData({
    required this.stats,
    required this.exercises,
    this.clientName,
  });
}

/// Provider to fetch session data for visual report
final visualReportDataProvider =
    FutureProvider.family<VisualReportData?, String>((ref, sessionId) async {
  final client = Supabase.instance.client;

  try {
    // Fetch session with exercises and sets
    final sessionData = await client
        .from('sessions')
        .select('''
          *,
          session_exercises(
            *,
            exercises(id, name, name_ko),
            set_records(*)
          ),
          clients:accounts!sessions_client_id_fkey(full_name)
        ''')
        .eq('id', sessionId)
        .single();

    final clientId = sessionData['client_id'] as String?;
    final clientName = sessionData['clients']?['full_name'] as String?;
    final startedAt = DateTime.parse(sessionData['started_at'] as String);
    final durationSeconds = sessionData['duration_seconds'] as int? ?? 0;

    final sessionExercises =
        sessionData['session_exercises'] as List<dynamic>? ?? [];

    // Filter to only exercises with recorded sets
    final completedExercises = sessionExercises
        .where((e) => (e['set_records'] as List<dynamic>? ?? []).isNotEmpty)
        .toList();

    // Get exercise IDs for fetching previous data
    final exerciseIds = completedExercises
        .map((e) => e['exercise_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    // Fetch previous session data for comparison
    Map<String, Map<String, dynamic>> previousData = {};
    if (exerciseIds.isNotEmpty && clientId != null) {
      final previousSessions = await client
          .from('session_exercises')
          .select('''
            exercise_id,
            set_records(*),
            sessions!inner(client_id, started_at)
          ''')
          .eq('sessions.client_id', clientId)
          .inFilter('exercise_id', exerciseIds)
          .lt('sessions.started_at', startedAt.toIso8601String())
          .order('sessions(started_at)', ascending: false)
          .limit(50);

      // Group by exercise_id and get the most recent data
      for (final prev in previousSessions) {
        final exerciseId = prev['exercise_id'] as String;
        if (!previousData.containsKey(exerciseId)) {
          final sets = prev['set_records'] as List<dynamic>? ?? [];
          if (sets.isNotEmpty) {
            double volume = 0;
            double maxWeight = 0;
            for (final set in sets) {
              final weight = (set['weight'] as num?)?.toDouble() ?? 0;
              final reps = set['reps'] as int? ?? 0;
              volume += weight * reps;
              if (weight > maxWeight) maxWeight = weight;
            }
            previousData[exerciseId] = {
              'volume': volume,
              'maxWeight': maxWeight,
            };
          }
        }
      }
    }

    // Build exercises list
    final exercises = <VisualReportExercise>[];
    int totalSets = 0;
    int totalReps = 0;
    double totalVolume = 0;

    for (final exercise in completedExercises) {
      final exerciseInfo = exercise['exercises'] as Map<String, dynamic>?;
      final exerciseId = exercise['exercise_id'] as String?;
      final setRecords = exercise['set_records'] as List<dynamic>? ?? [];
      final exerciseNotes = exercise['notes'] as String?;

      final sets = <VisualReportSet>[];
      double exerciseVolume = 0;

      for (int i = 0; i < setRecords.length; i++) {
        final set = setRecords[i];
        final weight = (set['weight'] as num?)?.toDouble() ?? 0;
        final reps = set['reps'] as int? ?? 0;
        final rpe = (set['rpe'] as num?)?.toDouble();
        final tags = (set['tags'] as List<dynamic>?)
                ?.map((t) => t.toString())
                .toList() ??
            [];

        sets.add(VisualReportSet(
          setNumber: i + 1,
          weight: weight,
          reps: reps,
          rpe: rpe,
          tags: tags,
        ));

        exerciseVolume += weight * reps;
        totalReps += reps;
      }

      totalSets += sets.length;
      totalVolume += exerciseVolume;

      final prev = exerciseId != null ? previousData[exerciseId] : null;

      // Parse trainer comments from notes JSON
      List<VisualReportTrainerComment> trainerComments = [];
      if (exerciseNotes != null && exerciseNotes.isNotEmpty) {
        try {
          final notesData = jsonDecode(exerciseNotes) as Map<String, dynamic>;
          final commentsJson = notesData['trainerComments'] as List<dynamic>?;
          if (commentsJson != null) {
            trainerComments = commentsJson
                .map((c) => VisualReportTrainerComment.fromJson(c as Map<String, dynamic>))
                .toList();
          }
        } catch (e) {
          // Ignore JSON parsing errors
        }
      }

      exercises.add(VisualReportExercise(
        name: (exerciseInfo?['name'] as String?) ?? 'Exercise',
        nameKo: exerciseInfo?['name_ko'] as String?,
        sets: sets,
        totalVolume: exerciseVolume,
        previousVolume: prev?['volume'] as double?,
        previousMaxWeight: prev?['maxWeight'] as double?,
        trainerComments: trainerComments,
      ));
    }

    return VisualReportData(
      stats: VisualReportStats(
        exerciseCount: exercises.length,
        totalSets: totalSets,
        totalReps: totalReps,
        totalVolume: totalVolume,
        durationMinutes: (durationSeconds / 60).round(),
        sessionDate: startedAt,
      ),
      exercises: exercises,
      clientName: clientName,
    );
  } catch (e) {
    return null;
  }
});
