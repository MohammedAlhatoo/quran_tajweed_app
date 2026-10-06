import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/mosque.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../entities/organization.dart';

/// Manages the administrative hierarchy: regions, squares, mosques and the
/// accounts linked to them. All methods throw `AppFailure` on error, and the
/// security rules refuse anything outside the caller's scope.
abstract interface class OrganizationRepository {
  Future<Organization> fetchOrganization(AdminScope scope);

  /// Creates the region when [id] is null, otherwise updates it.
  Future<void> saveRegion({
    String? id,
    required String name,
    required bool isActive,
  });

  /// Creates the square in [regionId] when [id] is null, otherwise updates
  /// it. A square never moves to another region.
  Future<void> saveSquare({
    String? id,
    required String name,
    required String regionId,
    required bool isActive,
  });

  /// Creates the mosque in [square] when [id] is null, otherwise updates its
  /// details. Moving an existing mosque is done with [moveMosque].
  Future<void> saveMosque({
    String? id,
    required String name,
    required String address,
    required Square square,
    required bool isActive,
  });

  /// Links [mosque] to [square] and gives the mosque's students the square
  /// and region of [square]. Examinations already started keep the scope
  /// they were started in.
  ///
  /// The mosque and its students change together or not at all.
  Future<void> moveMosque({
    required AdminScope scope,
    required Mosque mosque,
    required Square square,
  });

  /// Creates the Firebase Authentication account of a region officer or a
  /// square supervisor, then its `users` document under the same UID, links
  /// it to its scope, and emails its owner a link to set the password. No
  /// password is stored.
  Future<void> createStaff({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required String regionId,
    String? squareId,
  });

  /// Links the officer [user] to [regionId], or the supervisor [user] to
  /// [squareId] of [regionId]. A null [squareId] leaves a supervisor without
  /// a square.
  Future<void> assignStaff({
    required AppUser user,
    required String regionId,
    String? squareId,
  });

  /// Activates or suspends an account. A suspended account cannot sign in.
  ///
  /// A suspended square supervisor leaves every square that names them, so
  /// the squares can be given to another supervisor. The squares, their
  /// mosques, students and examinations are kept.
  Future<void> setAccountActive({
    required AdminScope scope,
    required AppUser user,
    required bool isActive,
  });

  /// Deletes the account of a region officer or a square supervisor, and
  /// clears it from every region or square that names it. Only the General
  /// Admin may, and never their own account. Nothing else is deleted.
  Future<void> deleteStaff({required AdminScope scope, required AppUser user});

  /// Deletes [square] when it has no mosques, students or examinations, and
  /// leaves its supervisor without a square. Only the General Admin may.
  Future<void> deleteSquare({
    required AdminScope scope,
    required Square square,
  });

  /// Deletes [mosque] when it has no students or examinations. Only the
  /// General Admin may.
  Future<void> deleteMosque({
    required AdminScope scope,
    required Mosque mosque,
  });

  /// Deletes [region] when it has no squares, mosques, accounts or
  /// examinations. Only the General Admin may.
  Future<void> deleteRegion({
    required AdminScope scope,
    required Region region,
  });

  /// Emails [email] a link to set a new password.
  Future<void> sendPasswordReset(String email);
}
