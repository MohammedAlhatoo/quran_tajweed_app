import '../entities/app_user.dart';
import '../entities/mosque.dart';

/// An authentication error carrying an Arabic message ready to show the user.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}

/// All methods throw [AuthFailure] on error.
abstract interface class AuthRepository {
  /// Signs in and returns the account. Inactive accounts are rejected.
  Future<AppUser> signIn({required String email, required String password});

  /// Creates a student account linked to [mosqueId]. The square and region are
  /// taken from the mosque document.
  Future<AppUser> registerStudent({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String mosqueId,
  });

  /// The mosques a student can choose from during registration.
  Future<List<Mosque>> fetchActiveMosques();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();
}
