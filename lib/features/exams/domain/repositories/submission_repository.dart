import '../entities/submission_answer.dart';

/// All methods throw `AppFailure` on error.
abstract interface class SubmissionRepository {
  /// Saves the submission of [examId] and moves the examination to
  /// `pending_review`, together. The same write notifies the supervisor of
  /// the examination's square, naming the student as [studentName].
  ///
  /// The theory score and the evaluation record are not created here; they
  /// need access the student does not have.
  Future<void> submitExam({
    required String examId,
    required String studentId,
    required String studentName,
    required List<SubmissionAnswer> answers,
  });
}
