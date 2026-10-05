import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../../exams/domain/repositories/exams_repository.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/tajweed_rule_group.dart';
import '../../domain/repositories/courses_repository.dart';

sealed class CourseDetailsState {
  const CourseDetailsState();
}

class CourseDetailsLoading extends CourseDetailsState {
  const CourseDetailsLoading();
}

class CourseDetailsLoaded extends CourseDetailsState {
  const CourseDetailsLoaded({
    required this.course,
    required this.ruleGroups,
    this.openExam,
    this.isAwaitingReview = false,
  });

  final Course course;

  /// The Tajweed rules of the course, grouped by chapter.
  final List<TajweedRuleGroup> ruleGroups;

  /// The student's open examination of the course, which is continued instead
  /// of starting another.
  final Exam? openExam;

  /// Whether an examination of the course is waiting for the supervisor, so a
  /// new one cannot be started. Never true while [openExam] is set.
  final bool isAwaitingReview;
}

class CourseDetailsError extends CourseDetailsState {
  const CourseDetailsError(this.message);

  final String message;
}

class CourseDetailsCubit extends Cubit<CourseDetailsState> {
  CourseDetailsCubit(
    this._repository,
    this._exams,
    this._courseId,
    this._studentId,
  ) : super(const CourseDetailsLoading());

  final CoursesRepository _repository;
  final ExamsRepository _exams;
  final String _courseId;
  final String _studentId;

  Future<void> load() async {
    emit(const CourseDetailsLoading());
    try {
      final course = await _repository.fetchCourse(_courseId);
      if (course == null) {
        emit(const CourseDetailsError('هذه الدورة غير متاحة.'));
        return;
      }
      final rules = await _repository.fetchCourseRules(_courseId);
      final courseExams = await _fetchCourseExams();
      // The same order as starting an examination: an open one is continued
      // before one awaiting review is looked at.
      final openExam = courseExams
          .where((exam) => exam.status.isOpen)
          .firstOrNull;
      if (isClosed) return;
      emit(
        CourseDetailsLoaded(
          course: course,
          ruleGroups: TajweedRuleGroup.byCategory(rules),
          openExam: openExam,
          isAwaitingReview:
              openExam == null &&
              courseExams.any((exam) => exam.status.isAwaitingReview),
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(CourseDetailsError(failure.message));
    }
  }

  /// The student's examinations of the course. When they cannot be read, the
  /// course is still shown: the status is taken as unknown, and starting an
  /// examination checks for an open or awaiting one again.
  Future<List<Exam>> _fetchCourseExams() async {
    try {
      return [
        for (final exam in await _exams.fetchStudentExams(_studentId))
          if (exam.courseId == _courseId) exam,
      ];
    } on AppFailure {
      return const [];
    }
  }
}
