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

  const ReportGenerationState({
    this.report,
    this.isLoading = false,
    this.error,
  });

  ReportGenerationState copyWith({
    SessionReportEntity? report,
    bool? isLoading,
    String? error,
  }) {
    return ReportGenerationState(
      report: report ?? this.report,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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
