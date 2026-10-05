import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../../courses/domain/entities/tajweed_rule.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../../exams/domain/entities/recitation_error.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/services/exam_scoring.dart';

enum EvaluationStatus { editing, saving, approved }

class EvaluationState {
  const EvaluationState({
    this.status = EvaluationStatus.editing,
    this.recitationScore,
    this.feedback = '',
    this.errors = const [],
    this.errorMessage,
  });

  /// The longest general notes the security rules accept.
  static const int maxFeedbackLength = 2000;

  final EvaluationStatus status;

  /// The recitation score out of 80, or null while the entered value is
  /// missing or invalid.
  final int? recitationScore;

  /// The supervisor's general notes as typed.
  final String feedback;

  /// The Tajweed errors recorded so far, in the order they were added.
  final List<RecitationError> errors;

  /// Set only on the state emitted by a failed action.
  final String? errorMessage;

  bool get canAddError => errors.length < RecitationError.maxPerEvaluation;

  /// A copy without the failure message, which belongs to one state only.
  EvaluationState _copyWith({
    EvaluationStatus? status,
    int? Function()? recitationScore,
    String? feedback,
    List<RecitationError>? errors,
    String? errorMessage,
  }) {
    return EvaluationState(
      status: status ?? this.status,
      recitationScore: recitationScore == null
          ? this.recitationScore
          : recitationScore(),
      feedback: feedback ?? this.feedback,
      errors: errors ?? this.errors,
      errorMessage: errorMessage,
    );
  }
}

/// The supervisor's evaluation of one examination: the recitation score, the
/// general notes, the detailed Tajweed errors, and the approval of the
/// result.
class EvaluationCubit extends Cubit<EvaluationState> {
  EvaluationCubit({
    required this._repository,
    required this._supervisorId,
    this._now = DateTime.now,
  }) : super(const EvaluationState());

  final ReviewRepository _repository;
  final String _supervisorId;
  final DateTime Function() _now;

  /// Numbers the errors of this evaluation, so a removed error's ID is never
  /// reused.
  int _nextErrorNumber = 1;

  bool get _editing => state.status == EvaluationStatus.editing;

  /// Takes the recitation score as typed. Anything but a whole number from
  /// 0 to 80 clears the score.
  void setRecitationScore(String input) {
    if (!_editing) return;
    final score = int.tryParse(input.trim());
    emit(
      state._copyWith(
        recitationScore: () =>
            score != null && ExamScoring.isValidRecitationScore(score)
            ? score
            : null,
      ),
    );
  }

  /// Takes the general notes as typed.
  void setFeedback(String input) {
    if (!_editing) return;
    emit(state._copyWith(feedback: input));
  }

  /// Records an error against [rule]. [ayahNumber] and [word] locate it and
  /// may be left out. Ignored once the evaluation holds the most errors it
  /// can.
  void recordError({
    required TajweedRule rule,
    required String description,
    int? ayahNumber,
    String? word,
  }) {
    if (!_editing || !state.canAddError) return;
    final trimmedWord = word?.trim() ?? '';
    emit(
      state._copyWith(
        errors: [
          ...state.errors,
          RecitationError(
            id: 'error-${_nextErrorNumber++}',
            ruleId: rule.id,
            ruleName: rule.name,
            ayahNumber: ayahNumber,
            word: trimmedWord.isEmpty ? null : trimmedWord,
            description: description.trim(),
            createdAt: _now(),
          ),
        ],
      ),
    );
  }

  /// Removes the error with [errorId] before the result is approved.
  void removeError(String errorId) {
    if (!_editing) return;
    emit(
      state._copyWith(
        errors: [
          for (final error in state.errors)
            if (error.id != errorId) error,
        ],
      ),
    );
  }

  /// Approves the result of [exam] with the entered recitation score, notes
  /// and errors. [theoryScore] is the score saved when the student submitted;
  /// the supervisor never enters or changes it. [courseName] names the course
  /// in the student's notification.
  Future<void> approve({
    required Exam exam,
    required String courseName,
    required int theoryScore,
  }) async {
    final recitationScore = state.recitationScore;
    if (!_editing || recitationScore == null) return;
    final feedback = state.feedback.trim();
    emit(state._copyWith(status: EvaluationStatus.saving));
    try {
      await _repository.approveExam(
        exam: exam,
        courseName: courseName,
        supervisorId: _supervisorId,
        recitationScore: recitationScore,
        theoryScore: theoryScore,
        feedback: feedback.isEmpty ? null : feedback,
        errors: state.errors,
      );
      emit(state._copyWith(status: EvaluationStatus.approved));
    } on AppFailure catch (failure) {
      emit(
        state._copyWith(
          status: EvaluationStatus.editing,
          errorMessage: failure.message,
        ),
      );
    }
  }
}
