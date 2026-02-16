import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/supabase_provider.dart';
import '../../data/datasources/academy_remote_datasource.dart';
import '../../data/repositories/academy_repository_impl.dart';
import '../../domain/entities/academy_category.dart';
import '../../domain/entities/academy_video_entity.dart';
import '../../domain/repositories/academy_repository.dart';

/// Provider for remote data source
final academyRemoteDataSourceProvider =
    Provider<AcademyRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AcademyRemoteDataSourceImpl(client);
});

/// Provider for repository
final academyRepositoryProvider = Provider<AcademyRepository>((ref) {
  final dataSource = ref.watch(academyRemoteDataSourceProvider);
  return AcademyRepositoryImpl(dataSource);
});

/// Currently selected category
final academyCategoryProvider =
    StateProvider<AcademyCategory>((ref) => AcademyCategory.all);

/// Currently playing video ID (null = none playing)
final academyPlayingVideoProvider = StateProvider<String?>((ref) => null);

/// State for the video list
class AcademyVideosState {
  final List<AcademyVideoEntity> videos;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSyncing;
  final bool hasMore;
  final String? errorMessage;

  const AcademyVideosState({
    this.videos = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSyncing = false,
    this.hasMore = true,
    this.errorMessage,
  });

  AcademyVideosState copyWith({
    List<AcademyVideoEntity>? videos,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSyncing,
    bool? hasMore,
    String? errorMessage,
  }) {
    return AcademyVideosState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSyncing: isSyncing ?? this.isSyncing,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for academy video list with pagination
class AcademyVideosNotifier extends StateNotifier<AcademyVideosState> {
  final AcademyRepository _repository;
  final String? _categoryFilter;
  static const int _pageSize = 500;

  AcademyVideosNotifier(this._repository, this._categoryFilter)
      : super(const AcademyVideosState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final category =
        (_categoryFilter == null || _categoryFilter == 'all') ? null : _categoryFilter;

    final result = await _repository.getVideos(
      category: category,
      limit: _pageSize,
      offset: 0,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (videos) {
        if (videos.isEmpty) {
          // DB empty — trigger initial sync
          _syncThenReload(category);
        } else {
          state = state.copyWith(
            isLoading: false,
            videos: videos,
            hasMore: videos.length >= _pageSize,
          );
        }
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final category =
        (_categoryFilter == null || _categoryFilter == 'all') ? null : _categoryFilter;

    final result = await _repository.getVideos(
      category: category,
      limit: _pageSize,
      offset: state.videos.length,
    );

    result.fold(
      (failure) => state = state.copyWith(isLoadingMore: false),
      (videos) => state = state.copyWith(
        isLoadingMore: false,
        videos: [...state.videos, ...videos],
        hasMore: videos.length >= _pageSize,
      ),
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isSyncing: true);

    // Sync from YouTube RSS first
    await _repository.syncVideos();

    state = state.copyWith(isSyncing: false);

    // Then reload from DB
    await loadInitial();
  }

  Future<void> _syncThenReload(String? category) async {
    state = state.copyWith(isSyncing: true);

    await _repository.syncVideos();

    // Re-read from DB after sync
    final result = await _repository.getVideos(
      category: category,
      limit: _pageSize,
      offset: 0,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isSyncing: false,
        errorMessage: failure.message,
      ),
      (videos) => state = state.copyWith(
        isLoading: false,
        isSyncing: false,
        videos: videos,
        hasMore: videos.length >= _pageSize,
      ),
    );
  }
}

/// Provider for academy videos notifier, auto-recreated on category change
final academyVideosProvider =
    StateNotifierProvider<AcademyVideosNotifier, AcademyVideosState>((ref) {
  final repository = ref.watch(academyRepositoryProvider);
  final category = ref.watch(academyCategoryProvider);
  return AcademyVideosNotifier(repository, category.dbValue);
});
