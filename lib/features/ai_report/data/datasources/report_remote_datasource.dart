import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/timestamp_utils.dart';
import '../models/session_report_model.dart';
import '../../domain/entities/session_report.dart';

/// Remote datasource for AI report operations
class ReportRemoteDataSource {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  ReportRemoteDataSource(this._client);

  /// Generate a session report using AI
  Future<SessionReportModel> generateReport({
    required String sessionId,
    required ReportType type,
    String? trainerComment,
  }) async {
    // Fetch session data
    // Note: sets are stored as JSONB in session_exercises.sets, not a separate table
    final sessionData = await _client
        .from('sessions')
        .select('''
          *,
          session_exercises(
            *,
            exercises(name, name_ko),
            set_records(*)
          ),
          clients:accounts!sessions_client_id_fkey(full_name),
          trainers:accounts!sessions_trainer_id_fkey(full_name)
        ''')
        .eq('id', sessionId)
        .single();

    // Generate report content
    final reportId = _uuid.v4();
    final clientName = sessionData['clients']?['full_name'] ?? 'Client';
    final exercises = sessionData['session_exercises'] as List<dynamic>? ?? [];

    // Analyze session for highlights
    final highlights = _extractHighlights(exercises);

    // Generate content based on type
    final content = _generateContent(
      type: type,
      clientName: clientName,
      sessionData: sessionData,
      exercises: exercises,
      highlights: highlights,
    );

    final title = _generateTitle(type, clientName, sessionData);

    // Generate summary (shorter version for the required summary column)
    final summary = _generateSummary(
      clientName: clientName,
      exercises: exercises,
      highlights: highlights,
    );

    // Save report to database
    final reportData = {
      'id': reportId,
      'session_id': sessionId,
      'client_id': sessionData['client_id'],
      'trainer_id': sessionData['trainer_id'],
      'type': type.id,
      'status': ReportStatus.generated.id,
      'title': title,
      'summary': summary,
      'summary_ko': summary,
      'content': content,
      'highlights': highlights
          .map((h) => {
                'type': h.type.id,
                'title': h.title,
                'title_ko': h.titleKo,
                'description': h.description,
                'description_ko': h.descriptionKo,
                'exercise_name': h.exerciseName,
                'data': h.data,
              })
          .toList(),
      'trainer_comment': trainerComment,
      'generated_at': nowLocalIso8601(),
    };

    await _client.from('session_reports').insert(reportData);

    return SessionReportModel.fromJson(reportData);
  }

  /// Get a report by ID
  Future<SessionReportModel> getReport(String reportId) async {
    final response = await _client
        .from('session_reports')
        .select()
        .eq('id', reportId)
        .single();

    return SessionReportModel.fromJson(response);
  }

