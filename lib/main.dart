import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

class QuranTajweedApp extends StatelessWidget {
  const QuranTajweedApp({super.key});

  static const Locale _arabic = Locale('ar');

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (_) => FirebaseAuthRepository(authService: AuthService()),
      child: BlocProvider(
        create: (context) => AuthCubit(context.read<AuthRepository>()),
        child: MaterialApp.router(
          title: AppConstants.appName,
          theme: AppTheme.light,
          // The Arabic locale makes the whole app RTL.
          locale: _arabic,
          supportedLocales: const [_arabic],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
