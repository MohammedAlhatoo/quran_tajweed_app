import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/user_role.dart';
import 'package:quran_tajweed_app/features/auth/presentation/state/auth_state.dart';
import 'package:quran_tajweed_app/router/app_router.dart';
import 'package:quran_tajweed_app/router/route_names.dart';

AuthAuthenticated _signedInAs(UserRole role) {
  return AuthAuthenticated(
    AppUser(
      uid: 'uid-1',
      name: 'مستخدم',
      email: 'user@example.com',
      role: role,
      isActive: true,
    ),
  );
}

void main() {
  const homes = {
    UserRole.student: RouteNames.student,
    UserRole.squareSupervisor: RouteNames.supervisor,
    UserRole.regionOfficer: RouteNames.region,
    UserRole.generalAdmin: RouteNames.admin,
  };

  test('waits on the splash screen until the session is checked', () {
    expect(
      AppRouter.redirectFor(const AuthInitial(), RouteNames.splash),
      isNull,
    );
    expect(
      AppRouter.redirectFor(const AuthInitial(), RouteNames.student),
      RouteNames.splash,
    );
  });

  test('opens the onboarding when the app starts signed out', () {
    expect(
      AppRouter.redirectFor(const AuthUnauthenticated(), RouteNames.splash),
      RouteNames.onboarding,
    );
    expect(
      AppRouter.redirectFor(const AuthError('خطأ'), RouteNames.splash),
      RouteNames.onboarding,
    );
  });

  test('skips the onboarding once it has been seen', () {
    const signedOutStates = [
      AuthUnauthenticated(),
      AuthError('خطأ'),
      AuthPasswordResetSent('user@example.com'),
    ];
    for (final state in signedOutStates) {
      expect(
        AppRouter.redirectFor(state, RouteNames.splash, onboardingSeen: true),
        RouteNames.login,
      );
    }
  });

  test('ignores the onboarding for a signed-in user', () {
    for (final MapEntry(key: role, value: home) in homes.entries) {
      for (final seen in [true, false]) {
        expect(
          AppRouter.redirectFor(
            _signedInAs(role),
            RouteNames.splash,
            onboardingSeen: seen,
          ),
          home,
        );
      }
    }
  });

  test('sends a signed-out user to the login page', () {
    for (final location in homes.values) {
      expect(
        AppRouter.redirectFor(const AuthUnauthenticated(), location),
        RouteNames.login,
      );
    }
    expect(
      AppRouter.redirectFor(const AuthError('خطأ'), RouteNames.admin),
      RouteNames.login,
    );
  });

  test('lets a signed-out user open the onboarding, login and registration '
      'pages', () {
    const signedOutStates = [
      AuthUnauthenticated(),
      AuthError('خطأ'),
      AuthPasswordResetSent('user@example.com'),
    ];
    for (final state in signedOutStates) {
      expect(AppRouter.redirectFor(state, RouteNames.onboarding), isNull);
      expect(AppRouter.redirectFor(state, RouteNames.login), isNull);
      expect(AppRouter.redirectFor(state, RouteNames.register), isNull);
    }
  });

  test('sends each role to its own area after sign-in', () {
    for (final MapEntry(key: role, value: home) in homes.entries) {
      final state = _signedInAs(role);
      expect(AppRouter.redirectFor(state, RouteNames.login), home);
      expect(AppRouter.redirectFor(state, RouteNames.register), home);
      expect(AppRouter.redirectFor(state, RouteNames.splash), home);
      expect(AppRouter.redirectFor(state, RouteNames.onboarding), home);
      expect(AppRouter.redirectFor(state, home), isNull);
      expect(AppRouter.redirectFor(state, '$home/details'), isNull);
    }
  });

  test('keeps every role out of the other roles\' areas', () {
    for (final MapEntry(key: role, value: home) in homes.entries) {
      for (final other in homes.values.where((path) => path != home)) {
        expect(AppRouter.redirectFor(_signedInAs(role), other), home);
        expect(AppRouter.redirectFor(_signedInAs(role), '$other/x'), home);
      }
    }
  });

  test('does not redirect while an auth action is running', () {
    expect(
      AppRouter.redirectFor(const AuthLoading(), RouteNames.login),
      isNull,
    );
    expect(
      AppRouter.redirectFor(const AuthLoading(), RouteNames.student),
      isNull,
    );
  });
}
