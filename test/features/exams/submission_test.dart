import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/submission_answer.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/recording_repository.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/submission_repository.dart';
import 'package:quran_tajweed_app/features/exams/presentation/state/submission_cubit.dart';
import 'package:quran_tajweed_app/features/questions/domain/entities/exam_question.dart';

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

final _chosen = {for (final question in _questions) question.id: 'أ'};

class _FakeSubmissionRepository implements SubmissionRepository {
  AppFailure? failure;
  String? examId;
  List<SubmissionAnswer>? answers;

  @override
  Future<void> submitExam({
    required String examId,
    required List<SubmissionAnswer> answers,
  }) async {
    if (failure case final failure?) throw failure;
    this.examId = examId;
    this.answers = answers;
  }
}

class _FakeRecordingRepository implements RecordingRepository {
  AppFailure? failure;
  bool uploaded = true;
  int uploads = 0;

  @override
  Future<void> uploadRecording({
    required String examId,
    required String filePath,
    void Function(double progress)? onProgress,
  }) async => uploads++;

  @override
  Future<bool> hasRecording(String examId) async {
    if (failure case final failure?) throw failure;
    return uploaded;
  }
}

void main() {
  late _FakeSubmissionRepository submissions;
  late _FakeRecordingRepository recordings;
  late SubmissionCubit cubit;

  setUp(() {
    submissions = _FakeSubmissionRepository();
    recordings = _FakeRecordingRepository();
    cubit = SubmissionCubit(
      submissions: submissions,
      recordings: recordings,
      examId: 'exam-1',
    );
  });

  test('the recording path is the one the Storage rules protect', () {
    expect(
      recitationRecordingPath('exam-1'),
      'exam_recordings/exam-1/recitation.m4a',
    );
  });

  group('SubmissionAnswer', () {
    test('listFrom keeps the order and the source question', () {
      final answers = SubmissionAnswer.listFrom(_questions, _chosen)!;

      expect(answers, hasLength(10));
      expect(answers[2].toMap(), {
        'order': 3,
        'questionId': 'q3',
        'answer': 'أ',
      });
    });

    test('listFrom returns null when a question has no answer', () {
      final chosen = {..._chosen}..remove('exam-1_7');

      expect(SubmissionAnswer.listFrom(_questions, chosen), isNull);
    });
  });

  group('SubmissionCubit', () {
    test('load reports whether the recording is uploaded', () async {
      await cubit.load();
      expect(cubit.state.status, SubmissionStatus.ready);
      expect(cubit.state.hasRecording, isTrue);

      recordings.uploaded = false;
      await cubit.load();
      expect(cubit.state.hasRecording, isFalse);
    });

    test('load reports a failed check', () async {
      recordings.failure = const AppFailure('تعذّر الاتصال.');

      await cubit.load();

      expect(cubit.state.status, SubmissionStatus.ready);
      expect(cubit.state.hasRecording, isFalse);
      expect(cubit.state.errorMessage, 'تعذّر الاتصال.');
    });

    test('submit sends the ten answers of the student', () async {
      await cubit.load();

      await cubit.submit(questions: _questions, chosen: _chosen);

      expect(cubit.state.status, SubmissionStatus.submitted);
      expect(submissions.examId, 'exam-1');
      expect(submissions.answers!.map((answer) => answer.order), [
        for (var order = 1; order <= 10; order++) order,
      ]);
    });

    test('submit is refused while a question has no answer', () async {
      await cubit.load();

      await cubit.submit(
        questions: _questions,
        chosen: {..._chosen}..remove('exam-1_1'),
      );

      expect(cubit.state.status, SubmissionStatus.ready);
      expect(cubit.state.errorMessage, isNotNull);
      expect(submissions.answers, isNull);
    });

    test(
      'submit is refused when the recording is no longer uploaded',
      () async {
        await cubit.load();
        recordings.uploaded = false;

        await cubit.submit(questions: _questions, chosen: _chosen);

        expect(cubit.state.status, SubmissionStatus.ready);
        expect(cubit.state.hasRecording, isFalse);
        expect(cubit.state.errorMessage, isNotNull);
        expect(submissions.answers, isNull);
      },
    );

    test('submit does not succeed without an uploaded recording', () async {
      recordings.uploaded = false;
      await cubit.load();

      await cubit.submit(questions: _questions, chosen: _chosen);

      expect(cubit.state.status, SubmissionStatus.ready);
      expect(cubit.state.hasRecording, isFalse);
      expect(
        cubit.state.errorMessage,
        'ارفع تسجيل التلاوة قبل إرسال الاختبار.',
      );
      expect(submissions.examId, isNull);
      expect(recordings.uploads, 0);
    });

    test('submit never uploads the recording', () async {
      await cubit.load();

      await cubit.submit(questions: _questions, chosen: _chosen);

      expect(cubit.state.status, SubmissionStatus.submitted);
      expect(recordings.uploads, 0);
    });

    test('a refused submit shows the reason and sends nothing more', () async {
      await cubit.load();
      submissions.failure = const AppFailure(
        'أسئلة هذا الاختبار غير مكتملة، لذا لا يمكن إرساله. تواصل مع الإدارة.',
      );

      await cubit.submit(questions: _questions, chosen: _chosen);

      expect(cubit.state.status, SubmissionStatus.ready);
      expect(cubit.state.errorMessage, contains('غير مكتملة'));
      expect(submissions.answers, isNull);
    });

    test('a failed submit can be retried', () async {
      await cubit.load();
      submissions.failure = const AppFailure('تعذّر الاتصال.');

      await cubit.submit(questions: _questions, chosen: _chosen);
      expect(cubit.state.status, SubmissionStatus.ready);
      expect(cubit.state.errorMessage, 'تعذّر الاتصال.');

      submissions.failure = null;
      await cubit.submit(questions: _questions, chosen: _chosen);
      expect(cubit.state.status, SubmissionStatus.submitted);
    });

    test('submit does nothing before the check or after submitting', () async {
      await cubit.submit(questions: _questions, chosen: _chosen);
      expect(submissions.answers, isNull);

      await cubit.load();
      await cubit.submit(questions: _questions, chosen: _chosen);
      submissions.answers = null;
      await cubit.submit(questions: _questions, chosen: _chosen);

      expect(submissions.answers, isNull);
      expect(cubit.state.status, SubmissionStatus.submitted);
    });
  });
}
