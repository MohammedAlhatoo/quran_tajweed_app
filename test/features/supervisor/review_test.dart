import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/user_role.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course_level.dart';
import 'package:quran_tajweed_app/features/courses/domain/repositories/courses_repository.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_segment.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/submission.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/submission_answer.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/exams_repository.dart';
import 'package:quran_tajweed_app/features/exams/domain/services/recitation_audio.dart';
import 'package:quran_tajweed_app/features/questions/domain/entities/exam_question.dart';
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
  Future<List<String>> fetchCourseRuleNames(String courseId) async => const [];
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

  /// Questions 1-7 are answered correctly by [_submission].
  Map<String, String> correctAnswers = {
    for (var order = 1; order <= 10; order++) 'q$order': order <= 7 ? 'ب' : 'أ',
  };
  ({
    String examId,
    String courseName,
    String supervisorId,
    int recitationScore,
    int theoryScore,
  })?
  approved;
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
  Future<Map<String, String>> fetchCorrectAnswers(
    List<String> questionIds,
  ) async => {for (final id in questionIds) id: ?correctAnswers[id]};

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
  }) async {
    if (failure case final failure?) throw failure;
    approved = (
      examId: exam.id,
      courseName: courseName,
      supervisorId: supervisorId,
      recitationScore: recitationScore,
      theoryScore: theoryScore,
    );
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

  setUp(() {
    exams = _FakeExamsRepository();
    reviews = _FakeReviewRepository();
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
      // Seven correct answers out of ten.
      expect(state.theoryScore, 14);
    });

    test('the theory score is unknown without a correct answer', () async {
      reviews.correctAnswers.remove('q4');
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

    test('the theory score gives every question two marks', () {
      int? score(Map<String, String> correct) => ExamScoring.theoryScore(
        questions: _questions,
        answers: _submission.answers,
        correctAnswers: correct,
      );

      expect(score({for (final q in _questions) q.questionId: 'ب'}), 18);
      expect(score({for (final q in _questions) q.questionId: 'أ'}), 0);
      expect(score(const {}), isNull);
      expect(
        ExamScoring.theoryScore(
          questions: const [],
          answers: _submission.answers,
          correctAnswers: const {},
        ),
        isNull,
      );
    });
  });

  group('EvaluationCubit', () {
    late EvaluationCubit cubit;

    setUp(() {
      cubit = EvaluationCubit(
        repository: reviews,
        supervisorId: 'supervisor-1',
      );
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
