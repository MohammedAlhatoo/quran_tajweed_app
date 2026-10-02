import '../../../auth/domain/entities/app_user.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../../exams/domain/entities/submission.dart';
import '../../../questions/domain/entities/exam_question.dart';

/// What a square supervisor reads and writes to review the examinations of
/// the square.
/// All methods throw `AppFailure` on error.
abstract interface class ReviewRepository {
  /// The submitted examinations of [squareId] that are not approved yet,
  /// oldest submission first.
  Future<List<Exam>> fetchPendingExams(String squareId);

  /// The examinations of [squareId] whose result is approved, newest
  /// approval first.
  Future<List<Exam>> fetchReviewedExams(String squareId);

  /// Returns null when the student's account does not exist.
  Future<AppUser?> fetchStudent(String studentId);

  /// Returns null when the examination has no submission.
  Future<Submission?> fetchSubmission(String examId);

  /// The ten questions shown to the student in [examId], in their order.
  Future<List<ExamQuestion>> fetchExamQuestions(String examId);

  /// The correct answer of each of [questionIds], from `question_answers`.
  /// A question without a stored answer is absent from the result.
  Future<Map<String, String>> fetchCorrectAnswers(List<String> questionIds);

  /// Approves the result of [exam]: saves its evaluation and moves the
  /// examination to `approved`, together. The final score and the result are
  /// derived from the two scores.
  ///
  /// The same write notifies the student of the result in [courseName], and
  /// issues the certificate when the result is `passed`.
  Future<void> approveExam({
    required Exam exam,
    required String courseName,
    required String supervisorId,
    required int recitationScore,
    required int theoryScore,
  });

  /// Downloads the recitation of [examId] from the Storage path
  /// [recordingPath] and returns the path of the local file.
  Future<String> downloadRecording({
    required String examId,
    required String recordingPath,
  });
}
