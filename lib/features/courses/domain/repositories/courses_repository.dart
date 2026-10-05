import '../entities/course.dart';
import '../entities/tajweed_rule.dart';

/// All methods throw `AppFailure` on error.
abstract interface class CoursesRepository {
  /// The active courses, ordered by level.
  Future<List<Course>> fetchActiveCourses();

  /// Returns null when the course does not exist or is not active.
  Future<Course?> fetchCourse(String courseId);

  /// The Tajweed rules linked to the course through `course_rules`.
  Future<List<TajweedRule>> fetchCourseRules(String courseId);
}
