import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Service for interacting with ExerciseDB API via RapidAPI
/// Provides exercise search and image URL generation
class ExerciseDbService {
  static const String baseUrl = 'https://exercisedb-api1.p.rapidapi.com/api/v1';
  static const String apiKey =
      '25ab153720mshb5306c51953cddap123896jsn5627703e9564';
  static const String apiHost = 'exercisedb-api1.p.rapidapi.com';

  final Dio _dio;

  ExerciseDbService() : _dio = Dio() {
    _dio.options.headers = {
      'x-rapidapi-key': apiKey,
      'x-rapidapi-host': apiHost,
    };
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Search exercises by name
  /// Returns a list of matching exercises from ExerciseDB
  Future<List<ExerciseDbExercise>> searchByName(String name) async {
    try {
      final response = await _dio.get(
        '$baseUrl/exercises/search',
        queryParameters: {'search': name, 'limit': 20},
      );

      if (response.data is Map && response.data['success'] == true) {
        final data = response.data['data'] as List;
        return data
            .map((e) => ExerciseDbExercise.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('ExerciseDB search error: $e');
      return [];
    }
  }

  /// Get exercise details by ID
  Future<ExerciseDbExercise?> getExerciseById(String exerciseId) async {
    try {
      final response = await _dio.get('$baseUrl/exercises/$exerciseId');

      if (response.data is Map && response.data['success'] == true) {
        return ExerciseDbExercise.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('ExerciseDB get by id error: $e');
      return null;
    }
  }

  /// Get all exercises (paginated)
  Future<List<ExerciseDbExercise>> getAllExercises({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/exercises',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.data is Map && response.data['success'] == true) {
        final data = response.data['data'] as List;
        return data
            .map((e) => ExerciseDbExercise.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('ExerciseDB get all error: $e');
      return [];
    }
  }

  /// Get image URL for an exercise (no auth required - direct CDN URL)
  /// Returns the appropriate resolution image URL
  static String? getImageUrl(String? imageUrl, {String resolution = '480p'}) {
    // Images are served directly from CDN, no auth needed
    return imageUrl;
  }

  /// Get HTTP headers - not needed for CDN images but kept for compatibility
  static Map<String, String> getImageHeaders() {
    // CDN images don't require auth headers
    return {};
  }
}

/// Model for ExerciseDB API exercise response
class ExerciseDbExercise {
  final String exerciseId;
  final String name;
  final String? exerciseType;
  final List<String> bodyParts;
  final List<String> targetMuscles;
  final List<String> secondaryMuscles;
  final List<String> equipments;
  final String? imageUrl;
  final Map<String, String>? imageUrls;
  final String? gifUrl;
  final String? videoUrl;
  final List<String> instructions;

  const ExerciseDbExercise({
    required this.exerciseId,
    required this.name,
    this.exerciseType,
    this.bodyParts = const [],
    this.targetMuscles = const [],
    this.secondaryMuscles = const [],
    this.equipments = const [],
    this.imageUrl,
    this.imageUrls,
    this.gifUrl,
    this.videoUrl,
    this.instructions = const [],
  });

  factory ExerciseDbExercise.fromJson(Map<String, dynamic> json) {
    // Parse imageUrls map
    Map<String, String>? imageUrlsMap;
    if (json['imageUrls'] is Map) {
      imageUrlsMap = Map<String, String>.from(
        (json['imageUrls'] as Map).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      );
    }

    return ExerciseDbExercise(
      exerciseId: json['exerciseId'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      exerciseType: json['exerciseType'] as String?,
      bodyParts: _parseStringList(json['bodyParts'] ?? json['bodyPart']),
      targetMuscles: _parseStringList(json['targetMuscles'] ?? json['target']),
      secondaryMuscles: _parseStringList(json['secondaryMuscles']),
      equipments: _parseStringList(json['equipments'] ?? json['equipment']),
      imageUrl: json['imageUrl'] as String?,
      imageUrls: imageUrlsMap,
      gifUrl: json['gifUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      instructions: _parseStringList(json['instructions']),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is String) return [value];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Get image URL at specific resolution (360p, 480p, 720p, 1080p)
  String? getImageAtResolution(String resolution) {
    return imageUrls?[resolution] ?? imageUrl;
  }

  @override
  String toString() => 'ExerciseDbExercise(id: $exerciseId, name: $name)';
}
