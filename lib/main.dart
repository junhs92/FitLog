import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';
import 'shared/services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style (dark theme)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0E12),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    LoggerService.info('Supabase initialized successfully');
  } catch (e) {
    LoggerService.warning(
      'Supabase initialization skipped: $e',
    );
    // Continue without Supabase in development if not configured
    if (AppConfig.isProduction) {
      rethrow;
    }
  }

  runApp(
    const ProviderScope(
      child: FitLogApp(),
    ),
  );
}
