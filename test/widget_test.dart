import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitlog_pro_app/features/exercises/models/exercise_type.dart';
import 'package:fitlog_pro_app/features/exercises/widgets/exercise_animation.dart';
import 'package:fitlog_pro_app/main.dart';

void main() {
  testWidgets('App launches on the exercise demo screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FitLogApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Dumbbell Bench Press'), findsOneWidget);
    expect(find.byType(ExerciseAnimationWidget), findsOneWidget);
  });

  testWidgets('Animation advances frames without errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: ExerciseAnimationWidget(
              exerciseType: ExerciseType.dumbbellBenchPress,
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
  });
}
