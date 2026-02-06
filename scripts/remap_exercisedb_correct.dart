/// Improved ExerciseDB Mapping Script with Fuzzy Matching
///
/// This script uses Levenshtein distance and keyword matching to correctly
/// map local exercises to ExerciseDB entries, avoiding loose string matches
/// that caused incorrect mappings like:
///   - Battle Ropes -> Calf Stretch with Rope (both contain "Rope")
///   - Box Jump -> Jump Rope (both contain "Jump")
///   - Bird Dog -> Downward Facing Dog (both contain "Dog")
///
/// Usage:
///   dart run scripts/remap_exercisedb_correct.dart
///
/// Output:
///   - Console report of all mappings with confidence scores
///   - SQL migration file for review and manual application

import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';

// ExerciseDB API configuration (using original API that works)
const String exerciseDbBaseUrl = 'https://exercisedb.p.rapidapi.com';
const String apiKey = '25ab153720mshb5306c51953cddap123896jsn5627703e9564';
const String apiHost = 'exercisedb.p.rapidapi.com';

// Supabase configuration
const String supabaseUrl = 'https://cqgqzefzgcrvfnjushwk.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxZ3F6ZWZ6Z2NydmZuanVzaHdrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3NjgwMjQsImV4cCI6MjA4MDM0NDAyNH0.4V8tbA7dEkpwreT_bLB3LdTGluH0oAyCE-Dtqfd9CdI';

// Matching thresholds
const int minMatchScore = 40; // Minimum score to accept a match
const double minNameSimilarity = 0.60; // Minimum Levenshtein similarity (60%)

late Dio exerciseDbDio;
late Dio supabaseDio;

// Results storage
final List<MatchResult> matchResults = [];
final List<MatchResult> needsManualReview = [];
final List<MatchResult> successfulMatches = [];

void main() async {
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║     ExerciseDB Correct Mapping Script (Fuzzy Matching)       ║');
  print('╚══════════════════════════════════════════════════════════════╝\n');

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
    };

  try {
    // Step 1: Fetch all exercises from Supabase
    print('📥 Fetching exercises from Supabase...');
    final exercises = await fetchSupabaseExercises();
    print('   Found ${exercises.length} exercises\n');

    // Step 2: Process each exercise
    print('🔍 Searching for correct matches...\n');

    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final name = exercise['name'] as String;
      final equipment = exercise['equipment'] as String?;
      final muscleGroup = exercise['muscle_group'] as String?;
      final id = exercise['id'] as String;
      final currentExerciseDbId = exercise['exercisedb_id'] as String?;

      print(
          '[${'${i + 1}'.padLeft(2)}/${exercises.length}] $name (${equipment ?? 'no equipment'})');

      try {
        final match = await findBestMatchWithScoring(
          name,
          equipment: equipment,
          muscleGroup: muscleGroup,
        );

        final result = MatchResult(
          localId: id,
          localName: name,
          localEquipment: equipment,
          localMuscleGroup: muscleGroup,
          currentExerciseDbId: currentExerciseDbId,
        );

        if (match != null) {
          result.matchedName = match['name'] as String?;
          result.matchedExerciseDbId = match['exerciseId'] as String? ?? match['id'] as String?;
          result.matchedImageUrl = match['_thumbnailUrl'] as String?;  // GIF from image endpoint (360p)
          result.matchedVideoUrl = match['_videoUrl'] as String?;  // GIF from image endpoint (720p)
          result.matchScore = match['_score'] as int? ?? 0;
          result.matchDetails = match['_scoreDetails'] as String? ?? '';

          // Check if this is a different mapping than current
          if (currentExerciseDbId != result.matchedExerciseDbId) {
            result.needsUpdate = true;
          }

          if (result.matchScore >= minMatchScore) {
            print('   ✓ ${result.matchedName} (score: ${result.matchScore})');
            print('     ${result.matchDetails}');
            successfulMatches.add(result);
          } else {
            print(
                '   ⚠ Low confidence: ${result.matchedName} (score: ${result.matchScore})');
            print('     ${result.matchDetails}');
            needsManualReview.add(result);
          }
        } else {
          print('   ✗ No match found');
          needsManualReview.add(result);
        }

        matchResults.add(result);

        // Rate limiting - increased delay to avoid API throttling
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('   ✗ Error: $e');
        final result = MatchResult(
          localId: id,
          localName: name,
          localEquipment: equipment,
          localMuscleGroup: muscleGroup,
          currentExerciseDbId: currentExerciseDbId,
          error: e.toString(),
        );
        needsManualReview.add(result);
        matchResults.add(result);
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    // Step 3: Generate reports
    print('\n' + '═' * 60);
    print('                        SUMMARY');
    print('═' * 60);
    print('Total exercises: ${exercises.length}');
    print('Successful matches: ${successfulMatches.length}');
    print('Needs manual review: ${needsManualReview.length}');

    // Count how many need updates
    final needsUpdates =
        successfulMatches.where((m) => m.needsUpdate).toList();
    print('Exercises needing URL updates: ${needsUpdates.length}');

    // Generate SQL migration file
    await generateSqlMigration(successfulMatches);

    // Print manual review list
    if (needsManualReview.isNotEmpty) {
      print('\n' + '═' * 60);
      print('            EXERCISES REQUIRING MANUAL REVIEW');
      print('═' * 60);
      for (final result in needsManualReview) {
        print('\n• ${result.localName}');
        print('  Equipment: ${result.localEquipment ?? 'N/A'}');
        print('  Muscle group: ${result.localMuscleGroup ?? 'N/A'}');
        if (result.matchedName != null) {
          print('  Best match: ${result.matchedName} (score: ${result.matchScore})');
        }
        if (result.error != null) {
          print('  Error: ${result.error}');
        }
      }
    }

    print('\n✅ Done! Check the generated SQL file for updates.');
  } catch (e, stack) {
    print('❌ Error: $e');
    print(stack);
    exit(1);
  }
}

