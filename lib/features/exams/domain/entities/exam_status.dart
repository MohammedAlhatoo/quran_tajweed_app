enum ExamStatus {
  draft('draft', 'مسودة'),
  inProgress('in_progress', 'قيد التنفيذ'),
  submitted('submitted', 'تم التسليم'),
  pendingReview('pending_review', 'بانتظار المراجعة'),
  underReview('under_review', 'قيد المراجعة'),
  approved('approved', 'معتمد');

  const ExamStatus(this.value, this.label);

  /// The value stored in the `status` field of the `exams` document.
  final String value;

  final String label;

  /// The student has not submitted the examination yet and can continue it.
  bool get isOpen => this == draft || this == inProgress;

  /// Submitted and waiting for the supervisor's approval.
  bool get isAwaitingReview =>
      this == submitted || this == pendingReview || this == underReview;

  static ExamStatus? fromValue(Object? value) {
    for (final status in values) {
      if (status.value == value) return status;
    }
    return null;
  }
}
