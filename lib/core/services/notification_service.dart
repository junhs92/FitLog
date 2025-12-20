import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notification types supported by the app
enum NotificationType {
  sessionReminder('session_reminder', 'Session Reminder', '세션 알림'),
  sessionComplete('session_complete', 'Session Complete', '세션 완료'),
  reportReady('report_ready', 'Report Ready', '리포트 생성'),
  trainerMessage('trainer_message', 'Trainer Message', '트레이너 메시지'),
  clientLog('client_log', 'Client Log', '클라이언트 기록'),
  lifestyleAlert('lifestyle_alert', 'Lifestyle Alert', '생활습관 알림'),
  achievement('achievement', 'Achievement', '업적 달성'),
  programUpdate('program_update', 'Program Update', '프로그램 업데이트');

  final String id;
  final String name;
  final String nameKo;

  const NotificationType(this.id, this.name, this.nameKo);

  String get displayName => nameKo;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (n) => n.id == value,
      orElse: () => NotificationType.trainerMessage,
    );
  }
}

/// Notification entity
class NotificationEntity {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  NotificationEntity copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

/// Notification preferences
class NotificationPreferences {
  final bool sessionReminders;
  final bool reportNotifications;
  final bool trainerMessages;
  final bool clientLogs;
  final bool achievements;
  final bool marketingEmails;
  final int reminderMinutesBefore;

  const NotificationPreferences({
    this.sessionReminders = true,
    this.reportNotifications = true,
    this.trainerMessages = true,
    this.clientLogs = true,
    this.achievements = true,
    this.marketingEmails = false,
    this.reminderMinutesBefore = 60,
  });

  NotificationPreferences copyWith({
    bool? sessionReminders,
    bool? reportNotifications,
    bool? trainerMessages,
    bool? clientLogs,
    bool? achievements,
    bool? marketingEmails,
    int? reminderMinutesBefore,
  }) {
    return NotificationPreferences(
      sessionReminders: sessionReminders ?? this.sessionReminders,
      reportNotifications: reportNotifications ?? this.reportNotifications,
      trainerMessages: trainerMessages ?? this.trainerMessages,
      clientLogs: clientLogs ?? this.clientLogs,
      achievements: achievements ?? this.achievements,
      marketingEmails: marketingEmails ?? this.marketingEmails,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_reminders': sessionReminders,
      'report_notifications': reportNotifications,
      'trainer_messages': trainerMessages,
      'client_logs': clientLogs,
      'achievements': achievements,
      'marketing_emails': marketingEmails,
      'reminder_minutes_before': reminderMinutesBefore,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      sessionReminders: json['session_reminders'] as bool? ?? true,
      reportNotifications: json['report_notifications'] as bool? ?? true,
      trainerMessages: json['trainer_messages'] as bool? ?? true,
      clientLogs: json['client_logs'] as bool? ?? true,
      achievements: json['achievements'] as bool? ?? true,
      marketingEmails: json['marketing_emails'] as bool? ?? false,
      reminderMinutesBefore: json['reminder_minutes_before'] as int? ?? 60,
    );
  }
}

/// Notification service for managing push notifications
class NotificationService {
  final SupabaseClient _client;
  String? _fcmToken;

  NotificationService(this._client);

  /// Initialize notification service
  Future<void> initialize() async {
    // TODO: Initialize Firebase Messaging
    // final messaging = FirebaseMessaging.instance;

    // Request permission
    // await messaging.requestPermission();

    // Get FCM token
    // _fcmToken = await messaging.getToken();

    // Save token to database
    if (_fcmToken != null) {
      await _saveFcmToken(_fcmToken!);
    }

    // Listen for token refresh
    // messaging.onTokenRefresh.listen(_saveFcmToken);
  }