/// Fetch all non-custom exercises from Supabase
Future<List<Map<String, dynamic>>> fetchSupabaseExercises() async {
  final response = await supabaseDio.get(
    '$supabaseUrl/rest/v1/exercises',
    queryParameters: {
      'select':
          'id,name,equipment,muscle_group,exercisedb_id,thumbnail_url,video_url',
      'is_custom': 'eq.false',
      'order': 'name.asc',
    },
  );

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(response.data);
  }
  throw Exception('Failed to fetch exercises: ${response.statusCode}');
}

/// Find the best match using a scoring system
Future<Map<String, dynamic>?> findBestMatchWithScoring(
  String localName, {
  String? equipment,
  String? muscleGroup,
}) async {
  // Try multiple search strategies
  final searchStrategies = [
    localName, // Full name
    _getCoreName(localName), // Core exercise name
  ];

  Map<String, dynamic>? bestMatch;
  int bestScore = 0;
  String bestScoreDetails = '';

  for (final searchTerm in searchStrategies.toSet()) {
    if (searchTerm.isEmpty) continue;

    try {
      // URL encode the search term for the path
      final encodedName = Uri.encodeComponent(searchTerm.toLowerCase());

      final response = await exerciseDbDio.get(
        '$exerciseDbBaseUrl/exercises/name/$encodedName',
        queryParameters: {'limit': '20'},
      );

      if (response.statusCode == 200 && response.data is List) {
        final results = List<Map<String, dynamic>>.from(response.data);

        for (final result in results) {
          final scoreResult = _calculateMatchScore(
            localName: localName,
            localEquipment: equipment,
            localMuscleGroup: muscleGroup,
            candidate: result,
          );

          if (scoreResult.score > bestScore) {
            bestScore = scoreResult.score;
            bestMatch = Map<String, dynamic>.from(result);
            bestMatch!['_score'] = bestScore;
            bestMatch['_scoreDetails'] = scoreResult.details;
            bestScoreDetails = scoreResult.details;

            // Original API uses 'id' not 'exerciseId'
            bestMatch['exerciseId'] = result['id'];
            final id = result['id'] as String;
            // Use the image endpoint for both thumbnail and video (returns GIF files)
            // The /image endpoint returns animated GIFs which work as both thumbnail and video
            // Include API key for authenticated access
            bestMatch['_thumbnailUrl'] = 'https://exercisedb.p.rapidapi.com/image?exerciseId=$id&resolution=360&rapidapi-key=$apiKey';
            bestMatch['_videoUrl'] = 'https://exercisedb.p.rapidapi.com/image?exerciseId=$id&resolution=720&rapidapi-key=$apiKey';
          }
        }
      }

      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        continue;
      }
      // Continue with other search strategies
    }
  }

  return bestMatch;
}

