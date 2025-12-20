/// Report type for different communication channels
enum ReportType {
  full('full', 'Full Report', '전체 리포트'),
  summary('summary', 'Summary', '요약'),
  kakaoTalk('kakao', 'KakaoTalk', '카카오톡'),
  sms('sms', 'SMS', '문자');

  final String id;
  final String name;
  final String nameKo;

  const ReportType(this.id, this.name, this.nameKo);

  String get displayName => nameKo;

  static ReportType fromString(String value) {
    return ReportType.values.firstWhere(
      (r) => r.id == value,
      orElse: () => ReportType.summary,
    );
  }
}

/// Report status
enum ReportStatus {
  draft('draft', 'Draft', '초안'),
  generated('generated', 'Generated', '생성됨'),
  sent('sent', 'Sent', '전송됨'),
  viewed('viewed', 'Viewed', '확인됨');

  final String id;
  final String name;
  final String nameKo;

  const ReportStatus(this.id, this.name, this.nameKo);

  String get displayName => nameKo;

  static ReportStatus fromString(String value) {
    return ReportStatus.values.firstWhere(
      (s) => s.id == value,
      orElse: () => ReportStatus.draft,
    );
  }
}

/// Session report entity
class SessionReportEntity {
  final String id;
  final String sessionId;
  final String clientId;
  final String trainerId;
  final ReportType type;
  final ReportStatus status;
  final String title;
  final String content;
  final List<ReportHighlight> highlights;
  final String? trainerComment;
  final DateTime generatedAt;
  final DateTime? sentAt;
  final DateTime? viewedAt;

  const SessionReportEntity({
    required this.id,
    required this.sessionId,
    required this.clientId,
    required this.trainerId,
    required this.type,
    required this.status,
    required this.title,
    required this.content,
    required this.highlights,
    this.trainerComment,
    required this.generatedAt,
    this.sentAt,
    this.viewedAt,
  });

  SessionReportEntity copyWith({
    String? id,
    String? sessionId,
    String? clientId,
    String? trainerId,
    ReportType? type,
    ReportStatus? status,
    String? title,
    String? content,
    List<ReportHighlight>? highlights,
    String? trainerComment,
    DateTime? generatedAt,
    DateTime? sentAt,
    DateTime? viewedAt,
  }) {
    return SessionReportEntity(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      clientId: clientId ?? this.clientId,
      trainerId: trainerId ?? this.trainerId,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      content: content ?? this.content,
      highlights: highlights ?? this.highlights,
      trainerComment: trainerComment ?? this.trainerComment,
      generatedAt: generatedAt ?? this.generatedAt,
      sentAt: sentAt ?? this.sentAt,
      viewedAt: viewedAt ?? this.viewedAt,
    );
  }
}

/// Highlight type for report
enum HighlightType {
  pr('pr', 'Personal Record', '개인 기록'),
  improvement('improvement', 'Improvement', '향상'),
  consistency('consistency', 'Consistency', '꾸준함'),
  effort('effort', 'Great Effort', '노력'),
  milestone('milestone', 'Milestone', '마일스톤'),
  caution('caution', 'Caution', '주의');

  final String id;
  final String name;
  final String nameKo;

  const HighlightType(this.id, this.name, this.nameKo);

  String get displayName => nameKo;

  String get emoji {
    switch (this) {
      case HighlightType.pr:
        return '🏆';
      case HighlightType.improvement:
        return '📈';
      case HighlightType.consistency:
        return '💪';
      case HighlightType.effort:
        return '⭐';
      case HighlightType.milestone:
        return '🎯';
      case HighlightType.caution:
        return '⚠️';
    }
  }
}

/// Individual highlight in report
class ReportHighlight {
  final HighlightType type;
  final String title;
  final String? titleKo;
  final String description;
  final String? descriptionKo;
  final String? exerciseName;
  final Map<String, dynamic>? data;

  const ReportHighlight({
    required this.type,
    required this.title,
    this.titleKo,
    required this.description,
    this.descriptionKo,
    this.exerciseName,
    this.data,
  });

  String get displayTitle => titleKo ?? title;
  String get displayDescription => descriptionKo ?? description;
}

/// Report template for customization
class ReportTemplate {
  final String id;
  final String name;
  final String? nameKo;
  final ReportType type;
  final String headerTemplate;
  final String bodyTemplate;
  final String footerTemplate;
  final bool isDefault;

  const ReportTemplate({
    required this.id,
    required this.name,
    this.nameKo,
    required this.type,
    required this.headerTemplate,
    required this.bodyTemplate,
    required this.footerTemplate,
    this.isDefault = false,
  });

  String get displayName => nameKo ?? name;
}
