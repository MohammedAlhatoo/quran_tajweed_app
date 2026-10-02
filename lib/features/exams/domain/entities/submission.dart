import 'submission_answer.dart';

/// A student's submission of one examination, from the `submissions`
/// collection. Its ID is the examination's ID.
class Submission {
  const Submission({
    required this.examId,
    required this.studentId,
    required this.recordingPath,
    required this.answers,
    this.submittedAt,
  });

  final String examId;
  final String studentId;

  /// The Storage path of the recitation recording, stored as `recordingUrl`.
  final String recordingPath;

  /// The student's answers, in the order of the questions.
  final List<SubmissionAnswer> answers;

  final DateTime? submittedAt;

  /// Returns null when a required field is missing. [toDate] converts a
  /// stored timestamp value.
  static Submission? fromMap(
    String id,
    Map<String, dynamic> data, {
    required DateTime? Function(Object? value) toDate,
  }) {
    final studentId = data['studentId'];
    final recordingPath = data['recordingUrl'];
    final answers = data['answers'];
    if (studentId is! String || recordingPath is! String || answers is! List) {
      return null;
    }
    return Submission(
      examId: id,
      studentId: studentId,
      recordingPath: recordingPath,
      answers: [
        for (final answer in answers)
          if (answer is Map) ?SubmissionAnswer.fromMap(answer),
      ]..sort((a, b) => a.order.compareTo(b.order)),
      submittedAt: toDate(data['submittedAt']),
    );
  }
}
