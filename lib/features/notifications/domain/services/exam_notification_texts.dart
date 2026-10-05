/// The wording of the notification the app sends when a result is approved.
/// The notification of a submission is worded by the `submitExam` Cloud
/// Function.
abstract final class ExamNotificationTexts {
  static const String approvedTitle = 'تم اعتماد نتيجة اختبارك';

  /// States the result plainly: passed or failed, with the final score.
  static String approvedBody({
    required String courseName,
    required int finalScore,
    required bool passed,
  }) {
    final result = passed ? 'ناجح' : 'راسب';
    return 'نتيجتك في اختبار $courseName: $result بدرجة $finalScore من 100.';
  }
}
