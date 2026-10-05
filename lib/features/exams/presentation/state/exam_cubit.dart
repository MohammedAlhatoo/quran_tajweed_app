import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../../quran/domain/entities/quran_ayah.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
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
  const ExamLoaded({
    required this.exam,
    required this.segment,
    required this.ayahs,
  });

  final Exam exam;
  final ExamSegment segment;

  /// The ayahs of the segment, in order, from the Quran data in the app.
  final List<QuranAyah> ayahs;
}

class ExamError extends ExamState {
  const ExamError(this.message);

  final String message;
}

/// Loads one examination with its Quran segment and the text of the segment.
class ExamCubit extends Cubit<ExamState> {
  ExamCubit(this._repository, this._quran, this._examId)
    : super(const ExamLoading());

  final ExamsRepository _repository;
  final QuranRepository _quran;
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
      if (segment == null) {
        emit(const ExamError('مقطع هذا الاختبار غير متاح.'));
        return;
      }
      final ayahs = await _quran.ayahsOf(
        segment.surah,
        segment.ayahFrom,
        segment.ayahTo,
      );
      emit(ExamLoaded(exam: exam, segment: segment, ayahs: ayahs));
    } on AppFailure catch (failure) {
      emit(ExamError(failure.message));
    } on QuranDataException {
      // The examination is not shown without the text to recite.
      emit(const ExamError('تعذّر تحميل نص المقطع.'));
    }
  }
}
