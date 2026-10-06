import '../../../exams/domain/entities/exam_status.dart';

/// Whose examinations a report covers: one square, one region, or the whole
/// system.
class ReportScope {
  const ReportScope.square(String this.squareId) : regionId = null;

  const ReportScope.region(String this.regionId) : squareId = null;

  const ReportScope.system() : squareId = null, regionId = null;

  final String? squareId;
  final String? regionId;
}

/// The counts of a set of examinations.
class ReportTotals {
  const ReportTotals({
    required this.exams,
    required this.inProgress,
    required this.awaitingReview,
    required this.approved,
    required this.passed,
    required this.failed,
    required this.averageScore,
  });

  final int exams;
  final int inProgress;
  final int awaitingReview;
  final int approved;
  final int passed;
  final int failed;

  /// The mean final score of the approved examinations, or null when none is
  /// approved.
  final double? averageScore;

  /// The share of passed examinations among the approved ones, from 0 to
  /// 100, or null when none is approved.
  double? get passRate {
    final evaluated = passed + failed;
    return evaluated == 0 ? null : passed * 100 / evaluated;
  }
}

/// The totals of one course, square or region inside a report.
class ReportGroup {
  const ReportGroup({required this.label, required this.totals});

  final String label;
  final ReportTotals totals;
}

/// One examination listed in a report.
class ReportExam {
  const ReportExam({
    required this.examId,
    required this.studentName,
    required this.courseName,
    required this.status,
    this.recitationScore,
    this.theoryScore,
    this.finalScore,
    this.passed,
    this.date,
  });

  final String examId;
  final String studentName;
  final String courseName;
  final ExamStatus status;

  /// Out of 80 and out of 20. Null until the result is approved.
  final int? recitationScore;
  final int? theoryScore;

  /// Null until the result is approved.
  final int? finalScore;
  final bool? passed;

  /// When the examination was submitted, or started if not submitted yet.
  final DateTime? date;
}

class ExamReport {
  const ExamReport({
    required this.students,
    required this.totals,
    required this.byCourse,
    required this.byUnit,
    required this.unitTitle,
    required this.exams,
    this.scopeName = '',
  });

  /// The name of the square or the region the report covers, or empty when
  /// it is unknown or the report covers the whole system.
  final String scopeName;

  /// The number of student accounts in the scope.
  final int students;
  final ReportTotals totals;
  final List<ReportGroup> byCourse;

  /// The totals of each square of a region, or of each region of the
  /// system. Empty for a square.
  final List<ReportGroup> byUnit;

  /// What [byUnit] lists, for example "حسب المربع".
  final String unitTitle;

  /// Newest first.
  final List<ReportExam> exams;
}
