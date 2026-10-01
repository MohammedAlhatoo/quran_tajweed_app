import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/services/auth_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/mosque.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required this._authService,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthService _authService;
  final FirebaseFirestore _firestore;

  static const AuthFailure _unexpected = AuthFailure(
    'حدث خطأ غير متوقع. حاول مرة أخرى.',
  );

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirebaseCollections.users);

  CollectionReference<Map<String, dynamic>> get _mosques =>
      _firestore.collection(FirebaseCollections.mosques);

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final User firebaseUser;
    try {
      firebaseUser = await _authService.signIn(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }

    final AppUser? user;
    try {
      final snapshot = await _users.doc(firebaseUser.uid).get();
      final data = snapshot.data();
      user = data == null ? null : AppUser.fromMap(snapshot.id, data);
    } on FirebaseException catch (e) {
      await _authService.signOut();
      throw _mapFirestoreError(e);
    }

    if (user == null) {
      await _authService.signOut();
      throw const AuthFailure('لا توجد بيانات لهذا الحساب. تواصل مع الإدارة.');
    }
    if (!user.isActive) {
      // The Firebase Authentication account is kept; only the session ends.
      await _authService.signOut();
      throw const AuthFailure('هذا الحساب موقوف. تواصل مع الإدارة.');
    }
    return user;
  }

  @override
  Future<AppUser> registerStudent({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String mosqueId,
  }) async {
    final mosque = await _readActiveMosque(mosqueId);

    final User firebaseUser;
    try {
      firebaseUser = await _authService.createAccount(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }

    final user = AppUser(
      uid: firebaseUser.uid,
      name: name,
      email: firebaseUser.email ?? email,
      phone: phone,
      role: UserRole.student,
      isActive: true,
      mosqueId: mosque.id,
      squareId: mosque.squareId,
      regionId: mosque.regionId,
    );

    try {
      // One write, so the document is never missing its affiliation fields.
      await _users.doc(user.uid).set({
        'uid': user.uid,
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'role': user.role.value,
        'regionId': user.regionId,
        'squareId': user.squareId,
        'mosqueId': user.mosqueId,
        'isActive': user.isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // Do not leave an account behind that has no users document.
      await _discardNewAccount();
      throw _mapFirestoreError(e);
    }
    return user;
  }

  @override
  Future<List<Mosque>> fetchActiveMosques() async {
    try {
      final snapshot = await _mosques.where('isActive', isEqualTo: true).get();
      final mosques = [
        for (final doc in snapshot.docs) ?Mosque.fromMap(doc.id, doc.data()),
      ];
      mosques.sort((a, b) => a.name.compareTo(b.name));
      return mosques;
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  Future<Mosque> _readActiveMosque(String mosqueId) async {
    const unavailable = AuthFailure(
      'المسجد المختار غير متاح. اختر مسجدًا آخر.',
    );
    try {
      final snapshot = await _mosques.doc(mosqueId).get();
      final data = snapshot.data();
      if (data == null || data['isActive'] != true) throw unavailable;
      return Mosque.fromMap(snapshot.id, data) ?? (throw unavailable);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw unavailable;
      throw _mapFirestoreError(e);
    }
  }

  Future<void> _discardNewAccount() async {
    try {
      await _authService.deleteCurrentAccount();
    } on FirebaseAuthException {
      await _authService.signOut();
    }
  }

  AuthFailure _mapAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'INVALID_LOGIN_CREDENTIALS' => const AuthFailure(
        'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
      ),
      'invalid-email' => const AuthFailure('البريد الإلكتروني غير صحيح.'),
      'user-disabled' => const AuthFailure(
        'هذا الحساب موقوف. تواصل مع الإدارة.',
      ),
      'email-already-in-use' => const AuthFailure(
        'هذا البريد الإلكتروني مسجّل مسبقًا.',
      ),
      'weak-password' => const AuthFailure('كلمة المرور ضعيفة.'),
      'too-many-requests' => const AuthFailure(
        'محاولات كثيرة. حاول مرة أخرى لاحقًا.',
      ),
      'network-request-failed' => const AuthFailure(
        'تعذّر الاتصال. تحقق من الإنترنت وحاول مرة أخرى.',
      ),
      _ => _unexpected,
    };
  }

  AuthFailure _mapFirestoreError(FirebaseException e) {
    return switch (e.code) {
      'unavailable' || 'deadline-exceeded' => const AuthFailure(
        'تعذّر الاتصال. تحقق من الإنترنت وحاول مرة أخرى.',
      ),
      'permission-denied' => const AuthFailure(
        'لا تملك صلاحية تنفيذ هذا الإجراء.',
      ),
      _ => _unexpected,
    };
  }
}
