import 'package:flutter/material.dart';

import '../models/exercise_type.dart';
import 'dumbbell_bench_press_painter.dart';

class ExerciseAnimationWidget extends StatefulWidget {
  const ExerciseAnimationWidget({
    super.key,
    required this.exerciseType,
    this.cycle = const Duration(seconds: 2),
  });

  final ExerciseType exerciseType;
  final Duration cycle;

  @override
  State<ExerciseAnimationWidget> createState() =>
      _ExerciseAnimationWidgetState();
}

class _ExerciseAnimationWidgetState extends State<ExerciseAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.cycle)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant ExerciseAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cycle != widget.cycle) {
      _controller.duration = widget.cycle;
      _controller
        ..stop()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CustomPainter _painterFor(ExerciseType type, double progress) {
    switch (type) {
      case ExerciseType.dumbbellBenchPress:
        return DumbbellBenchPressPainter(progress: progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _painterFor(widget.exerciseType, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}
