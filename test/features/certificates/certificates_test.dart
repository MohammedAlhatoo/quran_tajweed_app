import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/certificates/domain/entities/certificate.dart';
import 'package:quran_tajweed_app/features/certificates/domain/repositories/certificates_repository.dart';
import 'package:quran_tajweed_app/features/certificates/presentation/state/certificates_cubit.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course_level.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/tajweed_rule.dart';
import 'package:quran_tajweed_app/features/courses/domain/repositories/courses_repository.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/evaluation.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_segment.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/evaluations_repository.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/exams_repository.dart';
import 'package:quran_tajweed_app/features/exams/presentation/state/exam_result_cubit.dart';

const _exam = Exam(
  id: 'exam-1',
  studentId: 'uid-1',
  courseId: 'course-1',
  segmentId: 'segment-1',
  status: ExamStatus.approved,
  mosqueId: 'mosque-1',
  squareId: 'square-1',
  regionId: 'region-1',
);

const _certificate = Certificate(
  examId: 'exam-1',
  studentId: 'uid-1',
  courseId: 'course-1',
  certificateNumber: 'QT-2026-EXAM-1',
  finalScore: 88,
);

Evaluation _evaluation(int finalScore) {
  return Evaluation(
    examId: 'exam-1',
    recitationScore: finalScore - 18,
    theoryScore: 18,
    finalScore: finalScore,
    result: finalScore >= 70 ? 'passed' : 'failed',
  );
}

class _FakeExamsRepository implements ExamsRepository {
  Exam? exam = _exam;

  @override
  Future<Exam> startExam({
    required AppUser student,
    required String courseId,
  }) async => _exam;

  @override
  Future<Exam?> fetchExam(String examId) async => exam;

  @override
  Future<ExamSegment?> fetchSegment(String segmentId) async => null;

  @override
  Future<List<Exam>> fetchStudentExams(String studentId) async => [_exam];
}

class _FakeEvaluationsRepository implements EvaluationsRepository {
  Evaluation? evaluation = _evaluation(88);
  AppFailure? failure;

  @override
  Future<Evaluation?> fetchEvaluation(String examId) async {
    if (failure case final failure?) throw failure;
    return evaluation;
  }

  @override
  Future<Map<String, Evaluation>> fetchEvaluations(
    Iterable<String> examIds,
  ) async => {for (final id in examIds) id: ?evaluation};
}

class _FakeCertificatesRepository implements CertificatesRepository {
  int lookups = 0;
  AppFailure? failure;

  @override
  Future<Certificate?> fetchCertificate(String examId) async {
    lookups++;
    return _certificate;
  }

  @override
  Future<List<Certificate>> fetchStudentCertificates(String studentId) async {
    if (failure case final failure?) throw failure;
    return [_certificate];
  }
}

class _FakeCoursesRepository implements CoursesRepository {
  @override
  Future<List<Course>> fetchActiveCourses() async => const [];

  @override
  Future<Course?> fetchCourse(String courseId) async => Course(
    id: courseId,
    name: 'تمهيدية',
    description: '',
    level: CourseLevel.introductory,
  );

  @override
  Future<List<TajweedRule>> fetchCourseRules(String courseId) async => const [];
}

DateTime? _noDate(Object? value) => null;

void main() {
  group('Certificate', () {
    test('the number is built from the year and the examination', () {
      expect(
        Certificate.numberFor(examId: 'abcDEF123456xyz', year: 2026),
        'QT-2026-ABCDEF12',
      );
      expect(Certificate.numberFor(examId: 'ab1', year: 2026), 'QT-2026-AB1');
    });

    test('fromMap reads the student, the course and the score', () {
      final certificate = Certificate.fromMap('exam-1', {
        'studentId': 'uid-1',
        'examId': 'exam-1',
        'courseId': 'course-1',
        'certificateNumber': 'QT-2026-EXAM-1',
        'finalScore': 88,
        'fileUrl': null,
      }, toDate: _noDate)!;

      expect(certificate.examId, 'exam-1');
      expect(certificate.finalScore, 88);
    });

    test('fromMap rejects a document without a score or a number', () {
      expect(
        Certificate.fromMap('exam-1', {
          'studentId': 'uid-1',
          'courseId': 'course-1',
          'certificateNumber': 'QT-2026-EXAM-1',
        }, toDate: _noDate),
        isNull,
      );
    });
  });

  test('Evaluation.fromMap reads the scores and the result', () {
    final evaluation = Evaluation.fromMap('exam-1', {
      'recitationScore': 60,
      'theoryScore': 14,
      'finalScore': 74,
      'result': 'passed',
      'supervisorId': 'sup-1',
    }, toDate: _noDate)!;

    expect(evaluation.passed, isTrue);
    expect(evaluation.finalScore, 74);
    expect(
      Evaluation.fromMap('exam-1', {'result': 'passed'}, toDate: _noDate),
      isNull,
    );
  });

  group('ExamResultCubit', () {
    late _FakeExamsRepository exams;
    late _FakeEvaluationsRepository evaluations;
    late _FakeCertificatesRepository certificates;

    setUp(() {
      exams = _FakeExamsRepository();
      evaluations = _FakeEvaluationsRepository();
      certificates = _FakeCertificatesRepository();
    });

    ExamResultCubit build() => ExamResultCubit(
      exams: exams,
      evaluations: evaluations,
      certificates: certificates,
      courses: _FakeCoursesRepository(),
      examId: 'exam-1',
    );

    test('a passed examination comes with its certificate', () async {
      final cubit = build();

      await cubit.load();

      final state = cubit.state as ExamResultLoaded;
      expect(state.evaluation!.passed, isTrue);
      expect(state.certificate!.certificateNumber, 'QT-2026-EXAM-1');
      expect(state.course!.name, 'تمهيدية');
    });

    test('a failed examination has no certificate', () async {
      evaluations.evaluation = _evaluation(55);
      final cubit = build();

      await cubit.load();

      final state = cubit.state as ExamResultLoaded;
      expect(state.evaluation!.passed, isFalse);
      expect(state.certificate, isNull);
      expect(certificates.lookups, 0);
    });

    test('an examination not approved yet has no result', () async {
      evaluations.evaluation = null;
      final cubit = build();

      await cubit.load();

      final state = cubit.state as ExamResultLoaded;
      expect(state.evaluation, isNull);
      expect(state.certificate, isNull);
    });

    test(
      'load emits an error for a missing examination or a failure',
      () async {
        exams.exam = null;
        var cubit = build();
        await cubit.load();
        expect(cubit.state, isA<ExamResultError>());

        exams.exam = _exam;
        evaluations.failure = const AppFailure('تعذّر الاتصال.');
        cubit = build();
        await cubit.load();
        expect((cubit.state as ExamResultError).message, 'تعذّر الاتصال.');
      },
    );
  });

  group('CertificatesCubit', () {
    test('load emits the certificates of the student', () async {
      final cubit = CertificatesCubit(_FakeCertificatesRepository(), 'uid-1');

      await cubit.load();

      expect(
        (cubit.state as CertificatesLoaded).certificates.single.examId,
        'exam-1',
      );
    });

    test('load emits the failure message', () async {
      final repository = _FakeCertificatesRepository()
        ..failure = const AppFailure('تعذّر الاتصال.');
      final cubit = CertificatesCubit(repository, 'uid-1');

      await cubit.load();

      expect((cubit.state as CertificatesError).message, 'تعذّر الاتصال.');
    });
  });
}
