import '../entities/exam_report.dart';

/// Throws `AppFailure` on error. The security rules refuse a scope the
/// caller does not hold.
abstract interface class ReportsRepository {
  /// The examinations, results and students of [scope].
  Future<ExamReport> fetchReport(ReportScope scope);
}
