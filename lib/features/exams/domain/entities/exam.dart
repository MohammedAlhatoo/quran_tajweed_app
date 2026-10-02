import 'exam_status.dart';

/// An examination from the `exams` collection.
class Exam {
  const Exam({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.segmentId,
    required this.status,
    required this.mosqueId,
    required this.squareId,
    required this.regionId,
    this.startedAt,
    this.submittedAt,
  });

  final String id;
  final String studentId;
  final String courseId;
  final String segmentId;
  final ExamStatus status;

  /// The student's affiliation when the examination was started.
  final String mosqueId;
  final String squareId;
  final String regionId;

  final DateTime? startedAt;
  final DateTime? submittedAt;

  /// Returns null when a required field is missing or invalid. [toDate]
  /// converts a stored timestamp value.
  static Exam? fromMap(
    String id,
    Map<String, dynamic> data, {
    required DateTime? Function(Object? value) toDate,
  }) {
    final status = ExamStatus.fromValue(data['status']);
    final studentId = data['studentId'];
    final courseId = data['courseId'];
    final segmentId = data['segmentId'];
    if (status == null ||
        studentId is! String ||
        courseId is! String ||
        segmentId is! String) {
      return null;
    }
    return Exam(
      id: id,
      studentId: studentId,
      courseId: courseId,
      segmentId: segmentId,
      status: status,
      mosqueId: data['mosqueId'] as String? ?? '',
      squareId: data['squareId'] as String? ?? '',
      regionId: data['regionId'] as String? ?? '',
      startedAt: toDate(data['startedAt']),
      submittedAt: toDate(data['submittedAt']),
    );
  }
}
