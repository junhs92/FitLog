import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/academy_video_model.dart';

abstract class AcademyRemoteDataSource {
  Future<List<AcademyVideoModel>> getVideos({
    String? category,
    int limit = 10,
    int offset = 0,
  });

  Future<void> syncVideos();
}

class AcademyRemoteDataSourceImpl implements AcademyRemoteDataSource {
  final SupabaseClient _client;

  AcademyRemoteDataSourceImpl(this._client);

  @override
  Future<List<AcademyVideoModel>> getVideos({
    String? category,
    int limit = 10,
    int offset = 0,
  }) async {
    var query = _client
        .from('academy_videos')
        .select('*, academy_channels(channel_name_ko)');

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    final oneMonthAgo =
        DateTime.now().subtract(const Duration(days: 30)).toUtc().toIso8601String();
    query = query.gte('published_at', oneMonthAgo);

    final response = await query
        .order('published_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AcademyVideoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> syncVideos() async {
    await _client.functions.invoke('sync-academy-videos');
  }
}
