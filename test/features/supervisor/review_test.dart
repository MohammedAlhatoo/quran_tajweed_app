import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/user_role.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course_level.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/tajweed_rule.dart';
import 'package:quran_tajweed_app/features/courses/domain/repositories/courses_repository.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/recitation_error.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_segment.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/submission.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/submission_answer.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/exams_repository.dart';
import 'package:quran_tajweed_app/features/exams/domain/services/recitation_audio.dart';
import 'package:quran_tajweed_app/features/questions/domain/entities/exam_question.dart';
import 'package:quran_tajweed_app/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran_tajweed_app/features/quran/domain/repositories/quran_repository.dart';
import 'package:quran_tajweed_app/features/supervisor/domain/repositories/review_repository.dart';
import 'package:quran_tajweed_app/features/supervisor/domain/services/exam_scoring.dart';
import 'package:quran_tajweed_app/features/supervisor/presentation/state/evaluation_cubit.dart';
import 'package:quran_tajweed_app/features/supervisor/presentation/state/exam_review_cubit.dart';
import 'package:quran_tajweed_app/features/supervisor/presentation/state/pending_exams_cubit.dart';
import 'package:quran_tajweed_app/features/supervisor/presentation/state/recitation_playback_cubit.dart';

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
  status: ExamStatus.pendingReview,
  mosqueId: 'mosque-1',
  squareId: 'square-1',
  regionId: 'region-1',
);

