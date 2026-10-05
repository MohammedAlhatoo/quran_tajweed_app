import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course_level.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/tajweed_rule.dart';
import 'package:quran_tajweed_app/features/courses/domain/repositories/courses_repository.dart';
import 'package:quran_tajweed_app/features/courses/presentation/pages/course_details_page.dart';
import 'package:quran_tajweed_app/features/courses/presentation/state/course_details_cubit.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_segment.dart';
import 'package:quran_tajweed_app/features/exams/domain/entities/exam_status.dart';
import 'package:quran_tajweed_app/features/exams/domain/repositories/exams_repository.dart';
import 'package:quran_tajweed_app/features/exams/presentation/state/start_exam_cubit.dart';
import 'package:quran_tajweed_app/router/route_names.dart';

class _FakeCoursesRepository implements CoursesRepository {
  _FakeCoursesRepository(this.level, this.objectives);

  final CourseLevel level;
  final List<String> objectives;

  @override
  Future<List<Course>> fetchActiveCourses() async => const [];

  @override
  Future<Course?> fetchCourse(String courseId) async => Course(
    id: courseId,
    name: 'دورة الأحكام',
    description: 'جميع أحكام رواية حفص',
    level: level,
    objectives: objectives,
  );

  @override
  Future<List<TajweedRule>> fetchCourseRules(String courseId) async => const [
    TajweedRule(
      id: 'intro_lahn_jali',
      name: 'اللحن الجلي',
      category: TajweedCategory.intro,
      kind: TajweedRuleKind.theoretical,
    ),
    TajweedRule(
      id: 'madd_tabii',
      name: 'المد الطبيعي',
      category: TajweedCategory.madd,
    ),
    TajweedRule(
      id: 'madd_muttasil',
      name: 'المد المتصل',
      category: TajweedCategory.madd,
    ),
    TajweedRule(
      id: 'madd_long',
      name: _longRuleName,
      category: TajweedCategory.madd,
    ),
  ];
}

/// Too long for one column of the grid.
const _longRuleName = 'المد اللازم الكلمي المثقل والمخفف';

class _FakeExamsRepository implements ExamsRepository {
  _FakeExamsRepository(this.exams, this.failure);

  final List<Exam> exams;
  final AppFailure? failure;
  var started = 0;

  @override
  Future<List<Exam>> fetchStudentExams(String studentId) async {
    if (failure case final failure?) throw failure;
    return exams;
  }

  @override
  Future<Exam> startExam({
    required AppUser student,
    required String courseId,
  }) async {
    started++;
    return _examOf('new', ExamStatus.inProgress);
  }

  @override
  Future<Exam?> fetchExam(String examId) => throw UnimplementedError();

  @override
  Future<ExamSegment?> fetchSegment(String segmentId) =>
      throw UnimplementedError();
}

Exam _examOf(String id, ExamStatus status) => Exam(
  id: id,
  studentId: 'uid-1',
  courseId: 'course-1',
  segmentId: 'segment-1',
  status: status,
  mosqueId: 'mosque-1',
  squareId: 'square-1',
  regionId: 'region-1',
);

Future<_FakeExamsRepository> _pump(
  WidgetTester tester, {
  List<Exam> exams = const [],
  AppFailure? examsFailure,
  CourseLevel level = CourseLevel.sanad,
  List<String> objectives = const [],
  Size size = const Size(800, 1600),
}) async {
  final examsRepository = _FakeExamsRepository(exams, examsFailure);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => CourseDetailsCubit(
                _FakeCoursesRepository(level, objectives),
                examsRepository,
                'course-1',
                'uid-1',
              )..load(),
            ),
            BlocProvider(create: (_) => StartExamCubit(examsRepository)),
          ],
          child: const CourseDetailsPage(),
        ),
      ),
      GoRoute(
        path: RouteNames.studentExamPattern,
        builder: (context, state) =>
            Text('exam ${state.pathParameters['examId']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  // Tall enough for the list to build every section.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
    ),
  );
  await tester.pumpAndSettle();
  return examsRepository;
}

FilledButton _button(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton));

/// The tag that holds the rule called [name].
Finder _tag(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(Container)).first;

