import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/services/exam_scoring.dart';

enum EvaluationStatus { editing, saving, approved }

class EvaluationState {
  const EvaluationState({
    this.status = EvaluationStatus.editing,
    this.recitationScore,
    this.errorMessage,
  });

  final EvaluationStatus status;

  /// The recitation score out of 80, or null while the entered value is
  /// missing or invalid.
  final int? recitationScore;

  /// Set only on the state emitted by a failed action.
  final String? errorMessage;
}

/// The supervisor's evaluation of one examination: the recitation score and
/// the approval of the result.
class EvaluationCubit extends Cubit<EvaluationState> {
  EvaluationCubit({
    required this._repository,
    required this._examId,
    required this._supervisorId,
  }) : super(const EvaluationState());

  final ReviewRepository _repository;
  final String _examId;
  final String _supervisorId;

  /// Takes the recitation score as typed. Anything but a whole number from
  /// 0 to 80 clears the score.
  void setRecitationScore(String input) {
    if (state.status != EvaluationStatus.editing) return;
    final score = int.tryParse(input.trim());
    emit(
      EvaluationState(
        recitationScore:
            score != null && ExamScoring.isValidRecitationScore(score)
            ? score
            : null,
      ),
    );
  }

  /// Approves the result with the entered recitation score and
  /// [theoryScore], the score calculated from the student's answers.
  Future<void> approve({required int theoryScore}) async {
    final recitationScore = state.recitationScore;
    if (state.status != EvaluationStatus.editing || recitationScore == null) {
      return;
    }
    emit(
      EvaluationState(
        status: EvaluationStatus.saving,
        recitationScore: recitationScore,
      ),
    );
    try {
      await _repository.approveExam(
        examId: _examId,
        supervisorId: _supervisorId,
        recitationScore: recitationScore,
        theoryScore: theoryScore,
      );
      emit(
        EvaluationState(
          status: EvaluationStatus.approved,
          recitationScore: recitationScore,
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        EvaluationState(
          recitationScore: recitationScore,
          errorMessage: failure.message,
        ),
      );
    }
  }
}
