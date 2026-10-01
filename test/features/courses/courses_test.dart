import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course_level.dart';
import 'package:quran_tajweed_app/features/courses/domain/repositories/courses_repository.dart';
import 'package:quran_tajweed_app/features/courses/presentation/state/course_details_cubit.dart';
import 'package:quran_tajweed_app/features/courses/presentation/state/courses_cubit.dart';

const _course = Course(
  id: 'course-1',
  name: 'الدورة التمهيدية',
  description: 'أساسيات أحكام التجويد',
  level: CourseLevel.introductory,
);

class _FakeCoursesRepository implements CoursesRepository {
  AppFailure? failure;
  List<Course> courses = const [_course];
  List<String> ruleNames = const ['المدود'];

  @override
  Future<List<Course>> fetchActiveCourses() async {
    if (failure case final failure?) throw failure;
    return courses;
  }

  @override
  Future<Course?> fetchCourse(String courseId) async {
    if (failure case final failure?) throw failure;
    return courses.where((course) => course.id == courseId).firstOrNull;
  }

  @override
  Future<List<String>> fetchCourseRuleNames(String courseId) async {
    if (failure case final failure?) throw failure;
    return ruleNames;
  }
}

void main() {
  late _FakeCoursesRepository repository;

  setUp(() => repository = _FakeCoursesRepository());

  group('Course.fromMap', () {
    test('reads the fields and the optional objectives', () {
      final course = Course.fromMap('course-1', {
        'name': 'الدورة العليا',
        'description': 'إتقان الأحكام',
        'level': 'advanced',
        'objectives': ['هدف أول', 2, 'هدف ثانٍ'],
      })!;

      expect(course.level, CourseLevel.advanced);
      expect(course.objectives, ['هدف أول', 'هدف ثانٍ']);
    });

    test('rejects a document without a valid level', () {
      expect(Course.fromMap('course-1', {'name': 'دورة'}), isNull);
      expect(Course.fromMap('course-1', {'level': 'expert'}), isNull);
    });
  });

  test('course levels are ordered from introductory to sanad', () {
    expect(CourseLevel.values.map((level) => level.value), [
      'introductory',
      'qualifying',
      'advanced',
      'sanad',
    ]);
  });

  group('CoursesCubit', () {
    test('load emits the active courses', () async {
      final cubit = CoursesCubit(repository);

      await cubit.load();

      expect((cubit.state as CoursesLoaded).courses.single.id, 'course-1');
    });

    test('load emits an error when reading fails', () async {
      repository.failure = const AppFailure('تعذّر الاتصال.');
      final cubit = CoursesCubit(repository);

      await cubit.load();

      expect((cubit.state as CoursesError).message, 'تعذّر الاتصال.');
    });
  });

  group('CourseDetailsCubit', () {
    test('load emits the course with its rule names', () async {
      final cubit = CourseDetailsCubit(repository, 'course-1');

      await cubit.load();

      final state = cubit.state as CourseDetailsLoaded;
      expect(state.course.id, 'course-1');
      expect(state.ruleNames, ['المدود']);
    });

    test('load emits an error for a missing course', () async {
      final cubit = CourseDetailsCubit(repository, 'unknown');

      await cubit.load();

      expect(cubit.state, isA<CourseDetailsError>());
    });

    test('load emits an error when reading fails', () async {
      final cubit = CourseDetailsCubit(repository, 'course-1');
      repository.failure = const AppFailure('تعذّر الاتصال.');

      await cubit.load();

      expect((cubit.state as CourseDetailsError).message, 'تعذّر الاتصال.');
    });
  });
}
