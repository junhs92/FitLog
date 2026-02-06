import 'package:flutter/material.dart';
import '../../domain/entities/muscle_group.dart';

/// SVG-based body map widget with partitioned muscle regions
/// Each muscle group is a separate path that can be individually colored
class SvgBodyMap extends StatelessWidget {
  /// Map of muscle groups to their intensity values (0.0 - 1.0)
  final Map<MuscleGroup, double> intensities;

  /// Height of the widget
  final double height;

  /// Currently selected muscle (highlighted with border)
  final MuscleGroup? selectedMuscle;

  /// Callback when a muscle region is tapped
  final void Function(MuscleGroup group)? onMuscleTap;

  /// Whether to show labels on muscle regions
  final bool showLabels;

  /// Base viewBox dimensions (coordinate system)
  static const double viewBoxWidth = 400;
  static const double viewBoxHeight = 500;

  /// Vertical offset to add space between labels and body
  static const double labelBodyGap = 20.0;

  const SvgBodyMap({
    required this.intensities,
    this.height = 400,
    this.selectedMuscle,
    this.onMuscleTap,
    this.showLabels = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Maintain 4:5 aspect ratio
    final width = height * (viewBoxWidth / viewBoxHeight);

    return GestureDetector(
      onTapUp: onMuscleTap != null ? (details) => _handleTap(details, Size(width, height)) : null,
      child: CustomPaint(
        size: Size(width, height),
        painter: _BodyMapPainter(
          intensities: intensities,
          selectedMuscle: selectedMuscle,
          showLabels: showLabels,
        ),
      ),
    );
  }

  void _handleTap(TapUpDetails details, Size size) {
    final localPosition = details.localPosition;
    final scaleX = viewBoxWidth / size.width;
    final scaleY = viewBoxHeight / size.height;

    // Convert tap position to viewBox coordinates
    final viewBoxX = localPosition.dx * scaleX;
    // Account for the vertical offset applied to body parts
    final viewBoxY = localPosition.dy * scaleY - labelBodyGap;

    // Find which muscle was tapped
    for (final pathData in _bodyPartPaths.values) {
      final muscleGroup = pathData.muscleGroup;
      if (muscleGroup == null) continue;

      // Check if tap is within the path bounds
      final path = pathData.createPath(const Size(viewBoxWidth, viewBoxHeight));
      if (path.contains(Offset(viewBoxX, viewBoxY))) {
        onMuscleTap?.call(muscleGroup);
        return;
      }
    }
  }
}

/// CustomPainter that draws the body map with colored muscle regions
class _BodyMapPainter extends CustomPainter {
  final Map<MuscleGroup, double> intensities;
  final MuscleGroup? selectedMuscle;
  final bool showLabels;

