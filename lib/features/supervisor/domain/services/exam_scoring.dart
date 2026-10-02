import '../../../exams/domain/entities/submission_answer.dart';
import '../../../questions/domain/entities/exam_question.dart';

/// The approved scoring: recitation out of 80, theory out of 20, and a pass
/// mark of 70 out of 100.
abstract final class ExamScoring {
  static const int maxRecitationScore = 80;
  static const int maxTheoryScore = 20;
  static const int passMark = 70;

  static const String passed = 'passed';
  static const String failed = 'failed';

  /// Whether [score] can be entered as a recitation score.
  static bool isValidRecitationScore(int score) =>
      score >= 0 && score <= maxRecitationScore;

  /// The theory score out of 20: every question has the same share, and a
  /// question without an answer earns nothing.
  ///
  /// [correctAnswers] holds the correct answer of each question, keyed by the
  /// ID of its source question. Returns null when there are no questions or
  /// the correct answer of one of them is missing.
  static int? theoryScore({
    required List<ExamQuestion> questions,
    required List<SubmissionAnswer> answers,
    required Map<String, String> correctAnswers,
  }) {
    if (questions.isEmpty) return null;
    final answerByOrder = {
      for (final answer in answers) answer.order: answer.answer,
    };
    var correct = 0;
    for (final question in questions) {
      final correctAnswer = correctAnswers[question.questionId];
      if (correctAnswer == null) return null;
      if (answerByOrder[question.order] == correctAnswer) correct++;
    }
    return (correct * maxTheoryScore / questions.length).round();
  }

  static int finalScore({
    required int recitationScore,
    required int theoryScore,
  }) => recitationScore + theoryScore;

  /// `passed` or `failed`, as stored in the `result` field.
  static String resultOf(int finalScore) =>
      finalScore >= passMark ? passed : failed;
}
