/// Interactive Exercise Search Tool
///
/// Usage: dart run scripts/search_exercise.dart "exercise name"
///
/// This tool searches the ExerciseDB API and shows matching exercises
/// with their IDs and GIF URLs for manual mapping.

import 'dart:io';
import 'package:dio/dio.dart';

const String apiKey = '25ab153720mshb5306c51953cddap123896jsn5627703e9564';
const String apiHost = 'exercisedb.p.rapidapi.com';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run scripts/search_exercise.dart "exercise name"');
    print('');
    print('Examples:');
    print('  dart run scripts/search_exercise.dart "bench press"');
    print('  dart run scripts/search_exercise.dart "bicep curl"');
    print('  dart run scripts/search_exercise.dart "squat"');
    exit(1);
  }

  final searchTerm = args.join(' ').toLowerCase();
  print('Searching for: "$searchTerm"\n');

  final dio = Dio()
    ..options.headers = {
      'x-rapidapi-key': apiKey,
      'x-rapidapi-host': apiHost,
    }
    ..options.connectTimeout = const Duration(seconds: 15)
    ..options.receiveTimeout = const Duration(seconds: 15);

  try {
    final encodedName = Uri.encodeComponent(searchTerm);
    final response = await dio.get(
      'https://exercisedb.p.rapidapi.com/exercises/name/$encodedName',
      queryParameters: {'limit': '15'},
    );

    if (response.statusCode == 200 && response.data is List) {
      final results = response.data as List;

      if (results.isEmpty) {
        print('No exercises found matching "$searchTerm"');
        print('\nTry a different search term or check spelling.');
        exit(0);
      }

      print('Found ${results.length} exercises:\n');
      print('=' * 80);

      for (int i = 0; i < results.length; i++) {
        final exercise = results[i] as Map<String, dynamic>;
        print('');
        print('[${i + 1}] ${exercise['name']}');
        print('    ID: ${exercise['id']}');
        print('    Equipment: ${exercise['equipment']}');
        print('    Body Part: ${exercise['bodyPart']}');
        print('    Target: ${exercise['target']}');
        if (exercise['gifUrl'] != null) {
          print('    GIF: ${exercise['gifUrl']}');
        }
        print('-' * 80);
      }

      print('\n✅ Copy the ID of the exercise you want to use.');
      print('');
      print('SQL Update Template:');
      print("UPDATE exercises SET exercisedb_id = '<ID>', thumbnail_url = '<GIF_URL>' WHERE name = '<YOUR_EXERCISE_NAME>';");
    }
  } catch (e) {
    print('Error: $e');
    if (e is DioException) {
      print('Status: ${e.response?.statusCode}');
      print('Response: ${e.response?.data}');
    }
    exit(1);
  }
}
