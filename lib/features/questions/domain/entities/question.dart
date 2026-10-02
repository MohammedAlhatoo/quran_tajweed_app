/// A question from the `question_bank` collection.
///
/// It never carries the correct answer: answers live in `question_answers`,
/// which students cannot read.
class Question {
  const Question({
    required this.id,
    required this.courseId,
    required this.ruleId,
    required this.type,
    required this.question,
    required this.options,
    required this.isActive,
  });

  final String id;
  final String courseId;
  final String ruleId;
  final String type;
  final String question;
  final List<String> options;
  final bool isActive;

  /// Returns null when the document has no course, type or question text.
  static Question? fromMap(String id, Map<String, dynamic> data) {
    final courseId = data['courseId'];
    final type = data['type'];
    final question = data['question'];
    if (courseId is! String || type is! String) return null;
    if (question is! String || question.isEmpty) return null;

    final options = data['options'];
    return Question(
      id: id,
      courseId: courseId,
      ruleId: data['ruleId'] as String? ?? '',
      type: type,
      question: question,
      options: options is List
          ? options.whereType<String>().toList()
          : const [],
      isActive: data['isActive'] == true,
    );
  }
}