  _BodyMapPainter({
    required this.intensities,
    this.selectedMuscle,
    this.showLabels = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / SvgBodyMap.viewBoxWidth;
    final scaleY = size.height / SvgBodyMap.viewBoxHeight;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Draw "FRONT" and "BACK" labels first (at top)
    _drawViewLabels(canvas);

    // Shift body parts down to create gap below labels
    canvas.translate(0, SvgBodyMap.labelBodyGap);

    // Draw all body parts
    for (final entry in _bodyPartPaths.entries) {
      final pathData = entry.value;
      final path = pathData.createPath(const Size(SvgBodyMap.viewBoxWidth, SvgBodyMap.viewBoxHeight));

      // Get intensity for this muscle group
      final muscleGroup = pathData.muscleGroup;
      double? intensity;
      if (muscleGroup != null) {
        intensity = _getIntensityForMuscle(muscleGroup);
      }

      // Draw fill
      final fillColor = _getColorForIntensity(intensity);
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Draw stroke outline
      final isSelected = muscleGroup != null && muscleGroup == selectedMuscle;
      final strokePaint = Paint()
        ..color = isSelected ? const Color(0xFF2196F3) : const Color(0xFFCCCCCC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.5 : 0.5;
      canvas.drawPath(path, strokePaint);
    }

    canvas.restore();
  }

  double? _getIntensityForMuscle(MuscleGroup group) {
    // Direct match
    if (intensities.containsKey(group)) {
      return intensities[group];
    }

    // Handle muscle group mappings
    // back maps to: back, lats, traps
    if (group == MuscleGroup.back) {
      final backIntensity = intensities[MuscleGroup.back];
      final latsIntensity = intensities[MuscleGroup.lats];
      final trapsIntensity = intensities[MuscleGroup.traps];
      final values = [backIntensity, latsIntensity, trapsIntensity].whereType<double>().toList();
      if (values.isNotEmpty) {
        return values.reduce((a, b) => a > b ? a : b);
      }
    }

    // core maps to: core, abs
    if (group == MuscleGroup.core || group == MuscleGroup.abs) {
      final coreIntensity = intensities[MuscleGroup.core];
      final absIntensity = intensities[MuscleGroup.abs];
      final values = [coreIntensity, absIntensity].whereType<double>().toList();
      if (values.isNotEmpty) {
        return values.reduce((a, b) => a > b ? a : b);
      }
    }

    return null;
  }

  Color _getColorForIntensity(double? intensity) {
    if (intensity == null || intensity <= 0) {
      return const Color(0xFFE0E0E0); // Gray (inactive)
    }
    // Lerp from light red to deep red
    return Color.lerp(
      const Color(0xFFFFCDD2), // Light red
      const Color(0xFFD32F2F), // Deep red
      intensity.clamp(0.0, 1.0),
    )!;
  }

  void _drawViewLabels(Canvas canvas) {
    const textStyle = TextStyle(
      color: Color(0xFF757575),
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.0,
    );

    // Draw "FRONT" label above left figure
    final frontPainter = TextPainter(
      text: const TextSpan(text: 'FRONT', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    frontPainter.layout();
    frontPainter.paint(
      canvas,
      Offset(90 - frontPainter.width / 2, 5),
    );

    // Draw "BACK" label above right figure
    final backPainter = TextPainter(
      text: const TextSpan(text: 'BACK', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    backPainter.layout();
    backPainter.paint(
      canvas,
      Offset(310 - backPainter.width / 2, 5),
    );
  }

  @override
  bool shouldRepaint(covariant _BodyMapPainter oldDelegate) {
    return intensities != oldDelegate.intensities ||
        selectedMuscle != oldDelegate.selectedMuscle ||
        showLabels != oldDelegate.showLabels;
  }
}

/// Data class for body part path definitions
class _BodyPartPath {
  final String id;
  final MuscleGroup? muscleGroup;
  final Path Function(Size size) createPath;

  const _BodyPartPath({
    required this.id,
    this.muscleGroup,
    required this.createPath,
  });
}

/// All body part paths defined in viewBox coordinates (400x500)
/// Front view: x = 0-180, Back view: x = 220-400
final Map<String, _BodyPartPath> _bodyPartPaths = {
  // ============================================
  // FRONT VIEW (Left side: 0-180)
  // ============================================

  // Head (decorative only)
  'front_head': _BodyPartPath(
    id: 'front_head',
    muscleGroup: null,
    createPath: (size) => Path()
      ..addOval(Rect.fromCenter(
        center: const Offset(90, 40),
        width: 40,
        height: 48,
      )),
  ),

  // Neck (decorative)
  'front_neck': _BodyPartPath(
    id: 'front_neck',
    muscleGroup: null,
    createPath: (size) => Path()
      ..moveTo(80, 62)
      ..lineTo(100, 62)
      ..lineTo(100, 85)
      ..lineTo(80, 85)
      ..close(),
  ),

  // Chest
  'front_chest': _BodyPartPath(
    id: 'front_chest',
    muscleGroup: MuscleGroup.chest,
    createPath: (size) => Path()
      ..moveTo(55, 90)
      ..quadraticBezierTo(90, 85, 125, 90)
      ..lineTo(120, 135)
      ..quadraticBezierTo(90, 140, 60, 135)
      ..close(),
  ),

  // Left Shoulder (Front)
  'front_shoulder_left': _BodyPartPath(
    id: 'front_shoulder_left',
    muscleGroup: MuscleGroup.shoulders,
    createPath: (size) => Path()
      ..moveTo(40, 88)
      ..quadraticBezierTo(35, 95, 38, 115)
      ..lineTo(55, 115)
      ..lineTo(55, 90)
      ..quadraticBezierTo(48, 85, 40, 88),
  ),

  // Right Shoulder (Front)
  'front_shoulder_right': _BodyPartPath(
    id: 'front_shoulder_right',
    muscleGroup: MuscleGroup.shoulders,
    createPath: (size) => Path()
      ..moveTo(140, 88)
      ..quadraticBezierTo(145, 95, 142, 115)
      ..lineTo(125, 115)
      ..lineTo(125, 90)
      ..quadraticBezierTo(132, 85, 140, 88),
  ),

  // Abs / Core
  'front_abs': _BodyPartPath(
    id: 'front_abs',
    muscleGroup: MuscleGroup.abs,
    createPath: (size) => Path()
      ..moveTo(65, 140)
      ..lineTo(115, 140)
      ..lineTo(112, 210)
      ..quadraticBezierTo(90, 215, 68, 210)
      ..close(),
  ),

  // Left Bicep
  'front_bicep_left': _BodyPartPath(
    id: 'front_bicep_left',
    muscleGroup: MuscleGroup.biceps,
    createPath: (size) => Path()
      ..moveTo(35, 118)
      ..quadraticBezierTo(28, 140, 30, 175)
      ..lineTo(48, 175)
      ..quadraticBezierTo(52, 140, 50, 118)
      ..close(),
  ),

  // Right Bicep
  'front_bicep_right': _BodyPartPath(
    id: 'front_bicep_right',
    muscleGroup: MuscleGroup.biceps,
    createPath: (size) => Path()
      ..moveTo(145, 118)
      ..quadraticBezierTo(152, 140, 150, 175)
      ..lineTo(132, 175)
      ..quadraticBezierTo(128, 140, 130, 118)
      ..close(),
  ),

  // Left Forearm (Front)
  'front_forearm_left': _BodyPartPath(
    id: 'front_forearm_left',
    muscleGroup: MuscleGroup.forearms,
    createPath: (size) => Path()
      ..moveTo(28, 180)
      ..quadraticBezierTo(20, 210, 18, 250)
      ..lineTo(35, 250)
      ..quadraticBezierTo(42, 210, 50, 180)
      ..close(),
  ),

  // Right Forearm (Front)
  'front_forearm_right': _BodyPartPath(
    id: 'front_forearm_right',
    muscleGroup: MuscleGroup.forearms,
    createPath: (size) => Path()
      ..moveTo(152, 180)
      ..quadraticBezierTo(160, 210, 162, 250)
      ..lineTo(145, 250)
      ..quadraticBezierTo(138, 210, 130, 180)
      ..close(),
  ),

  // Left Quad
  'front_quad_left': _BodyPartPath(
    id: 'front_quad_left',
    muscleGroup: MuscleGroup.quadriceps,
    createPath: (size) => Path()
      ..moveTo(68, 218)
      ..lineTo(88, 218)
      ..quadraticBezierTo(90, 290, 88, 340)
      ..lineTo(65, 340)
      ..quadraticBezierTo(62, 290, 68, 218),
  ),

  // Right Quad
  'front_quad_right': _BodyPartPath(
    id: 'front_quad_right',
    muscleGroup: MuscleGroup.quadriceps,
    createPath: (size) => Path()
      ..moveTo(92, 218)
      ..lineTo(112, 218)
      ..quadraticBezierTo(118, 290, 115, 340)
      ..lineTo(92, 340)
      ..quadraticBezierTo(90, 290, 92, 218),
  ),

  // Left Adductor (inner thigh)
  'front_adductor_left': _BodyPartPath(
    id: 'front_adductor_left',
    muscleGroup: MuscleGroup.adductors,
    createPath: (size) => Path()
      ..moveTo(88, 220)
      ..lineTo(90, 220)
      ..quadraticBezierTo(92, 260, 90, 320)
      ..lineTo(88, 340)
      ..lineTo(85, 340)
      ..quadraticBezierTo(84, 280, 88, 220),
  ),

  // Right Adductor (inner thigh)
  'front_adductor_right': _BodyPartPath(
    id: 'front_adductor_right',
    muscleGroup: MuscleGroup.adductors,
    createPath: (size) => Path()
      ..moveTo(90, 220)
      ..lineTo(92, 220)
      ..quadraticBezierTo(96, 280, 95, 340)
      ..lineTo(92, 340)
      ..lineTo(90, 320)
      ..quadraticBezierTo(88, 260, 90, 220),
  ),

  // Left Shin (decorative)
  'front_shin_left': _BodyPartPath(
    id: 'front_shin_left',
    muscleGroup: null,
    createPath: (size) => Path()
      ..moveTo(65, 345)
      ..lineTo(88, 345)
      ..quadraticBezierTo(88, 410, 85, 470)
      ..lineTo(68, 470)
      ..quadraticBezierTo(62, 410, 65, 345),
  ),

  // Right Shin (decorative)
  'front_shin_right': _BodyPartPath(
    id: 'front_shin_right',
    muscleGroup: null,
    createPath: (size) => Path()
      ..moveTo(92, 345)
      ..lineTo(115, 345)
      ..quadraticBezierTo(118, 410, 112, 470)
      ..lineTo(95, 470)
      ..quadraticBezierTo(92, 410, 92, 345),
  ),

  // Left Hand (Front - decorative)
  'front_hand_left': _BodyPartPath(
    id: 'front_hand_left',
    muscleGroup: null,
    createPath: (size) => Path()
      ..moveTo(18, 252)
      ..quadraticBezierTo(12, 265, 14, 282)
      ..lineTo(22, 285)
      ..lineTo(24, 278)
      ..lineTo(27, 285)
      ..lineTo(29, 278)
      ..lineTo(32, 284)
      ..lineTo(34, 277)
      ..lineTo(38, 280)
      ..quadraticBezierTo(40, 265, 35, 252)
      ..close(),
  ),

  // Right Hand (Front - decorative)
  'front_hand_right': _BodyPartPath(
    id: 'front_hand_right',
    muscleGroup: null,
    createPath: (size) => Path()
      ..moveTo(162, 252)
      ..quadraticBezierTo(168, 265, 166, 282)
      ..lineTo(158, 285)
      ..lineTo(156, 278)
      ..lineTo(153, 285)
      ..lineTo(151, 278)
      ..lineTo(148, 284)
      ..lineTo(146, 277)
      ..lineTo(142, 280)
      ..quadraticBezierTo(140, 265, 145, 252)
      ..close(),
  ),

  // Left Foot (Front - decorative)
  'front_foot_left': _BodyPartPath(
    id: 'front_foot_left',
    muscleGroup: null,
    createPath: (size) => Path()
      ..moveTo(68, 472)
      ..lineTo(85, 472)
      ..lineTo(88, 480)
      ..lineTo(85, 488)
      ..lineTo(62, 488)
      ..lineTo(60, 480)
      ..close(),
  ),

  // Right Foot (Front - decorative)
  'front_foot_right': _BodyPartPath(
    id: 'front_foot_right',
    muscleGroup: null,
    createPath: (size) => Path()
      ..moveTo(95, 472)
      ..lineTo(112, 472)
      ..lineTo(120, 480)
      ..lineTo(118, 488)
      ..lineTo(92, 488)
      ..lineTo(92, 480)
      ..close(),
  ),

  // ============================================
  // BACK VIEW (Right side: 220-400)
  // ============================================

  // Head (decorative only)
  'back_head': _BodyPartPath(
    id: 'back_head',
    muscleGroup: null,
    createPath: (size) => Path()
      ..addOval(Rect.fromCenter(
        center: const Offset(310, 40),
        width: 40,
        height: 48,
      )),
  ),

  // Neck (decorative)
  'back_neck': _BodyPartPath(
    id: 'back_neck',
    muscleGroup: null,
    createPath: (size) => Path()
      ..moveTo(300, 62)
      ..lineTo(320, 62)
      ..lineTo(320, 85)
      ..lineTo(300, 85)
      ..close(),
  ),

  // Traps
  'back_traps': _BodyPartPath(
    id: 'back_traps',
    muscleGroup: MuscleGroup.traps,
    createPath: (size) => Path()
      ..moveTo(280, 85)
      ..quadraticBezierTo(310, 80, 340, 85)
      ..lineTo(335, 105)
      ..quadraticBezierTo(310, 100, 285, 105)
      ..close(),
  ),

  // Left Rear Shoulder
  'back_shoulder_left': _BodyPartPath(
    id: 'back_shoulder_left',
    muscleGroup: MuscleGroup.shoulders,
    createPath: (size) => Path()
      ..moveTo(260, 88)
      ..quadraticBezierTo(255, 95, 258, 115)
      ..lineTo(275, 115)
      ..lineTo(275, 90)
      ..quadraticBezierTo(268, 85, 260, 88),
  ),

  // Right Rear Shoulder
  'back_shoulder_right': _BodyPartPath(
    id: 'back_shoulder_right',
    muscleGroup: MuscleGroup.shoulders,
    createPath: (size) => Path()
      ..moveTo(360, 88)
      ..quadraticBezierTo(365, 95, 362, 115)
      ..lineTo(345, 115)
      ..lineTo(345, 90)
      ..quadraticBezierTo(352, 85, 360, 88),
  ),

  // Upper Back (Lats area)
  'back_upper': _BodyPartPath(
    id: 'back_upper',
    muscleGroup: MuscleGroup.lats,
    createPath: (size) => Path()
      ..moveTo(280, 108)
      ..quadraticBezierTo(310, 105, 340, 108)
      ..lineTo(338, 165)
      ..quadraticBezierTo(310, 170, 282, 165)
      ..close(),
  ),

  // Lower Back
  'back_lower': _BodyPartPath(
    id: 'back_lower',
    muscleGroup: MuscleGroup.back,
    createPath: (size) => Path()
      ..moveTo(282, 168)
      ..lineTo(338, 168)
      ..lineTo(335, 210)
      ..quadraticBezierTo(310, 215, 285, 210)
      ..close(),
  ),

  // Left Tricep
  'back_tricep_left': _BodyPartPath(
    id: 'back_tricep_left',
    muscleGroup: MuscleGroup.triceps,
    createPath: (size) => Path()
      ..moveTo(255, 118)
      ..quadraticBezierTo(248, 140, 250, 175)
      ..lineTo(268, 175)
      ..quadraticBezierTo(272, 140, 270, 118)
      ..close(),
  ),

  // Right Tricep
  'back_tricep_right': _BodyPartPath(
    id: 'back_tricep_right',
    muscleGroup: MuscleGroup.triceps,
    createPath: (size) => Path()
      ..moveTo(365, 118)
      ..quadraticBezierTo(372, 140, 370, 175)
      ..lineTo(352, 175)
      ..quadraticBezierTo(348, 140, 350, 118)
      ..close(),
  ),

  // Left Forearm (Back)
  'back_forearm_left': _BodyPartPath(
    id: 'back_forearm_left',
    muscleGroup: MuscleGroup.forearms,
    createPath: (size) => Path()
      ..moveTo(248, 180)
      ..quadraticBezierTo(240, 210, 238, 250)
      ..lineTo(255, 250)
      ..quadraticBezierTo(262, 210, 270, 180)
      ..close(),
  ),

  // Right Forearm (Back)
  'back_forearm_right': _BodyPartPath(
    id: 'back_forearm_right',
    muscleGroup: MuscleGroup.forearms,
    createPath: (size) => Path()
      ..moveTo(372, 180)
      ..quadraticBezierTo(380, 210, 382, 250)
      ..lineTo(365, 250)
      ..quadraticBezierTo(358, 210, 350, 180)
      ..close(),
  ),

  // Glutes
  'back_glutes': _BodyPartPath(
    id: 'back_glutes',
    muscleGroup: MuscleGroup.glutes,
    createPath: (size) => Path()
      ..moveTo(280, 212)
      ..quadraticBezierTo(310, 208, 340, 212)
      ..lineTo(338, 255)
      ..quadraticBezierTo(310, 260, 282, 255)
      ..close(),
  ),

  // Left Hamstring
  'back_hamstring_left': _BodyPartPath(
    id: 'back_hamstring_left',
    muscleGroup: MuscleGroup.hamstrings,
    createPath: (size) => Path()
      ..moveTo(282, 258)
      ..lineTo(305, 258)
      ..quadraticBezierTo(308, 320, 305, 365)
      ..lineTo(280, 365)
      ..quadraticBezierTo(275, 320, 282, 258),
  ),

  // Right Hamstring
  'back_hamstring_right': _BodyPartPath(
    id: 'back_hamstring_right',
    muscleGroup: MuscleGroup.hamstrings,
    createPath: (size) => Path()
      ..moveTo(315, 258)
      ..lineTo(338, 258)
      ..quadraticBezierTo(345, 320, 340, 365)
      ..lineTo(315, 365)
      ..quadraticBezierTo(312, 320, 315, 258),
  ),

  // Left Calf
  'back_calf_left': _BodyPartPath(
    id: 'back_calf_left',
    muscleGroup: MuscleGroup.calves,
    createPath: (size) => Path()
      ..moveTo(280, 370)
      ..lineTo(305, 370)
      ..quadraticBezierTo(308, 420, 302, 470)
      ..lineTo(285, 470)
      ..quadraticBezierTo(275, 420, 280, 370),
  ),

  // Right Calf
  'back_calf_right': _BodyPartPath(
    id: 'back_calf_right',
    muscleGroup: MuscleGroup.calves,
    createPath: (size) => Path()
      ..moveTo(315, 370)
      ..lineTo(340, 370)
      ..quadraticBezierTo(345, 420, 335, 470)
      ..lineTo(318, 470)
      ..quadraticBezierTo(312, 420, 315, 370),
  ),

  // Left Hand (Back - decorative)
  'back_hand_left': _BodyPartPath(
    id: 'back_hand_left',
    muscleGroup: null,
    createPath: (size) => Path()
      ..moveTo(238, 252)
      ..quadraticBezierTo(232, 265, 234, 282)
      ..lineTo(242, 285)
      ..lineTo(244, 278)
      ..lineTo(247, 285)
      ..lineTo(249, 278)
      ..lineTo(252, 284)
      ..lineTo(254, 277)
      ..lineTo(258, 280)
      ..quadraticBezierTo(260, 265, 255, 252)
      ..close(),
  ),

  // Right Hand (Back - decorative)
  'back_hand_right': _BodyPartPath(
    id: 'back_hand_right',
    muscleGroup: null,
    createPath: (size) => Path()
      ..moveTo(382, 252)
      ..quadraticBezierTo(388, 265, 386, 282)
      ..lineTo(378, 285)
      ..lineTo(376, 278)
      ..lineTo(373, 285)
      ..lineTo(371, 278)
      ..lineTo(368, 284)
      ..lineTo(366, 277)
      ..lineTo(362, 280)
      ..quadraticBezierTo(360, 265, 365, 252)
      ..close(),
  ),

  // Left Foot (Back - decorative)
  'back_foot_left': _BodyPartPath(
    id: 'back_foot_left',
    muscleGroup: null,
    createPath: (size) => Path()
      ..moveTo(285, 472)
      ..lineTo(302, 472)
      ..lineTo(305, 480)
      ..lineTo(302, 488)
      ..lineTo(280, 488)
      ..lineTo(278, 480)
      ..close(),
  ),

  // Right Foot (Back - decorative)
  'back_foot_right': _BodyPartPath(
    id: 'back_foot_right',
    muscleGroup: null,
    createPath: (size) => Path()
      ..moveTo(318, 472)
      ..lineTo(335, 472)
      ..lineTo(342, 480)
      ..lineTo(340, 488)
      ..lineTo(312, 488)
      ..lineTo(312, 480)
      ..close(),
  ),
};

/// Get color for an intensity value (0.0 - 1.0)
Color getBodyMapColorForIntensity(double? intensity) {
  if (intensity == null || intensity <= 0) {
    return const Color(0xFFE0E0E0); // Gray (inactive)
  }
  // Lerp from light red to deep red
  return Color.lerp(
    const Color(0xFFFFCDD2), // Light red
    const Color(0xFFD32F2F), // Deep red
    intensity.clamp(0.0, 1.0),
  )!;
}
