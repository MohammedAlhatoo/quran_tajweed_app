import '../../../exams/domain/entities/evaluation.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../../exams/domain/entities/exam_status.dart';
import '../entities/exam_report.dart';

/// Builds a report from the examinations of a scope and their evaluations.
abstract final class ReportBuilder {
  static const String _unknownCourse = 'دورة غير متاحة';
  static const String _unknownStudent = 'طالب غير معروف';

  /// [evaluations] is keyed by examination ID, and the name maps by the ID of
  /// what they name. [unitOf] gives the square or region an examination is
  /// grouped under, or is null when the report has no such grouping.
  static ExamReport build({
    required List<Exam> exams,
    required Map<String, Evaluation> evaluations,
    required int students,
    required Map<String, String> studentNames,
    required Map<String, String> courseNames,
    Map<String, String> unitNames = const {},
    String Function(Exam exam)? unitOf,
    String unitTitle = '',
    String scopeName = '',
  }) {
    final oldest = DateTime.fromMillisecondsSinceEpoch(0);
    DateTime? dateOf(Exam exam) => exam.submittedAt ?? exam.startedAt;
    final sorted = [...exams]
      ..sort((a, b) => (dateOf(b) ?? oldest).compareTo(dateOf(a) ?? oldest));

    return ExamReport(
      scopeName: scopeName,
      students: students,
      totals: totalsOf(exams, evaluations),
      byCourse: _groups(
        exams,
        evaluations,
        keyOf: (exam) => exam.courseId,
        names: courseNames,
        unknown: _unknownCourse,
      ),
      byUnit: unitOf == null
          ? const []
          : _groups(
              exams,
              evaluations,
              keyOf: unitOf,
              names: unitNames,
              unknown: 'غير معروف',
            ),
      unitTitle: unitTitle,
      exams: [
        for (final exam in sorted)
          ReportExam(
            examId: exam.id,
            studentName: studentNames[exam.studentId] ?? _unknownStudent,
            courseName: courseNames[exam.courseId] ?? _unknownCourse,
            status: exam.status,
            recitationScore: evaluations[exam.id]?.recitationScore,
            theoryScore: evaluations[exam.id]?.theoryScore,
            finalScore: evaluations[exam.id]?.finalScore,
            passed: evaluations[exam.id]?.passed,
            date: dateOf(exam),
          ),
      ],
    );
  }

  /// An approved examination counts as passed or failed only when its
  /// evaluation is known.
  static ReportTotals totalsOf(
    List<Exam> exams,
    Map<String, Evaluation> evaluations,
  ) {
    var inProgress = 0;
    var awaitingReview = 0;
    var approved = 0;
    var passed = 0;
    var failed = 0;
    var scoreSum = 0;
    for (final exam in exams) {
      if (exam.status.isOpen) inProgress++;
      if (exam.status.isAwaitingReview) awaitingReview++;
      if (exam.status != ExamStatus.approved) continue;
      approved++;
      final evaluation = evaluations[exam.id];
      if (evaluation == null) continue;
      scoreSum += evaluation.finalScore;
      evaluation.passed ? passed++ : failed++;
    }
    final evaluated = passed + failed;
    return ReportTotals(
      exams: exams.length,
      inProgress: inProgress,
      awaitingReview: awaitingReview,
      approved: approved,
      passed: passed,
      failed: failed,
      averageScore: evaluated == 0 ? null : scoreSum / evaluated,
    );
  }

  static List<ReportGroup> _groups(
    List<Exam> exams,
    Map<String, Evaluation> evaluations, {
    required String Function(Exam exam) keyOf,
    required Map<String, String> names,
    required String unknown,
  }) {
    final byKey = <String, List<Exam>>{};
    for (final exam in exams) {
      byKey.putIfAbsent(keyOf(exam), () => []).add(exam);
    }
    return [
      for (final MapEntry(:key, :value) in byKey.entries)
        ReportGroup(
          label: names[key] ?? unknown,
          totals: totalsOf(value, evaluations),
        ),
    ]..sort((a, b) => a.label.compareTo(b.label));
  }
}
