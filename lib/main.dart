import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/state/auth_cubit.dart';
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
    return RepositoryProvider<AuthRepository>.value(
      value: _authRepository,
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
