import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/role_shell.dart';
import '../core/widgets/state_views.dart';
import '../features/admin/domain/entities/exam_report.dart';
import '../features/admin/domain/entities/organization.dart';
import '../features/admin/domain/repositories/organization_repository.dart';
import '../features/admin/domain/repositories/reports_repository.dart';
import '../features/admin/presentation/pages/admin_home_page.dart';
import '../features/admin/presentation/state/organization_cubit.dart';
import '../features/admin/presentation/state/report_cubit.dart';
import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/domain/entities/user_role.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/state/auth_cubit.dart';
import '../features/auth/presentation/state/auth_state.dart';
import '../features/auth/presentation/state/mosques_cubit.dart';
import '../features/onboarding/data/onboarding_store.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/region/presentation/pages/region_home_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/certificates/domain/repositories/certificates_repository.dart';
import '../features/certificates/presentation/pages/certificate_page.dart';
import '../features/certificates/presentation/pages/certificates_page.dart';
import '../features/certificates/presentation/state/certificates_cubit.dart';
import '../features/courses/domain/repositories/courses_repository.dart';
import '../features/courses/presentation/pages/course_details_page.dart';
import '../features/courses/presentation/pages/courses_page.dart';
import '../features/courses/presentation/state/course_details_cubit.dart';
import '../features/courses/presentation/state/courses_cubit.dart';
import '../features/exams/data/services/device_recitation_audio.dart';
import '../features/exams/domain/repositories/evaluations_repository.dart';
import '../features/exams/domain/repositories/exams_repository.dart';
import '../features/exams/domain/repositories/recording_repository.dart';
import '../features/exams/presentation/pages/exam_history_page.dart';
import '../features/exams/presentation/pages/exam_result_page.dart';
import '../features/exams/presentation/state/exam_result_cubit.dart';
import '../features/notifications/domain/entities/app_notification.dart';
import '../features/notifications/domain/repositories/notifications_repository.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/notifications/presentation/state/notifications_cubit.dart';
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
import '../features/supervisor/presentation/state/reviewed_exams_cubit.dart';
import 'route_names.dart';

abstract final class AppRouter {
  /// The shortest time the splash screen stays on screen.
  static const Duration splashMinimum = Duration(seconds: 3);

