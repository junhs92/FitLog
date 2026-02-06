/// Script to map existing exercises to ExerciseDB IDs and thumbnail URLs
///
/// This script fetches all exercises from Supabase and attempts to match
/// them with exercises from the ExerciseDB API, then updates the
/// exercisedb_id and thumbnail_url columns in the database.
///
/// Usage:
///   dart run scripts/map_exercisedb_ids.dart
///
/// Prerequisites:
///   - Run the migration to add exercisedb_id column
///   - Ensure RAPIDAPI_KEY is valid and subscribed to ExerciseDB API

import 'dart:io';
import 'package:dio/dio.dart';

// ExerciseDB API configuration (exercisedb-api1)
const String exerciseDbBaseUrl = 'https://exercisedb-api1.p.rapidapi.com/api/v1';
const String apiKey = '25ab153720mshb5306c51953cddap123896jsn5627703e9564';
const String apiHost = 'exercisedb-api1.p.rapidapi.com';

// Supabase configuration
const String supabaseUrl = 'https://cqgqzefzgcrvfnjushwk.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxZ3F6ZWZ6Z2NydmZuanVzaHdrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3NjgwMjQsImV4cCI6MjA4MDM0NDAyNH0.4V8tbA7dEkpwreT_bLB3LdTGluH0oAyCE-Dtqfd9CdI';

late Dio exerciseDbDio;
late Dio supabaseDio;

