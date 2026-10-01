import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial());

  final AuthRepository _repository;

  Future<void> signIn({required String email, required String password}) {
    return _run(() async {
      final user = await _repository.signIn(
        email: email.trim(),
        password: password,
      );
      return AuthAuthenticated(user);
    });
  }

  Future<void> registerStudent({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String mosqueId,
  }) {
    return _run(() async {
      final user = await _repository.registerStudent(
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
        mosqueId: mosqueId,
      );
      return AuthAuthenticated(user, isNewAccount: true);
    });
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _run(() async {
      await _repository.sendPasswordResetEmail(email.trim());
      return AuthPasswordResetSent(email.trim());
    });
  }

  Future<void> signOut() {
    return _run(() async {
      await _repository.signOut();
      return const AuthInitial();
    });
  }

  Future<void> _run(Future<AuthState> Function() action) async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());
    try {
      emit(await action());
    } on AuthFailure catch (failure) {
      emit(AuthError(failure.message));
    }
  }
}