  /// Get all reports for a session
  Future<List<SessionReportModel>> getSessionReports(String sessionId) async {
    final response = await _client
        .from('session_reports')
        .select()
        .eq('session_id', sessionId)
        .order('generated_at', ascending: false);

    return (response as List)
        .map((r) => SessionReportModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Get all reports for a client
  Future<List<SessionReportModel>> getClientReports({
    required String clientId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _client
        .from('session_reports')
        .select()
        .eq('client_id', clientId);

    if (fromDate != null) {
      query = query.gte('generated_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('generated_at', toDate.toIso8601String());
    }

    final response = await query.order('generated_at', ascending: false);

    return (response as List)
        .map((r) => SessionReportModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Update report with trainer comment
  Future<SessionReportModel> updateTrainerComment({
    required String reportId,
    required String comment,
  }) async {
    await _client.from('session_reports').update({
      'trainer_comment': comment,
    }).eq('id', reportId);

    return getReport(reportId);
  }

  /// Send report to client
  Future<SessionReportModel> sendReport({
    required String reportId,
    required String channel,
  }) async {
    // Update status and sent timestamp
    await _client.from('session_reports').update({
      'status': ReportStatus.sent.id,
      'sent_at': nowLocalIso8601(),
    }).eq('id', reportId);

    // TODO: Implement actual sending via KakaoTalk/SMS
    // This would integrate with external services

    return getReport(reportId);
  }

  /// Mark report as viewed
  Future<void> markAsViewed(String reportId) async {
    await _client.from('session_reports').update({
      'status': ReportStatus.viewed.id,
      'viewed_at': nowLocalIso8601(),
    }).eq('id', reportId);
  }

  /// Get available report templates
  Future<List<ReportTemplateModel>> getTemplates(ReportType type) async {
    // Return default templates (could be stored in database)
    return _getDefaultTemplates(type);
  }

  /// Delete a report
  Future<void> deleteReport(String reportId) async {
    await _client.from('session_reports').delete().eq('id', reportId);
  }

  /// Generate shareable HTML report
  /// Returns a map with 'htmlUrl' and 'htmlContent'
  Future<Map<String, String>> generateHtmlReport({
    required String reportId,
    String? sessionId,
  }) async {
    final response = await _client.functions.invoke(
      'generate-html-report',
      body: {
        'reportId': reportId,
        if (sessionId != null) 'sessionId': sessionId,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to generate HTML report: ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;
    return {
      'htmlUrl': data['htmlUrl'] as String,
      'htmlContent': data['htmlContent'] as String,
    };
  }

  /// Regenerate report with different template
  Future<SessionReportModel> regenerateReport({
    required String reportId,
    String? templateId,
  }) async {
    final existing = await getReport(reportId);

    // Delete existing and regenerate
    await deleteReport(reportId);

    return generateReport(
      sessionId: existing.sessionId,
      type: existing.type,
      trainerComment: existing.trainerComment,
    );
  }

  // Private helper methods

  String _generateSummary({
    required String clientName,
    required List<dynamic> exercises,
    required List<ReportHighlight> highlights,
  }) {
    final buffer = StringBuffer();
    buffer.write('$clientName님 운동 완료. ');
    buffer.write('${exercises.length}개 운동 수행. ');

    if (highlights.isNotEmpty) {
      final topHighlight = highlights.first;
      buffer.write('${topHighlight.type.emoji} ${topHighlight.displayTitle}');
    }

    return buffer.toString();
  }

  List<ReportHighlight> _extractHighlights(List<dynamic> exercises) {
    final highlights = <ReportHighlight>[];

    // Only process exercises with recorded sets
    final completedExercises = exercises
        .where((e) => (e['set_records'] as List<dynamic>? ?? []).isNotEmpty)
        .toList();

    for (final exercise in completedExercises) {
      final sets = exercise['set_records'] as List<dynamic>? ?? [];
      final exerciseName =
          exercise['exercises']?['name_ko'] ?? exercise['exercises']?['name'] ?? 'Exercise';

      // Check for PRs
      double? maxWeight;
      int? maxReps;
      for (final set in sets) {
        final weight = (set['weight'] as num?)?.toDouble() ?? 0;
        final reps = set['reps'] as int? ?? 0;

        if (maxWeight == null || weight > maxWeight) {
          maxWeight = weight;
        }
        if (maxReps == null || reps > maxReps) {
          maxReps = reps;
        }

        // Check for PR tag
        final tags = set['tags'] as List<dynamic>? ?? [];
        if (tags.contains('pr')) {
          highlights.add(ReportHighlight(
            type: HighlightType.pr,
            title: 'Personal Record!',
            titleKo: '개인 기록 달성!',
            description: '$exerciseName: ${weight}kg x $reps reps',
            descriptionKo: '$exerciseName: ${weight}kg x $reps회',
            exerciseName: exerciseName,
            data: {'weight': weight, 'reps': reps},
          ));
        }
      }

      // Check for high volume
      if (sets.length >= 4) {
        highlights.add(ReportHighlight(
          type: HighlightType.effort,
          title: 'High Volume',
          titleKo: '고볼륨 훈련',
          description: '$exerciseName: ${sets.length} sets completed',
          descriptionKo: '$exerciseName: ${sets.length}세트 완료',
          exerciseName: exerciseName,
          data: {'sets': sets.length},
        ));
      }
    }

    // Add general session highlights if nothing specific
    if (highlights.isEmpty && completedExercises.isNotEmpty) {
      highlights.add(const ReportHighlight(
        type: HighlightType.consistency,
        title: 'Great Session!',
        titleKo: '훌륭한 세션!',
        description: 'Completed full workout as planned',
        descriptionKo: '계획대로 운동 완료',
      ));
    }

    return highlights;
  }

  String _generateTitle(
    ReportType type,
    String clientName,
    Map<String, dynamic> sessionData,
  ) {
    final date = DateTime.parse(sessionData['started_at'] as String);
    final dateStr = '${date.month}/${date.day}';

    switch (type) {
      case ReportType.full:
        return '$clientName님의 $dateStr 운동 리포트';
      case ReportType.summary:
        return '$dateStr 운동 요약';
      case ReportType.kakaoTalk:
      case ReportType.sms:
        return '$dateStr 운동 완료';
    }
  }

  String _generateContent({
    required ReportType type,
    required String clientName,
    required Map<String, dynamic> sessionData,
    required List<dynamic> exercises,
    required List<ReportHighlight> highlights,
  }) {
    final buffer = StringBuffer();
    final date = DateTime.parse(sessionData['started_at'] as String);
    final durationSeconds = sessionData['duration_seconds'] as int? ?? 0;
    final duration = (durationSeconds / 60).round(); // Convert to minutes

    // Filter to only exercises with recorded sets
    final completedExercises = exercises
        .where((e) => (e['set_records'] as List<dynamic>? ?? []).isNotEmpty)
        .toList();

    // Calculate overall volume
    double overallVolume = 0;
    for (final exercise in completedExercises) {
      final sets = exercise['set_records'] as List<dynamic>? ?? [];
      for (final set in sets) {
        final weight = (set['weight'] as num?)?.toDouble() ?? 0;
        final reps = set['reps'] as int? ?? 0;
        overallVolume += weight * reps;
      }
    }

    switch (type) {
      case ReportType.full:
        buffer.writeln('# $clientName님의 운동 리포트\n');
        buffer.writeln('📅 ${date.year}년 ${date.month}월 ${date.day}일');
        buffer.writeln('⏱️ 운동 시간: $duration분\n');

        if (highlights.isNotEmpty) {
          buffer.writeln('## 🌟 하이라이트\n');
          for (final h in highlights) {
            buffer.writeln('${h.type.emoji} **${h.displayTitle}**');
            buffer.writeln('   ${h.displayDescription}\n');
          }
        }

        buffer.writeln('## 💪 운동 내역\n');
        for (final exercise in completedExercises) {
          final name = exercise['exercises']?['name_ko'] ??
              exercise['exercises']?['name'] ??
              'Exercise';
          final sets = exercise['set_records'] as List<dynamic>? ?? [];

          // Calculate exercise volume
          double exerciseVolume = 0;
          for (final set in sets) {
            final weight = (set['weight'] as num?)?.toDouble() ?? 0;
            final reps = set['reps'] as int? ?? 0;
            exerciseVolume += weight * reps;
          }

          buffer.writeln('### $name');
          buffer.writeln('');
          for (int i = 0; i < sets.length; i++) {
            final set = sets[i];
            final weight = (set['weight'] as num?)?.toDouble() ?? 0;
            final reps = set['reps'] as int? ?? 0;
            final rpe = set['rpe'] as num?;
            final tags = set['tags'] as List<dynamic>? ?? [];

            // Build set line with details
            final weightStr = weight % 1 == 0 ? weight.toInt().toString() : weight.toStringAsFixed(1);
            String setLine = '- 세트 ${i + 1}: ${weightStr}kg × ${reps}회';

            // Add RPE if available
            if (rpe != null) {
              final rpeStr = rpe % 1 == 0 ? rpe.toInt().toString() : rpe.toStringAsFixed(1);
              setLine += ' (RPE $rpeStr)';
            }

            // Add tags if available
            if (tags.isNotEmpty) {
              final tagEmojis = tags.map((t) => _getTagEmoji(t.toString())).join(' ');
              setLine += ' $tagEmojis';
            }

            buffer.writeln(setLine);
          }

          // Show exercise volume
          final volumeStr = exerciseVolume % 1 == 0
              ? exerciseVolume.toInt().toString()
              : exerciseVolume.toStringAsFixed(0);
          buffer.writeln('📊 볼륨: ${volumeStr}kg');
          buffer.writeln('');
        }

        // Overall volume at the bottom
        buffer.writeln('---\n');
        final overallVolumeStr = overallVolume % 1 == 0
            ? overallVolume.toInt().toString()
            : overallVolume.toStringAsFixed(0);
        buffer.writeln('## 📈 총 볼륨: ${overallVolumeStr}kg');
        break;

      case ReportType.summary:
        buffer.writeln('$clientName님, 오늘도 수고하셨습니다! 💪\n');
        buffer.writeln('📅 ${date.year}년 ${date.month}월 ${date.day}일');
        buffer.writeln('⏱️ 운동 시간: $duration분');
        buffer.writeln('🏋️ 운동 수: ${completedExercises.length}개\n');

        // Exercise list with volume
        buffer.writeln('## 운동 목록\n');
        for (final exercise in completedExercises) {
          final name = exercise['exercises']?['name_ko'] ??
              exercise['exercises']?['name'] ??
              'Exercise';
          final sets = exercise['set_records'] as List<dynamic>? ?? [];

          // Calculate exercise volume
          double exerciseVolume = 0;
          for (final set in sets) {
            final weight = (set['weight'] as num?)?.toDouble() ?? 0;
            final reps = set['reps'] as int? ?? 0;
            exerciseVolume += weight * reps;
          }

          final volumeStr = exerciseVolume % 1 == 0
              ? exerciseVolume.toInt().toString()
              : exerciseVolume.toStringAsFixed(0);
          buffer.writeln('• $name - ${sets.length}세트, ${volumeStr}kg');
        }

        buffer.writeln('');
        final overallVolumeSummaryStr = overallVolume % 1 == 0
            ? overallVolume.toInt().toString()
            : overallVolume.toStringAsFixed(0);
        buffer.writeln('📈 총 볼륨: ${overallVolumeSummaryStr}kg\n');

        if (highlights.isNotEmpty) {
          buffer.writeln('✨ 오늘의 하이라이트:');
          for (final h in highlights.take(3)) {
            buffer.writeln('${h.type.emoji} ${h.displayTitle}');
          }
        }
        break;

      case ReportType.kakaoTalk:
      case ReportType.sms:
        buffer.write('[$clientName님] ');
        buffer.write('${date.month}/${date.day} 운동 완료! ');
        buffer.write('${completedExercises.length}개 운동, $duration분. ');
        if (highlights.isNotEmpty) {
          buffer.write('${highlights.first.type.emoji} ${highlights.first.displayTitle}');
        }
        break;
    }

    return buffer.toString();
  }

  List<ReportTemplateModel> _getDefaultTemplates(ReportType type) {
    switch (type) {
      case ReportType.full:
        return [
          const ReportTemplateModel(
            id: 'full_default',
            name: 'Standard Full Report',
            nameKo: '기본 전체 리포트',
            type: ReportType.full,
            headerTemplate: '# {clientName}님의 운동 리포트\n\n📅 {date}\n⏱️ 운동 시간: {duration}분',
            bodyTemplate: '## 💪 운동 내역\n\n{exercises}\n\n## 🌟 하이라이트\n\n{highlights}',
            footerTemplate: '---\n\n오늘도 수고하셨습니다! 다음 세션에서 뵙겠습니다. 💪',
            isDefault: true,
          ),
        ];
      case ReportType.summary:
        return [
          const ReportTemplateModel(
            id: 'summary_default',
            name: 'Standard Summary',
            nameKo: '기본 요약',
            type: ReportType.summary,
            headerTemplate: '{clientName}님, 오늘도 수고하셨습니다! 💪',
            bodyTemplate: '⏱️ 운동 시간: {duration}분\n🏋️ 운동 수: {exerciseCount}개\n\n{highlights}',
            footerTemplate: '',
            isDefault: true,
          ),
        ];
      case ReportType.kakaoTalk:
      case ReportType.sms:
        return [
          const ReportTemplateModel(
            id: 'short_default',
            name: 'Short Message',
            nameKo: '짧은 메시지',
            type: ReportType.kakaoTalk,
            headerTemplate: '[{clientName}님]',
            bodyTemplate: '{date} 운동 완료! {exerciseCount}개 운동, {duration}분.',
            footerTemplate: '{topHighlight}',
            isDefault: true,
          ),
        ];
    }
  }

  /// Convert tag string to emoji
  String _getTagEmoji(String tag) {
    switch (tag.toLowerCase()) {
      case 'pr':
        return '🏆';
      case 'form_issue':
        return '⚠️';
      case 'pain':
        return '🤕';
      case 'fatigue':
        return '😓';
      case 'good_condition':
        return '💪';
      case 'warmup':
        return '🔥';
      case 'drop_set':
        return '⬇️';
      case 'failure_set':
        return '💀';
      default:
        return '';
    }
  }
}
