import '../../../auth/domain/entities/app_user.dart';
import '../entities/exam.dart';
import '../entities/exam_segment.dart';

/// All methods throw `AppFailure` on error.
abstract interface class ExamsRepository {
  /// Starts an examination of [courseId] for [student] and returns it.
  ///
  /// When the student already has an open examination in the course, that one
  /// is returned instead of creating another. Starting is refused while an
  /// examination of the course is awaiting review.
  Future<Exam> startExam({required AppUser student, required String courseId});

  /// Returns null when the examination does not exist.
  Future<Exam?> fetchExam(String examId);

  /// Returns null when the segment does not exist.
  Future<ExamSegment?> fetchSegment(String segmentId);

  /// The student's examinations, newest first.
  Future<List<Exam>> fetchStudentExams(String studentId);
}
