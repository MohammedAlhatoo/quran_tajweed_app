abstract final class AppAssets {
  static const String logo = 'assets/images/logo.svg';
  static const String mosqueSilhouette = 'assets/images/mosque_silhouette.svg';

  static const String mailIcon = 'assets/icons/mail.svg';
  static const String lockIcon = 'assets/icons/lock.svg';
  static const String eyeIcon = 'assets/icons/eye.svg';
  static const String bellIcon = 'assets/icons/bell.svg';
  static const String backIcon = 'assets/icons/back.svg';
  static const String backLightIcon = 'assets/icons/back_light.svg';
  static const String chevronIcon = 'assets/icons/chevron.svg';
  static const String checkIcon = 'assets/icons/check.svg';
  static const String avatarIcon = 'assets/icons/avatar.svg';
  static const String micIcon = 'assets/icons/mic.svg';

  static const String navHomeIcon = 'assets/icons/nav_home.svg';
  static const String navCoursesIcon = 'assets/icons/nav_courses.svg';
  static const String navExamsIcon = 'assets/icons/nav_exams.svg';
  static const String navProfileIcon = 'assets/icons/nav_profile.svg';

  static const String homeHeroBookIcon = 'assets/icons/home_hero_book.svg';
  static const String courseBookIcon = 'assets/icons/course_book.svg';

  /// Course level icon on the home grid. [level] is the stored level value.
  static String homeLevelIcon(String level) =>
      'assets/icons/home_level_$level.svg';

  /// Course level icon on the courses list. [level] is the stored level value.
  static String levelIcon(String level) => 'assets/icons/level_$level.svg';

  /// Course level icon on the exam history. [level] is the stored level
  /// value.
  static String historyLevelIcon(String level) =>
      'assets/icons/history_level_$level.svg';

  static const String profileInfoIcon = 'assets/icons/profile_info.svg';
  static const String profileHistoryIcon = 'assets/icons/profile_history.svg';
  static const String profileCertificatesIcon =
      'assets/icons/profile_certificates.svg';
}
