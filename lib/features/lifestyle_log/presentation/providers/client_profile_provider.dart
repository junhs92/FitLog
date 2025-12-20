import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client profile data entity
class ClientProfile {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final List<String> fitnessGoals;
  final DateTime createdAt;

  const ClientProfile({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.fitnessGoals = const [],
    required this.createdAt,
  });

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      fitnessGoals: (json['fitness_goals'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get displayName => fullName ?? 'Client User';

  String get formattedDateOfBirth {
    if (dateOfBirth == null) return 'Not specified';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateOfBirth!.month - 1]} ${dateOfBirth!.day}, ${dateOfBirth!.year}';
  }

  String get formattedGender {
    if (gender == null) return 'Not specified';
    return gender!.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  int get weeksSinceJoined {
    return DateTime.now().difference(createdAt).inDays ~/ 7;
  }
}

/// Client stats data
class ClientStats {
  final int sessionCount;
  final int consistencyPercent;
  final int weeksSinceJoined;

  const ClientStats({
    required this.sessionCount,
    required this.consistencyPercent,
    required this.weeksSinceJoined,
  });

  factory ClientStats.empty() => const ClientStats(
        sessionCount: 0,
        consistencyPercent: 0,
        weeksSinceJoined: 0,
      );
}

/// Trainer info for client profile
class TrainerInfo {
  final String id;
  final String name;
  final String? avatarUrl;
  final String status;

  const TrainerInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.status,
  });
}

/// Provider for client profile data
/// Note: clientId here is the auth user_id (from Supabase auth.uid())
final clientProfileProvider =
    FutureProvider.family<ClientProfile?, String>((ref, clientId) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase
        .from('accounts')
        .select()
        .eq('user_id', clientId)
        .single();

    return ClientProfile.fromJson(response);
  } catch (e) {
    return null;
  }
});

/// Provider for client stats
/// Note: clientId here is the auth user_id, we get account.id from profile
final clientStatsProvider =
    FutureProvider.family<ClientStats, String>((ref, clientId) async {
  final supabase = Supabase.instance.client;

  try {
    // Get profile for weeks calculation and account ID
    final profile = await ref.watch(clientProfileProvider(clientId).future);
    if (profile == null) return ClientStats.empty();

    final accountId = profile.id; // Use account ID for FK queries
    final weeksSinceJoined = profile.weeksSinceJoined;

    // Get session count
    int sessionCount = 0;
    try {
      final sessionsResponse = await supabase
          .from('sessions')
          .select('id')
          .eq('client_id', accountId)
          .eq('status', 'completed');
      sessionCount = (sessionsResponse as List).length;
    } catch (_) {
      // Sessions table might not exist
    }

    // Calculate consistency from lifestyle logs (last 30 days)
    int consistencyPercent = 0;
    try {
      final thirtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

      // Count days with any log entries
      final mealDays = await supabase
          .from('meal_logs')
          .select('log_date')
          .eq('client_id', accountId)
          .gte('log_date', thirtyDaysAgo.split('T')[0]);

      final moodDays = await supabase
          .from('mood_logs')
          .select('log_date')
          .eq('client_id', accountId)
          .gte('log_date', thirtyDaysAgo.split('T')[0]);

      final waterDays = await supabase
          .from('water_logs')
          .select('log_date')
          .eq('client_id', accountId)
          .gte('log_date', thirtyDaysAgo.split('T')[0]);

      // Get unique dates with any activity
      final allDates = <String>{};
      for (final row in mealDays as List) {
        allDates.add(row['log_date'] as String);
      }
      for (final row in moodDays as List) {
        allDates.add(row['log_date'] as String);
      }
      for (final row in waterDays as List) {
        allDates.add(row['log_date'] as String);
      }

      // Calculate percentage (out of 30 days)
      consistencyPercent = ((allDates.length / 30) * 100).round().clamp(0, 100);
    } catch (_) {
      // Tables might not exist or be empty
    }

    return ClientStats(
      sessionCount: sessionCount,
      consistencyPercent: consistencyPercent,
      weeksSinceJoined: weeksSinceJoined,
    );
  } catch (e) {
    return ClientStats.empty();
  }
});

/// Provider for assigned trainer info
/// Note: clientId here is the auth user_id, we get account.id from profile
final assignedTrainerProvider =
    FutureProvider.family<TrainerInfo?, String>((ref, clientId) async {
  final supabase = Supabase.instance.client;

  try {
    // Get profile to get account ID
    final profile = await ref.watch(clientProfileProvider(clientId).future);
    if (profile == null) return null;

    final accountId = profile.id; // Use account ID for FK queries

    // Get active trainer relationship
    final response = await supabase
        .from('trainer_client_relationships')
        .select('''
          status,
          trainer:trainer_id(id, full_name, avatar_url)
        ''')
        .eq('client_id', accountId)
        .eq('status', 'active')
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    final trainer = response['trainer'] as Map<String, dynamic>?;
    if (trainer == null) return null;

    return TrainerInfo(
      id: trainer['id'] as String,
      name: trainer['full_name'] as String? ?? 'Your Trainer',
      avatarUrl: trainer['avatar_url'] as String?,
      status: response['status'] as String? ?? 'active',
    );
  } catch (e) {
    return null;
  }
});
