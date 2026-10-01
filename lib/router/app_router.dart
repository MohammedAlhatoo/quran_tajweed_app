import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/state/mosques_cubit.dart';
import 'route_names.dart';

abstract final class AppRouter {
  // Role-based redirects are added in the routing step.
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.login,
    routes: [
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
    ],
  );
}
