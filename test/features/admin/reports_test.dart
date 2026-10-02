import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/admin/domain/entities/exam_report.dart';
import 'package:quran_tajweed_app/features/admin/domain/repositories/reports_repository.dart';
import 'package:quran_tajweed_app/features/admin/domain/services/report_builder.dart';
import 'package:quran_tajweed_app/features/admin/presentation/state/report_cubit.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/evaluation.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';

Exam _exam(
  String id,
  ExamStatus status, {
  String course = 'course-1',
  String square = 'square-1',
  String student = 'uid-1',
  DateTime? submittedAt,
}) {
  return Exam(
    id: id,
    studentId: student,
    courseId: course,
    segmentId: 'segment-1',
    status: status,
    mosqueId: 'mosque-1',
    squareId: square,
    regionId: 'region-1',
    submittedAt: submittedAt,
  );
}

Evaluation _evaluation(String examId, int finalScore) {
  return Evaluation(
    examId: examId,
    recitationScore: finalScore - 10,
    theoryScore: 10,
    finalScore: finalScore,
    result: finalScore >= 70 ? 'passed' : 'failed',
  );
}

final _exams = [
  _exam('e1', ExamStatus.inProgress),
  _exam('e2', ExamStatus.pendingReview, submittedAt: DateTime(2026, 9, 3)),
  _exam('e3', ExamStatus.approved, submittedAt: DateTime(2026, 9, 1)),
  _exam(
    'e4',
    ExamStatus.approved,
    course: 'course-2',
    square: 'square-2',
    student: 'uid-2',
    submittedAt: DateTime(2026, 9, 2),
  ),
  // Approved, but its evaluation could not be read.
  _exam('e5', ExamStatus.approved, square: 'square-2'),
];

final _evaluations = {'e3': _evaluation('e3', 90), 'e4': _evaluation('e4', 60)};

ExamReport _build({String Function(Exam exam)? unitOf}) {
  return ReportBuilder.build(
    exams: _exams,
    evaluations: _evaluations,
    students: 2,
    studentNames: const {'uid-1': 'أحمد'},
    courseNames: const {'course-1': 'تمهيدية'},
    unitNames: const {'square-1': 'المربع الأول'},
    unitOf: unitOf,
    unitTitle: 'حسب المربع',
  );
}

class _FakeReportsRepository implements ReportsRepository {
  AppFailure? failure;
  ReportScope? requested;

  @override
  Future<ExamReport> fetchReport(ReportScope scope) async {
    if (failure case final failure?) throw failure;
    requested = scope;
    return _build();
  }
}

void main() {
  group('ReportBuilder', () {
    test('counts the examinations by status and by result', () {
      final totals = _build().totals;

      expect(totals.exams, 5);
      expect(totals.inProgress, 1);
      expect(totals.awaitingReview, 1);
      expect(totals.approved, 3);
      expect(totals.passed, 1);
      expect(totals.failed, 1);
      expect(totals.passRate, 50);
      expect(totals.averageScore, 75);
    });

    test('has no pass rate before any result is approved', () {
      final totals = ReportBuilder.totalsOf([
        _exam('e1', ExamStatus.pendingReview),
      ], const {});

      expect(totals.passRate, isNull);
      expect(totals.averageScore, isNull);
    });

    test('groups by course, naming the ones still available', () {
      final byCourse = _build().byCourse;

      expect(byCourse.map((group) => group.label), [
        'تمهيدية',
        'دورة غير متاحة',
      ]);
      expect(byCourse.first.totals.exams, 4);
      expect(byCourse.last.totals.failed, 1);
    });

    test('groups by the unit an examination was started in', () {
      expect(_build().byUnit, isEmpty);

      final byUnit = _build(unitOf: (exam) => exam.squareId).byUnit;
      expect(byUnit.map((group) => group.totals.exams), [3, 2]);
      expect(byUnit.first.label, 'المربع الأول');
    });

    test('lists the examinations newest first with their results', () {
      final exams = _build().exams;

      expect(exams.map((exam) => exam.examId).take(3), ['e2', 'e4', 'e3']);
      final failed = exams.firstWhere((exam) => exam.examId == 'e4');
      expect(failed.passed, isFalse);
      expect(failed.finalScore, 60);
      expect(failed.studentName, 'طالب غير معروف');
      expect(exams.first.finalScore, isNull);
      expect(exams.first.studentName, 'أحمد');
    });
  });

  group('ReportCubit', () {
    test('load reports the scope it was given', () async {
      final repository = _FakeReportsRepository();
      final cubit = ReportCubit(repository, const ReportScope.square('sq'));

      await cubit.load();

      expect(repository.requested!.squareId, 'sq');
      expect(repository.requested!.regionId, isNull);
      expect((cubit.state as ReportLoaded).report.students, 2);
    });

    test('load is refused for an account without a scope', () async {
      final repository = _FakeReportsRepository();
      final cubit = ReportCubit(repository, null);

      await cubit.load();

      expect(cubit.state, isA<ReportError>());
      expect(repository.requested, isNull);
    });

    test('load emits the failure message', () async {
      final repository = _FakeReportsRepository()
        ..failure = const AppFailure('لا تملك صلاحية عرض هذه البيانات.');
      final cubit = ReportCubit(repository, const ReportScope.system());

      await cubit.load();

      expect(
        (cubit.state as ReportError).message,
        'لا تملك صلاحية عرض هذه البيانات.',
      );
    });
  });
}
