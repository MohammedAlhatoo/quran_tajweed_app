import 'course_level.dart';

/// A course from the `courses` collection.
class Course {
  const Course({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    this.objectives = const [],
  });

  final String id;
  final String name;
  final String description;
  final CourseLevel level;

  /// Optional learning objectives shown on the course details screen.
  final List<String> objectives;

  /// Returns null when the document has no valid level.
  static Course? fromMap(String id, Map<String, dynamic> data) {
    final level = CourseLevel.fromValue(data['level']);
    if (level == null) return null;
    final objectives = data['objectives'];
    return Course(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      level: level,
      objectives: objectives is List
          ? objectives.whereType<String>().toList()
          : const [],
    );
  }
}
