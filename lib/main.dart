import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/exercises/screens/exercise_demo_screen.dart';

void main() {
  runApp(const FitLogApp());
}

class FitLogApp extends StatelessWidget {
  const FitLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitLog Pro',
      theme: AppTheme.lightTheme,
      home: const ExerciseDemoScreen(),
    );
  }
}
