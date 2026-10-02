import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/pages/admin_home_page.dart';
import '../features/auth/domain/entities/user_role.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/state/auth_cubit.dart';
import '../features/auth/presentation/state/auth_state.dart';
import '../features/auth/presentation/state/mosques_cubit.dart';
import '../features/region/presentation/pages/region_home_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/courses/domain/repositories/courses_repository.dart';
import '../features/courses/presentation/pages/course_details_page.dart';
import '../features/courses/presentation/pages/courses_page.dart';
import '../features/courses/presentation/state/course_details_cubit.dart';
import '../features/courses/presentation/state/courses_cubit.dart';
import '../features/exams/data/services/device_recitation_audio.dart';
import '../features/exams/domain/repositories/exams_repository.dart';
import '../features/exams/domain/repositories/recording_repository.dart';
import '../features/exams/presentation/pages/exam_history_page.dart';
import '../features/exams/domain/repositories/submission_repository.dart';
import '../features/exams/presentation/pages/exam_segment_page.dart';
import '../features/exams/presentation/pages/submission_review_page.dart';
import '../features/exams/presentation/state/submission_cubit.dart';
import '../features/exams/presentation/state/exam_cubit.dart';
import '../features/exams/presentation/state/exam_history_cubit.dart';
import '../features/exams/presentation/state/recording_cubit.dart';
import '../features/exams/presentation/state/start_exam_cubit.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/questions/domain/repositories/questions_repository.dart';
import '../features/questions/presentation/pages/questions_page.dart';
import '../features/questions/presentation/state/questions_cubit.dart';
import '../features/student/domain/repositories/student_profile_repository.dart';
import '../features/student/presentation/pages/personal_info_page.dart';
import '../features/student/presentation/pages/profile_page.dart';
import '../features/student/presentation/pages/student_shell.dart';
import '../features/student/presentation/state/mosque_name_cubit.dart';
import '../features/supervisor/domain/repositories/review_repository.dart';
import '../features/supervisor/presentation/pages/exam_review_page.dart';
import '../features/supervisor/presentation/pages/supervisor_home_page.dart';
import '../features/supervisor/presentation/state/evaluation_cubit.dart';
import '../features/supervisor/presentation/state/exam_review_cubit.dart';
import '../features/supervisor/presentation/state/pending_exams_cubit.dart';
import '../features/supervisor/presentation/state/recitation_playback_cubit.dart';
import 'route_names.dart';

