import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:quran_tajweed_app/core/constants/firebase_collections.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/user_role.dart';
import 'package:quran_tajweed_app/features/certificates/domain/entities/certificate.dart';
import 'package:quran_tajweed_app/features/certificates/domain/repositories/certificates_repository.dart';
import 'package:quran_tajweed_app/features/certificates/presentation/state/certificates_cubit.dart';
import 'package:quran_tajweed_app/features/courses/data/seed/curriculum_seeder.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course_level.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/tajweed_rule.dart';
import 'package:quran_tajweed_app/features/courses/domain/repositories/courses_repository.dart';
import 'package:quran_tajweed_app/features/courses/presentation/state/course_details_cubit.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/evaluation.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_segment.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/recitation_error.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/submission.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/submission_answer.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/evaluations_repository.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/exams_repository.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/recording_repository.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/submission_repository.dart';
import 'package:quran_tajweed_app/features/exams/domain/services/recitation_audio.dart';
import 'package:quran_tajweed_app/features/exams/domain/services/segment_selector.dart';
import 'package:quran_tajweed_app/features/exams/presentation/state/exam_cubit.dart';
import 'package:quran_tajweed_app/features/exams/presentation/state/exam_result_cubit.dart';
import 'package:quran_tajweed_app/features/exams/presentation/state/recording_cubit.dart';
import 'package:quran_tajweed_app/features/exams/presentation/state/start_exam_cubit.dart';
import 'package:quran_tajweed_app/features/exams/presentation/state/submission_cubit.dart';
import 'package:quran_tajweed_app/features/notifications/data/repositories/firestore_notifications_repository.dart';
import 'package:quran_tajweed_app/features/notifications/domain/entities/app_notification.dart';
import 'package:quran_tajweed_app/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:quran_tajweed_app/features/notifications/presentation/state/notifications_cubit.dart';
import 'package:quran_tajweed_app/features/questions/domain/entities/exam_question.dart';
import 'package:quran_tajweed_app/features/questions/domain/entities/question.dart';
import 'package:quran_tajweed_app/features/questions/domain/repositories/questions_repository.dart';
import 'package:quran_tajweed_app/features/questions/domain/services/question_selector.dart';
import 'package:quran_tajweed_app/features/questions/presentation/state/questions_cubit.dart';
import 'package:quran_tajweed_app/features/quran/data/repositories/asset_quran_repository.dart';
import 'package:quran_tajweed_app/features/supervisor/data/repositories/firebase_review_repository.dart';
import 'package:quran_tajweed_app/features/supervisor/domain/repositories/review_repository.dart';
import 'package:quran_tajweed_app/features/supervisor/presentation/state/evaluation_cubit.dart';
import 'package:quran_tajweed_app/features/supervisor/presentation/state/exam_review_cubit.dart';
import 'package:quran_tajweed_app/features/supervisor/presentation/state/pending_exams_cubit.dart';

/// The whole examination, from the student starting it to the certificate,
/// through the cubits of the app.
///
/// Firebase is replaced by [_Backend], documents kept in memory. Everything
/// around it is the code of the app: the curriculum written by
/// [CurriculumSeeder], the selection of the segment and the questions, the
/// documents of the submission notification and of the approval, the
/// entities that read them, the scoring, and the bundled Quran text.
///
/// What [_Backend] does itself (the checks before an examination starts and
/// the fields of the examination, question and submission documents) repeats
/// the Firestore repositories by hand. This test does not run those
/// repositories or the security rules.
const _student = AppUser(
  uid: 'student-1',
  name: 'أحمد',
  email: 'student@example.com',
  role: UserRole.student,
  isActive: true,
  mosqueId: 'mosque-1',
  squareId: 'square-1',
  regionId: 'region-1',
);

const _supervisor = AppUser(
  uid: 'supervisor-1',
  name: 'المشرف',
  email: 'supervisor@example.com',
  role: UserRole.squareSupervisor,
  isActive: true,
  squareId: 'square-1',
  regionId: 'region-1',
);

final _courseId = CourseLevel.introductory.value;

typedef _Docs = Map<String, Map<String, dynamic>>;