const _approvedExam = Exam(
  id: 'exam-2',
  studentId: 'uid-1',
  courseId: 'course-1',
  segmentId: 'segment-1',
  status: ExamStatus.approved,
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

const _ikhfa = TajweedRule(id: 'rule-a', name: 'الإخفاء');
const _qalqalah = TajweedRule(id: 'rule-b', name: 'القلقلة');

final _questions = [
  for (var order = 1; order <= 10; order++)
    ExamQuestion(
      id: 'exam-1_$order',
      examId: 'exam-1',
      questionId: 'q$order',
      order: order,
      type: 'multiple_choice',
      question: 'سؤال $order',
      options: const ['أ', 'ب'],
    ),
];

final _submission = Submission(
  examId: 'exam-1',
  studentId: 'uid-1',
  recordingPath: 'exam_recordings/exam-1/recitation.m4a',
  answers: [
    // The last question is left without an answer.
    for (var order = 1; order <= 9; order++)
      SubmissionAnswer(order: order, questionId: 'q$order', answer: 'ب'),
  ],
);

class _FakeExamsRepository implements ExamsRepository {
  Exam? exam = _exam;
  ExamSegment? segment = _segment;

  @override
  Future<Exam> startExam({
    required AppUser student,
    required String courseId,
  }) async => _exam;

  @override
  Future<Exam?> fetchExam(String examId) async => exam;

  @override
  Future<ExamSegment?> fetchSegment(String segmentId) async => segment;

  @override
  Future<List<Exam>> fetchStudentExams(String studentId) async => [_exam];
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

class _FakeQuranRepository implements QuranRepository {
  QuranDataException? failure;

  @override
  Future<List<QuranAyah>> ayahsOf(int surah, int from, int to) async {
    if (failure case final failure?) throw failure;
    return [
      for (var ayah = from; ayah <= to; ayah++)
        QuranAyah(
          surah: surah,
          ayah: ayah,
          page: 2,
          juz: 1,
          lineStart: 2 + ayah,
          lineEnd: 2 + ayah,
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

class _FakePlayer implements RecitationPlayer {
  final played = <String>[];

  @override
  Future<void> play(String filePath) async => played.add(filePath);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _FakeReviewRepository implements ReviewRepository {
  AppFailure? failure;
  AppFailure? studentFailure;
  int downloads = 0;

  /// The answer key: questions 1-7 are answered correctly by [_submission].
  Map<int, String> answerKey = {
    for (var order = 1; order <= 10; order++) order: order <= 7 ? 'ب' : 'أ',
  };

  /// The theory score saved when the examination was submitted.
  int? theoryScore = 14;
  ({
    String examId,
    String courseName,
    String supervisorId,
    int recitationScore,
    int theoryScore,
  })?
  approved;
  String? approvedFeedback;
  List<RecitationError> approvedErrors = const [];
  AppFailure? rulesFailure;
  String? requestedSquareId;
  AppUser? student = _student;
  Submission? submission = _submission;

  @override
  Future<List<Exam>> fetchPendingExams(String squareId) async {
    if (failure case final failure?) throw failure;
    requestedSquareId = squareId;
    return [_exam];
  }

  @override
  Future<AppUser?> fetchStudent(String studentId) async {
    if (studentFailure ?? failure case final failure?) throw failure;
    return student;
  }

  @override
  Future<Submission?> fetchSubmission(String examId) async {
    if (failure case final failure?) throw failure;
    return submission;
  }

  @override
  Future<List<ExamQuestion>> fetchExamQuestions(String examId) async =>
      _questions;

  @override
  Future<int?> fetchTheoryScore(String examId) async => theoryScore;

  @override
  Future<Map<int, String>> fetchAnswerKey(String examId) async => answerKey;

  @override
  Future<List<Exam>> fetchReviewedExams(String squareId) async {
    if (failure case final failure?) throw failure;
    return [_approvedExam];
  }

  @override
  Future<void> approveExam({
    required Exam exam,
    required String courseName,
    required String supervisorId,
    required int recitationScore,
    required int theoryScore,
    required String? feedback,
    required List<RecitationError> errors,
  }) async {
    if (failure case final failure?) throw failure;
    approvedFeedback = feedback;
    approvedErrors = errors;
    approved = (
      examId: exam.id,
      courseName: courseName,
      supervisorId: supervisorId,
      recitationScore: recitationScore,
      theoryScore: theoryScore,
    );
  }

  @override
  Future<List<TajweedRule>> fetchTajweedRules() async {
    if (rulesFailure case final failure?) throw failure;
    return const [_ikhfa, _qalqalah];
  }

  @override
  Future<String> downloadRecording({
    required String examId,
    required String recordingPath,
  }) async {
    if (failure case final failure?) throw failure;
    downloads++;
    return 'local/$examId.m4a';
  }
}

DateTime? _noDate(Object? value) => null;

void main() {
  late _FakeExamsRepository exams;
  late _FakeReviewRepository reviews;
  late _FakeQuranRepository quran;

  setUp(() {
    exams = _FakeExamsRepository();
    reviews = _FakeReviewRepository();
    quran = _FakeQuranRepository();
  });

  group('Submission.fromMap', () {
    test('reads the recording path and the answers in order', () {
      final submission = Submission.fromMap('exam-1', {
        'examId': 'exam-1',
        'studentId': 'uid-1',
        'recordingUrl': 'exam_recordings/exam-1/recitation.m4a',
        'answers': [
          {'order': 2, 'questionId': 'q2', 'answer': 'ب'},
          {'order': 1, 'questionId': 'q1', 'answer': 'أ'},
          {'order': 3, 'questionId': 'q3'},
        ],
      }, toDate: _noDate)!;

      expect(submission.recordingPath, 'exam_recordings/exam-1/recitation.m4a');
      expect(submission.answers.map((answer) => answer.questionId), [
        'q1',
        'q2',
      ]);
    });

    test('rejects a document without a recording or answers', () {
      expect(
        Submission.fromMap('exam-1', {
          'studentId': 'uid-1',
          'answers': <Object>[],
        }, toDate: _noDate),
        isNull,
      );
      expect(
        Submission.fromMap('exam-1', {
          'studentId': 'uid-1',
          'recordingUrl': 'exam_recordings/exam-1/recitation.m4a',
        }, toDate: _noDate),
        isNull,
      );
    });
  });

  group('PendingExamsCubit', () {
    test('load emits the examinations of the supervisor square', () async {
      final cubit = PendingExamsCubit(reviews, 'square-1');

      await cubit.load();

      expect(reviews.requestedSquareId, 'square-1');
      final state = cubit.state as PendingExamsLoaded;
      expect(state.exams.single.id, 'exam-1');
      expect(state.students['uid-1']!.name, 'طالب');
    });

    test('load lists an examination whose student cannot be read', () async {
      reviews.studentFailure = const AppFailure('تعذّر الاتصال.');
      final cubit = PendingExamsCubit(reviews, 'square-1');

      await cubit.load();

      final state = cubit.state as PendingExamsLoaded;
      expect(state.exams, hasLength(1));
      expect(state.students, isEmpty);
    });

    test('load is refused for an account without a square', () async {
      final cubit = PendingExamsCubit(reviews, null);

      await cubit.load();

      expect(cubit.state, isA<PendingExamsError>());
      expect(reviews.requestedSquareId, isNull);
    });

    test('load emits the failure message', () async {
      reviews.failure = const AppFailure('تعذّر الاتصال.');
      final cubit = PendingExamsCubit(reviews, 'square-1');

      await cubit.load();

      expect((cubit.state as PendingExamsError).message, 'تعذّر الاتصال.');
    });
  });

  group('ExamReviewCubit', () {
    ExamReviewCubit build() => ExamReviewCubit(
      reviews: reviews,
      exams: exams,
      courses: _FakeCoursesRepository(),
      quran: quran,
      examId: 'exam-1',
    );

    test('load emits the student, segment, submission and questions', () async {
      final cubit = build();

      await cubit.load();

      final state = cubit.state as ExamReviewLoaded;
      expect(state.student!.uid, 'uid-1');
      expect(state.course!.name, 'تمهيدية');
      expect(state.segment.id, 'segment-1');
      expect(state.submission.recordingPath, isNotEmpty);
      expect(state.questions, hasLength(10));
      expect(state.answerTo(_questions.first), 'ب');
      expect(state.answerTo(_questions.last), isNull);
      expect(state.correctAnswerTo(_questions.first), 'ب');
      expect(state.correctAnswerTo(_questions.last), 'أ');
      expect(state.theoryScore, 14);
    });

    test('load emits the ayahs of the segment, in order', () async {
      final cubit = build();

      await cubit.load();

      final state = cubit.state as ExamReviewLoaded;
      expect(
        [for (final ayah in state.ayahs) (ayah.surah, ayah.ayah)],
        [
          for (var ayah = _segment.ayahFrom; ayah <= _segment.ayahTo; ayah++)
            (_segment.surah, ayah),
        ],
      );
    });

    test('the review is still shown when the Quran data fails', () async {
      quran.failure = const QuranDataException('no data');
      final cubit = build();

      await cubit.load();

      final state = cubit.state as ExamReviewLoaded;
      expect(state.ayahs, isEmpty);
      expect(state.segment.id, 'segment-1');
    });

    test('the theory score is the saved one, never recalculated', () async {
      // The saved score disagrees with what the answers would earn here.
      reviews.theoryScore = 6;
      var cubit = build();
      await cubit.load();
      expect((cubit.state as ExamReviewLoaded).theoryScore, 6);

      // It does not depend on the answer key being readable either.
      reviews.answerKey = const {};
      cubit = build();
      await cubit.load();
      final state = cubit.state as ExamReviewLoaded;
      expect(state.theoryScore, 6);
      expect(state.correctAnswerTo(_questions.first), isNull);
    });

    test('an examination without a saved theory score has none', () async {
      reviews.theoryScore = null;
      final cubit = build();

      await cubit.load();

      expect((cubit.state as ExamReviewLoaded).theoryScore, isNull);
    });

    test('load emits an error when a part is missing', () async {
      exams.exam = null;
      var cubit = build();
      await cubit.load();
      expect(cubit.state, isA<ExamReviewError>());

      exams.exam = _exam;
      reviews.submission = null;
      cubit = build();
      await cubit.load();
      expect(cubit.state, isA<ExamReviewError>());
    });

    test('stays reviewable when the student can no longer be read', () async {
      // The student's mosque moved to another square after the examination.
      reviews.studentFailure = const AppFailure(
        'لا تملك صلاحية عرض هذه البيانات.',
      );
      final cubit = build();

      await cubit.load();

      final state = cubit.state as ExamReviewLoaded;
      expect(state.student, isNull);
      expect(state.exam.id, 'exam-1');
      expect(state.theoryScore, 14);
    });

    test('load emits the Tajweed rules an error can be recorded on', () async {
      final cubit = build();

      await cubit.load();

      final state = cubit.state as ExamReviewLoaded;
      expect(state.rules.map((rule) => rule.id), ['rule-a', 'rule-b']);
    });

    test('stays reviewable when the Tajweed rules cannot be read', () async {
      reviews.rulesFailure = const AppFailure('تعذّر الاتصال.');
      final cubit = build();

      await cubit.load();

      final state = cubit.state as ExamReviewLoaded;
      expect(state.rules, isEmpty);
      expect(state.theoryScore, 14);
    });

    test('load emits the failure message', () async {
      reviews.failure = const AppFailure('تعذّر الاتصال.');
      final cubit = build();

      await cubit.load();

      expect((cubit.state as ExamReviewError).message, 'تعذّر الاتصال.');
    });
  });

  group('ExamScoring', () {
    test('the final score is out of 100 with a pass mark of 70', () {
      expect(ExamScoring.finalScore(recitationScore: 80, theoryScore: 20), 100);
      expect(ExamScoring.resultOf(70), 'passed');
      expect(ExamScoring.resultOf(69), 'failed');
    });

    test('the recitation score is from 0 to 80', () {
      expect(ExamScoring.isValidRecitationScore(0), isTrue);
      expect(ExamScoring.isValidRecitationScore(80), isTrue);
      expect(ExamScoring.isValidRecitationScore(81), isFalse);
      expect(ExamScoring.isValidRecitationScore(-1), isFalse);
    });
  });

  group('EvaluationCubit', () {
    late EvaluationCubit cubit;

    setUp(() {
      cubit = EvaluationCubit(
        repository: reviews,
        supervisorId: 'supervisor-1',
        now: () => DateTime(2026, 10, 3),
      );
    });

    test('records several errors and removes one before approval', () {
      cubit.recordError(
        rule: _ikhfa,
        ayahNumber: 3,
        word: ' أنتم ',
        description: ' لم تُخفَ النون ',
      );
      cubit.recordError(rule: _qalqalah, description: '');
      cubit.recordError(rule: _ikhfa, description: 'خطأ ثالث');

      expect(cubit.state.errors.map((error) => error.id).toSet(), hasLength(3));
      final first = cubit.state.errors.first;
      expect(first.ruleId, 'rule-a');
      expect(first.ruleName, 'الإخفاء');
      expect(first.ayahNumber, 3);
      expect(first.word, 'أنتم');
      expect(first.description, 'لم تُخفَ النون');
      expect(first.createdAt, DateTime(2026, 10, 3));
      expect(cubit.state.errors[1].ayahNumber, isNull);
      expect(cubit.state.errors[1].word, isNull);

      cubit.removeError(cubit.state.errors[1].id);

      expect(cubit.state.errors.map((error) => error.ruleId), [
        'rule-a',
        'rule-a',
      ]);
      // A removed error's ID is not given to a later one.
      cubit.recordError(rule: _qalqalah, description: '');
      expect(cubit.state.errors.map((error) => error.id).toSet(), hasLength(3));
    });

    test('keeps the score, the notes and the errors apart', () {
      cubit.setRecitationScore('64');
      cubit.setFeedback('أحسنت');
      cubit.recordError(rule: _ikhfa, description: '');
      cubit.setRecitationScore('abc');

      expect(cubit.state.recitationScore, isNull);
      expect(cubit.state.feedback, 'أحسنت');
      expect(cubit.state.errors, hasLength(1));
    });

    test('holds at most the errors the security rules accept', () {
      for (var i = 0; i < RecitationError.maxPerEvaluation + 3; i++) {
        cubit.recordError(rule: _ikhfa, description: '');
      }

      expect(cubit.state.errors, hasLength(RecitationError.maxPerEvaluation));
      expect(cubit.state.canAddError, isFalse);
    });

    test('approve saves the notes and the errors with the scores', () async {
      cubit.setRecitationScore('60');
      cubit.setFeedback('  راجع أحكام النون الساكنة  ');
      cubit.recordError(rule: _ikhfa, ayahNumber: 2, description: 'إظهار');

      await cubit.approve(exam: _exam, courseName: 'تمهيدية', theoryScore: 14);

      expect(cubit.state.status, EvaluationStatus.approved);
      expect(reviews.approvedFeedback, 'راجع أحكام النون الساكنة');
      expect(reviews.approvedErrors.single.ruleId, 'rule-a');
      expect(reviews.approvedErrors.single.ayahNumber, 2);

      // Nothing changes once the result is approved.
      cubit.setFeedback('تعديل');
      cubit.recordError(rule: _qalqalah, description: '');
      cubit.removeError(cubit.state.errors.single.id);
      expect(cubit.state.feedback, '  راجع أحكام النون الساكنة  ');
      expect(cubit.state.errors, hasLength(1));
    });

    test('approve saves no notes when none were written', () async {
      cubit.setRecitationScore('60');
      cubit.setFeedback('   ');

      await cubit.approve(exam: _exam, courseName: 'تمهيدية', theoryScore: 14);

      expect(reviews.approved, isNotNull);
      expect(reviews.approvedFeedback, isNull);
      expect(reviews.approvedErrors, isEmpty);
    });

    test('a failed approval keeps the notes and the errors', () async {
      cubit.setRecitationScore('60');
      cubit.setFeedback('ملاحظة');
      cubit.recordError(rule: _ikhfa, description: '');
      reviews.failure = const AppFailure('تعذّر الاتصال.');

      await cubit.approve(exam: _exam, courseName: 'تمهيدية', theoryScore: 14);

      expect(cubit.state.status, EvaluationStatus.editing);
      expect(cubit.state.errorMessage, 'تعذّر الاتصال.');
      expect(cubit.state.feedback, 'ملاحظة');
      expect(cubit.state.errors, hasLength(1));
    });

    test('accepts only a whole recitation score from 0 to 80', () {
      cubit.setRecitationScore(' 64 ');
      expect(cubit.state.recitationScore, 64);

      for (final input in ['81', '-1', '7.5', 'abc', '']) {
        cubit.setRecitationScore(input);
        expect(cubit.state.recitationScore, isNull, reason: input);
      }
    });

    test('approve saves the two scores under the supervisor', () async {
      cubit.setRecitationScore('60');

      await cubit.approve(exam: _exam, courseName: 'تمهيدية', theoryScore: 14);

      expect(cubit.state.status, EvaluationStatus.approved);
      expect(reviews.approved, (
        examId: 'exam-1',
        courseName: 'تمهيدية',
        supervisorId: 'supervisor-1',
        recitationScore: 60,
        theoryScore: 14,
      ));
    });

    test('approve does nothing without a valid recitation score', () async {
      await cubit.approve(exam: _exam, courseName: 'تمهيدية', theoryScore: 14);

      expect(cubit.state.status, EvaluationStatus.editing);
      expect(reviews.approved, isNull);
    });

    test('a failed approval can be retried and is not repeated', () async {
      cubit.setRecitationScore('60');
      reviews.failure = const AppFailure('تعذّر الاتصال.');

      await cubit.approve(exam: _exam, courseName: 'تمهيدية', theoryScore: 14);
      expect(cubit.state.status, EvaluationStatus.editing);
      expect(cubit.state.recitationScore, 60);
      expect(cubit.state.errorMessage, 'تعذّر الاتصال.');

      reviews.failure = null;
      await cubit.approve(exam: _exam, courseName: 'تمهيدية', theoryScore: 14);
      expect(cubit.state.status, EvaluationStatus.approved);

      reviews.approved = null;
      await cubit.approve(exam: _exam, courseName: 'تمهيدية', theoryScore: 14);
      cubit.setRecitationScore('10');
      expect(reviews.approved, isNull);
      expect(cubit.state.recitationScore, 60);
    });
  });

  group('RecitationPlaybackCubit', () {
    late _FakePlayer player;
    late RecitationPlaybackCubit cubit;

    setUp(() {
      player = _FakePlayer();
      cubit = RecitationPlaybackCubit(
        repository: reviews,
        player: player,
        examId: 'exam-1',
      );
    });

    test('play downloads the recording once and plays it', () async {
      final statuses = <PlaybackStatus>[];
      final subscription = cubit.stream.listen(
        (state) => statuses.add(state.status),
      );

      await cubit.play(_submission.recordingPath);
      await cubit.play(_submission.recordingPath);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(reviews.downloads, 1);
      expect(player.played, ['local/exam-1.m4a', 'local/exam-1.m4a']);
      expect(statuses, [
        PlaybackStatus.loading,
        PlaybackStatus.playing,
        PlaybackStatus.idle,
        PlaybackStatus.playing,
        PlaybackStatus.idle,
      ]);
    });

    test('play reports a failed download and can be retried', () async {
      reviews.failure = const AppFailure('تعذّر الاتصال.');

      await cubit.play(_submission.recordingPath);
      expect(cubit.state.status, PlaybackStatus.idle);
      expect(cubit.state.errorMessage, 'تعذّر الاتصال.');
      expect(player.played, isEmpty);

      reviews.failure = null;
      await cubit.play(_submission.recordingPath);
      expect(player.played, hasLength(1));
    });
  });
}