abstract final class AppRouter {
  /// Builds the router. It re-runs [redirectFor] whenever the authentication
  /// state changes.
  static GoRouter create(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: RouteNames.splash,
      refreshListenable: _StreamListenable(authCubit.stream),
      redirect: (context, state) =>
          redirectFor(authCubit.state, state.matchedLocation),
      routes: [
        GoRoute(
          path: RouteNames.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: RouteNames.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: RouteNames.register,
          builder: (context, state) => BlocProvider(
            create: (context) =>
                MosquesCubit(context.read<AuthRepository>())..load(),
            child: const RegisterPage(),
          ),
        ),
        ..._studentRoutes(authCubit),
        ..._supervisorRoutes(authCubit),
        GoRoute(
          path: RouteNames.region,
          builder: (context, state) => const RegionHomePage(),
        ),
        GoRoute(
          path: RouteNames.admin,
          builder: (context, state) => const AdminHomePage(),
        ),
      ],
    );
  }

  /// The student's area: four tabs inside the shell, and full-screen pages
  /// that open above it.
  static List<RouteBase> _studentRoutes(AuthCubit authCubit) {
    // The shell's cubit, kept so a submitted examination can refresh the
    // history from a screen outside the shell.
    ExamHistoryCubit? examHistory;

    return [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  CoursesCubit(context.read<CoursesRepository>())..load(),
            ),
            BlocProvider(
              create: (context) {
                final authState = authCubit.state;
                return examHistory = ExamHistoryCubit(
                  context.read<ExamsRepository>(),
                  authState is AuthAuthenticated ? authState.user.uid : '',
                )..load();
              },
            ),
          ],
          child: StudentShell(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.student,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.studentCourses,
                builder: (context, state) => const CoursesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.studentExams,
                builder: (context, state) => const ExamHistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.studentProfile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.studentCourseDetailsPattern,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => CourseDetailsCubit(
                context.read<CoursesRepository>(),
                state.pathParameters['courseId']!,
              )..load(),
            ),
            BlocProvider(
              create: (context) =>
                  StartExamCubit(context.read<ExamsRepository>()),
            ),
          ],
          child: const CourseDetailsPage(),
        ),
      ),
      GoRoute(
        path: RouteNames.studentExamPattern,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => ExamCubit(
                context.read<ExamsRepository>(),
                state.pathParameters['examId']!,
              )..load(),
            ),
            BlocProvider(
              create: (context) => RecordingCubit(
                repository: context.read<RecordingRepository>(),
                recorder: DeviceRecitationRecorder(),
                player: DeviceRecitationPlayer(),
                examId: state.pathParameters['examId']!,
              )..load(),
            ),
            // Kept here so the answers survive leaving the questions screen.
            BlocProvider(
              create: (context) => _questionsCubit(context, authCubit, state),
            ),
          ],
          child: const ExamSegmentPage(),
        ),
      ),
      GoRoute(
        path: RouteNames.studentExamQuestionsPattern,
        builder: (context, state) {
          // The examination screen passes its cubit along with the answers.
          final shared = state.extra;
          return shared is QuestionsCubit
              ? BlocProvider.value(value: shared, child: const QuestionsPage())
              : BlocProvider(
                  create: (context) =>
                      _questionsCubit(context, authCubit, state),
                  child: const QuestionsPage(),
                );
        },
      ),
      GoRoute(
        path: RouteNames.studentExamReviewPattern,
        builder: (context, state) {
          // The questions screen passes its cubit along with the answers.
          final shared = state.extra;
          final authState = authCubit.state;
          return MultiBlocProvider(
            providers: [
              shared is QuestionsCubit
                  ? BlocProvider.value(value: shared)
                  : BlocProvider(
                      create: (context) =>
                          _questionsCubit(context, authCubit, state),
                    ),
              BlocProvider(
                create: (context) => SubmissionCubit(
                  submissions: context.read<SubmissionRepository>(),
                  recordings: context.read<RecordingRepository>(),
                  examId: state.pathParameters['examId']!,
                  studentId: authState is AuthAuthenticated
                      ? authState.user.uid
                      : '',
                )..load(),
              ),
            ],
            child: SubmissionReviewPage(
              onDone: () {
                // The history still shows the examination as in progress.
                final history = examHistory;
                if (history != null && !history.isClosed) history.load();
                context.go(RouteNames.studentExams);
              },
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.studentPersonalInfo,
        builder: (context, state) => BlocProvider(
          create: (context) {
            final authState = authCubit.state;
            return MosqueNameCubit(context.read<StudentProfileRepository>())
              ..load(
                authState is AuthAuthenticated ? authState.user.mosqueId : null,
              );
          },
          child: const PersonalInfoPage(),
        ),
      ),
    ];
  }

  /// The square supervisor's area: the examinations awaiting review, and the
  /// review of one of them.
  static List<RouteBase> _supervisorRoutes(AuthCubit authCubit) {
    // The home's cubit, kept so an approved examination can leave the list.
    PendingExamsCubit? pendingExams;

    return [
      GoRoute(
        path: RouteNames.supervisor,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  CoursesCubit(context.read<CoursesRepository>())..load(),
            ),
            BlocProvider(
              create: (context) {
                final authState = authCubit.state;
                return pendingExams = PendingExamsCubit(
                  context.read<ReviewRepository>(),
                  authState is AuthAuthenticated
                      ? authState.user.squareId
                      : null,
                )..load();
              },
            ),
          ],
          child: const SupervisorHomePage(),
        ),
      ),
      GoRoute(
        path: RouteNames.supervisorExamPattern,
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          final authState = authCubit.state;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => ExamReviewCubit(
                  reviews: context.read<ReviewRepository>(),
                  exams: context.read<ExamsRepository>(),
                  courses: context.read<CoursesRepository>(),
                  examId: examId,
                )..load(),
              ),
              BlocProvider(
                create: (context) => RecitationPlaybackCubit(
                  repository: context.read<ReviewRepository>(),
                  player: DeviceRecitationPlayer(),
                  examId: examId,
                ),
              ),
              BlocProvider(
                create: (context) => EvaluationCubit(
                  repository: context.read<ReviewRepository>(),
                  examId: examId,
                  supervisorId: authState is AuthAuthenticated
                      ? authState.user.uid
                      : '',
                ),
              ),
            ],
            child: ExamReviewPage(
              onApproved: () {
                final pending = pendingExams;
                if (pending != null && !pending.isClosed) pending.load();
                context.go(RouteNames.supervisor);
              },
            ),
          );
        },
      ),
    ];
  }

  static QuestionsCubit _questionsCubit(
    BuildContext context,
    AuthCubit authCubit,
    GoRouterState state,
  ) {
    final authState = authCubit.state;
    return QuestionsCubit(
      context.read<QuestionsRepository>(),
      examId: state.pathParameters['examId']!,
      studentId: authState is AuthAuthenticated ? authState.user.uid : '',
    )..load();
  }

  /// The root of the area a role is allowed to open.
  static String homeFor(UserRole role) {
    return switch (role) {
      UserRole.student => RouteNames.student,
      UserRole.squareSupervisor => RouteNames.supervisor,
      UserRole.regionOfficer => RouteNames.region,
      UserRole.generalAdmin => RouteNames.admin,
    };
  }

  /// Where to send the user instead of [location], or null to stay.
  static String? redirectFor(AuthState authState, String location) {
    switch (authState) {
      case AuthInitial():
        return location == RouteNames.splash ? null : RouteNames.splash;
      case AuthLoading():
        // A sign-in, registration or sign-out is running; wait for its result.
        return null;
      case AuthAuthenticated(:final user):
        final home = homeFor(user.role);
        final insideOwnArea = location == home || location.startsWith('$home/');
        return insideOwnArea ? null : home;
      case AuthUnauthenticated() || AuthError() || AuthPasswordResetSent():
        final isAuthPage =
            location == RouteNames.login || location == RouteNames.register;
        return isAuthPage ? null : RouteNames.login;
    }
  }
}

/// Notifies the router on every event of [stream].
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
