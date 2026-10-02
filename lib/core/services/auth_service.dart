import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firebase Authentication.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// The user kept from a previous launch, once Firebase has restored it.
  Future<User?> restoreUser() => _auth.authStateChanges().first;

  /// The UID of the signed-in account, or null when nobody is signed in.
  String? get currentUid => _auth.currentUser?.uid;

  Future<User> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  Future<User> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() => _auth.signOut();

  Future<void> deleteCurrentAccount() async => _auth.currentUser?.delete();
}
