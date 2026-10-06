import 'recitation_error.dart';

/// The approved evaluation of one examination, from the `evaluations`
/// collection. Its ID is the examination's ID.
///
/// The document is created when the supervisor approves the result.
class Evaluation {
  const Evaluation({
    required this.examId,
    required this.recitationScore,
    required this.theoryScore,
    required this.finalScore,
    required this.result,
    this.supervisorId,
    this.approvedAt,
    this.feedback,
    this.detailedErrors = const [],
  });

  /// The values of the `result` field.
  static const String passedResult = 'passed';

  final String examId;

  /// Out of 80, entered by the supervisor.
  final int recitationScore;

  /// Out of 20, calculated from the student's answers when the examination
  /// was submitted.
  final int theoryScore;

  /// Out of 100.
  final int finalScore;

  /// `passed` or `failed`.
  final String result;
  final String? supervisorId;
  final DateTime? approvedAt;

  /// The supervisor's general notes, or null when there are none.
  final String? feedback;

  /// The Tajweed errors the supervisor recorded, in the order they were
  /// added. Empty for an evaluation saved without them.
  final List<RecitationError> detailedErrors;

  bool get passed => result == passedResult;

  /// Returns null when a score or the result is missing, as in an evaluation
  /// that is not approved yet. [toDate] converts a stored timestamp value.
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
    final feedback = data['feedback'];
    final detailedErrors = data['detailedErrors'];
    return Evaluation(
      examId: id,
      recitationScore: recitationScore,
      theoryScore: theoryScore,
      finalScore: finalScore,
      result: result,
      supervisorId: data['supervisorId'] as String?,
      approvedAt: toDate(data['approvedAt']),
      feedback: feedback is String && feedback.trim().isNotEmpty
          ? feedback
          : null,
      detailedErrors: [
        if (detailedErrors is List)
          for (final error in detailedErrors)
            ?RecitationError.fromMap(error, toDate: toDate),
      ],
    );
  }
}
