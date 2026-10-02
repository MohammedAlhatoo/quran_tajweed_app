import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/services/auth_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/state/auth_cubit.dart';
import 'features/courses/data/repositories/firestore_courses_repository.dart';
import 'features/courses/domain/repositories/courses_repository.dart';
import 'features/exams/data/repositories/firebase_recording_repository.dart';
import 'features/exams/data/repositories/firestore_exams_repository.dart';
import 'features/exams/domain/repositories/exams_repository.dart';
import 'features/exams/data/repositories/firestore_submission_repository.dart';
import 'features/exams/domain/repositories/recording_repository.dart';
import 'features/exams/domain/repositories/submission_repository.dart';
import 'features/questions/data/repositories/firestore_questions_repository.dart';
import 'features/questions/domain/repositories/questions_repository.dart';
import 'features/student/data/repositories/firestore_student_profile_repository.dart';
import 'features/student/domain/repositories/student_profile_repository.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const QuranTajweedApp());
}

class QuranTajweedApp extends StatefulWidget {
  const QuranTajweedApp({super.key});

  @override
  State<QuranTajweedApp> createState() => _QuranTajweedAppState();
}

class _QuranTajweedAppState extends State<QuranTajweedApp> {
  static const Locale _arabic = Locale('ar');

  late final AuthRepository _authRepository;
  late final AuthCubit _authCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRepository = FirebaseAuthRepository(authService: AuthService());
    _authCubit = AuthCubit(_authRepository)..restoreSession();
    _router = AppRouter.create(_authCubit);
  }

  @override
  void dispose() {
    _router.dispose();
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<CoursesRepository>(
          create: (_) => FirestoreCoursesRepository(),
        ),
        RepositoryProvider<ExamsRepository>(
          create: (_) => FirestoreExamsRepository(),
        ),
        RepositoryProvider<RecordingRepository>(
          create: (_) =>
              FirebaseRecordingRepository(storageService: StorageService()),
        ),
        RepositoryProvider<SubmissionRepository>(
          create: (_) => FirestoreSubmissionRepository(),
        ),
        RepositoryProvider<QuestionsRepository>(
          create: (_) => FirestoreQuestionsRepository(),
        ),
        RepositoryProvider<StudentProfileRepository>(
          create: (_) => FirestoreStudentProfileRepository(),
        ),
      ],
      child: BlocProvider<AuthCubit>.value(
        value: _authCubit,
        child: MaterialApp.router(
          title: AppConstants.appName,
          theme: AppTheme.light,
          // The Arabic locale makes the whole app RTL.
          locale: _arabic,
          supportedLocales: const [_arabic],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: _router,
        ),
      ),
    );
  }
}
