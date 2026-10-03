import '../../domain/entities/question_type.dart';

export '../../domain/entities/question_type.dart' show QuestionType;

/// The definition of one theory question and its correct answer.
///
/// The question and the answer are written to two collections:
/// `question_bank` never holds the answer, `question_answers` holds only it.
class QuestionSeed {
  const QuestionSeed(
    this.ruleId,
    this.question,
    this.correctAnswer,
    this._wrongAnswers, {
    this.number = 1,
    this.difficulty,
  }) : type = QuestionType.multipleChoice;

  /// A statement that is either true or false.
  const QuestionSeed.trueFalse(
    this.ruleId,
    this.question,
    bool isTrue, {
    this.number = 1,
    this.difficulty,
  }) : type = QuestionType.trueFalse,
       correctAnswer = isTrue ? trueOption : falseOption,
       _wrongAnswers = const [];

  static const String trueOption = 'صح';
  static const String falseOption = 'خطأ';

  /// The Tajweed rule the question examines, from `tajweed_rules`.
  final String ruleId;

  final String question;

  /// One of [options], word for word: the theory score compares the
  /// student's answer with it as text.
  final String correctAnswer;

  final List<String> _wrongAnswers;

  /// The place of the question among those of its rule, starting at 1.
  final int number;

  /// From 1 (easy) to 3 (hard). Null when it follows the level that
  /// introduces the rule.
  final int? difficulty;

  final QuestionType type;

  /// Identifies the question in every course. It is permanent: the document
  /// IDs of `question_bank` and `question_answers` are built from it.
  String get key => '${ruleId}_$number';

  /// The options in the order shown to the student. The place of the correct
  /// answer depends on [key] only, so it varies between questions and never
  /// changes between two runs.
  List<String> get options {
    if (type == QuestionType.trueFalse) return const [trueOption, falseOption];
    final place =
        key.codeUnits.fold(0, (sum, unit) => sum + unit) %
        (_wrongAnswers.length + 1);
    return [..._wrongAnswers]..insert(place, correctAnswer);
  }

  /// The fields of the `question_bank` document, without `isActive` and its
  /// timestamps. It never holds the correct answer.
  Map<String, Object?> toMap({
    required String courseId,
    required String ruleId,
    required int difficulty,
  }) => {
    'courseId': courseId,
    'ruleId': ruleId,
    'type': type.value,
    'question': question,
    'options': options,
    'difficulty': difficulty,
  };

  /// The fields of the `question_answers` document.
  Map<String, Object?> answerToMap() => {'correctAnswer': correctAnswer};
}
