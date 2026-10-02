/// The approved evaluation of one examination, from the `evaluations`
/// collection. Its ID is the examination's ID.
class Evaluation {
  const Evaluation({
    required this.examId,
    required this.recitationScore,
    required this.theoryScore,
    required this.finalScore,
    required this.result,
    this.supervisorId,
    this.approvedAt,
  });

  /// The values of the `result` field.
  static const String passedResult = 'passed';

  final String examId;

  /// Out of 80, entered by the supervisor.
  final int recitationScore;

  /// Out of 20, calculated from the student's answers.
  final int theoryScore;

  /// Out of 100.
  final int finalScore;

  /// `passed` or `failed`.
  final String result;
  final String? supervisorId;
  final DateTime? approvedAt;

  bool get passed => result == passedResult;

  /// Returns null when a score or the result is missing. [toDate] converts a
  /// stored timestamp value.
  static Evaluation? fromMap(
    String id,
    Map<String, dynamic> data, {
    required DateTime? Function(Object? value) toDate,
  }) {
    final recitationScore = data['recitationScore'];
    final theoryScore = data['theoryScore'];
    final finalScore = data['finalScore'];
    final result = data['result'];
    if (recitationScore is! int ||
        theoryScore is! int ||
        finalScore is! int ||
        result is! String) {
      return null;
    }
    return Evaluation(
      examId: id,
      recitationScore: recitationScore,
      theoryScore: theoryScore,
      finalScore: finalScore,
      result: result,
      supervisorId: data['supervisorId'] as String?,
      approvedAt: toDate(data['approvedAt']),
    );
  }
}
