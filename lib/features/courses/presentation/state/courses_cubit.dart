import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/course.dart';
import '../../domain/repositories/courses_repository.dart';

sealed class CoursesState {
  const CoursesState();
}

class CoursesLoading extends CoursesState {
  const CoursesLoading();
}

class CoursesLoaded extends CoursesState {
  const CoursesLoaded(this.courses);

  final List<Course> courses;
}

class CoursesError extends CoursesState {
  const CoursesError(this.message);

  final String message;
}

/// The active courses, shared by the home and courses tabs.
class CoursesCubit extends Cubit<CoursesState> {
  CoursesCubit(this._repository) : super(const CoursesLoading());

  final CoursesRepository _repository;

  Future<void> load() async {
    emit(const CoursesLoading());
    try {
      emit(CoursesLoaded(await _repository.fetchActiveCourses()));
    } on AppFailure catch (failure) {
      emit(CoursesError(failure.message));
    }
  }
}
