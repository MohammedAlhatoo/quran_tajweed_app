/// The form of a theory question.
enum QuestionType {
  /// One correct answer among several options.
  multipleChoice('multiple_choice'),

  /// A statement answered with true or false.
  trueFalse('true_false');

  const QuestionType(this.value);

  /// The value stored in the `type` field of the `question_bank` document.
  final String value;

  /// Returns null when [value] is not a known type.
  static QuestionType? fromValue(Object? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}