void main() {
  // The Cairo font is not fetched in a test.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows the course, its level name and the examination info', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('دورة الأحكام'), findsOneWidget);
    expect(find.text('السند'), findsOneWidget);
    expect(find.text('معلومات الامتحان'), findsOneWidget);
    expect(find.text('عدد الأسئلة النظرية'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('درجة التلاوة'), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
    expect(find.text('درجة الأسئلة'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('درجة النجاح'), findsOneWidget);
    expect(find.text('70/100'), findsOneWidget);
    expect(find.text('تسجيل التلاوة'), findsOneWidget);
    expect(find.text('ضمن الامتحان'), findsOneWidget);
    // The examination has no time limit.
    expect(find.textContaining('مدة'), findsNothing);
    // No objectives are stored, so their section is left out.
    expect(find.text('أهداف الدورة'), findsNothing);
  });

  for (final (level, label) in const [
    (CourseLevel.introductory, 'تمهيدية'),
    (CourseLevel.qualifying, 'تأهيلية'),
    (CourseLevel.advanced, 'عليا'),
    (CourseLevel.sanad, 'السند'),
  ]) {
    testWidgets('shows the approved name of the level: $label', (tester) async {
      await _pump(tester, level: level);

      expect(find.text(label), findsOneWidget);
      expect(find.textContaining('المستوى'), findsNothing);
      expect(find.textContaining('متقدم'), findsNothing);
    });
  }

  testWidgets('leaves 24 between the last objective and the next section', (
    tester,
  ) async {
    await _pump(tester, objectives: const ['هدف أول', 'هدف ثان']);

    expect(find.text('أهداف الدورة'), findsOneWidget);
    final gap =
        tester.getTopLeft(find.text('معلومات الامتحان')).dy -
        tester.getBottomLeft(find.text('هدف ثان')).dy;
    expect(gap, 24);
  });

  testWidgets('groups the rules by chapter and opens a chapter on tap', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('الأحكام الرئيسية'), findsOneWidget);
    expect(find.text('مقدمات'), findsOneWidget);
    expect(find.text('المدود'), findsOneWidget);
    expect(find.text('عدد الأحكام: 3'), findsOneWidget);
    expect(find.text('المد الطبيعي'), findsNothing);

    await tester.ensureVisible(find.text('المدود'));
    await tester.tap(find.text('المدود'));
    await tester.pumpAndSettle();

    expect(find.text('المد الطبيعي'), findsOneWidget);
    expect(find.text('المد المتصل'), findsOneWidget);
    // The theoretical rule stays inside its own closed chapter.
    expect(find.text('اللحن الجلي'), findsNothing);
  });

  testWidgets('lays the rules on a grid and highlights the open chapter', (
    tester,
  ) async {
    await _pump(tester);
    await tester.ensureVisible(find.text('المدود'));
    await tester.tap(find.text('المدود'));
    await tester.pumpAndSettle();

    // Two short names share a row, with 8 between them.
    final first = tester.getRect(_tag('المد الطبيعي'));
    final second = tester.getRect(_tag('المد المتصل'));
    expect(first.height, 33);
    expect(second.size, first.size);
    expect(second.top, first.top);
    expect(first.left - second.right, 8);
    // The name sits in the middle of its tag.
    expect(
      tester.getCenter(find.text('المد الطبيعي')).dx,
      moreOrLessEquals(first.center.dx, epsilon: 0.5),
    );

    // The long name takes more columns instead of being cut.
    final long = tester.getRect(_tag(_longRuleName));
    expect(long.width, greaterThan(first.width));
    expect(long.height, 33);
    expect(
      tester.getSize(find.text(_longRuleName)).width,
      lessThan(long.width),
    );

    expect(
      tester.widget<Text>(find.text('المدود')).style?.color,
      const Color(0xFF11554F),
    );
    // Only the title row is highlighted, not the rules under it.
    final header = tester.widget<Ink>(
      find.ancestor(of: find.text('المدود'), matching: find.byType(Ink)).first,
    );
    final decoration = header.decoration! as ShapeDecoration;
    expect(decoration.color, const Color(0xFFD2EBE7));
    expect(
      (decoration.shape as RoundedRectangleBorder).side.color,
      const Color(0xFFB2DED8),
    );
    final headerRect = tester.getRect(
      find
          .ancestor(of: find.text('المدود'), matching: find.byType(ListTile))
          .first,
    );
    expect(first.top - headerRect.bottom, 8);
    final closed = tester.widget<Ink>(
      find.ancestor(of: find.text('مقدمات'), matching: find.byType(Ink)).first,
    );
    expect((closed.decoration! as ShapeDecoration).color, Colors.transparent);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps a long rule name whole on a narrow screen', (
    tester,
  ) async {
    await _pump(tester, size: const Size(320, 1600));
    await tester.ensureVisible(find.text('المدود'));
    await tester.tap(find.text('المدود'));
    await tester.pumpAndSettle();

    expect(find.text(_longRuleName), findsOneWidget);
    expect(find.text('المد الطبيعي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers to sit the examination when none is open', (
    tester,
  ) async {
    await _pump(tester, exams: [_examOf('old', ExamStatus.approved)]);

    expect(find.text('تقديم الامتحان'), findsOneWidget);
    expect(find.text('متابعة الامتحان'), findsNothing);
    expect(_button(tester).onPressed, isNotNull);
    expect(tester.getSize(find.byType(FilledButton)).height, 48);
    expect(
      _button(tester).style?.backgroundColor?.resolve({}),
      const Color(0xFF18675F),
    );
  });

  testWidgets('still shows the course when the examinations cannot be read', (
    tester,
  ) async {
    final exams = await _pump(
      tester,
      examsFailure: const AppFailure('تعذّر الاتصال.'),
    );

    expect(find.text('تعذّر الاتصال.'), findsNothing);
    expect(find.text('دورة الأحكام'), findsOneWidget);
    expect(find.text('معلومات الامتحان'), findsOneWidget);
    expect(find.text('الأحكام الرئيسية'), findsOneWidget);
    expect(find.text('المدود'), findsOneWidget);
    expect(find.text('تقديم الامتحان'), findsOneWidget);
    expect(_button(tester).onPressed, isNotNull);
    expect(exams.started, 0);
  });

  testWidgets('continues the open examination without starting another', (
    tester,
  ) async {
    final exams = await _pump(
      tester,
      exams: [_examOf('open', ExamStatus.inProgress)],
    );

    expect(find.text('متابعة الامتحان'), findsOneWidget);
    expect(find.text('تقديم الامتحان'), findsNothing);

    await tester.tap(find.text('متابعة الامتحان'));
    await tester.pumpAndSettle();

    expect(find.text('exam open'), findsOneWidget);
    expect(exams.started, 0);
  });

  testWidgets('disables the button while an examination awaits review', (
    tester,
  ) async {
    await _pump(tester, exams: [_examOf('sent', ExamStatus.pendingReview)]);

    expect(find.text('الامتحان قيد المراجعة'), findsOneWidget);
    expect(find.text('تقديم الامتحان'), findsNothing);
    expect(find.text('متابعة الامتحان'), findsNothing);
    expect(_button(tester).onPressed, isNull);
  });
}