  /// Save FCM token to database
  Future<void> _saveFcmToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('user_fcm_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': _getPlatform(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  String _getPlatform() {
    // TODO: Detect actual platform
    return 'mobile';
  }

  /// Send notification to a user
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Save to notifications table
    await _client.from('notifications').insert({
      'user_id': userId,
      'type': type.id,
      'title': title,
      'body': body,
      'data': data,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });

    // TODO: Trigger FCM push notification via Edge Function
    // await _client.functions.invoke('send-push-notification', body: {...});
  }

  /// Get notifications for current user
  Future<List<NotificationEntity>> getNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _client
        .from('notifications')
        .select()
        .eq('user_id', userId);

    if (unreadOnly) {
      query = query.eq('is_read', false);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((n) {
      return NotificationEntity(
        id: n['id'] as String,
        userId: n['user_id'] as String,
        type: NotificationType.fromString(n['type'] as String),
        title: n['title'] as String,
        body: n['body'] as String,
        data: n['data'] as Map<String, dynamic>?,
        isRead: n['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(n['created_at'] as String),
        readAt: n['read_at'] != null
            ? DateTime.parse(n['read_at'] as String)
            : null,
      );
    }).toList();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }

  /// Get notification preferences
  Future<NotificationPreferences> getPreferences() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const NotificationPreferences();

    final response = await _client
        .from('notification_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return const NotificationPreferences();
    }

    return NotificationPreferences.fromJson(response);
  }

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferences prefs) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('notification_preferences').upsert({
      'user_id': userId,
      ...prefs.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _client.from('notifications').delete().eq('id', notificationId);
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('notifications').delete().eq('user_id', userId);
  }

  /// Send report ready notification to a client
  Future<void> sendReportReadyNotification({
    required String clientId,
    required String sessionId,
    required String sessionDate,
    String? pdfUrl,
  }) async {
    await sendNotification(
      userId: clientId,
      type: NotificationType.reportReady,
      title: 'Your workout report is ready!',
      body: 'Check out your session report from $sessionDate',
      data: {
        'session_id': sessionId,
        'pdf_url': pdfUrl,
      },
    );

    // Trigger push notification via Edge Function
    try {
      await _client.functions.invoke('send-push-notification', body: {
        'userId': clientId,
        'title': 'Your workout report is ready!',
        'body': 'Check out your session report from $sessionDate',
        'data': {
          'type': NotificationType.reportReady.id,
          'session_id': sessionId,
        },
      });
    } catch (e) {
      // Push notification is non-critical, log but don't fail
      print('Failed to send push notification: $e');
    }
  }

  /// Send session complete notification
  Future<void> sendSessionCompleteNotification({
    required String clientId,
    required String trainerName,
    required String sessionId,
    int? totalSets,
    int? totalVolume,
  }) async {
    final statsText = totalSets != null && totalVolume != null
        ? ' ($totalSets sets, ${totalVolume}kg volume)'
        : '';

    await sendNotification(
      userId: clientId,
      type: NotificationType.sessionComplete,
      title: 'Session complete!',
      body: 'Great workout with $trainerName$statsText',
      data: {
        'session_id': sessionId,
        'total_sets': totalSets,
        'total_volume': totalVolume,
      },
    );
  }

  /// Send PR achievement notification
  Future<void> sendPrAchievementNotification({
    required String userId,
    required String exerciseName,
    required double weight,
    required int reps,
    required String sessionId,
  }) async {
    await sendNotification(
      userId: userId,
      type: NotificationType.achievement,
      title: '🏆 New Personal Record!',
      body: '$exerciseName: ${weight}kg x $reps reps',
      data: {
        'type': 'pr',
        'session_id': sessionId,
        'exercise_name': exerciseName,
        'weight': weight,
        'reps': reps,
      },
    );
  }
}

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(Supabase.instance.client);
});

/// Provider for notifications list
final notificationsProvider = FutureProvider<List<NotificationEntity>>((ref) async {
  final service = ref.read(notificationServiceProvider);
  return service.getNotifications();
});

/// Provider for unread count
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final service = ref.read(notificationServiceProvider);
  return service.getUnreadCount();
});

/// Provider for notification preferences
final notificationPreferencesProvider =
    FutureProvider<NotificationPreferences>((ref) async {
  final service = ref.read(notificationServiceProvider);
  return service.getPreferences();
});
