import 'package:flutter/material.dart';

enum AcademyCategory {
  all('all', '전체', Icons.grid_view_rounded),
  bodybuilding('bodybuilding', '보디빌딩', Icons.fitness_center),
  powerlifting('powerlifting', '파워리프팅', Icons.sports_gymnastics),
  rehabMobility('rehab_mobility', '재활/모빌리티', Icons.healing),
  nutrition('nutrition', '영양', Icons.restaurant),
  stretching('stretching', '스트레칭', Icons.self_improvement);

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
