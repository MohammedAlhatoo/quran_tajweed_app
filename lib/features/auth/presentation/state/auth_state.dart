import '../../domain/entities/app_user.dart';

sealed class AuthState {
  const AuthState();
}

/// The saved session has not been checked yet.
class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user, {this.isNewAccount = false});

  final AppUser user;
  final bool isNewAccount;
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent(this.email);

  final String email;
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}
