import '../entities/submission_answer.dart';

/// All methods throw `AppFailure` on error.
abstract interface class SubmissionRepository {
  /// Submits [examId], an examination of the signed-in student, with its ten
  /// [answers].
  ///
  /// A trusted backend does all of it together: it saves the submission,
  /// calculates the theory score from the answer key of the examination and
  /// saves it in a pending evaluation, moves the examination to
  /// `pending_review`, and notifies the supervisor of its square. The theory
  /// score is not given back; the student sees it with the approved result.
  ///
  /// Refused unless the examination holds its ten questions and [answers]
  /// answers each of them.
  Future<void> submitExam({
    required String examId,
    required List<SubmissionAnswer> answers,
  });
}
