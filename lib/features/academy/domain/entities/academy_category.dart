import 'package:flutter/material.dart';

enum AcademyCategory {
  all('all', '전체', Icons.grid_view_rounded),
  exercise('exercise', '운동', Icons.fitness_center),
  rehab('rehab', '재활', Icons.healing),
  nutrition('nutrition', '영양', Icons.restaurant);

  const AcademyCategory(this.dbValue, this.displayName, this.icon);

  final String dbValue;
  final String displayName;
  final IconData icon;

  /// Parse from DB string value
  static AcademyCategory fromDbValue(String value) {
    return AcademyCategory.values.firstWhere(
      (c) => c.dbValue == value,
      orElse: () => AcademyCategory.all,
    );
  }
}
