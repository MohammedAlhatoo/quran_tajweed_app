/// One Tajweed error the supervisor recorded in a recitation, stored in the
/// `detailedErrors` list of its evaluation.
///
/// Fields may be added later, such as the marks the error cost or its
/// position inside the recording.
class RecitationError {
  const RecitationError({
    required this.id,
    required this.ruleId,
    required this.description,
    this.ruleName,
    this.ayahNumber,
    this.word,
    this.createdAt,
  });

  /// The most errors the security rules accept in one evaluation.
  static const int maxPerEvaluation = 20;

  /// The limits of the supervisor's form.
  static const int maxDescriptionLength = 300;
  static const int maxWordLength = 60;

  /// Unique within its evaluation.
  final String id;

  /// References `tajweed_rules`.
  final String ruleId;

  /// The rule's name when the error was recorded, or null when unknown.
  final String? ruleName;

  /// The ayah of the examination's segment, or null when not specified.
  final int? ayahNumber;

  /// The word the error occurred in, or null when not specified.
  final String? word;

  /// Empty when the supervisor wrote none.
  final String description;
  final DateTime? createdAt;

  /// The ayah and the word, or null when neither is specified.
  String? get position {
    final parts = [
      if (ayahNumber case final ayah?) 'الآية $ayah',
      if (word case final word?) '«$word»',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Returns null when [value] is not an error with an ID and a rule.
  /// [toDate] converts a stored timestamp value.
  static RecitationError? fromMap(
    Object? value, {
    required DateTime? Function(Object? value) toDate,
  }) {
    if (value is! Map) return null;
    final id = value['id'];
    final ruleId = value['ruleId'];
    if (id is! String || ruleId is! String) return null;
    final ruleName = value['ruleName'];
    final ayahNumber = value['ayahNumber'];
    final word = value['word'];
    final description = value['description'];
    return RecitationError(
      id: id,
      ruleId: ruleId,
      ruleName: ruleName is String && ruleName.isNotEmpty ? ruleName : null,
      ayahNumber: ayahNumber is int ? ayahNumber : null,
      word: word is String && word.isNotEmpty ? word : null,
      description: description is String ? description : '',
      createdAt: toDate(value['createdAt']),
    );
  }

  /// The stored form. [fromDate] converts a date to a stored timestamp
  /// value.
  Map<String, dynamic> toMap({
    required Object Function(DateTime date) fromDate,
  }) => {
    'id': id,
    'ruleId': ruleId,
    'ruleName': ruleName,
    'ayahNumber': ayahNumber,
    'word': word,
    'description': description,
    'createdAt': createdAt == null ? null : fromDate(createdAt!),
  };
}
