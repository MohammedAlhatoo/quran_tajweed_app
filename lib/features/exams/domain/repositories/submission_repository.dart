import '../entities/submission_answer.dart';

/// All methods throw `AppFailure` on error.
abstract interface class SubmissionRepository {
  /// Submits [examId], an examination of the signed-in student, with its ten
  /// [answers].
  ///
  /// All of it happens together: the submission is saved with the link of
  /// the uploaded recitation, the examination moves to `pending_review`, and
  /// the supervisor of its square is notified. Nothing is graded; the student
  /// sees the theory score with the approved result.
  ///
  /// Refused unless the recitation is uploaded and the examination is still
  /// in progress.
  Future<void> submitExam({
    required String examId,
    required List<SubmissionAnswer> answers,
  });
}
