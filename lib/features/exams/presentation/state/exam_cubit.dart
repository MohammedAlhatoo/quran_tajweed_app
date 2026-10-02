import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/exam_segment.dart';
import '../../domain/repositories/exams_repository.dart';

sealed class ExamState {
  const ExamState();
}

class ExamLoading extends ExamState {
  const ExamLoading();
}

class ExamLoaded extends ExamState {
  const ExamLoaded({required this.exam, required this.segment});

  final Exam exam;
  final ExamSegment segment;
}

class ExamError extends ExamState {
  const ExamError(this.message);

  final String message;
}

/// Loads one examination with its Quran segment.
class ExamCubit extends Cubit<ExamState> {
  ExamCubit(this._repository, this._examId) : super(const ExamLoading());

  final ExamsRepository _repository;
  final String _examId;

  Future<void> load() async {
    emit(const ExamLoading());
    try {
      final exam = await _repository.fetchExam(_examId);
      if (exam == null) {
        emit(const ExamError('هذا الاختبار غير موجود.'));
        return;
      }
      final segment = await _repository.fetchSegment(exam.segmentId);
      emit(
        segment == null
            ? const ExamError('مقطع هذا الاختبار غير متاح.')
            : ExamLoaded(exam: exam, segment: segment),
      );
    } on AppFailure catch (failure) {
      emit(ExamError(failure.message));
    }
  }
}