/// Calculate a match score between local exercise and API candidate
_ScoreResult _calculateMatchScore({
  required String localName,
  required String? localEquipment,
  required String? localMuscleGroup,
  required Map<String, dynamic> candidate,
}) {
  int score = 0;
  final details = <String>[];

  final candidateName = (candidate['name'] as String? ?? '').toLowerCase();
  final localNameLower = localName.toLowerCase();

  // 1. Exact name match (highest priority)
  if (candidateName == localNameLower) {
    score += 50;
    details.add('+50 exact name');
  } else {
    // 2. Calculate name similarity using Levenshtein distance
    final similarity = _calculateSimilarity(localNameLower, candidateName);

    if (similarity >= 0.90) {
      score += 45;
      details.add('+45 name ~${(similarity * 100).toInt()}%');
    } else if (similarity >= 0.80) {
      score += 35;
      details.add('+35 name ~${(similarity * 100).toInt()}%');
    } else if (similarity >= 0.70) {
      score += 25;
      details.add('+25 name ~${(similarity * 100).toInt()}%');
    } else if (similarity >= 0.60) {
      score += 15;
      details.add('+15 name ~${(similarity * 100).toInt()}%');
    }

    // 3. Keyword matching - all keywords must be present
    final localKeywords = _extractKeywords(localName);
    final candidateKeywords = _extractKeywords(candidate['name'] as String? ?? '');

    final matchedKeywords = localKeywords
        .where((kw) =>
            candidateKeywords.contains(kw) || candidateName.contains(kw))
        .toList();

    if (localKeywords.isNotEmpty) {
      final keywordMatchRatio = matchedKeywords.length / localKeywords.length;

      if (keywordMatchRatio == 1.0 && localKeywords.length >= 2) {
        score += 30;
        details.add('+30 all keywords match');
      } else if (keywordMatchRatio >= 0.75) {
        score += 20;
        details.add('+20 ${matchedKeywords.length}/${localKeywords.length} keywords');
      } else if (keywordMatchRatio >= 0.5) {
        score += 10;
        details.add('+10 ${matchedKeywords.length}/${localKeywords.length} keywords');
      }
    }
  }

  // 4. Equipment match bonus
  if (localEquipment != null) {
    // Original API uses 'equipment' (singular string)
    final candidateEquipment = (candidate['equipment'] as String? ?? '').toLowerCase();
    final equipmentLower = localEquipment.toLowerCase();

    final equipmentMatches = candidateEquipment == equipmentLower ||
        candidateEquipment.contains(equipmentLower) ||
        equipmentLower.contains(candidateEquipment) ||
        _equipmentAliases(equipmentLower).contains(candidateEquipment);

    if (equipmentMatches) {
      score += 10;
      details.add('+10 equipment');
    }
  }

  // 5. Muscle group match bonus
  if (localMuscleGroup != null) {
    // Original API uses 'bodyPart' and 'target' (singular strings)
    final candidateBodyPart = (candidate['bodyPart'] as String? ?? '').toLowerCase();
    final candidateTarget = (candidate['target'] as String? ?? '').toLowerCase();

    final muscleLower = localMuscleGroup.toLowerCase();
    final muscleMatches =
        candidateBodyPart == muscleLower ||
        candidateBodyPart.contains(muscleLower) ||
        muscleLower.contains(candidateBodyPart) ||
        candidateTarget == muscleLower ||
        candidateTarget.contains(muscleLower) ||
        muscleLower.contains(candidateTarget) ||
        _muscleAliases(muscleLower).contains(candidateBodyPart) ||
        _muscleAliases(muscleLower).contains(candidateTarget);

    if (muscleMatches) {
      score += 10;
      details.add('+10 muscle');
    }
  }

  // 6. Penalty for likely mismatches
  // If names share a common word but are clearly different exercises
  if (_isLikelyMismatch(localNameLower, candidateName)) {
    score -= 30;
    details.add('-30 likely mismatch');
  }

  return _ScoreResult(score, details.join(', '));
}

/// Check if two exercise names are likely a mismatch despite sharing words
bool _isLikelyMismatch(String local, String candidate) {
  // Known problematic patterns
  final mismatchPatterns = [
    // Battle Ropes should not match Rope stretches
    (local: 'battle ropes', badMatch: 'stretch'),
    (local: 'battle ropes', badMatch: 'calf'),
    // Box Jump should not match Jump Rope
    (local: 'box jump', badMatch: 'rope'),
    // Bird Dog should not match Downward Dog
    (local: 'bird dog', badMatch: 'downward'),
    (local: 'bird dog', badMatch: 'facing'),
    // Pull-up should not match Push-up
    (local: 'pull-up', badMatch: 'push'),
    (local: 'pull up', badMatch: 'push'),
    (local: 'pullup', badMatch: 'push'),
    // Tricep Kickback should not match floor dips
    (local: 'kickback', badMatch: 'dip'),
    (local: 'kickback', badMatch: 'floor'),
    // Cable Crossover should not match scissors
    (local: 'crossover', badMatch: 'scissor'),
    // Row should not match suspended row for barbell row
    (local: 'barbell row', badMatch: 'suspended'),
    // Squat should not match bodyweight squat for barbell squat
    (local: 'barbell squat', badMatch: 'bodyweight'),
    // Curl should not match hammer curl for regular curl
    (local: 'barbell curl', badMatch: 'hammer'),
    (local: 'barbell curl', badMatch: 'cable'),
  ];

  for (final pattern in mismatchPatterns) {
    if (local.contains(pattern.local) && candidate.contains(pattern.badMatch)) {
      return true;
    }
  }

  return false;
}

