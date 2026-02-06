import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';

/// Widget that displays a body map with highlighted muscle groups
/// Uses body_map.png as the base image with colored overlay regions
class MuscleBodyMap extends StatelessWidget {
  final List<String> highlightedMuscles;
  final Color highlightColor;
  final double height;

  const MuscleBodyMap({
    required this.highlightedMuscles,
    this.highlightColor = const Color(0xFFEF4444),
    this.height = 500,
    super.key,
  });

  /// Maps exercise muscleGroup values to display regions and names
  static const Map<String, MuscleRegion> muscleGroupMapping = {
    'chest': MuscleRegion(
      displayName: '가슴',
      view: BodyView.front,
      position: MusclePosition(top: 0.20, left: 0.14, width: 0.22, height: 0.10),
    ),
    'back': MuscleRegion(
      displayName: '등',
      view: BodyView.back,
      position: MusclePosition(top: 0.20, left: 0.58, width: 0.24, height: 0.14),
    ),
    'shoulders': MuscleRegion(
      displayName: '어깨',
      view: BodyView.front,
      position: MusclePosition(top: 0.16, left: 0.08, width: 0.08, height: 0.06),
      mirrorPosition: MusclePosition(top: 0.16, left: 0.34, width: 0.08, height: 0.06),
    ),
    'biceps': MuscleRegion(
      displayName: '이두',
      view: BodyView.front,
      position: MusclePosition(top: 0.26, left: 0.06, width: 0.06, height: 0.12),
      mirrorPosition: MusclePosition(top: 0.26, left: 0.38, width: 0.06, height: 0.12),
    ),
    'triceps': MuscleRegion(
      displayName: '삼두',
      view: BodyView.back,
      position: MusclePosition(top: 0.26, left: 0.52, width: 0.06, height: 0.12),
      mirrorPosition: MusclePosition(top: 0.26, left: 0.82, width: 0.06, height: 0.12),
    ),
    'forearms': MuscleRegion(
      displayName: '전완',
      view: BodyView.front,
      position: MusclePosition(top: 0.40, left: 0.02, width: 0.06, height: 0.16),
      mirrorPosition: MusclePosition(top: 0.40, left: 0.42, width: 0.06, height: 0.16),
    ),
    'quadriceps': MuscleRegion(
      displayName: '대퇴사두',
      view: BodyView.front,
      position: MusclePosition(top: 0.50, left: 0.12, width: 0.10, height: 0.20),
      mirrorPosition: MusclePosition(top: 0.50, left: 0.28, width: 0.10, height: 0.20),
    ),
    'hamstrings': MuscleRegion(
      displayName: '햄스트링',
      view: BodyView.back,
      position: MusclePosition(top: 0.52, left: 0.58, width: 0.10, height: 0.16),
      mirrorPosition: MusclePosition(top: 0.52, left: 0.72, width: 0.10, height: 0.16),
    ),
    'glutes': MuscleRegion(
      displayName: '둔근',
      view: BodyView.back,
      position: MusclePosition(top: 0.42, left: 0.60, width: 0.20, height: 0.10),
    ),
    'calves': MuscleRegion(
      displayName: '종아리',
      view: BodyView.back,
      position: MusclePosition(top: 0.72, left: 0.60, width: 0.08, height: 0.16),
      mirrorPosition: MusclePosition(top: 0.72, left: 0.72, width: 0.08, height: 0.16),
    ),
    'core': MuscleRegion(
      displayName: '코어',
      view: BodyView.front,
      position: MusclePosition(top: 0.30, left: 0.16, width: 0.18, height: 0.12),
    ),
    'abs': MuscleRegion(
      displayName: '복근',
      view: BodyView.front,
      position: MusclePosition(top: 0.32, left: 0.17, width: 0.16, height: 0.10),
    ),
    'lats': MuscleRegion(
      displayName: '광배근',
      view: BodyView.back,
      position: MusclePosition(top: 0.26, left: 0.56, width: 0.10, height: 0.12),
      mirrorPosition: MusclePosition(top: 0.26, left: 0.74, width: 0.10, height: 0.12),
    ),
    'traps': MuscleRegion(
      displayName: '승모근',
      view: BodyView.back,
      position: MusclePosition(top: 0.12, left: 0.62, width: 0.16, height: 0.08),
    ),
  };

  /// Expand full_body to all muscle groups
  Set<String> get _expandedMuscles {
    final expanded = <String>{};
    for (final muscle in highlightedMuscles) {
      final normalized = muscle.toLowerCase();
      if (normalized == 'full_body') {
        // Add all muscle groups for full body
        expanded.addAll(muscleGroupMapping.keys);
      } else if (muscleGroupMapping.containsKey(normalized)) {
        expanded.add(normalized);
      }
    }
    return expanded;
  }

  @override
  Widget build(BuildContext context) {
    final muscles = _expandedMuscles;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Muscles Worked',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.neutralBlack,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Image-based body map
          Center(
            child: SizedBox(
              height: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Stack(
                  children: [
                    // Base anatomical image
                    Image.asset(
                      'images/body_map.png',
                      height: height,
                      fit: BoxFit.contain,
                    ),
                    // Colored overlay regions
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MuscleOverlayPainter(
                          highlightedMuscles: muscles,
                          highlightColor: highlightColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Legend
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: highlightedMuscles.map((muscle) {
              final region = muscleGroupMapping[muscle.toLowerCase()];
              final displayName = region?.displayName ?? muscle;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: highlightColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: highlightColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: highlightColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Painter that draws colored overlays on muscle regions with natural blending
class _MuscleOverlayPainter extends CustomPainter {
  final Set<String> highlightedMuscles;
  final Color highlightColor;

  _MuscleOverlayPainter({
    required this.highlightedMuscles,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (final muscle in highlightedMuscles) {
      final region = MuscleBodyMap.muscleGroupMapping[muscle];
      if (region == null) continue;

      _drawMuscleRegion(canvas, size, region.position);
      if (region.mirrorPosition != null) {
        _drawMuscleRegion(canvas, size, region.mirrorPosition!);
      }
    }

    canvas.restore();
  }

  void _drawMuscleRegion(
    Canvas canvas,
    Size size,
    MusclePosition pos,
  ) {
    final centerX = size.width * (pos.left + pos.width / 2);
    final centerY = size.height * (pos.top + pos.height / 2);
    final radiusX = size.width * pos.width / 2;
    final radiusY = size.height * pos.height / 2;

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [
        highlightColor.withValues(alpha: 0.7),
        highlightColor.withValues(alpha: 0.4),
        highlightColor.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: radiusX * 2.2,
      height: radiusY * 2.2,
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.multiply;

    canvas.drawOval(rect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _MuscleOverlayPainter oldDelegate) {
    return highlightedMuscles != oldDelegate.highlightedMuscles ||
        highlightColor != oldDelegate.highlightColor;
  }
}

enum BodyView { front, back }

class MuscleRegion {
  final String displayName;
  final BodyView view;
  final MusclePosition position;
  final MusclePosition? mirrorPosition;

  const MuscleRegion({
    required this.displayName,
    required this.view,
    required this.position,
    this.mirrorPosition,
  });
}

class MusclePosition {
  final double top;
  final double left;
  final double width;
  final double height;

  const MusclePosition({
    required this.top,
    required this.left,
    required this.width,
    required this.height,
  });
}