DateTime? _toDate(Object? value) => switch (value) {
  DateTime() => value,
  Timestamp() => value.toDate(),
  _ => null,
};

/// The documents of the app, by collection, with the repositories over them.
class _Backend
    implements
        SeedStore,
        ExamsRepository,
        CoursesRepository,
        RecordingRepository,
        SubmissionRepository,
        ReviewRepository,
        EvaluationsRepository,
        CertificatesRepository,
        NotificationsRepository {
  final Map<String, _Docs> _collections = {};

  /// The examinations whose recitation is in Storage.
  final Set<String> recordings = {};

  final Random _random = Random(7);
  final _changes = StreamController<void>.broadcast();

  DateTime _clock = DateTime(2026, 10, 5, 9);
  int _nextExam = 1;

  _Docs docs(String collection) =>
      _collections.putIfAbsent(collection, () => {});

  /// Every write gets a later time, as a server timestamp would.
  DateTime _now() => _clock = _clock.add(const Duration(minutes: 1));

  void _set(String collection, String id, Map<String, Object?> data) {
    final now = _now();
    docs(collection)[id] = {
      for (final MapEntry(:key, :value) in data.entries)
        key: value is FieldValue ? now : value,
    };
    _changes.add(null);
  }

  void _update(String collection, String id, Map<String, Object?> data) =>
      _set(collection, id, {...docs(collection)[id]!, ...data});

  // The seed store.

  @override
  Object get timestamp => _clock;

  @override
  Future<_Docs> readAll(String collection) async => {
    for (final entry in docs(collection).entries) entry.key: {...entry.value},
  };

  @override
  Future<void> writeAll(
    String collection,
    Map<String, Map<String, Object?>> documents,
  ) async {
    for (final entry in documents.entries) {
      docs(collection).putIfAbsent(entry.key, () => {}).addAll(entry.value);
    }
  }

  // Examinations.

  Exam? _exam(String id) {
    final data = docs(FirebaseCollections.exams)[id];
    return data == null ? null : Exam.fromMap(id, data, toDate: _toDate);
  }

  List<Exam> _exams(bool Function(Map<String, dynamic> data) where) => [
    for (final entry in docs(FirebaseCollections.exams).entries)
      if (where(entry.value))
        ?Exam.fromMap(entry.key, entry.value, toDate: _toDate),
  ];

  @override
  Future<Exam> startExam({
    required AppUser student,
    required String courseId,
  }) async {
    final courseExams = _exams(
      (data) =>
          data['studentId'] == student.uid && data['courseId'] == courseId,
    );
    for (final exam in courseExams) {
      if (exam.status.isOpen) return exam;
    }
    if (courseExams.any((exam) => exam.status.isAwaitingReview)) {
      throw const AppFailure('لديك اختبار في هذه الدورة بانتظار المراجعة.');
    }

    final level = CourseLevel.fromValue(
      docs(FirebaseCollections.courses)[courseId]?['level'],
    );
    if (level == null) throw const AppFailure('هذه الدورة غير متاحة حاليًا.');
    final weights = <String, double>{
      for (final link in docs(FirebaseCollections.courseRules).values)
        if (link['courseId'] == courseId)
          link['ruleId'] as String: (link['weight'] as num).toDouble(),
    };
    final segment = const SegmentSelector().select(
      courseId: courseId,
      segments: [
        for (final entry in docs(FirebaseCollections.examSegments).entries)
          if ((entry.value['courseIds'] as List).contains(courseId))
            ?ExamSegment.fromMap(entry.key, entry.value),
      ],
      courseRuleWeights: weights,
      random: _random,
    );
    if (segment == null) {
      throw const AppFailure('لا توجد مقاطع متاحة لهذه الدورة حاليًا.');
    }
    final questions = const QuestionSelector().select(
      courseId: courseId,
      courseLevel: level,
      questions: [
        for (final entry in docs(FirebaseCollections.questionBank).entries)
          if (entry.value['courseId'] == courseId)
            ?Question.fromMap(entry.key, entry.value),
      ],
      courseRuleWeights: weights,
      random: _random,
    );
    if (questions == null) {
      throw const AppFailure('لا توجد أسئلة كافية لهذه الدورة حاليًا.');
    }

    final examId = 'exam-${_nextExam++}';
    _set(FirebaseCollections.exams, examId, {
      'studentId': student.uid,
      'courseId': courseId,
      'segmentId': segment.id,
      'status': ExamStatus.inProgress.value,
      'mosqueId': student.mosqueId,
      'squareId': student.squareId,
      'regionId': student.regionId,
      'startedAt': FieldValue.serverTimestamp(),
      'submittedAt': null,
      'reviewedAt': null,
      'approvedAt': null,
    });
    for (final (index, question) in questions.indexed) {
      _set(FirebaseCollections.examQuestions, '${examId}_${index + 1}', {
        'examId': examId,
        'studentId': student.uid,
        'questionId': question.id,
        'order': index + 1,
        'type': question.type,
        'question': question.question,
        'options': question.options,
      });
    }
    return _exam(examId)!;
  }

  @override
  Future<Exam?> fetchExam(String examId) async => _exam(examId);

  @override
  Future<ExamSegment?> fetchSegment(String segmentId) async {
    final data = docs(FirebaseCollections.examSegments)[segmentId];
    return data == null ? null : ExamSegment.fromMap(segmentId, data);
  }

  @override
  Future<List<Exam>> fetchStudentExams(String studentId) async =>
      _exams((data) => data['studentId'] == studentId);

  // Courses.

  @override
  Future<List<Course>> fetchActiveCourses() async => [
    for (final entry in docs(FirebaseCollections.courses).entries)
      if (entry.value['isActive'] == true)
        ?Course.fromMap(entry.key, entry.value),
  ];

  @override
  Future<Course?> fetchCourse(String courseId) async {
    final data = docs(FirebaseCollections.courses)[courseId];
    return data == null ? null : Course.fromMap(courseId, data);
  }

  @override
  Future<List<TajweedRule>> fetchCourseRules(String courseId) async {
    final rules = docs(FirebaseCollections.tajweedRules);
    return [
      for (final link in docs(FirebaseCollections.courseRules).values)
        if (link['courseId'] == courseId)
          ?TajweedRule.fromMap(
            link['ruleId'] as String,
            rules[link['ruleId']]!,
          ),
    ];
  }

  // Questions.

  List<ExamQuestion> _questionsOf(String examId) => [
    for (final entry in docs(FirebaseCollections.examQuestions).entries)
      if (entry.value['examId'] == examId)
        ?ExamQuestion.fromMap(entry.key, entry.value),
  ]..sort((a, b) => a.order.compareTo(b.order));

  @override
  Future<List<ExamQuestion>> fetchExamQuestions(String examId) async =>
      _questionsOf(examId);

  // The recitation.

  @override
  Future<void> uploadRecording({
    required String examId,
    required String filePath,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1);
    recordings.add(examId);
  }

  @override
  Future<bool> hasRecording(String examId) async => recordings.contains(examId);

  // Submission.

  @override
  Future<void> submitExam({
    required String examId,
    required String studentId,
    required String studentName,
    required List<SubmissionAnswer> answers,
  }) async {
    _set(FirebaseCollections.submissions, examId, {
      'examId': examId,
      'studentId': studentId,
      'recordingUrl': recitationRecordingPath(examId),
      'answers': [for (final answer in answers) answer.toMap()],
      'submittedAt': FieldValue.serverTimestamp(),
    });
    _update(FirebaseCollections.exams, examId, {
      'status': ExamStatus.pendingReview.value,
      'submittedAt': FieldValue.serverTimestamp(),
    });
    final (id, data) = FirestoreNotificationsRepository.examSubmitted(
      examId: examId,
      squareId: docs(FirebaseCollections.exams)[examId]!['squareId'] as String,
      studentName: studentName,
    );
    _set(FirebaseCollections.notifications, id, data);
  }

  // Review.

  @override
  Future<List<Exam>> fetchPendingExams(String squareId) async => _exams(
    (data) =>
        data['squareId'] == squareId &&
        ExamStatus.values.any(
          (status) => status.isAwaitingReview && status.value == data['status'],
        ),
  );

  @override
  Future<List<Exam>> fetchReviewedExams(String squareId) async => _exams(
    (data) =>
        data['squareId'] == squareId &&
        data['status'] == ExamStatus.approved.value,
  );

  @override
  Future<AppUser?> fetchStudent(String studentId) async =>
      studentId == _student.uid ? _student : null;

  @override
  Future<Submission?> fetchSubmission(String examId) async {
    final data = docs(FirebaseCollections.submissions)[examId];
    return data == null
        ? null
        : Submission.fromMap(examId, data, toDate: _toDate);
  }

  @override
  Future<Map<String, String>> fetchCorrectAnswers(
    List<String> questionIds,
  ) async => {
    for (final id in questionIds)
      if (docs(FirebaseCollections.questionAnswers)[id] case final answer?)
        id: answer['correctAnswer'] as String,
  };

  @override
  Future<List<TajweedRule>> fetchTajweedRules() async => [
    for (final entry in docs(FirebaseCollections.tajweedRules).entries)
      if (TajweedRule.fromMap(entry.key, entry.value) case final rule?
          when rule.isActive && rule.isRecitation)
        rule,
  ];

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
    _update(FirebaseCollections.exams, exam.id, {
      'status': ExamStatus.approved.value,
      'reviewedAt': FieldValue.serverTimestamp(),
      'approvedAt': FieldValue.serverTimestamp(),
    });
    final documents = FirebaseReviewRepository.approvalDocuments(
      exam: exam,
      courseName: courseName,
      supervisorId: supervisorId,
      recitationScore: recitationScore,
      theoryScore: theoryScore,
      feedback: feedback,
      errors: errors,
    );
    for (final MapEntry(key: path, value: data) in documents.entries) {
      final [collection, id] = path.split('/');
      _set(collection, id, data);
    }
  }

  @override
  Future<String> downloadRecording({
    required String examId,
    required String recordingPath,
  }) async => 'local/$examId.m4a';

  // Results.

  @override
  Future<Evaluation?> fetchEvaluation(String examId) async {
    final data = docs(FirebaseCollections.evaluations)[examId];
    return data == null
        ? null
        : Evaluation.fromMap(examId, data, toDate: _toDate);
  }

  @override
  Future<Map<String, Evaluation>> fetchEvaluations(
    Iterable<String> examIds,
  ) async => {for (final id in examIds) id: ?await fetchEvaluation(id)};

  @override
  Future<Certificate?> fetchCertificate(String examId) async {
    final data = docs(FirebaseCollections.certificates)[examId];
    return data == null
        ? null
        : Certificate.fromMap(examId, data, toDate: _toDate);
  }

  @override
  Future<List<Certificate>> fetchStudentCertificates(String studentId) async =>
      [
        for (final entry in docs(FirebaseCollections.certificates).entries)
          if (entry.value['studentId'] == studentId)
            ?Certificate.fromMap(entry.key, entry.value, toDate: _toDate),
      ];

  // Notifications.

  List<AppNotification> _notificationsOf(NotificationAudience audience) => [
    for (final entry in docs(FirebaseCollections.notifications).entries)
      if (audience.userId != null
          ? entry.value['userId'] == audience.userId
          : entry.value['squareId'] == audience.squareId)
        AppNotification.fromMap(entry.key, entry.value, toDate: _toDate),
  ];

  @override
  Stream<List<AppNotification>> watch(NotificationAudience audience) {
    late final StreamController<List<AppNotification>> controller;
    StreamSubscription<void>? changes;
    controller = StreamController(
      onListen: () {
        controller.add(_notificationsOf(audience));
        changes = _changes.stream.listen(
          (_) => controller.add(_notificationsOf(audience)),
        );
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> markRead(String notificationId) async => _update(
    FirebaseCollections.notifications,
    notificationId,
    {'isRead': true},
  );
}

/// The questions of an examination as the student reads them.
class _StudentQuestions implements QuestionsRepository {
  const _StudentQuestions(this._backend);

  final _Backend _backend;

  @override
  Future<List<ExamQuestion>> fetchExamQuestions({
    required String examId,
    required String studentId,
  }) async => [
    for (final question in _backend._questionsOf(examId))
      if (_backend.docs(
            FirebaseCollections.examQuestions,
          )[question.id]!['studentId'] ==
          studentId)
        question,
  ];
}

class _FakeRecorder implements RecitationRecorder {
  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start() async {}

  @override
  Future<String?> stop() async => 'local/recitation.m4a';

  @override
  Future<void> dispose() async {}
}

class _FakePlayer implements RecitationPlayer {
  @override
  Future<void> play(String filePath) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Backend backend;

  setUp(() async {
    backend = _Backend();
    await CurriculumSeeder(backend).seed();
  });

  Future<Exam> start() async {
    final cubit = StartExamCubit(backend);
    await cubit.start(student: _student, courseId: _courseId);
    final state = cubit.state;
    await cubit.close();
    if (state is StartExamError) fail(state.message);
    return (state as StartExamReady).exam;
  }

  Future<void> recordAndUpload(String examId) async {
    final cubit = RecordingCubit(
      repository: backend,
      recorder: _FakeRecorder(),
      player: _FakePlayer(),
      examId: examId,
    );
    await cubit.start();
    await cubit.stop();
    await cubit.upload();
    expect(cubit.state.status, RecordingStatus.uploaded);
    await cubit.close();
  }

  /// Answers the ten questions, the first [correct] of them correctly, and
  /// returns what the questions screen hands to the submission.
  Future<QuestionsLoaded> answer(String examId, {required int correct}) async {
    final cubit = QuestionsCubit(
      _StudentQuestions(backend),
      examId: examId,
      studentId: _student.uid,
    );
    await cubit.load();
    final questions = (cubit.state as QuestionsLoaded).questions;
    final answers = await backend.fetchCorrectAnswers([
      for (final question in questions) question.questionId,
    ]);
    for (final (index, question) in questions.indexed) {
      final right = answers[question.questionId]!;
      cubit
        ..selectAnswer(
          index < correct
              ? right
              : question.options.firstWhere((option) => option != right),
        )
        ..next();
    }
    final state = cubit.state as QuestionsLoaded;
    await cubit.close();
    return state;
  }

  SubmissionCubit submission(String examId) => SubmissionCubit(
    submissions: backend,
    recordings: backend,
    examId: examId,
    studentId: _student.uid,
    studentName: _student.name,
  );

  Future<void> submit(String examId, QuestionsLoaded answered) async {
    final cubit = submission(examId);
    await cubit.load();
    await cubit.submit(questions: answered.questions, chosen: answered.answers);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.status, SubmissionStatus.submitted);
    await cubit.close();
  }

  Future<ExamReviewLoaded> review(String examId) async {
    final cubit = ExamReviewCubit(
      reviews: backend,
      exams: backend,
      courses: backend,
      quran: AssetQuranRepository(),
      examId: examId,
    );
    await cubit.load();
    final state = cubit.state;
    await cubit.close();
    if (state is ExamReviewError) fail(state.message);
    return state as ExamReviewLoaded;
  }

  Future<void> approve(
    ExamReviewLoaded review, {
    required int recitationScore,
    String feedback = '',
    bool withError = false,
  }) async {
    final cubit = EvaluationCubit(
      repository: backend,
      supervisorId: _supervisor.uid,
    );
    cubit
      ..setRecitationScore('$recitationScore')
      ..setFeedback(feedback);
    if (withError) {
      cubit.recordError(
        rule: review.rules.first,
        description: 'لم يُتم الغنة',
        ayahNumber: review.segment.ayahFrom,
      );
    }
    await cubit.approve(
      exam: review.exam,
      courseName: review.course!.name,
      theoryScore: review.theoryScore!,
    );
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.status, EvaluationStatus.approved);
    await cubit.close();
  }

  Future<ExamResultLoaded> result(String examId) async {
    final cubit = ExamResultCubit(
      exams: backend,
      evaluations: backend,
      certificates: backend,
      courses: backend,
      examId: examId,
    );
    await cubit.load();
    final state = cubit.state as ExamResultLoaded;
    await cubit.close();
    return state;
  }

  Future<List<AppNotification>> notifications(
    NotificationAudience audience,
  ) async {
    final cubit = NotificationsCubit(backend, audience)..start();
    await pumpEventQueue();
    final items = (cubit.state as NotificationsLoaded).items;
    await cubit.close();
    return items;
  }

  Future<List<Exam>> pending(String? squareId) async {
    final cubit = PendingExamsCubit(backend, squareId);
    await cubit.load();
    final state = cubit.state as PendingExamsLoaded;
    await cubit.close();
    return state.exams;
  }

  /// Sits and submits a whole examination, then has it approved.
  Future<Exam> sitAndApprove({
    required int correct,
    required int recitationScore,
  }) async {
    final exam = await start();
    await recordAndUpload(exam.id);
    await submit(exam.id, await answer(exam.id, correct: correct));
    await approve(await review(exam.id), recitationScore: recitationScore);
    return exam;
  }

  test('a passed examination, from the start to the certificate', () async {
    // The student opens the course and starts its examination.
    final details = CourseDetailsCubit(
      backend,
      backend,
      _courseId,
      _student.uid,
    );
    await details.load();
    final course = details.state as CourseDetailsLoaded;
    expect(course.course.name, 'تمهيدية');
    expect(course.ruleGroups, isNotEmpty);
    expect(course.openExam, isNull);
    expect(course.isAwaitingReview, isFalse);

    final exam = await start();
    expect(exam.status, ExamStatus.inProgress);
    expect(exam.squareId, _student.squareId);

    // The examination screen shows the text of the chosen segment.
    final examCubit = ExamCubit(backend, AssetQuranRepository(), exam.id);
    await examCubit.load();
    final loaded = examCubit.state as ExamLoaded;
    await examCubit.close();
    expect(loaded.segment.id, exam.segmentId);
    expect(
      [for (final ayah in loaded.ayahs) ayah.ayah],
      [
        for (
          var ayah = loaded.segment.ayahFrom;
          ayah <= loaded.segment.ayahTo;
          ayah++
        )
          ayah,
      ],
    );
    expect(
      loaded.ayahs.every((ayah) => ayah.page == loaded.segment.page),
      isTrue,
    );

    // The course now offers to continue it.
    await details.load();
    expect((details.state as CourseDetailsLoaded).openExam?.id, exam.id);

    // The student recites, answers nine questions out of ten, and submits.
    await recordAndUpload(exam.id);
    final answered = await answer(exam.id, correct: 9);
    expect(answered.questions, hasLength(QuestionSelector.examQuestionCount));
    expect(answered.answers, hasLength(10));
    await submit(exam.id, answered);

    expect(
      (await backend.fetchExam(exam.id))!.status,
      ExamStatus.pendingReview,
    );
    await details.load();
    final awaiting = details.state as CourseDetailsLoaded;
    expect(awaiting.openExam, isNull);
    expect(awaiting.isAwaitingReview, isTrue);
    await details.close();

    // The supervisor of the square is notified and finds it waiting.
    final toSupervisor = await notifications(
      NotificationAudience.square(_supervisor.squareId!),
    );
    expect(toSupervisor.single.type, AppNotification.examSubmitted);
    expect(toSupervisor.single.relatedId, exam.id);
    expect(toSupervisor.single.body, contains(_student.name));
    expect([for (final exam in await pending('square-1')) exam.id], [exam.id]);
    expect(await pending('square-2'), isEmpty);

    // The review shows the student, the text, the answers and the score.
    final reviewed = await review(exam.id);
    expect(reviewed.student!.uid, _student.uid);
    expect(reviewed.ayahs, hasLength(loaded.ayahs.length));
    expect(reviewed.submission.recordingPath, recitationRecordingPath(exam.id));
    expect(reviewed.questions, hasLength(10));
    expect(reviewed.theoryScore, 18);

    // 60 for the recitation and 18 for the theory make 78: passed.
    await approve(
      reviewed,
      recitationScore: 60,
      feedback: '  تلاوة جيدة  ',
      withError: true,
    );
    expect(await pending('square-1'), isEmpty);
    expect(
      [
        for (final exam in await backend.fetchReviewedExams('square-1'))
          exam.id,
      ],
      [exam.id],
    );

    // The student sees the result, the certificate and the notification.
    final shown = await result(exam.id);
    expect(shown.exam.status, ExamStatus.approved);
    expect(shown.evaluation!.recitationScore, 60);
    expect(shown.evaluation!.theoryScore, 18);
    expect(shown.evaluation!.finalScore, 78);
    expect(shown.evaluation!.passed, isTrue);
    expect(shown.evaluation!.supervisorId, _supervisor.uid);
    expect(shown.evaluation!.feedback, 'تلاوة جيدة');
    expect(
      shown.evaluation!.detailedErrors.single.ruleId,
      reviewed.rules.first.id,
    );
    expect(shown.certificate!.finalScore, 78);
    expect(shown.certificate!.courseId, _courseId);

    final certificates = CertificatesCubit(backend, _student.uid);
    await certificates.load();
    expect(
      (certificates.state as CertificatesLoaded).certificates.single.examId,
      exam.id,
    );
    await certificates.close();

    final toStudent = await notifications(
      NotificationAudience.user(_student.uid),
    );
    expect(toStudent.single.type, AppNotification.examApproved);
    expect(toStudent.single.body, contains('ناجح'));
    expect(toStudent.single.body, contains('78'));
  });

  test('a failed examination gets its result without a certificate, and can be '
      'sat again', () async {
    // 69 for the recitation and nothing for the theory: one mark short.
    final exam = await sitAndApprove(correct: 0, recitationScore: 69);

    final shown = await result(exam.id);
    expect(shown.evaluation!.theoryScore, 0);
    expect(shown.evaluation!.finalScore, 69);
    expect(shown.evaluation!.passed, isFalse);
    expect(shown.certificate, isNull);
    expect(await backend.fetchStudentCertificates(_student.uid), isEmpty);
    final toStudent = await notifications(
      NotificationAudience.user(_student.uid),
    );
    expect(toStudent.single.body, contains('راسب'));

    // A new attempt is a new examination; the approved one stays as it is.
    final again = await start();
    expect(again.id, isNot(exam.id));
    expect(again.status, ExamStatus.inProgress);
    expect((await backend.fetchExam(exam.id))!.status, ExamStatus.approved);
  });

  test(
    'exactly 70 passes: 50 for the recitation and 20 for the theory',
    () async {
      final exam = await sitAndApprove(correct: 10, recitationScore: 50);

      final shown = await result(exam.id);
      expect(shown.evaluation!.theoryScore, 20);
      expect(shown.evaluation!.finalScore, 70);
      expect(shown.evaluation!.passed, isTrue);
      expect(shown.certificate, isNotNull);
    },
  );

  test('an open examination is continued with its segment and questions, and '
      'is not submitted without its recitation', () async {
    final exam = await start();
    final questions = await backend.fetchExamQuestions(exam.id);

    final continued = await start();
    expect(continued.id, exam.id);
    expect(continued.segmentId, exam.segmentId);
    expect(
      [for (final q in await backend.fetchExamQuestions(exam.id)) q.questionId],
      [for (final q in questions) q.questionId],
    );

    final answered = await answer(exam.id, correct: 10);
    final cubit = submission(exam.id);
    await cubit.load();
    await cubit.submit(questions: answered.questions, chosen: answered.answers);
    expect(cubit.state.status, SubmissionStatus.ready);
    expect(cubit.state.errorMessage, isNotNull);
    await cubit.close();
    expect((await backend.fetchExam(exam.id))!.status, ExamStatus.inProgress);
    expect(await pending('square-1'), isEmpty);
  });

  test('a new examination is refused while one awaits review', () async {
    final exam = await start();
    await recordAndUpload(exam.id);
    await submit(exam.id, await answer(exam.id, correct: 5));

    final cubit = StartExamCubit(backend);
    await cubit.start(student: _student, courseId: _courseId);
    expect(cubit.state, isA<StartExamError>());
    await cubit.close();
    expect(await backend.fetchStudentExams(_student.uid), hasLength(1));
  });
}