void main() async {
  print('=== ExerciseDB ID Mapping Script ===\n');

  // Initialize HTTP clients
  exerciseDbDio = Dio()
    ..options.headers = {
      'x-rapidapi-key': apiKey,
      'x-rapidapi-host': apiHost,
    }
    ..options.connectTimeout = const Duration(seconds: 15)
    ..options.receiveTimeout = const Duration(seconds: 15);

  supabaseDio = Dio()
    ..options.headers = {
      'apikey': supabaseAnonKey,
      'Authorization': 'Bearer $supabaseAnonKey',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    };

  try {
    // Step 1: Fetch all exercises from Supabase
    print('Fetching exercises from Supabase...');
    final exercises = await fetchSupabaseExercises();
    print('Found ${exercises.length} exercises\n');

    // Step 2: Filter exercises without thumbnail_url
    final unmappedExercises = exercises
        .where((e) =>
            e['thumbnail_url'] == null ||
            (e['thumbnail_url'] as String).isEmpty)
        .toList();
    print('${unmappedExercises.length} exercises need mapping\n');

    if (unmappedExercises.isEmpty) {
      print('All exercises already have thumbnail URLs!');
      return;
    }

    // Step 3: Map each exercise
    int successCount = 0;
    int failCount = 0;
    final results = <Map<String, dynamic>>[];

    for (int i = 0; i < unmappedExercises.length; i++) {
      final exercise = unmappedExercises[i];
      final name = exercise['name'] as String;
      final equipment = exercise['equipment'] as String?;
      final id = exercise['id'] as String;

      print(
          '[${'${i + 1}'.padLeft(2)}/${unmappedExercises.length}] Searching: $name');

      try {
        // Search ExerciseDB by name
        final match = await findBestMatch(name, equipment);

        if (match != null) {
          // Update Supabase with ExerciseDB ID and thumbnail URL
          await updateExercise(
            id,
            match['exerciseId'] as String,
            match['imageUrl'] as String?,
          );
          print('    ✓ Mapped to: ${match['name']} (${match['exerciseId']})');
          if (match['imageUrl'] != null) {
            print('    ✓ Image: ${match['imageUrl']}');
          }
          successCount++;
          results.add({
            'local_name': name,
            'exercisedb_name': match['name'],
            'exercisedb_id': match['exerciseId'],
            'image_url': match['imageUrl'],
            'status': 'success',
          });
        } else {
          print('    ✗ No match found');
          failCount++;
          results.add({
            'local_name': name,
            'status': 'no_match',
          });
        }

        // Rate limiting: wait 300ms between API calls
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        print('    ✗ Error: $e');
        failCount++;
        results.add({
          'local_name': name,
          'status': 'error',
          'error': e.toString(),
        });
        // Wait longer on errors (might be rate limit)
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    // Step 4: Print summary
    print('\n=== Summary ===');
    print('Successfully mapped: $successCount');
    print('Failed to map: $failCount');

    // Print failed mappings for manual review
    if (failCount > 0) {
      print('\n=== Exercises requiring manual mapping ===');
      for (final result in results.where((r) => r['status'] != 'success')) {
        print('  - ${result['local_name']}');
      }
    }
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

/// Fetch all exercises from Supabase
Future<List<Map<String, dynamic>>> fetchSupabaseExercises() async {
  final response = await supabaseDio.get(
    '$supabaseUrl/rest/v1/exercises',
    queryParameters: {
      'select': 'id,name,equipment,muscle_group,exercisedb_id,thumbnail_url',
      'order': 'name.asc',
    },
  );

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(response.data);
  }
  throw Exception('Failed to fetch exercises: ${response.statusCode}');
}

/// Search ExerciseDB and find the best match for an exercise
Future<Map<String, dynamic>?> findBestMatch(
    String name, String? equipment) async {
  try {
    // Clean the search name
    final searchName = _cleanSearchName(name);

    final response = await exerciseDbDio.get(
      '$exerciseDbBaseUrl/exercises/search',
      queryParameters: {'search': searchName, 'limit': 10},
    );

    if (response.statusCode == 200 &&
        response.data is Map &&
        response.data['success'] == true) {
      final results = List<Map<String, dynamic>>.from(response.data['data']);

      if (results.isEmpty) return null;

      // Try to find best match based on equipment
      if (equipment != null) {
        final equipmentLower = equipment.toLowerCase();

        for (final result in results) {
          final equipments = _parseEquipments(result);
          if (equipments.any((e) =>
              e.toLowerCase().contains(equipmentLower) ||
              equipmentLower.contains(e.toLowerCase()))) {
            return result;
          }
        }
      }

      // Return first result if no equipment match
      return results.first;
    }
    return null;
  } catch (e) {
    if (e is DioException && e.response?.statusCode == 404) {
      return null;
    }
    rethrow;
  }
}

/// Update the exercise in Supabase with ExerciseDB ID and thumbnail URL
Future<void> updateExercise(
  String exerciseId,
  String exerciseDbId,
  String? thumbnailUrl,
) async {
  final data = <String, dynamic>{
    'exercisedb_id': exerciseDbId,
  };

  if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
    data['thumbnail_url'] = thumbnailUrl;
  }

  final response = await supabaseDio.patch(
    '$supabaseUrl/rest/v1/exercises',
    queryParameters: {'id': 'eq.$exerciseId'},
    data: data,
  );

  if (response.statusCode != 200 && response.statusCode != 204) {
    throw Exception('Failed to update exercise: ${response.statusCode}');
  }
}

/// Clean exercise name for search
String _cleanSearchName(String name) {
  var cleanName = name.toLowerCase();

  // Remove equipment prefixes
  final prefixes = [
    'barbell',
    'dumbbell',
    'cable',
    'machine',
    'smith',
    'kettlebell',
    'resistance band',
    'ez bar',
    'ez-bar',
  ];

  for (final prefix in prefixes) {
    if (cleanName.startsWith(prefix)) {
      cleanName = cleanName.substring(prefix.length).trim();
    }
  }

  // Remove common suffixes and variations
  cleanName = cleanName
      .replaceAll(' (close grip)', '')
      .replaceAll(' (wide grip)', '')
      .replaceAll(' (neutral grip)', '')
      .replaceAll(' variation', '')
      .replaceAll(' - ', ' ')
      .trim();

  return cleanName;
}

/// Parse equipments from ExerciseDB response
List<String> _parseEquipments(Map<String, dynamic> exercise) {
  final equipments = exercise['equipments'] ?? exercise['equipment'];
  if (equipments == null) return [];
  if (equipments is String) return [equipments];
  if (equipments is List) return equipments.map((e) => e.toString()).toList();
  return [];
}
