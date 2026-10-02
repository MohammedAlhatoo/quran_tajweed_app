import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../constants/firebase_collections.dart';

/// Creates Firebase Authentication accounts for other people.
///
/// It works on a second Firebase app, so the signed-in administrator's own
/// session is left untouched.
class AccountCreationService {
  static const String _appName = 'accountCreation';

  Future<FirebaseApp> _app() async {
    final exists = Firebase.apps.any((app) => app.name == _appName);
    return exists
        ? Firebase.app(_appName)
        : Firebase.initializeApp(
            name: _appName,
            options: Firebase.app().options,
          );
  }

  Future<FirebaseAuth> _auth() async =>
      FirebaseAuth.instanceFor(app: await _app());

  /// Creates the account of [email] and returns its UID and its email as
  /// Firebase Authentication stores it.
  ///
  /// Firebase requires a password to create an account, so a random one is
  /// used and discarded: it is never shown or stored, and the owner sets
  /// their own through a password reset link.
  Future<({String uid, String email})> create(String email) async {
    final auth = await _auth();
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: _discardedPassword(),
    );
    final user = credential.user!;
    return (uid: user.uid, email: user.email ?? email);
  }

  /// Writes `users/{uid}` as the account just created. The security rules
  /// accept an administrative profile only from its own account, so the
  /// document always belongs to a real Firebase Authentication account.
  Future<void> saveProfile(String uid, Map<String, dynamic> data) async {
    await FirebaseFirestore.instanceFor(app: await _app())
        .collection(FirebaseCollections.users)
        .doc(uid)
        .set(data);
  }

  /// Deletes the account just created, when its profile could not be saved.
  ///
  /// Returns false when the account could not be deleted: it then stays in
  /// Firebase Authentication without a profile, and its email stays taken.
  Future<bool> discard() async {
    final auth = await _auth();
    try {
      await auth.currentUser?.delete();
      return true;
    } on FirebaseAuthException {
      await auth.signOut();
      return false;
    }
  }

  /// Ends the second app's session once the account is complete.
  Future<void> finish() async => (await _auth()).signOut();

  static String _discardedPassword() {
    final random = Random.secure();
    return String.fromCharCodes([
      for (var i = 0; i < 32; i++) 33 + random.nextInt(94),
    ]);
  }
}
