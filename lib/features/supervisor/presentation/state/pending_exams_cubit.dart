import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../domain/repositories/review_repository.dart';

sealed class PendingExamsState {
  const PendingExamsState();
}

class PendingExamsLoading extends PendingExamsState {
  const PendingExamsLoading();
}

class PendingExamsLoaded extends PendingExamsState {
  const PendingExamsLoaded({required this.exams, required this.students});

  final List<Exam> exams;

  /// The students of [exams], by ID. A student whose account could not be
  /// read is absent.
  final Map<String, AppUser> students;
}

class PendingExamsError extends PendingExamsState {
  const PendingExamsError(this.message);

  final String message;
}

/// The examinations of the supervisor's square that await review, oldest
/// submission first.
class PendingExamsCubit extends Cubit<PendingExamsState> {
  PendingExamsCubit(this._repository, this._squareId)
    : super(const PendingExamsLoading());

  final ReviewRepository _repository;

  /// Null when the supervisor's account has no square.
  final String? _squareId;

  Future<void> load() async {
    final squareId = _squareId;
    if (squareId == null || squareId.isEmpty) {
      emit(const PendingExamsError('حسابك غير مرتبط بمربع. تواصل مع الإدارة.'));
      return;
    }
    // Keep the current list visible while refreshing.
    if (state is! PendingExamsLoaded) emit(const PendingExamsLoading());
    try {
      final exams = await _repository.fetchPendingExams(squareId);
      final students = <String, AppUser>{};
      await Future.wait([
        for (final studentId in {for (final exam in exams) exam.studentId})
          _addStudent(students, studentId),
      ]);
      emit(PendingExamsLoaded(exams: exams, students: students));
    } on AppFailure catch (failure) {
      emit(PendingExamsError(failure.message));
    }
  }

  Future<void> _addStudent(Map<String, AppUser> students, String id) async {
    try {
      final student = await _repository.fetchStudent(id);
      if (student != null) students[id] = student;
    } on AppFailure {
      // The examination is still listed, without the student's name.
    }
  }
}
