import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/exam.dart';
import '../../domain/repositories/exams_repository.dart';

sealed class StartExamState {
  const StartExamState();
}

class StartExamIdle extends StartExamState {
  const StartExamIdle();
}

class StartExamLoading extends StartExamState {
  const StartExamLoading();
}

/// The examination is ready: a new one, or the open one being continued.
class StartExamReady extends StartExamState {
  const StartExamReady(this.exam);

  final Exam exam;
}

class StartExamError extends StartExamState {
  const StartExamError(this.message);

  final String message;
}

class StartExamCubit extends Cubit<StartExamState> {
  StartExamCubit(this._repository) : super(const StartExamIdle());

  final ExamsRepository _repository;

  Future<void> start({
    required AppUser student,
    required String courseId,
  }) async {
    if (state is StartExamLoading) return;
    emit(const StartExamLoading());
    try {
      emit(
        StartExamReady(
          await _repository.startExam(student: student, courseId: courseId),
        ),
      );
    } on AppFailure catch (failure) {
      emit(StartExamError(failure.message));
    }
  }
}
