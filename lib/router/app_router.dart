import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../features/exams/domain/repositories/exams_repository.dart';
import '../features/exams/presentation/pages/exam_history_page.dart';
import '../features/exams/presentation/pages/exam_segment_page.dart';
import '../features/exams/presentation/state/exam_cubit.dart';
import '../features/exams/presentation/state/exam_history_cubit.dart';
import '../features/exams/presentation/state/start_exam_cubit.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/student/domain/repositories/student_profile_repository.dart';
import '../features/student/presentation/pages/personal_info_page.dart';
import '../features/student/presentation/pages/profile_page.dart';
import '../features/student/presentation/pages/student_shell.dart';
import '../features/student/presentation/state/mosque_name_cubit.dart';
import '../features/supervisor/presentation/pages/supervisor_home_page.dart';
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
        GoRoute(
          path: RouteNames.supervisor,
          builder: (context, state) => const SupervisorHomePage(),
        ),
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
                return ExamHistoryCubit(
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
        builder: (context, state) => BlocProvider(
          create: (context) => ExamCubit(
            context.read<ExamsRepository>(),
            state.pathParameters['examId']!,
          )..load(),
          child: const ExamSegmentPage(),
        ),
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
