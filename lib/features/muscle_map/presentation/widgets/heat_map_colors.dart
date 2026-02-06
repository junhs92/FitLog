import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

/// Color utilities for muscle activity heat maps
class HeatMapColors {
  HeatMapColors._();

  /// Get color for an intensity value (0.0 - 1.0)
  ///
  /// Color scale:
  /// - 0.0 = Not worked (neutral gray)
  /// - 0.25 = Light activity (light blue)
  /// - 0.5 = Moderate (yellow/warning)
  /// - 0.75 = Active (orange)
  /// - 1.0 = Hot/Recent (red/error)
  static Color intensityToColor(double intensity) {
    if (intensity <= 0) {
      return AppColors.neutral300;
    } else if (intensity <= 0.25) {
      return Color.lerp(
        AppColors.neutral300,
        AppColors.info,
        intensity / 0.25,
      )!;
    } else if (intensity <= 0.5) {
      return Color.lerp(
        AppColors.info,
        AppColors.warning,
        (intensity - 0.25) / 0.25,
      )!;
    } else if (intensity <= 0.75) {
      return Color.lerp(
        AppColors.warning,
        const Color(0xFFFF9F43), // Orange
        (intensity - 0.5) / 0.25,
      )!;
    } else {
      return Color.lerp(
        const Color(0xFFFF9F43), // Orange
        AppColors.error,
        (intensity - 0.75) / 0.25,
      )!;
    }
  }

  /// Get color based on days since worked
  ///
  /// Color scale:
  /// - 0-1 days = Hot (red)
  /// - 2-3 days = Active (orange)
  /// - 4-5 days = Moderate (yellow)
  /// - 6-7 days = Light (blue)
  /// - 8+ days = Cold (gray)
  static Color daysSinceToColor(int? daysSince) {
    if (daysSince == null) {
      return AppColors.neutral300;
    } else if (daysSince <= 1) {
      return AppColors.error;
    } else if (daysSince <= 3) {
      return const Color(0xFFFF9F43); // Orange
    } else if (daysSince <= 5) {
      return AppColors.warning;
    } else if (daysSince <= 7) {
      return AppColors.info;
    } else {
      return AppColors.neutral400;
    }
  }

  /// Get fill color with appropriate opacity for overlays
  static Color intensityToFillColor(double intensity) {
    return intensityToColor(intensity).withValues(alpha: 0.6);
  }

  /// Get outline color for muscle regions
  static Color intensityToOutlineColor(double intensity) {
    if (intensity <= 0) {
      return AppColors.neutral400;
    }
    return intensityToColor(intensity);
  }

  /// Get status label for intensity
  static String intensityToLabel(double intensity) {
    if (intensity <= 0) {
      return 'Not worked';
    } else if (intensity <= 0.25) {
      return 'Light';
    } else if (intensity <= 0.5) {
      return 'Moderate';
    } else if (intensity <= 0.75) {
      return 'Active';
    } else {
      return 'Hot';
    }
  }

  /// Color stops for gradient legend
  static List<Color> get gradientStops => [
        AppColors.neutral300,
        AppColors.info,
        AppColors.warning,
        const Color(0xFFFF9F43),
        AppColors.error,
      ];

  /// Labels for gradient legend
  static List<String> get gradientLabels => [
        'None',
        'Light',
        'Moderate',
        'Active',
        'Hot',
      ];
}
