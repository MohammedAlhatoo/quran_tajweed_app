import '../../../questions/domain/entities/exam_question.dart';

/// The student's answer to one question, as stored in the `answers` list of
/// a `submissions` document.
class SubmissionAnswer {
  const SubmissionAnswer({
    required this.order,
    required this.questionId,
    required this.answer,
  });

  /// The position of the question in the examination, starting at 1.
  final int order;

  /// The ID of the source question in `question_bank`.
  final String questionId;

  /// The option the student chose.
  final String answer;

  Map<String, dynamic> toMap() => {
    'order': order,
    'questionId': questionId,
    'answer': answer,
  };

  /// Returns null when a field is missing or invalid.
  static SubmissionAnswer? fromMap(Map<dynamic, dynamic> data) {
    final order = data['order'];
    final questionId = data['questionId'];
    final answer = data['answer'];
    if (order is! int || questionId is! String || answer is! String) {
      return null;
    }
    return SubmissionAnswer(
      order: order,
      questionId: questionId,
      answer: answer,
    );
  }

  /// The answers to [questions], in their order. [chosen] holds the chosen
  /// option of each question, keyed by the ID of its `exam_questions` record.
  ///
  /// Returns null when a question has no answer.
  static List<SubmissionAnswer>? listFrom(
    List<ExamQuestion> questions,
    Map<String, String> chosen,
  ) {
    final answers = <SubmissionAnswer>[];
    for (final question in questions) {
      final answer = chosen[question.id];
      if (answer == null) return null;
      answers.add(
        SubmissionAnswer(
          order: question.order,
          questionId: question.questionId,
          answer: answer,
        ),
      );
    }
    return answers;
  }
}
