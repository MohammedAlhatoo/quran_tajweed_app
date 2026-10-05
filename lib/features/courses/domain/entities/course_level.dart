/// The four examination levels, in the order they are shown.
enum CourseLevel {
  introductory('introductory', 'تمهيدية'),
  qualifying('qualifying', 'تأهيلية'),
  advanced('advanced', 'عليا'),
  sanad('sanad', 'السند');

  const CourseLevel(this.value, this.label);

  /// The value stored in the `level` field of the `courses` document.
  final String value;

  /// The approved name of the level, as the student reads it.
  final String label;

  static CourseLevel? fromValue(Object? value) {
    for (final level in values) {
      if (level.value == value) return level;
    }
    return null;
  }
}
