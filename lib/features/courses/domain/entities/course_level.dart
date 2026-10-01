/// The four examination levels, in the order they are shown.
enum CourseLevel {
  introductory('introductory', 'مستوى المبتدئين'),
  qualifying('qualifying', 'مستوى متوسط'),
  advanced('advanced', 'مستوى متقدم'),
  sanad('sanad', 'مستوى عالي');

  const CourseLevel(this.value, this.label);

  /// The value stored in the `level` field of the `courses` document.
  final String value;

  final String label;

  static CourseLevel? fromValue(Object? value) {
    for (final level in values) {
      if (level.value == value) return level;
    }
    return null;
  }
}
