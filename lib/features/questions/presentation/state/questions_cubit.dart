import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/exam_question.dart';
import '../../domain/repositories/questions_repository.dart';

sealed class QuestionsState {
  const QuestionsState();
}

class QuestionsLoading extends QuestionsState {
  const QuestionsLoading();
}

class QuestionsLoaded extends QuestionsState {
  const QuestionsLoaded({
    required this.questions,
    this.index = 0,
    this.answers = const {},
  });

  /// Never empty.
  final List<ExamQuestion> questions;

  /// The position of the question on screen, starting at 0.
  final int index;

  /// The chosen option of each answered question, keyed by the ID of its
  /// `exam_questions` record.
  final Map<String, String> answers;

  ExamQuestion get current => questions[index];

  /// The option chosen for the question on screen, or null.
  String? get currentAnswer => answers[current.id];

  bool get isFirst => index == 0;
  bool get isLast => index == questions.length - 1;
}

class QuestionsError extends QuestionsState {
  const QuestionsError(this.message);

  final String message;
}

/// Loads the theory questions of one examination and keeps the student's
/// answers in memory. Submitting them belongs to the submission step.
class QuestionsCubit extends Cubit<QuestionsState> {
  QuestionsCubit(
    this._repository, {
    required this._examId,
    required this._studentId,
  }) : super(const QuestionsLoading());

  final QuestionsRepository _repository;
  final String _examId;
  final String _studentId;

  Future<void> load() async {
    emit(const QuestionsLoading());
    try {
      final questions = await _repository.fetchExamQuestions(
        examId: _examId,
        studentId: _studentId,
      );
      emit(
        questions.isEmpty
            ? const QuestionsError('أسئلة هذا الاختبار غير متاحة.')
            : QuestionsLoaded(questions: questions),
      );
    } on AppFailure catch (failure) {
      emit(QuestionsError(failure.message));
    }
  }

  /// Chooses [option] for the question on screen, replacing an earlier choice.
  void selectAnswer(String option) {
    final current = state;
    if (current is! QuestionsLoaded) return;
    if (!current.current.options.contains(option)) return;
    emit(
      QuestionsLoaded(
        questions: current.questions,
        index: current.index,
        answers: {...current.answers, current.current.id: option},
      ),
    );
  }

  /// Moves to the next question once the one on screen is answered.
  void next() {
    final current = state;
    if (current is! QuestionsLoaded) return;
    if (current.isLast || current.currentAnswer == null) return;
    _goTo(current, current.index + 1);
  }

  void previous() {
    final current = state;
    if (current is! QuestionsLoaded || current.isFirst) return;
    _goTo(current, current.index - 1);
  }

  void _goTo(QuestionsLoaded current, int index) {
    emit(
      QuestionsLoaded(
        questions: current.questions,
        index: index,
        answers: current.answers,
      ),
    );
  }
}
