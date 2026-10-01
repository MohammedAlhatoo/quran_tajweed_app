abstract final class RouteNames {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';

  // The root of each role's area. Screens of a role live under its root.
  static const String student = '/student';
  static const String studentCourses = '/student/courses';
  static const String studentExams = '/student/exams';
  static const String studentProfile = '/student/profile';
  static const String studentPersonalInfo = '/student/profile/info';
  static const String studentCourseDetailsPattern =
      '/student/courses/:courseId';

  static String studentCourseDetails(String courseId) =>
      '/student/courses/$courseId';

  static const String supervisor = '/supervisor';
  static const String region = '/region';
  static const String admin = '/admin';
}
