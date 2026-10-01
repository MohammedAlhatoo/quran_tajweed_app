import 'package:flutter/material.dart';

import '../../domain/entities/course_level.dart';

/// The colors a course level uses in the approved design.
class CourseLevelStyle {
  const CourseLevelStyle({
    required this.homeCardBackground,
    required this.homeCardBorder,
    required this.badgeBackground,
    required this.badgeBorder,
    required this.chipBackground,
    required this.chipText,
  });

  /// The card on the home grid.
  final Color homeCardBackground;
  final Color homeCardBorder;

  /// The icon badge on the courses list.
  final Color badgeBackground;
  final Color badgeBorder;

  /// The level chip on the courses list.
  final Color chipBackground;
  final Color chipText;

  static CourseLevelStyle of(CourseLevel level) {
    return switch (level) {
      CourseLevel.introductory => const CourseLevelStyle(
        homeCardBackground: Color(0xFFF0FAF7),
        homeCardBorder: Color(0xFFC5EDE2),
        badgeBackground: Color(0xCCFFFBEB),
        badgeBorder: Color(0xB3FDE68A),
        chipBackground: Color(0xFFF0FDFA),
        chipText: Color(0xFF0F766E),
      ),
      CourseLevel.qualifying => const CourseLevelStyle(
        homeCardBackground: Color(0xFFF2F7FD),
        homeCardBorder: Color(0xFFCFE1F9),
        badgeBackground: Color(0xCCECFEFF),
        badgeBorder: Color(0xB3A5F3FC),
        chipBackground: Color(0xFFECFEFF),
        chipText: Color(0xFF0E7490),
      ),
      CourseLevel.advanced => const CourseLevelStyle(
        homeCardBackground: Color(0xFFFFFBF0),
        homeCardBorder: Color(0xFFFEE6B8),
        badgeBackground: Color(0xCCECFDF5),
        badgeBorder: Color(0xB3A7F3D0),
        chipBackground: Color(0xFFECFDF5),
        chipText: Color(0xFF065F46),
      ),
      CourseLevel.sanad => const CourseLevelStyle(
        homeCardBackground: Color(0xFFFDF2F2),
        homeCardBorder: Color(0xFFF9CACA),
        badgeBackground: Color(0xCCFFF7ED),
        badgeBorder: Color(0xB3FED7AA),
        chipBackground: Color(0xFFFFFBEB),
        chipText: Color(0xFF92400E),
      ),
    };
  }
}
