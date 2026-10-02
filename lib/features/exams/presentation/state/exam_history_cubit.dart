import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/exam.dart';
import '../../domain/repositories/exams_repository.dart';

sealed class ExamHistoryState {
  const ExamHistoryState();
}

class ExamHistoryLoading extends ExamHistoryState {
  const ExamHistoryLoading();
}

class ExamHistoryLoaded extends ExamHistoryState {
  const ExamHistoryLoaded(this.exams);

  final List<Exam> exams;
}

class ExamHistoryError extends ExamHistoryState {
  const ExamHistoryError(this.message);

  final String message;
}

/// The student's examinations, newest first.
class ExamHistoryCubit extends Cubit<ExamHistoryState> {
  ExamHistoryCubit(this._repository, this._studentId)
    : super(const ExamHistoryLoading());

  final ExamsRepository _repository;
  final String _studentId;

  Future<void> load() async {
    // Keep the current list visible while refreshing.
    if (state is! ExamHistoryLoaded) emit(const ExamHistoryLoading());
    try {
      emit(ExamHistoryLoaded(await _repository.fetchStudentExams(_studentId)));
    } on AppFailure catch (failure) {
      emit(ExamHistoryError(failure.message));
    }
  }
}
