import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/course.dart';
import '../../domain/repositories/courses_repository.dart';

sealed class CourseDetailsState {
  const CourseDetailsState();
}

class CourseDetailsLoading extends CourseDetailsState {
  const CourseDetailsLoading();
}

class CourseDetailsLoaded extends CourseDetailsState {
  const CourseDetailsLoaded({required this.course, required this.ruleNames});

  final Course course;
  final List<String> ruleNames;
}

class CourseDetailsError extends CourseDetailsState {
  const CourseDetailsError(this.message);

  final String message;
}

class CourseDetailsCubit extends Cubit<CourseDetailsState> {
  CourseDetailsCubit(this._repository, this._courseId)
    : super(const CourseDetailsLoading());

  final CoursesRepository _repository;
  final String _courseId;

  Future<void> load() async {
    emit(const CourseDetailsLoading());
    try {
      final course = await _repository.fetchCourse(_courseId);
      if (course == null) {
        emit(const CourseDetailsError('هذه الدورة غير متاحة.'));
        return;
      }
      final ruleNames = await _repository.fetchCourseRuleNames(_courseId);
      emit(CourseDetailsLoaded(course: course, ruleNames: ruleNames));
    } on AppFailure catch (failure) {
      emit(CourseDetailsError(failure.message));
    }
  }
}
