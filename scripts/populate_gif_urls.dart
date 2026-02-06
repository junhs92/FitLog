// Script to populate gif_url column from ExerciseDB API
// Run: dart run scripts/populate_gif_urls.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String rapidApiKey = '25ab153720mshb5306c51953cddap123896jsn5627703e9564';
const String rapidApiHost = 'exercisedb-api1.p.rapidapi.com';
const String baseUrl = 'https://exercisedb-api1.p.rapidapi.com/api/v1';

// Supabase config
const String supabaseUrl = 'https://cqgqzefzgcrvfnjushwk.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxZ3F6ZWZ6Z2NydmZuanVzaHdrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3NjgwMjQsImV4cCI6MjA4MDM0NDAyNH0.4V8tbA7dEkpwreT_bLB3LdTGluH0oAyCE-Dtqfd9CdI';

Future<void> main() async {
  print('Fetching exercises with exercisedb_id from Supabase...');

  // Fetch exercises that have exercisedb_id
  final exercisesResponse = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/exercises?select=id,name,exercisedb_id,gif_url&exercisedb_id=not.is.null'),
    headers: {
      'apikey': supabaseAnonKey,
      'Authorization': 'Bearer $supabaseAnonKey',
    },
  );

  if (exercisesResponse.statusCode != 200) {
    print('Error fetching exercises: ${exercisesResponse.body}');
    return;
  }

  final exercises = jsonDecode(exercisesResponse.body) as List;
  print('Found ${exercises.length} exercises with exercisedb_id');

  // Filter to only exercises without gif_url
  final exercisesToUpdate = exercises.where((e) => e['gif_url'] == null).toList();
  print('${exercisesToUpdate.length} exercises need gif_url populated');

  if (exercisesToUpdate.isEmpty) {
    print('All exercises already have gif_url!');
    return;
  }

  final updates = <Map<String, dynamic>>[];

  for (var i = 0; i < exercisesToUpdate.length; i++) {
    final exercise = exercisesToUpdate[i];
    final exerciseDbId = exercise['exercisedb_id'] as String;
    final name = exercise['name'] as String;

    print('[$i/${exercisesToUpdate.length}] Fetching gif for: $name ($exerciseDbId)');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exercises/$exerciseDbId'),
        headers: {
          'x-rapidapi-key': rapidApiKey,
          'x-rapidapi-host': rapidApiHost,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final gifUrl = data['data']['gifUrl'] as String?;
          if (gifUrl != null && gifUrl.isNotEmpty) {
            updates.add({
              'id': exercise['id'],
              'name': name,
              'gif_url': gifUrl,
            });
            print('  ✓ Found gif: $gifUrl');
          } else {
            print('  ✗ No gifUrl in response');
          }
        }
      } else {
        print('  ✗ API error: ${response.statusCode}');
      }
    } catch (e) {
      print('  ✗ Error: $e');
    }

    // Rate limiting - wait 100ms between requests
    await Future.delayed(Duration(milliseconds: 100));
  }

  print('\n--- Summary ---');
  print('Found ${updates.length} exercises with gif URLs');

  if (updates.isEmpty) {
    print('No updates to apply.');
    return;
  }

  // Generate SQL update statements
  print('\n--- SQL Statements ---');
  print('-- Run these in Supabase SQL Editor:\n');

  for (final update in updates) {
    final id = update['id'];
    final name = update['name'];
    final gifUrl = update['gif_url'].toString().replaceAll("'", "''");
    print("UPDATE exercises SET gif_url = '$gifUrl' WHERE id = '$id'; -- $name");
  }

  print('\n--- Done ---');
}
