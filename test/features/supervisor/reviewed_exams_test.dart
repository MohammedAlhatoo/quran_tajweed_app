import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/user_role.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/evaluation.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/submission.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/evaluations_repository.dart';
import 'package:quran_tajweed_app/features/questions/domain/entities/exam_question.dart';
import 'package:quran_tajweed_app/features/supervisor/domain/repositories/review_repository.dart';
import 'package:quran_tajweed_app/features/supervisor/presentation/state/reviewed_exams_cubit.dart';

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

const _evaluation = Evaluation(
  examId: 'exam-1',
  recitationScore: 70,
  theoryScore: 16,
  finalScore: 86,
  result: 'passed',
);

class _FakeReviewRepository implements ReviewRepository {
  AppFailure? failure;
  String? requestedSquareId;

  @override
  Future<List<Exam>> fetchReviewedExams(String squareId) async {
    if (failure case final failure?) throw failure;
    requestedSquareId = squareId;
    return [_exam];
  }

  @override
  Future<AppUser?> fetchStudent(String studentId) async => AppUser(
    uid: studentId,
    name: 'طالب',
    email: 'student@example.com',
    role: UserRole.student,
    isActive: true,
  );

  @override
  Future<List<Exam>> fetchPendingExams(String squareId) async => const [];

  @override
  Future<Submission?> fetchSubmission(String examId) async => null;

  @override
  Future<List<ExamQuestion>> fetchExamQuestions(String examId) async =>
      const [];

  @override
  Future<Map<String, String>> fetchCorrectAnswers(
    List<String> questionIds,
  ) async => const {};

  @override
  Future<void> approveExam({
    required Exam exam,
    required String courseName,
    required String supervisorId,
    required int recitationScore,
    required int theoryScore,
  }) async {}

  @override
  Future<String> downloadRecording({
    required String examId,
    required String recordingPath,
  }) async => '';
}

class _FakeEvaluationsRepository implements EvaluationsRepository {
  @override
  Future<Evaluation?> fetchEvaluation(String examId) async => _evaluation;

  @override
  Future<Map<String, Evaluation>> fetchEvaluations(
    Iterable<String> examIds,
  ) async => {for (final id in examIds) id: _evaluation};
}

void main() {
  late _FakeReviewRepository reviews;

  setUp(() => reviews = _FakeReviewRepository());

  ReviewedExamsCubit build(String? squareId) => ReviewedExamsCubit(
    reviews: reviews,
    evaluations: _FakeEvaluationsRepository(),
    squareId: squareId,
  );

  test('load emits the reviewed examinations with their results', () async {
    final cubit = build('square-1');

    await cubit.load();

    final state = cubit.state as ReviewedExamsLoaded;
    expect(reviews.requestedSquareId, 'square-1');
    expect(state.exams.single.status, ExamStatus.approved);
    expect(state.students['uid-1']!.name, 'طالب');
    expect(state.evaluations['exam-1']!.finalScore, 86);
  });

  test('load is refused for an account without a square', () async {
    final cubit = build(null);

    await cubit.load();

    expect(cubit.state, isA<ReviewedExamsError>());
    expect(reviews.requestedSquareId, isNull);
  });

  test('load emits the failure message', () async {
    reviews.failure = const AppFailure('تعذّر الاتصال.');
    final cubit = build('square-1');

    await cubit.load();

    expect((cubit.state as ReviewedExamsError).message, 'تعذّر الاتصال.');
  });
}
