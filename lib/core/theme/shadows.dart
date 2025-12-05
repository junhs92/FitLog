import 'package:flutter/material.dart';
import 'colors.dart';

class AppShadows {
  AppShadows._();

  // Shadow levels
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: AppColors.neutralBlack.withOpacity(0.05),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: AppColors.neutralBlack.withOpacity(0.1),
          offset: const Offset(0, 4),
          blurRadius: 6,
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: AppColors.neutralBlack.withOpacity(0.1),
          offset: const Offset(0, 10),
          blurRadius: 15,
        ),
      ];

  static List<BoxShadow> get xl => [
        BoxShadow(
          color: AppColors.neutralBlack.withOpacity(0.15),
          offset: const Offset(0, 20),
          blurRadius: 25,
        ),
      ];
}
