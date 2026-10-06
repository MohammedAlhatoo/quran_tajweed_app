/// The approved scoring: recitation out of 80, theory out of 20, and a pass
/// mark of 70 out of 100.
///
/// The theory score is not calculated here: the review repository calculates
/// it from the student's answers.
abstract final class ExamScoring {
  static const int maxRecitationScore = 80;
  static const int maxTheoryScore = 20;
  static const int passMark = 70;

  static const String passed = 'passed';
  static const String failed = 'failed';

  /// Whether [score] can be entered as a recitation score.
  static bool isValidRecitationScore(int score) =>
      score >= 0 && score <= maxRecitationScore;

  static int finalScore({
    required int recitationScore,
    required int theoryScore,
  }) => recitationScore + theoryScore;

  /// `passed` or `failed`, as stored in the `result` field.
  static String resultOf(int finalScore) =>
      finalScore >= passMark ? passed : failed;
}
