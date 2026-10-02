import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/questions/domain/entities/exam_question.dart';
import 'package:quran_tajweed_app/features/questions/domain/repositories/questions_repository.dart';
import 'package:quran_tajweed_app/features/questions/presentation/state/questions_cubit.dart';

ExamQuestion _question(int order) => ExamQuestion(
  id: 'exam-1_$order',
  examId: 'exam-1',
  questionId: 'q$order',
  order: order,
  type: 'multiple_choice',
  question: 'سؤال $order',
  options: const ['أ', 'ب', 'ج', 'د'],
);

class _FakeQuestionsRepository implements QuestionsRepository {
  AppFailure? failure;
  List<ExamQuestion> questions = [for (var i = 1; i <= 10; i++) _question(i)];
  String? requestedExamId;
  String? requestedStudentId;

  @override
  Future<List<ExamQuestion>> fetchExamQuestions({
    required String examId,
    required String studentId,
  }) async {
    if (failure case final failure?) throw failure;
    requestedExamId = examId;
    requestedStudentId = studentId;
    return questions;
  }
}

void main() {
  late _FakeQuestionsRepository repository;
  late QuestionsCubit cubit;

  setUp(() {
    repository = _FakeQuestionsRepository();
    cubit = QuestionsCubit(repository, examId: 'exam-1', studentId: 'uid-1');
  });

  QuestionsLoaded loaded() => cubit.state as QuestionsLoaded;

  group('ExamQuestion.fromMap', () {
    final data = <String, dynamic>{
      'examId': 'exam-1',
      'studentId': 'uid-1',
      'questionId': 'q1',
      'order': 3,
      'type': 'multiple_choice',
      'question': 'سؤال',
      'options': ['أ', 'ب'],
    };

    test('reads the question as shown to the student', () {
      final question = ExamQuestion.fromMap('exam-1_3', data)!;

      expect(question.id, 'exam-1_3');
      expect(question.examId, 'exam-1');
      expect(question.questionId, 'q1');
      expect(question.order, 3);
      expect(question.options, ['أ', 'ب']);
    });

    test('rejects a document without an examination, order or text', () {
      expect(ExamQuestion.fromMap('x', {...data}..remove('examId')), isNull);
      expect(ExamQuestion.fromMap('x', {...data, 'order': 0}), isNull);
      expect(ExamQuestion.fromMap('x', {...data, 'order': '3'}), isNull);
      expect(ExamQuestion.fromMap('x', {...data, 'question': ''}), isNull);
    });

    test('treats missing options as an empty list', () {
      final question = ExamQuestion.fromMap('x', {...data}..remove('options'))!;

      expect(question.options, isEmpty);
    });
  });

  group('QuestionsCubit', () {
    test(
      'load emits the questions of the examination and the student',
      () async {
        await cubit.load();

        expect(repository.requestedExamId, 'exam-1');
        expect(repository.requestedStudentId, 'uid-1');
        expect(loaded().questions, hasLength(10));
        expect(loaded().index, 0);
        expect(loaded().isFirst, isTrue);
        expect(loaded().answers, isEmpty);
      },
    );

    test('load emits an error when the examination has no questions', () async {
      repository.questions = [];

      await cubit.load();

      expect(cubit.state, isA<QuestionsError>());
    });

    test('load emits the failure message', () async {
      repository.failure = const AppFailure('تعذّر الاتصال.');

      await cubit.load();

      expect((cubit.state as QuestionsError).message, 'تعذّر الاتصال.');
    });

    test('selectAnswer stores the choice and lets it be changed', () async {
      await cubit.load();

      cubit.selectAnswer('أ');
      expect(loaded().currentAnswer, 'أ');

      cubit.selectAnswer('ب');
      expect(loaded().answers, {'exam-1_1': 'ب'});
    });

    test('selectAnswer ignores a value that is not an option', () async {
      await cubit.load();

      cubit.selectAnswer('غير موجود');

      expect(loaded().currentAnswer, isNull);
    });

    test('next waits for an answer to the question on screen', () async {
      await cubit.load();

      cubit.next();
      expect(loaded().index, 0);

      cubit
        ..selectAnswer('أ')
        ..next();
      expect(loaded().index, 1);
      expect(loaded().current.order, 2);
      expect(loaded().currentAnswer, isNull);
    });

    test(
      'previous returns to the earlier question and keeps its answer',
      () async {
        await cubit.load();
        cubit
          ..selectAnswer('ج')
          ..next()
          ..selectAnswer('د')
          ..previous();

        expect(loaded().index, 0);
        expect(loaded().currentAnswer, 'ج');
        expect(loaded().answers, {'exam-1_1': 'ج', 'exam-1_2': 'د'});
      },
    );

    test('previous does nothing on the first question', () async {
      await cubit.load();

      cubit.previous();

      expect(loaded().index, 0);
    });

    test('next stops at the last question', () async {
      await cubit.load();
      for (var i = 0; i < 9; i++) {
        cubit
          ..selectAnswer('أ')
          ..next();
      }
      expect(loaded().isLast, isTrue);

      cubit
        ..selectAnswer('أ')
        ..next();

      expect(loaded().index, 9);
      expect(loaded().answers, hasLength(10));
    });
  });
}