/// Extract meaningful keywords from exercise name
List<String> _extractKeywords(String name) {
  final stopWords = {
    'with', 'and', 'the', 'a', 'an', 'to', 'for', 'of', 'on', 'in', 'at',
    'by', 'or', 'is', 'it', 'up', 'down', 'out', 'off', 'over', 'under',
    'again', 'further', 'then', 'once', 'here', 'there', 'when', 'where',
    'why', 'how', 'all', 'each', 'few', 'more', 'most', 'other', 'some',
    'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too',
    'very', 'just', 'both', 'but', 'if', 'into', 'through', 'during', 'before',
    'after', 'above', 'below', 'between', 'because', 'until', 'while',
    // Equipment words (handled separately)
    'barbell', 'dumbbell', 'cable', 'machine', 'smith', 'kettlebell', 'band',
    'ez', 'bar', 'resistance', 'trx', 'bodyweight',
    // Variations/modifiers
    'close', 'wide', 'grip', 'neutral', 'variation', 'seated', 'standing',
    'lying', 'incline', 'decline', 'flat', 'reverse', 'single', 'leg', 'arm',
    'alternate', 'alternating',
  };

  final words = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 2 && !stopWords.contains(w))
      .toList();

  return words;
}

/// Get the core exercise name without equipment/variation prefixes
String _getCoreName(String name) {
  var core = name.toLowerCase();

  // Remove equipment prefixes
  final prefixes = [
    'barbell', 'dumbbell', 'cable', 'machine', 'smith', 'kettlebell',
    'ez bar', 'ez-bar', 'resistance band', 'trx', 'bodyweight',
  ];

  for (final prefix in prefixes) {
    if (core.startsWith(prefix)) {
      core = core.substring(prefix.length).trim();
    }
  }

  // Remove common suffixes/variations
  core = core
      .replaceAll(RegExp(r'\(.*?\)'), '')
      .replaceAll(' - ', ' ')
      .trim();

  return core;
}

/// Calculate Levenshtein similarity between two strings (0.0 - 1.0)
double _calculateSimilarity(String s1, String s2) {
  if (s1 == s2) return 1.0;
  if (s1.isEmpty || s2.isEmpty) return 0.0;

  final distance = _levenshteinDistance(s1, s2);
  final maxLength = max(s1.length, s2.length);

  return 1.0 - (distance / maxLength);
}

/// Calculate Levenshtein distance between two strings
int _levenshteinDistance(String s1, String s2) {
  if (s1 == s2) return 0;
  if (s1.isEmpty) return s2.length;
  if (s2.isEmpty) return s1.length;

  List<int> previousRow = List<int>.generate(s2.length + 1, (i) => i);
  List<int> currentRow = List<int>.filled(s2.length + 1, 0);

  for (int i = 0; i < s1.length; i++) {
    currentRow[0] = i + 1;

    for (int j = 0; j < s2.length; j++) {
      final cost = s1[i] == s2[j] ? 0 : 1;
      currentRow[j + 1] = [
        currentRow[j] + 1, // insertion
        previousRow[j + 1] + 1, // deletion
        previousRow[j] + cost, // substitution
      ].reduce(min);
    }

    final temp = previousRow;
    previousRow = currentRow;
    currentRow = temp;
  }

  return previousRow[s2.length];
}

/// Parse a list field from ExerciseDB API response
List<String> _parseList(dynamic value) {
  if (value == null) return [];
  if (value is String) return [value];
  if (value is List) return value.map((e) => e.toString()).toList();
  return [];
}

/// Get equipment aliases for matching
Set<String> _equipmentAliases(String equipment) {
  final aliases = <String, Set<String>>{
    'barbell': {'barbell', 'bar', 'olympic bar'},
    'dumbbell': {'dumbbell', 'dumbbells', 'db'},
    'cable': {'cable', 'cables', 'pulley'},
    'machine': {'machine', 'leverage machine', 'selectorized'},
    'bodyweight': {'bodyweight', 'body weight', 'body'},
    'kettlebell': {'kettlebell', 'kb'},
    'band': {'band', 'resistance band', 'bands'},
    'smith': {'smith', 'smith machine'},
    'other': {'other', 'weighted', 'rope', 'medicine ball', 'wheel'},
  };

  return aliases[equipment] ?? {equipment};
}

