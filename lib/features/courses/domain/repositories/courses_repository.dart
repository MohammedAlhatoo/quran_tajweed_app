import '../entities/course.dart';

/// All methods throw `AppFailure` on error.
abstract interface class CoursesRepository {
  /// The active courses, ordered by level.
  Future<List<Course>> fetchActiveCourses();

  /// Returns null when the course does not exist or is not active.
  Future<Course?> fetchCourse(String courseId);

  /// The names of the Tajweed rules linked to the course.
  Future<List<String>> fetchCourseRuleNames(String courseId);
}
