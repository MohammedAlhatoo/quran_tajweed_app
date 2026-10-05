import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course_level.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/tajweed_rule.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/tajweed_rule_group.dart';
import 'package:quran_tajweed_app/features/courses/domain/repositories/courses_repository.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_segment.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/exams_repository.dart';
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
  List<TajweedRule> rules = const [
    TajweedRule(
      id: 'madd_tabii',
      name: 'المد الطبيعي',
      category: TajweedCategory.madd,
    ),
  ];

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
  Future<List<TajweedRule>> fetchCourseRules(String courseId) async {
    if (failure case final failure?) throw failure;
    return rules;
  }
}

class _FakeExamsRepository implements ExamsRepository {
  AppFailure? failure;
  List<Exam> exams = const [];

  @override
  Future<List<Exam>> fetchStudentExams(String studentId) async {
    if (failure case final failure?) throw failure;
    return exams;
  }

  @override
  Future<Exam?> fetchExam(String examId) => throw UnimplementedError();

  @override
  Future<ExamSegment?> fetchSegment(String segmentId) =>
      throw UnimplementedError();

  @override
  Future<Exam> startExam({
    required AppUser student,
    required String courseId,
  }) => throw UnimplementedError();
}

Exam _examOf(String id, ExamStatus status, {String courseId = 'course-1'}) =>
    Exam(
      id: id,
      studentId: 'uid-1',
      courseId: courseId,
      segmentId: 'segment-1',
      status: status,
      mosqueId: 'mosque-1',
      squareId: 'square-1',
      regionId: 'region-1',
    );

void main() {
  late _FakeCoursesRepository repository;
  late _FakeExamsRepository exams;

  setUp(() {
    repository = _FakeCoursesRepository();
    exams = _FakeExamsRepository();
  });

  CourseDetailsCubit detailsCubit([String courseId = 'course-1']) =>
      CourseDetailsCubit(repository, exams, courseId, 'uid-1');

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

    test('reads a document without objectives as an empty list', () {
      final course = Course.fromMap('course-1', {'level': 'sanad'})!;

      expect(course.objectives, isEmpty);
    });

    test('reads back what toMap writes', () {
      const course = Course(
        id: 'course-1',
        name: 'عليا',
        description: 'إتقان الأحكام',
        level: CourseLevel.advanced,
        objectives: ['هدف أول', 'هدف ثانٍ'],
      );

      final read = Course.fromMap(course.id, course.toMap())!;

      expect(read.name, course.name);
      expect(read.description, course.description);
      expect(read.level, course.level);
      expect(read.objectives, course.objectives);
    });
  });

  test('course levels carry the approved names of the courses', () {
    expect(CourseLevel.values.map((level) => level.label), [
      'تمهيدية',
      'تأهيلية',
      'عليا',
      'السند',
    ]);
  });

  group('TajweedRuleGroup.byCategory', () {
    test('groups the rules by chapter, in the order of the chapters', () {
      final groups = TajweedRuleGroup.byCategory(const [
        TajweedRule(id: 'm1', name: 'مد أول', category: TajweedCategory.madd),
        TajweedRule(
          id: 'i1',
          name: 'تعريف',
          category: TajweedCategory.intro,
          kind: TajweedRuleKind.theoretical,
        ),
        TajweedRule(id: 'x1', name: 'بلا باب'),
        TajweedRule(id: 'm2', name: 'مد ثانٍ', category: TajweedCategory.madd),
      ]);

      expect(groups.map((group) => group.category), [
        TajweedCategory.intro,
        TajweedCategory.madd,
        null,
      ]);
      expect(groups[1].rules.map((rule) => rule.id), ['m1', 'm2']);
      expect(groups.first.label, 'مقدمات');
      expect(groups.last.label, 'أحكام أخرى');
    });

    test('returns nothing for a course without rules', () {
      expect(TajweedRuleGroup.byCategory(const []), isEmpty);
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
    test('load emits the course with its rules grouped by chapter', () async {
      final cubit = detailsCubit();

      await cubit.load();

      final state = cubit.state as CourseDetailsLoaded;
      expect(state.course.id, 'course-1');
      expect(state.ruleGroups.single.category, TajweedCategory.madd);
      expect(state.ruleGroups.single.rules.single.name, 'المد الطبيعي');
      expect(state.openExam, isNull);
      expect(state.isAwaitingReview, isFalse);
    });

    test('load finds the open examination of the course', () async {
      exams.exams = [
        _examOf('other', ExamStatus.inProgress, courseId: 'course-2'),
        _examOf('reviewing', ExamStatus.pendingReview),
        _examOf('open', ExamStatus.inProgress),
      ];
      final cubit = detailsCubit();

      await cubit.load();

      final state = cubit.state as CourseDetailsLoaded;
      expect(state.openExam?.id, 'open');
      expect(state.isAwaitingReview, isFalse);
    });

    test('load reports an examination awaiting review', () async {
      exams.exams = [
        _examOf('approved', ExamStatus.approved),
        _examOf('reviewing', ExamStatus.pendingReview),
      ];
      final cubit = detailsCubit();

      await cubit.load();

      final state = cubit.state as CourseDetailsLoaded;
      expect(state.openExam, isNull);
      expect(state.isAwaitingReview, isTrue);
    });

    test('load leaves a new attempt possible after an approved one', () async {
      exams.exams = [
        _examOf('approved', ExamStatus.approved),
        _examOf('other', ExamStatus.pendingReview, courseId: 'course-2'),
      ];
      final cubit = detailsCubit();

      await cubit.load();

      final state = cubit.state as CourseDetailsLoaded;
      expect(state.openExam, isNull);
      expect(state.isAwaitingReview, isFalse);
    });

    test('load still emits the course when the examinations fail', () async {
      exams.failure = const AppFailure('تعذّر الاتصال.');
      final cubit = detailsCubit();

      await cubit.load();

      final state = cubit.state as CourseDetailsLoaded;
      expect(state.course.id, 'course-1');
      expect(state.ruleGroups, isNotEmpty);
      expect(state.openExam, isNull);
      expect(state.isAwaitingReview, isFalse);
    });

    test('load emits an error for a missing course', () async {
      final cubit = detailsCubit('unknown');

      await cubit.load();

      expect(cubit.state, isA<CourseDetailsError>());
    });

    test('load emits an error when reading fails', () async {
      final cubit = detailsCubit();
      repository.failure = const AppFailure('تعذّر الاتصال.');

      await cubit.load();

      expect((cubit.state as CourseDetailsError).message, 'تعذّر الاتصال.');
    });
  });
}