/// Get muscle group aliases for matching
Set<String> _muscleAliases(String muscle) {
  final aliases = <String, Set<String>>{
    'chest': {'chest', 'pectorals', 'pecs'},
    'back': {'back', 'lats', 'latissimus', 'upper back', 'lower back'},
    'shoulders': {'shoulders', 'delts', 'deltoids'},
    'biceps': {'biceps', 'bis'},
    'triceps': {'triceps', 'tris'},
    'forearms': {'forearms', 'wrists'},
    'quadriceps': {'quadriceps', 'quads', 'thighs'},
    'hamstrings': {'hamstrings', 'hams'},
    'glutes': {'glutes', 'gluteus', 'butt', 'hips'},
    'calves': {'calves', 'calf'},
    'core': {'core', 'abs', 'abdominals', 'waist', 'obliques'},
    'full_body': {'full body', 'full_body', 'cardio', 'total body'},
  };

  return aliases[muscle] ?? {muscle};
}

/// Generate SQL migration file
Future<void> generateSqlMigration(List<MatchResult> matches) async {
  final updates = matches.where((m) => m.needsUpdate && m.matchedExerciseDbId != null).toList();

  if (updates.isEmpty) {
    print('\n✓ No updates needed - all exercises are correctly mapped!');
    return;
  }

  final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\-TZ.]'), '').substring(0, 14);
  final fileName = '${timestamp}_fix_exercise_media_urls.sql';
  final filePath = 'supabase/migrations/$fileName';

  final buffer = StringBuffer();
  buffer.writeln('-- Migration: Fix Exercise Media URLs');
  buffer.writeln('-- Generated: ${DateTime.now().toIso8601String()}');
  buffer.writeln('-- Purpose: Correct exercisedb_id, thumbnail_url, and video_url mismatches');
  buffer.writeln('--');
  buffer.writeln('-- This migration fixes ${updates.length} exercises with incorrect mappings.');
  buffer.writeln('-- Review each update before applying!');
  buffer.writeln('');
  buffer.writeln('BEGIN;');
  buffer.writeln('');

  for (final update in updates) {
    final exerciseDbId = update.matchedExerciseDbId!;
    final imageUrl = update.matchedImageUrl ?? 'NULL';
    final videoUrl = update.matchedVideoUrl ?? 'NULL';

    buffer.writeln('-- ${update.localName}');
    buffer.writeln('-- Old: ${update.currentExerciseDbId ?? 'NULL'}');
    buffer.writeln('-- New: $exerciseDbId (Score: ${update.matchScore})');
    buffer.writeln('-- Match: ${update.matchedName}');
    buffer.writeln('UPDATE exercises SET');
    buffer.writeln("  exercisedb_id = '$exerciseDbId',");

    if (update.matchedImageUrl != null) {
      buffer.writeln("  thumbnail_url = '${_escapeSql(update.matchedImageUrl!)}',");
    } else {
      buffer.writeln('  thumbnail_url = NULL,');
    }

    if (update.matchedVideoUrl != null) {
      buffer.writeln("  video_url = '${_escapeSql(update.matchedVideoUrl!)}'");
    } else {
      buffer.writeln('  video_url = NULL');
    }

    buffer.writeln("WHERE id = '${update.localId}';");
    buffer.writeln('');
  }

  buffer.writeln('COMMIT;');

  // Ensure directory exists
  final dir = Directory('supabase/migrations');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  // Write file
  final file = File(filePath);
  await file.writeAsString(buffer.toString());

  print('\n📄 SQL migration generated: $filePath');
  print('   Contains ${updates.length} UPDATE statements');
}

String _escapeSql(String value) {
  return value.replaceAll("'", "''");
}

/// Result class for tracking match outcomes
class MatchResult {
  final String localId;
  final String localName;
  final String? localEquipment;
  final String? localMuscleGroup;
  final String? currentExerciseDbId;

  String? matchedName;
  String? matchedExerciseDbId;
  String? matchedImageUrl;
  String? matchedVideoUrl;
  int matchScore = 0;
  String matchDetails = '';
  bool needsUpdate = false;
  String? error;

  MatchResult({
    required this.localId,
    required this.localName,
    this.localEquipment,
    this.localMuscleGroup,
    this.currentExerciseDbId,
    this.error,
  });
}

class _ScoreResult {
  final int score;
  final String details;

  _ScoreResult(this.score, this.details);
}
