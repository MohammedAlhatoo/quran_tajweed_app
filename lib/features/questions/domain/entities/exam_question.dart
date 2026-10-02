/// A question of one examination, from the `exam_questions` collection.
///
/// It is the copy shown to the student and never carries the correct answer:
/// answers live in `question_answers`, which students cannot read.
class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.examId,
    required this.questionId,
    required this.order,
    required this.type,
    required this.question,
    required this.options,
  });

  final String id;
  final String examId;

  /// The ID of the source question in `question_bank`.
  final String questionId;

  /// The position of the question in the examination, starting at 1.
  final int order;
  final String type;
  final String question;
  final List<String> options;

  /// Returns null when the document has no examination, source question,
  /// order or question text.
  static ExamQuestion? fromMap(String id, Map<String, dynamic> data) {
    final examId = data['examId'];
    final questionId = data['questionId'];
    final order = data['order'];
    final question = data['question'];
    if (examId is! String || questionId is! String) return null;
    if (order is! int || order < 1) return null;
    if (question is! String || question.isEmpty) return null;

    final options = data['options'];
    return ExamQuestion(
      id: id,
      examId: examId,
      questionId: questionId,
      order: order,
      type: data['type'] as String? ?? '',
      question: question,
      options: options is List
          ? options.whereType<String>().toList()
          : const [],
    );
  }
}
