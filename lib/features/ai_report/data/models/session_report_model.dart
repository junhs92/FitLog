import '../../domain/entities/session_report.dart';

/// Data model for session report
class SessionReportModel extends SessionReportEntity {
  const SessionReportModel({
    required super.id,
    required super.sessionId,
    required super.clientId,
    required super.trainerId,
    required super.type,
    required super.status,
    required super.title,
    required super.content,
    required super.highlights,
    super.trainerComment,
    required super.generatedAt,
    super.sentAt,
    super.viewedAt,
  });

  factory SessionReportModel.fromJson(Map<String, dynamic> json) {
    return SessionReportModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      clientId: json['client_id'] as String,
      trainerId: json['trainer_id'] as String,
      type: ReportType.fromString(json['type'] as String),
      status: ReportStatus.fromString(json['status'] as String),
      title: json['title'] as String,
      content: json['content'] as String,
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((h) => ReportHighlightModel.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
      trainerComment: json['trainer_comment'] as String?,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      viewedAt: json['viewed_at'] != null
          ? DateTime.parse(json['viewed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'client_id': clientId,
      'trainer_id': trainerId,
      'type': type.id,
      'status': status.id,
      'title': title,
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
      'generated_at': generatedAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'viewed_at': viewedAt?.toIso8601String(),
    };
  }

  factory SessionReportModel.fromEntity(SessionReportEntity entity) {
    return SessionReportModel(
      id: entity.id,
      sessionId: entity.sessionId,
      clientId: entity.clientId,
      trainerId: entity.trainerId,
      type: entity.type,
      status: entity.status,
      title: entity.title,
      content: entity.content,
      highlights: entity.highlights,
      trainerComment: entity.trainerComment,
      generatedAt: entity.generatedAt,
      sentAt: entity.sentAt,
      viewedAt: entity.viewedAt,
    );
  }
}

/// Data model for report highlight
class ReportHighlightModel extends ReportHighlight {
  const ReportHighlightModel({
    required super.type,
    required super.title,
    super.titleKo,
    required super.description,
    super.descriptionKo,
    super.exerciseName,
    super.data,
  });

  factory ReportHighlightModel.fromJson(Map<String, dynamic> json) {
    return ReportHighlightModel(
      type: HighlightType.values.firstWhere(
        (t) => t.id == json['type'],
        orElse: () => HighlightType.effort,
      ),
      title: json['title'] as String,
      titleKo: json['title_ko'] as String?,
      description: json['description'] as String,
      descriptionKo: json['description_ko'] as String?,
      exerciseName: json['exercise_name'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Data model for report template
class ReportTemplateModel extends ReportTemplate {
  const ReportTemplateModel({
    required super.id,
    required super.name,
    super.nameKo,
    required super.type,
    required super.headerTemplate,
    required super.bodyTemplate,
    required super.footerTemplate,
    super.isDefault,
  });

  factory ReportTemplateModel.fromJson(Map<String, dynamic> json) {
    return ReportTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameKo: json['name_ko'] as String?,
      type: ReportType.fromString(json['type'] as String),
      headerTemplate: json['header_template'] as String,
      bodyTemplate: json['body_template'] as String,
      footerTemplate: json['footer_template'] as String,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}
