import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/services/account_creation_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/mosque.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/organization_repository.dart';

/// Interim implementation without a trusted backend: accounts are created
/// from the administrator's device. The security rules check the role and
/// the scope of every write, and accept an administrative users document
/// only from its own Firebase Authentication account, matching an invitation
/// written by an administrator. Deleting an account deletes its users
/// document and its invitation, which ends its access; the application
/// cannot delete the Firebase Authentication account of another person.
class FirebaseOrganizationRepository implements OrganizationRepository {
  FirebaseOrganizationRepository({
    required AuthService authService,
    required AccountCreationService accountCreationService,
    FirebaseFirestore? firestore,
  }) : _auth = authService,
       _accounts = accountCreationService,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthService _auth;
  final AccountCreationService _accounts;
  final FirebaseFirestore _firestore;

  /// The most students a mosque can have and still move in one batch, which
  /// holds up to 500 writes.
  static const int _maxStudentsPerMove = 450;

  CollectionReference<Map<String, dynamic>> _collection(String name) =>
      _firestore.collection(name);

  CollectionReference<Map<String, dynamic>> get _users =>
      _collection(FirebaseCollections.users);

  @override
  Future<Organization> fetchOrganization(AdminScope scope) async {
    final regionId = scope.regionId;
    // An officer's queries must filter on the region, as the security rules
    // require.
    Query<Map<String, dynamic>> scoped(String collection) => regionId == null
        ? _collection(collection)
        : _collection(collection).where('regionId', isEqualTo: regionId);

    try {
      final regions = <Region>[];
      if (regionId == null) {
        final snapshot = await _collection(FirebaseCollections.regions).get();
        regions.addAll([
          for (final doc in snapshot.docs) Region.fromMap(doc.id, doc.data()),
        ]);
      } else {
        final doc = await _collection(FirebaseCollections.regions)
            .doc(regionId)
            .get();
        if (doc.data() case final data?) {
          regions.add(Region.fromMap(doc.id, data));
        }
      }
      final squares = await scoped(FirebaseCollections.squares).get();
      final mosques = await scoped(FirebaseCollections.mosques).get();
      final users = await scoped(FirebaseCollections.users).get();

      return Organization(
        regions: regions..sort((a, b) => a.name.compareTo(b.name)),
        squares: [
          for (final doc in squares.docs) ?Square.fromMap(doc.id, doc.data()),
        ]..sort((a, b) => a.name.compareTo(b.name)),
        mosques: [
          for (final doc in mosques.docs) ?Mosque.fromMap(doc.id, doc.data()),
        ]..sort((a, b) => a.name.compareTo(b.name)),
        users: [
          for (final doc in users.docs) ?AppUser.fromMap(doc.id, doc.data()),
        ]..sort((a, b) => a.name.compareTo(b.name)),
      );
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<void> saveRegion({
    String? id,
    required String name,
    required bool isActive,
  }) {
    final regions = _collection(FirebaseCollections.regions);
    return _write(
      () => id == null
          ? regions.doc().set({
              'name': name,
              'description': '',
              'officerId': null,
              'isActive': isActive,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            })
          : regions.doc(id).update({
              'name': name,
              'isActive': isActive,
              'updatedAt': FieldValue.serverTimestamp(),
            }),
    );
  }

  @override
  Future<void> saveSquare({
    String? id,
    required String name,
    required String regionId,
    required bool isActive,
  }) {
    final squares = _collection(FirebaseCollections.squares);
    return _write(
      () => id == null
          ? squares.doc().set({
              'name': name,
              'regionId': regionId,
              'supervisorId': null,
              'isActive': isActive,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            })
          : squares.doc(id).update({
              'name': name,
              'isActive': isActive,
              'updatedAt': FieldValue.serverTimestamp(),
            }),
    );
  }

  @override
  Future<void> saveMosque({
    String? id,
    required String name,
    required String address,
    required Square square,
    required bool isActive,
  }) {
    final mosques = _collection(FirebaseCollections.mosques);
    return _write(
      () => id == null
          ? mosques.doc().set({
              'name': name,
              'address': address,
              'squareId': square.id,
              'regionId': square.regionId,
              'isActive': isActive,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            })
          : mosques.doc(id).update({
              'name': name,
              'address': address,
              'isActive': isActive,
              'updatedAt': FieldValue.serverTimestamp(),
            }),
    );
  }

  @override
  Future<void> moveMosque({
    required AdminScope scope,
    required Mosque mosque,
    required Square square,
  }) async {
    try {
      var students = _users
          .where('role', isEqualTo: UserRole.student.value)
          .where('mosqueId', isEqualTo: mosque.id);
      if (scope.regionId case final regionId?) {
        students = students.where('regionId', isEqualTo: regionId);
      }
      final outdated = [
        for (final doc in (await students.get()).docs)
          if (doc.data()['squareId'] != square.id ||
              doc.data()['regionId'] != square.regionId)
            doc.reference,
      ];
      // Refused as a whole rather than moved in parts.
      if (outdated.length > _maxStudentsPerMove) {
        throw const AppFailure(
          'عدد طلاب المسجد أكبر من أن يُنقل في عملية واحدة. '
          'لم يتغيّر شيء.',
        );
      }

      // One batch: the mosque and all its students move together, or nothing
      // does. Examinations are not part of it: each keeps the mosque, square
      // and region it was started in.
      final target = {
        'squareId': square.id,
        'regionId': square.regionId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final batch = _firestore.batch()
        ..update(
          _collection(FirebaseCollections.mosques).doc(mosque.id),
          target,
        );
      for (final student in outdated) {
        batch.update(student, target);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<void> createStaff({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required String regionId,
    String? squareId,
  }) async {
    // The Firebase Authentication account comes first; its UID names every
    // document written below.
    final String uid;
    final String accountEmail;
    try {
      (uid: uid, email: accountEmail) = await _accounts.create(email);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }

    final invite = _collection(FirebaseCollections.staffInvites).doc(uid);
    var invited = false;
    try {
      // The administrator states the role and the scope; the security rules
      // check the administrator's authority over them here.
      await invite.set({
        'name': name,
        'email': accountEmail,
        'phone': phone,
        'role': role.value,
        'regionId': regionId,
        'squareId': squareId,
        'createdBy': _auth.currentUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      invited = true;
      // The new account writes its own profile, and the rules accept it only
      // when it repeats the invitation. No password is stored anywhere.
      await _accounts.saveProfile(uid, {
        'uid': uid,
        'name': name,
        'email': accountEmail,
        'phone': phone,
        'role': role.value,
        'regionId': regionId,
        'squareId': squareId,
        'mosqueId': null,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // Do not leave behind an invitation, or an account without a profile.
      if (invited) {
        try {
          await invite.delete();
        } on FirebaseException {
          // An unused invitation gives nobody access once the account is
          // deleted.
        }
      }
      if (!await _accounts.discard()) {
        // The application cannot delete it later, so say where it can be.
        throw AppFailure(
          'تعذّر إنشاء الحساب، وبقي البريد $accountEmail محجوزًا دون حساب '
          'في التطبيق. احذفه من Firebase Console (Authentication) قبل '
          'إعادة المحاولة.',
        );
      }
      throw AppFailure.fromFirebase(e);
    }
    await _accounts.finish();

    var linked = true;
    try {
      final batch = _firestore.batch();
      _link(
        batch,
        role: role,
        uid: uid,
        regionId: regionId,
        squareId: squareId,
      );
      await batch.commit();
    } on FirebaseException {
      linked = false;
    }

    try {
      await _auth.sendPasswordResetEmail(accountEmail);
    } on FirebaseAuthException {
      throw const AppFailure(
        'تم إنشاء الحساب، لكن تعذّر إرسال رابط تعيين كلمة المرور. '
        'أعد إرساله من قائمة الحساب.',
      );
    }
    if (!linked) {
      throw const AppFailure(
        'تم إنشاء الحساب، لكن تعذّر تسجيله على المنطقة أو المربع. '
        'أعد ربطه من قائمة الحساب.',
      );
    }
  }

  @override
  Future<void> assignStaff({
    required AppUser user,
    required String regionId,
    String? squareId,
  }) async {
    try {
      final batch = _firestore.batch()
        ..update(_users.doc(user.uid), {
          'regionId': regionId,
          'squareId': squareId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      await _unlink(batch, user: user, regionId: regionId, squareId: squareId);
      _link(
        batch,
        role: user.role,
        uid: user.uid,
        regionId: regionId,
        squareId: squareId,
      );
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<void> setAccountActive({
    required AdminScope scope,
    required AppUser user,
    required bool isActive,
  }) async {
    try {
      final account = <String, dynamic>{
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final batch = _firestore.batch();
      if (!isActive && user.role == UserRole.squareSupervisor) {
        // The account's own squareId is what gives access to a square, so it
        // is cleared too: reactivated, the supervisor has no square until
        // one is assigned again.
        account['squareId'] = null;
        await _clearLinks(
          batch,
          collection: FirebaseCollections.squares,
          field: 'supervisorId',
          uid: user.uid,
          regionId: scope.regionId,
        );
      }
      batch.update(_users.doc(user.uid), account);
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<void> deleteStaff({
    required AdminScope scope,
    required AppUser user,
  }) async {
    _requireGeneralAdmin(scope);
    final isOfficer = user.role == UserRole.regionOfficer;
    if (!isOfficer && user.role != UserRole.squareSupervisor) {
      throw const AppFailure(
        'يمكن حذف حسابات مسؤولي المناطق ومشرفي المربعات فقط.',
      );
    }
    if (user.uid == _auth.currentUid) {
      throw const AppFailure('لا يمكنك حذف حسابك.');
    }
    try {
      // One batch: the account, its invitation and its links go together.
      // Without its invitation the account cannot write its profile again.
      final batch = _firestore.batch();
      await _clearLinks(
        batch,
        collection: isOfficer
            ? FirebaseCollections.regions
            : FirebaseCollections.squares,
        field: isOfficer ? 'officerId' : 'supervisorId',
        uid: user.uid,
      );
      batch
        ..delete(_collection(FirebaseCollections.staffInvites).doc(user.uid))
        ..delete(_users.doc(user.uid));
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<void> deleteSquare({
    required AdminScope scope,
    required Square square,
  }) async {
    _requireGeneralAdmin(scope);
    try {
      if (await _hasAny(FirebaseCollections.mosques, 'squareId', square.id)) {
        throw const AppFailure(
          'لا يمكن حذف المربع لأنه يحتوي على مساجد. '
          'انقل مساجده أو احذفها أولًا.',
        );
      }
      final accounts = await _users
          .where('squareId', isEqualTo: square.id)
          .get();
      final supervisors = [
        for (final doc in accounts.docs)
          if (doc.data()['role'] == UserRole.squareSupervisor.value)
            doc.reference,
      ];
      if (supervisors.length < accounts.docs.length) {
        throw const AppFailure('لا يمكن حذف المربع لأن فيه طلابًا مسجّلين.');
      }
      if (await _hasAny(FirebaseCollections.exams, 'squareId', square.id)) {
        throw const AppFailure(
          'لا يمكن حذف المربع لأن عليه امتحانات أو نتائج مسجّلة.',
        );
      }

      // The supervisor's account is kept, without a square.
      final batch = _firestore.batch();
      for (final supervisor in supervisors) {
        batch.update(supervisor, {
          'squareId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      batch.delete(_collection(FirebaseCollections.squares).doc(square.id));
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<void> deleteMosque({
    required AdminScope scope,
    required Mosque mosque,
  }) async {
    _requireGeneralAdmin(scope);
    try {
      if (await _hasAny(FirebaseCollections.users, 'mosqueId', mosque.id)) {
        throw const AppFailure('لا يمكن حذف المسجد لأن فيه طلابًا مسجّلين.');
      }
      if (await _hasAny(FirebaseCollections.exams, 'mosqueId', mosque.id)) {
        throw const AppFailure(
          'لا يمكن حذف المسجد لأن عليه امتحانات أو نتائج مسجّلة.',
        );
      }
      await _collection(FirebaseCollections.mosques).doc(mosque.id).delete();
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<void> deleteRegion({
    required AdminScope scope,
    required Region region,
  }) async {
    _requireGeneralAdmin(scope);
    try {
      const blockers = [
        (FirebaseCollections.squares, 'لأنها تحتوي على مربعات'),
        (FirebaseCollections.mosques, 'لأنها تحتوي على مساجد'),
        (
          FirebaseCollections.users,
          'لأن حسابات (مسؤولًا أو مشرفين أو طلابًا) ما زالت مرتبطة بها',
        ),
        (FirebaseCollections.exams, 'لأن عليها امتحانات أو نتائج مسجّلة'),
      ];
      for (final (collection, reason) in blockers) {
        if (await _hasAny(collection, 'regionId', region.id)) {
          throw AppFailure('لا يمكن حذف المنطقة $reason.');
        }
      }
      await _collection(FirebaseCollections.regions).doc(region.id).delete();
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  /// Records [uid] on the region an officer manages, or on the square a
  /// supervisor reviews.
  void _link(
    WriteBatch batch, {
    required UserRole role,
    required String uid,
    required String regionId,
    required String? squareId,
  }) {
    final update = {'updatedAt': FieldValue.serverTimestamp()};
    if (role == UserRole.regionOfficer) {
      batch.update(_collection(FirebaseCollections.regions).doc(regionId), {
        'officerId': uid,
        ...update,
      });
    } else if (role == UserRole.squareSupervisor && squareId != null) {
      batch.update(_collection(FirebaseCollections.squares).doc(squareId), {
        'supervisorId': uid,
        ...update,
      });
    }
  }

  /// Clears [user] from the region or square it leaves, when that one still
  /// names [user].
  Future<void> _unlink(
    WriteBatch batch, {
    required AppUser user,
    required String regionId,
    required String? squareId,
  }) async {
    final (collection, field, oldId, newId) = switch (user.role) {
      UserRole.regionOfficer => (
        FirebaseCollections.regions,
        'officerId',
        user.regionId,
        regionId,
      ),
      _ => (
        FirebaseCollections.squares,
        'supervisorId',
        user.squareId,
        squareId,
      ),
    };
    if (oldId == null || oldId == newId) return;
    final previous = _collection(collection).doc(oldId);
    if ((await previous.get()).data()?[field] == user.uid) {
      batch.update(previous, {
        field: null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Clears [uid] from every region or square that names it in [field]. An
  /// officer's query must filter on [regionId].
  Future<void> _clearLinks(
    WriteBatch batch, {
    required String collection,
    required String field,
    required String uid,
    String? regionId,
  }) async {
    var linked = _collection(collection).where(field, isEqualTo: uid);
    if (regionId != null) {
      linked = linked.where('regionId', isEqualTo: regionId);
    }
    for (final doc in (await linked.get()).docs) {
      batch.update(doc.reference, {
        field: null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Whether a document of [collection] has [field] equal to [id].
  Future<bool> _hasAny(String collection, String field, String id) async {
    final found = await _collection(collection)
        .where(field, isEqualTo: id)
        .limit(1)
        .get();
    return found.docs.isNotEmpty;
  }

  /// Deleting is the General Admin's alone; the security rules refuse it to
  /// everyone else as well.
  static void _requireGeneralAdmin(AdminScope scope) {
    if (!scope.isSystem) {
      throw const AppFailure('الحذف متاح للمدير العام فقط.');
    }
  }

  Future<void> _write(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  static AppFailure _mapAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' => const AppFailure(
        'هذا البريد الإلكتروني مسجّل مسبقًا.',
      ),
      'invalid-email' => const AppFailure('البريد الإلكتروني غير صحيح.'),
      'user-not-found' => const AppFailure(
        'لا يوجد حساب بهذا البريد الإلكتروني.',
      ),
      'too-many-requests' => const AppFailure(
        'محاولات كثيرة. حاول مرة أخرى لاحقًا.',
      ),
      'network-request-failed' => const AppFailure(
        'تعذّر الاتصال. تحقق من الإنترنت وحاول مرة أخرى.',
      ),
      _ => const AppFailure('حدث خطأ غير متوقع. حاول مرة أخرى.'),
    };
  }
}
