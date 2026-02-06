import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/muscle_activity_remote_datasource.dart';
import '../../data/repositories/muscle_activity_repository_impl.dart';
import '../../domain/entities/client_muscle_map_entity.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/muscle_activity_entity.dart';
import '../../domain/repositories/muscle_activity_repository.dart';

/// Provider for Supabase client
final _supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for muscle activity remote datasource
final muscleActivityDataSourceProvider =
    Provider<MuscleActivityRemoteDataSource>((ref) {
  return MuscleActivityRemoteDataSource(ref.read(_supabaseClientProvider));
});

/// Provider for muscle activity repository
final muscleActivityRepositoryProvider =
    Provider<MuscleActivityRepository>((ref) {
  return MuscleActivityRepositoryImpl(
    ref.read(muscleActivityDataSourceProvider),
  );
});

/// Provider for client's muscle map data
/// Parameters: (clientId: String, dayRange: int?) - null means all time
final clientMuscleMapProvider = FutureProvider.family<
    ClientMuscleMapEntity,
    ({String clientId, int? dayRange})>((ref, params) async {
  final repository = ref.read(muscleActivityRepositoryProvider);
  final result = await repository.getClientMuscleMap(
    clientId: params.clientId,
    dayRange: params.dayRange,
  );

  return result.fold(
    (failure) => ClientMuscleMapEntity.empty(params.clientId, dayRange: params.dayRange ?? 0),
    (muscleMap) => muscleMap,
  );
});

/// Convenience provider for 7-day muscle map
final clientMuscleMap7DayProvider =
    FutureProvider.family<ClientMuscleMapEntity, String>((ref, clientId) async {
  return ref.watch(clientMuscleMapProvider(
    (clientId: clientId, dayRange: 7),
  ).future);
});

/// Convenience provider for 14-day muscle map
final clientMuscleMap14DayProvider =
    FutureProvider.family<ClientMuscleMapEntity, String>((ref, clientId) async {
  return ref.watch(clientMuscleMapProvider(
    (clientId: clientId, dayRange: 14),
  ).future);
});

/// Convenience provider for 30-day muscle map
final clientMuscleMap30DayProvider =
    FutureProvider.family<ClientMuscleMapEntity, String>((ref, clientId) async {
  return ref.watch(clientMuscleMapProvider(
    (clientId: clientId, dayRange: 30),
  ).future);
});

/// Provider for session muscle activity
final sessionMuscleActivityProvider =
    FutureProvider.family<SessionMuscleActivity, String>((ref, sessionId) async {
  final repository = ref.read(muscleActivityRepositoryProvider);
  final result = await repository.getSessionMuscleActivity(sessionId: sessionId);

  return result.fold(
    (failure) => SessionMuscleActivity(
      sessionId: sessionId,
      sessionDate: DateTime.now(),
      muscleVolumes: {},
      muscleSets: {},
    ),
    (activity) => activity,
  );
});

/// Provider for muscle history
final muscleHistoryProvider = FutureProvider.family<
    List<SessionMuscleActivity>,
    ({String clientId, DateTime fromDate, DateTime toDate})>((ref, params) async {
  final repository = ref.read(muscleActivityRepositoryProvider);
  final result = await repository.getMuscleHistory(
    clientId: params.clientId,
    fromDate: params.fromDate,
    toDate: params.toDate,
  );

  return result.fold(
    (failure) => <SessionMuscleActivity>[],
    (history) => history,
  );
});

/// State for muscle map screen
class MuscleMapScreenState {
  final ClientMuscleMapEntity? muscleMap;
  final MuscleGroup? selectedMuscle;
  final int dayRange;
  final bool isLoading;
  final String? error;

  const MuscleMapScreenState({
    this.muscleMap,
    this.selectedMuscle,
    this.dayRange = 7,
    this.isLoading = false,
    this.error,
  });

  MuscleMapScreenState copyWith({
    ClientMuscleMapEntity? muscleMap,
    MuscleGroup? selectedMuscle,
    int? dayRange,
    bool? isLoading,
    String? error,
    bool clearSelectedMuscle = false,
  }) {
    return MuscleMapScreenState(
      muscleMap: muscleMap ?? this.muscleMap,
      selectedMuscle: clearSelectedMuscle ? null : (selectedMuscle ?? this.selectedMuscle),
      dayRange: dayRange ?? this.dayRange,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get activity for selected muscle
  MuscleActivityEntity? get selectedMuscleActivity {
    if (selectedMuscle == null || muscleMap == null) return null;
    return muscleMap!.getActivity(selectedMuscle!);
  }
}

/// Notifier for muscle map screen state
class MuscleMapScreenNotifier extends StateNotifier<MuscleMapScreenState> {
  final MuscleActivityRepository _repository;
  final String clientId;

  MuscleMapScreenNotifier(this._repository, this.clientId)
      : super(const MuscleMapScreenState()) {
    loadMuscleMap();
  }

  /// Load muscle map data
  Future<void> loadMuscleMap() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getClientMuscleMap(
      clientId: clientId,
      dayRange: state.dayRange,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (muscleMap) => state = state.copyWith(
        muscleMap: muscleMap,
        isLoading: false,
      ),
    );
  }

  /// Change the date range and reload
  Future<void> changeDayRange(int dayRange) async {
    if (dayRange == state.dayRange) return;
    state = state.copyWith(dayRange: dayRange);
    await loadMuscleMap();
  }

  /// Select a muscle group
  void selectMuscle(MuscleGroup? muscle) {
    if (muscle == state.selectedMuscle) {
      state = state.copyWith(clearSelectedMuscle: true);
    } else {
      state = state.copyWith(selectedMuscle: muscle);
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadMuscleMap();
  }
}

/// Provider for muscle map screen notifier
final muscleMapScreenProvider =
    StateNotifierProvider.family<MuscleMapScreenNotifier, MuscleMapScreenState, String>(
  (ref, clientId) {
    return MuscleMapScreenNotifier(
      ref.read(muscleActivityRepositoryProvider),
      clientId,
    );
  },
);

/// Provider for exercises filtered by muscle group
final exercisesByMuscleGroupProvider =
    FutureProvider.family<List<String>, MuscleGroup>((ref, muscleGroup) async {
  final repository = ref.read(muscleActivityRepositoryProvider);
  final result = await repository.getExerciseIdsByMuscleGroup(
    muscleGroup: muscleGroup,
  );

  return result.fold(
    (failure) => <String>[],
    (exerciseIds) => exerciseIds,
  );
});
