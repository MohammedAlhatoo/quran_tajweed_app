import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../exams/domain/entities/evaluation.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../../exams/domain/repositories/evaluations_repository.dart';
import '../../domain/repositories/review_repository.dart';

sealed class ReviewedExamsState {
  const ReviewedExamsState();
}

class ReviewedExamsLoading extends ReviewedExamsState {
  const ReviewedExamsLoading();
}

class ReviewedExamsLoaded extends ReviewedExamsState {
  const ReviewedExamsLoaded({
    required this.exams,
    required this.students,
    required this.evaluations,
  });

  final List<Exam> exams;

  /// The students of [exams], by ID. A student whose account could not be
  /// read is absent.
  final Map<String, AppUser> students;

  /// The approved evaluations, by examination ID.
  final Map<String, Evaluation> evaluations;
}

class ReviewedExamsError extends ReviewedExamsState {
  const ReviewedExamsError(this.message);

  final String message;
}

/// The examinations of the supervisor's square whose result is approved,
/// newest first, with their results.
class ReviewedExamsCubit extends Cubit<ReviewedExamsState> {
  ReviewedExamsCubit({
    required this._reviews,
    required this._evaluations,
    required this._squareId,
  }) : super(const ReviewedExamsLoading());

  final ReviewRepository _reviews;
  final EvaluationsRepository _evaluations;

  /// Null when the supervisor's account has no square.
  final String? _squareId;

  Future<void> load() async {
    final squareId = _squareId;
    if (squareId == null || squareId.isEmpty) {
      emit(
        const ReviewedExamsError('حسابك غير مرتبط بمربع. تواصل مع الإدارة.'),
      );
      return;
    }
    // Keep the current list visible while refreshing.
    if (state is! ReviewedExamsLoaded) emit(const ReviewedExamsLoading());
    try {
      final exams = await _reviews.fetchReviewedExams(squareId);
      final students = <String, AppUser>{};
      await Future.wait([
        for (final studentId in {for (final exam in exams) exam.studentId})
          _addStudent(students, studentId),
      ]);
      emit(
        ReviewedExamsLoaded(
          exams: exams,
          students: students,
          evaluations: await _evaluations.fetchEvaluations([
            for (final exam in exams) exam.id,
          ]),
        ),
      );
    } on AppFailure catch (failure) {
      emit(ReviewedExamsError(failure.message));
    }
  }

  Future<void> _addStudent(Map<String, AppUser> students, String id) async {
    try {
      final student = await _reviews.fetchStudent(id);
      if (student != null) students[id] = student;
    } on AppFailure {
      // The examination is still listed, without the student's name.
    }
  }
}
