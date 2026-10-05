import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/constants/surah_names.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/user_role.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_segment.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/exams_repository.dart';
import 'package:quran_tajweed_app/features/exams/presentation/state/exam_cubit.dart';
import 'package:quran_tajweed_app/features/exams/presentation/state/exam_history_cubit.dart';
import 'package:quran_tajweed_app/features/exams/presentation/state/start_exam_cubit.dart';
import 'package:quran_tajweed_app/features/questions/domain/entities/question.dart';
import 'package:quran_tajweed_app/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran_tajweed_app/features/quran/domain/repositories/quran_repository.dart';

const _student = AppUser(
  uid: 'uid-1',
  name: 'طالب',
  email: 'student@example.com',
  role: UserRole.student,
  isActive: true,
  mosqueId: 'mosque-1',
  squareId: 'square-1',
  regionId: 'region-1',
);

const _exam = Exam(
  id: 'exam-1',
  studentId: 'uid-1',
  courseId: 'course-1',
  segmentId: 'segment-1',
  status: ExamStatus.inProgress,
  mosqueId: 'mosque-1',
  squareId: 'square-1',
  regionId: 'region-1',
);

const _segment = ExamSegment(
  id: 'segment-1',
  surah: 2,
  ayahFrom: 1,
  ayahTo: 5,
  page: 2,
  ruleIds: ['rule-a'],
  courseIds: ['course-1'],
  ruleDensity: 1,
  isActive: true,
);

class _FakeExamsRepository implements ExamsRepository {
  AppFailure? failure;
  Exam? exam = _exam;
  ExamSegment? segment = _segment;

  @override
  Future<Exam> startExam({
    required AppUser student,
    required String courseId,
  }) async {
    if (failure case final failure?) throw failure;
    return _exam;
  }

  @override
  Future<Exam?> fetchExam(String examId) async {
    if (failure case final failure?) throw failure;
    return exam;
  }

  @override
  Future<ExamSegment?> fetchSegment(String segmentId) async {
    if (failure case final failure?) throw failure;
    return segment;
  }

  @override
  Future<List<Exam>> fetchStudentExams(String studentId) async {
    if (failure case final failure?) throw failure;
    return [_exam];
  }
}

/// Gives made-up ayahs for any range, and keeps the ranges asked for.
class _FakeQuranRepository implements QuranRepository {
  QuranDataException? failure;
  final asked = <(int, int, int)>[];

  @override
  Future<List<QuranAyah>> ayahsOf(int surah, int from, int to) async {
    asked.add((surah, from, to));
    if (failure case final failure?) throw failure;
    return [
      for (var ayah = from; ayah <= to; ayah++)
        QuranAyah(
          surah: surah,
          ayah: ayah,
          page: 2,
          juz: 1,
          lineStart: ayah,
          lineEnd: ayah,
          text: 'text $surah:$ayah',
          textEmlaey: 'plain $surah:$ayah',
        ),
    ];
  }

  @override
  Future<QuranAyah> ayah(int surah, int ayah) => throw UnimplementedError();

  @override
  Future<List<QuranAyah>> ayahsOfPage(int page) => throw UnimplementedError();
}

DateTime? _noDate(Object? value) => null;

