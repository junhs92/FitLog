import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class DumbbellBenchPressPainter extends CustomPainter {
  DumbbellBenchPressPainter({
    required this.progress,
    this.bodyColor = AppColors.primary,
    this.headColor = AppColors.neutral800,
    this.benchColor = AppColors.neutral700,
    this.dumbbellColor = AppColors.neutralBlack,
    this.floorColor = AppColors.neutral300,
  });

  final double progress;
  final Color bodyColor;
  final Color headColor;
  final Color benchColor;
  final Color dumbbellColor;
  final Color floorColor;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.shortestSide / 10.0;
    final center = Offset(size.width / 2, size.height / 2);

    Offset p(double x, double y) => center + Offset(x * u, y * u);

    final floorPaint = Paint()
      ..color = floorColor
      ..strokeWidth = 0.1 * u
      ..style = PaintingStyle.stroke;
    canvas.drawLine(p(-5, 2.7), p(5, 2.7), floorPaint);

    final benchPaint = Paint()..color = benchColor;
    final benchRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(p(-4, 0.3).dx, p(-4, 0.3).dy, p(4, 1.0).dx, p(4, 1.0).dy),
      Radius.circular(0.2 * u),
    );
    canvas.drawRRect(benchRect, benchPaint);

    final legPaint = Paint()..color = benchColor;
    canvas.drawRect(
      Rect.fromLTRB(p(-3.2, 1.0).dx, p(-3.2, 1.0).dy, p(-2.8, 2.7).dx,
          p(-2.8, 2.7).dy),
      legPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(p(2.8, 1.0).dx, p(2.8, 1.0).dy, p(3.2, 2.7).dx,
          p(3.2, 2.7).dy),
      legPaint,
    );

    final phase = (1 - math.cos(2 * math.pi * progress)) / 2;

    final headCenter = p(-3.2, -0.2);
    canvas.drawCircle(headCenter, 0.5 * u, Paint()..color = headColor);

    final neck = p(-2.6, -0.05);
    final hip = p(1.5, 0.1);

    final bodyStroke = Paint()
      ..color = bodyColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.55 * u
      ..style = PaintingStyle.stroke;

    canvas.drawLine(neck, hip, bodyStroke);

    final knee = p(2.7, -0.3);
    final foot = p(3.2, 1.0);
    final legStroke = Paint()
      ..color = bodyColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.42 * u
      ..style = PaintingStyle.stroke;
    canvas.drawLine(hip, knee, legStroke);
    canvas.drawLine(knee, foot, legStroke);

    final shoulder = p(-2.3, -0.05);

    const upperArm = 1.3;
    const foreArm = 1.3;
    final l1 = upperArm * u;
    final l2 = foreArm * u;

    final wristHeight = lerpDouble(0.3 * u, (l1 + l2) * 0.98, phase)!;
    final wrist = shoulder + Offset(0, -wristHeight);

    final d = wristHeight;
    final cosShoulder =
        ((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)).clamp(-1.0, 1.0);
    final shoulderAngle = math.acos(cosShoulder);
    final elbow = shoulder +
        Offset(math.sin(shoulderAngle) * l1, -math.cos(shoulderAngle) * l1);

    final armStroke = Paint()
      ..color = bodyColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.34 * u
      ..style = PaintingStyle.stroke;

    final backOffset = Offset(0, 0.18 * u);
    canvas.drawLine(shoulder + backOffset, elbow + backOffset, armStroke);
    canvas.drawLine(elbow + backOffset, wrist + backOffset, armStroke);
    _drawDumbbell(canvas, wrist + backOffset, u);

    canvas.drawLine(shoulder, elbow, armStroke);
    canvas.drawLine(elbow, wrist, armStroke);
    _drawDumbbell(canvas, wrist, u);
  }

  void _drawDumbbell(Canvas canvas, Offset handCenter, double u) {
    final bar = Paint()..color = dumbbellColor;
    final barRect = Rect.fromCenter(
      center: handCenter,
      width: 1.4 * u,
      height: 0.18 * u,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(0.05 * u)),
      bar,
    );

    final plateSize = Size(0.32 * u, 0.8 * u);
    final leftPlate = Rect.fromCenter(
      center: handCenter + Offset(-0.55 * u, 0),
      width: plateSize.width,
      height: plateSize.height,
    );
    final rightPlate = Rect.fromCenter(
      center: handCenter + Offset(0.55 * u, 0),
      width: plateSize.width,
      height: plateSize.height,
    );
    final plate = Paint()..color = dumbbellColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(leftPlate, Radius.circular(0.08 * u)),
      plate,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rightPlate, Radius.circular(0.08 * u)),
      plate,
    );
  }

  @override
  bool shouldRepaint(covariant DumbbellBenchPressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.headColor != headColor ||
        oldDelegate.benchColor != benchColor ||
        oldDelegate.dumbbellColor != dumbbellColor ||
        oldDelegate.floorColor != floorColor;
  }
}
