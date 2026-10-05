import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../../certificates/domain/entities/certificate.dart';
import '../../../certificates/domain/repositories/certificates_repository.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/domain/repositories/courses_repository.dart';
import '../../domain/entities/evaluation.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/exam_status.dart';
import '../../domain/repositories/evaluations_repository.dart';
import '../../domain/repositories/exams_repository.dart';

sealed class ExamResultState {
  const ExamResultState();
}

class ExamResultLoading extends ExamResultState {
  const ExamResultLoading();
}

class ExamResultLoaded extends ExamResultState {
  const ExamResultLoaded({
    required this.exam,
    required this.course,
    required this.evaluation,
    required this.certificate,
  });

  final Exam exam;

  /// Null when the course is no longer available.
  final Course? course;

  /// Null until the supervisor approves the result.
  final Evaluation? evaluation;

  /// Null unless the examination was passed.
  final Certificate? certificate;
}

class ExamResultError extends ExamResultState {
  const ExamResultError(this.message);

  final String message;
}

/// The approved result of one of the student's examinations, with its
/// certificate when it was passed.
class ExamResultCubit extends Cubit<ExamResultState> {
  ExamResultCubit({
    required this._exams,
    required this._evaluations,
    required this._certificates,
    required this._courses,
    required this._examId,
  }) : super(const ExamResultLoading());

  final ExamsRepository _exams;
  final EvaluationsRepository _evaluations;
  final CertificatesRepository _certificates;
  final CoursesRepository _courses;
  final String _examId;

  Future<void> load() async {
    emit(const ExamResultLoading());
    try {
      final exam = await _exams.fetchExam(_examId);
      if (exam == null) {
        emit(const ExamResultError('هذا الاختبار غير موجود.'));
        return;
      }
      // Before the approval the evaluation holds only the theory score, and
      // the security rules keep it from the student.
      final evaluation = exam.status == ExamStatus.approved
          ? await _evaluations.fetchEvaluation(_examId)
          : null;
      emit(
        ExamResultLoaded(
          exam: exam,
          course: await _courses.fetchCourse(exam.courseId),
          evaluation: evaluation,
          // A failed examination has no certificate to look for.
          certificate: evaluation != null && evaluation.passed
              ? await _certificates.fetchCertificate(_examId)
              : null,
        ),
      );
    } on AppFailure catch (failure) {
      emit(ExamResultError(failure.message));
    }
  }
}
