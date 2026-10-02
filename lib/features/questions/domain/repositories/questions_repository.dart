import '../entities/exam_question.dart';

/// All methods throw `AppFailure` on error.
abstract interface class QuestionsRepository {
  /// The questions of [examId] that belong to [studentId], in their order.
  Future<List<ExamQuestion>> fetchExamQuestions({
    required String examId,
    required String studentId,
  });
}