  /// Builds the router. It re-runs [redirectFor] whenever the authentication
  /// state changes.
  static GoRouter create(AuthCubit authCubit, OnboardingStore onboardingStore) {
    final splashHold = _SplashHold(splashMinimum);

    return GoRouter(
      initialLocation: RouteNames.splash,
      // On the web the address bar keeps the last page; every launch still
      // starts from the splash screen.
      overridePlatformDefaultLocation: true,
      refreshListenable: Listenable.merge([
        _StreamListenable(authCubit.stream),
        splashHold,
      ]),
      redirect: (context, state) {
        final location = state.matchedLocation;
        // The session is often checked faster than the splash can be seen.
        if (location == RouteNames.splash && !splashHold.isOver) return null;
        return redirectFor(
          authCubit.state,
          location,
          onboardingSeen: onboardingStore.isSeen,
        );
      },
      routes: [
        GoRoute(
          path: RouteNames.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: RouteNames.onboarding,
          builder: (context, state) => OnboardingPage(
            onStart: () {
              onboardingStore.markSeen();
              context.go(RouteNames.login);
            },
          ),
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
          builder: (context, state) {
            final regionId = _user(authCubit)?.regionId;
            // An officer who is not linked to a region manages nothing.
            if (regionId == null || regionId.isEmpty) {
              return const RoleShell(
                tabs: [
                  RoleTab(
                    label: 'المنطقة',
                    icon: Icons.map_outlined,
                    title: 'مسؤول المنطقة',
                    body: AppMessageView(
                      message: 'حسابك غير مرتبط بمنطقة. تواصل مع الإدارة.',
                    ),
                  ),
                ],
              );
            }
            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => OrganizationCubit(
                    context.read<OrganizationRepository>(),
                    AdminScope.region(regionId),
                  )..load(),
                ),
                BlocProvider(
                  create: (context) => ReportCubit(
                    context.read<ReportsRepository>(),
                    ReportScope.region(regionId),
                  ),
                ),
              ],
              child: const RegionHomePage(),
            );
          },
        ),
        GoRoute(
          path: RouteNames.admin,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => OrganizationCubit(
                  context.read<OrganizationRepository>(),
                  const AdminScope.system(),
                )..load(),
              ),
              BlocProvider(
                create: (context) => ReportCubit(
                  context.read<ReportsRepository>(),
                  const ReportScope.system(),
                ),
              ),
            ],
            child: const AdminHomePage(),
          ),
        ),
      ],
    );
  }

  /// The signed-in account, or null when nobody is signed in.
  static AppUser? _user(AuthCubit authCubit) {
    final state = authCubit.state;
    return state is AuthAuthenticated ? state.user : null;
  }

  static NotificationsCubit _studentNotifications(
    BuildContext context,
    AuthCubit authCubit,
  ) {
    final uid = _user(authCubit)?.uid;
    return NotificationsCubit(
      context.read<NotificationsRepository>(),
      uid == null ? null : NotificationAudience.user(uid),
    )..start();
  }

  static ExamResultCubit _examResult(
    BuildContext context,
    GoRouterState state,
  ) {
    return ExamResultCubit(
      exams: context.read<ExamsRepository>(),
      evaluations: context.read<EvaluationsRepository>(),
      certificates: context.read<CertificatesRepository>(),
      courses: context.read<CoursesRepository>(),
      examId: state.pathParameters['examId']!,
    )..load();
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
            // Feeds the unread counter on the home tab.
            BlocProvider(
              create: (context) => _studentNotifications(context, authCubit),
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
                  studentName: authState is AuthAuthenticated
                      ? authState.user.name
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
        path: RouteNames.studentExamResultPattern,
        builder: (context, state) => BlocProvider(
          create: (context) => _examResult(context, state),
          child: const ExamResultPage(),
        ),
      ),
      GoRoute(
        path: RouteNames.studentExamCertificatePattern,
        builder: (context, state) => BlocProvider(
          create: (context) => _examResult(context, state),
          child: const CertificatePage(),
        ),
      ),
      GoRoute(
        path: RouteNames.studentNotifications,
        builder: (context, state) => BlocProvider(
          create: (context) => _studentNotifications(context, authCubit),
          child: NotificationsPage(
            // Every student notification is about an examination's result.
            onOpen: (notification) => context.push(
              RouteNames.studentExamResult(notification.relatedId),
            ),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.studentCertificates,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  CoursesCubit(context.read<CoursesRepository>())..load(),
            ),
            BlocProvider(
              create: (context) => CertificatesCubit(
                context.read<CertificatesRepository>(),
                _user(authCubit)?.uid ?? '',
              )..load(),
            ),
          ],
          child: const CertificatesPage(),
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
            BlocProvider(
              create: (context) => ReviewedExamsCubit(
                reviews: context.read<ReviewRepository>(),
                evaluations: context.read<EvaluationsRepository>(),
                squareId: _user(authCubit)?.squareId,
              )..load(),
            ),
            // Loaded when its tab is opened.
            BlocProvider(
              create: (context) {
                final squareId = _user(authCubit)?.squareId;
                return ReportCubit(
                  context.read<ReportsRepository>(),
                  squareId == null || squareId.isEmpty
                      ? null
                      : ReportScope.square(squareId),
                );
              },
            ),
            BlocProvider(
              create: (context) {
                final squareId = _user(authCubit)?.squareId;
                return NotificationsCubit(
                  context.read<NotificationsRepository>(),
                  squareId == null || squareId.isEmpty
                      ? null
                      : NotificationAudience.square(squareId),
                )..start();
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
  static String? redirectFor(
    AuthState authState,
    String location, {
    bool onboardingSeen = false,
  }) {
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
        // A signed-out launch opens the onboarding first, but only until it
        // has been seen once.
        if (location == RouteNames.splash) {
          return onboardingSeen ? RouteNames.login : RouteNames.onboarding;
        }
        if (location == RouteNames.onboarding) {
          return onboardingSeen ? RouteNames.login : null;
        }
        final isPublicPage =
            location == RouteNames.login || location == RouteNames.register;
        return isPublicPage ? null : RouteNames.login;
    }
  }
}

/// Notifies the router once the splash screen has been shown long enough.
class _SplashHold extends ChangeNotifier {
  _SplashHold(Duration duration) {
    Timer(duration, () {
      isOver = true;
      notifyListeners();
    });
  }

  bool isOver = false;
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
