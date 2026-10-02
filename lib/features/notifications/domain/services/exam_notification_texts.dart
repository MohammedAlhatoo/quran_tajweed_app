/// The wording of the notifications sent for examination events.
abstract final class ExamNotificationTexts {
  static const String submittedTitle = 'اختبار جديد يحتاج مراجعة';

  static String submittedBody(String studentName) =>
      'أرسل الطالب $studentName اختبارًا بانتظار مراجعتك.';

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