void main() {
  late _FakeExamsRepository repository;
  late _FakeQuranRepository quran;

  setUp(() {
    repository = _FakeExamsRepository();
    quran = _FakeQuranRepository();
  });

  group('ExamStatus', () {
    test('open statuses can be continued', () {
      expect(ExamStatus.values.where((s) => s.isOpen), [
        ExamStatus.draft,
        ExamStatus.inProgress,
      ]);
    });

    test('statuses awaiting review block a new examination', () {
      expect(ExamStatus.values.where((s) => s.isAwaitingReview), [
        ExamStatus.submitted,
        ExamStatus.pendingReview,
        ExamStatus.underReview,
      ]);
    });

    test('approved is neither open nor awaiting review', () {
      expect(ExamStatus.approved.isOpen, isFalse);
      expect(ExamStatus.approved.isAwaitingReview, isFalse);
    });
  });

  group('entities', () {
    test('Exam.fromMap reads the status and the affiliation', () {
      final exam = Exam.fromMap('exam-1', {
        'studentId': 'uid-1',
        'courseId': 'course-1',
        'segmentId': 'segment-1',
        'status': 'pending_review',
        'mosqueId': 'mosque-1',
        'squareId': 'square-1',
        'regionId': 'region-1',
      }, toDate: _noDate)!;

      expect(exam.status, ExamStatus.pendingReview);
      expect(exam.squareId, 'square-1');
    });

    test('Exam.fromMap rejects an unknown status', () {
      final exam = Exam.fromMap('exam-1', {
        'studentId': 'uid-1',
        'courseId': 'course-1',
        'segmentId': 'segment-1',
        'status': 'rejected',
      }, toDate: _noDate);

      expect(exam, isNull);
    });

    test('ExamSegment.fromMap rejects a reference outside the Mushaf', () {
      Map<String, dynamic> data({int surah = 2, int page = 2, int to = 5}) => {
        'surah': surah,
        'ayahFrom': 3,
        'ayahTo': to,
        'page': page,
        'ruleDensity': 2,
        'isActive': true,
      };

      expect(ExamSegment.fromMap('s', data())!.ruleDensity, 2.0);
      expect(ExamSegment.fromMap('s', data(surah: 115)), isNull);
      expect(ExamSegment.fromMap('s', data(page: 605)), isNull);
      expect(ExamSegment.fromMap('s', data(to: 2)), isNull);
    });

    test('Question.fromMap never exposes a correct answer', () {
      final question = Question.fromMap('q1', {
        'courseId': 'course-1',
        'ruleId': 'rule-a',
        'type': 'multiple_choice',
        'question': 'سؤال',
        'options': ['أ', 'ب'],
        'isActive': true,
      })!;

      expect(question.options, ['أ', 'ب']);
      expect(Question.fromMap('q1', {'courseId': 'course-1'}), isNull);
    });

    test('SurahNames covers the first and last surah', () {
      expect(SurahNames.of(1), 'الفاتحة');
      expect(SurahNames.of(2), 'البقرة');
      expect(SurahNames.of(114), 'الناس');
    });
  });

  group('StartExamCubit', () {
    test('start emits the ready examination', () async {
      final cubit = StartExamCubit(repository);

      await cubit.start(student: _student, courseId: 'course-1');

      expect((cubit.state as StartExamReady).exam.id, 'exam-1');
    });

    test('start emits the refusal message', () async {
      repository.failure = const AppFailure('لديك اختبار بانتظار المراجعة.');
      final cubit = StartExamCubit(repository);

      await cubit.start(student: _student, courseId: 'course-1');

      expect(
        (cubit.state as StartExamError).message,
        'لديك اختبار بانتظار المراجعة.',
      );
    });
  });

  group('ExamCubit', () {
    test('load emits the examination with its segment', () async {
      final cubit = ExamCubit(repository, quran, 'exam-1');

      await cubit.load();

      final state = cubit.state as ExamLoaded;
      expect(state.exam.id, 'exam-1');
      expect(state.segment.id, 'segment-1');
    });

    test('load emits the ayahs of the segment, in order', () async {
      final cubit = ExamCubit(repository, quran, 'exam-1');

      await cubit.load();

      final state = cubit.state as ExamLoaded;
      expect(quran.asked, [(2, 1, 5)]);
      expect(
        [for (final ayah in state.ayahs) (ayah.surah, ayah.ayah)],
        [(2, 1), (2, 2), (2, 3), (2, 4), (2, 5)],
      );
      expect(state.ayahs.first.text, 'text 2:1');
    });

    test('load emits an error when the Quran data cannot be read', () async {
      quran.failure = const QuranDataException('no file');
      final cubit = ExamCubit(repository, quran, 'exam-1');

      await cubit.load();

      expect((cubit.state as ExamError).message, 'تعذّر تحميل نص المقطع.');
    });

    test('load again shows the examination once the data is read', () async {
      quran.failure = const QuranDataException('no file');
      final cubit = ExamCubit(repository, quran, 'exam-1');
      await cubit.load();
      expect(cubit.state, isA<ExamError>());

      quran.failure = null;
      await cubit.load();

      expect((cubit.state as ExamLoaded).ayahs, hasLength(5));
    });

    test('load does not read the Quran data without a segment', () async {
      repository.segment = null;
      final cubit = ExamCubit(repository, quran, 'exam-1');

      await cubit.load();

      expect(cubit.state, isA<ExamError>());
      expect(quran.asked, isEmpty);
    });

    test('load emits the message of a failed reading', () async {
      repository.failure = const AppFailure('تعذّر الاتصال.');
      final cubit = ExamCubit(repository, quran, 'exam-1');

      await cubit.load();

      expect((cubit.state as ExamError).message, 'تعذّر الاتصال.');
    });

    test('load emits an error for a missing examination or segment', () async {
      repository.exam = null;
      final missingExam = ExamCubit(repository, quran, 'exam-1');
      await missingExam.load();
      expect(missingExam.state, isA<ExamError>());

      repository
        ..exam = _exam
        ..segment = null;
      final missingSegment = ExamCubit(repository, quran, 'exam-1');
      await missingSegment.load();
      expect(missingSegment.state, isA<ExamError>());
    });
  });

  group('ExamHistoryCubit', () {
    test('load emits the student examinations', () async {
      final cubit = ExamHistoryCubit(repository, 'uid-1');

      await cubit.load();

      expect((cubit.state as ExamHistoryLoaded).exams.single.id, 'exam-1');
    });

    test('load emits an error when reading fails', () async {
      repository.failure = const AppFailure('تعذّر الاتصال.');
      final cubit = ExamHistoryCubit(repository, 'uid-1');

      await cubit.load();

      expect((cubit.state as ExamHistoryError).message, 'تعذّر الاتصال.');
    });
  });
}
