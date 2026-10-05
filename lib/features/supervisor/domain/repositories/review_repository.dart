import '../../../auth/domain/entities/app_user.dart';
import '../../../courses/domain/entities/tajweed_rule.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../../exams/domain/entities/recitation_error.dart';
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

  /// The theory score of [examId] out of 20, saved when the student
  /// submitted it. It is read, never calculated or written by the app.
  ///
  /// Returns null when none is saved: the examination was not submitted with
  /// its ten questions and answers, and cannot be approved.
  Future<int?> fetchTheoryScore(String examId);

  /// The correct answer of each question of [examId], keyed by the order of
  /// the question, from the answer key copied when the examination was
  /// created. Empty when the examination has no answer key.
  Future<Map<int, String>> fetchAnswerKey(String examId);

  /// The Tajweed rules of `tajweed_rules`, ordered by name.
  Future<List<TajweedRule>> fetchTajweedRules();

  /// Approves the result of [exam]: completes its evaluation with
  /// [recitationScore] and moves the examination to `approved`, together.
  /// [feedback] is the supervisor's general notes, and [errors] the Tajweed
  /// errors recorded in the recitation.
  ///
  /// [theoryScore] is the saved score, as [fetchTheoryScore] returned it. It
  /// is not written: the final score and the result are derived from it and
  /// are refused unless they agree with the saved score.
  ///
  /// The same write notifies the student of the result in [courseName], and
  /// issues the certificate when the result is `passed`.
  Future<void> approveExam({
    required Exam exam,
    required String courseName,
    required String supervisorId,
    required int recitationScore,
    required int theoryScore,
    required String? feedback,
    required List<RecitationError> errors,
  });

  /// Downloads the recitation of [examId] from the Storage path
  /// [recordingPath] and returns the path of the local file.
  Future<String> downloadRecording({
    required String examId,
    required String recordingPath,
  });
}
