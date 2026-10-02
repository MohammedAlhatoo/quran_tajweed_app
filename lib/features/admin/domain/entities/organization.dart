import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/mosque.dart';
import '../../../auth/domain/entities/user_role.dart';

/// What an administrator manages: the whole system, or one region.
class AdminScope {
  /// The General Admin's scope.
  const AdminScope.system() : regionId = null;

  /// A region officer's scope.
  const AdminScope.region(String this.regionId);

  /// Null for the whole system.
  final String? regionId;

  bool get isSystem => regionId == null;
}

/// A region from the `regions` collection.
class Region {
  const Region({
    required this.id,
    required this.name,
    required this.isActive,
    this.officerId,
  });

  final String id;
  final String name;
  final bool isActive;

  /// The officer linked to the region, if any.
  final String? officerId;

  static Region fromMap(String id, Map<String, dynamic> data) => Region(
    id: id,
    name: data['name'] as String? ?? '',
    isActive: data['isActive'] == true,
    officerId: data['officerId'] as String?,
  );
}

/// A square from the `squares` collection.
class Square {
  const Square({
    required this.id,
    required this.name,
    required this.regionId,
    required this.isActive,
    this.supervisorId,
  });

  final String id;
  final String name;
  final String regionId;
  final bool isActive;

  /// The supervisor linked to the square, if any.
  final String? supervisorId;

  /// Returns null when the document has no region.
  static Square? fromMap(String id, Map<String, dynamic> data) {
    final regionId = data['regionId'];
    if (regionId is! String || regionId.isEmpty) return null;
    return Square(
      id: id,
      name: data['name'] as String? ?? '',
      regionId: regionId,
      isActive: data['isActive'] == true,
      supervisorId: data['supervisorId'] as String?,
    );
  }
}

/// The regions, squares, mosques and accounts inside an [AdminScope].
class Organization {
  const Organization({
    required this.regions,
    required this.squares,
    required this.mosques,
    required this.users,
  });

  final List<Region> regions;
  final List<Square> squares;
  final List<Mosque> mosques;
  final List<AppUser> users;

  List<AppUser> usersWithRole(UserRole role) => [
    for (final user in users)
      if (user.role == role) user,
  ];

  String regionName(String? id) {
    for (final region in regions) {
      if (region.id == id) return region.name;
    }
    return 'منطقة غير معروفة';
  }

  String squareName(String? id) {
    if (id == null) return 'بدون مربع';
    for (final square in squares) {
      if (square.id == id) return square.name;
    }
    return 'مربع غير معروف';
  }

  String mosqueName(String? id) {
    for (final mosque in mosques) {
      if (mosque.id == id) return mosque.name;
    }
    return 'مسجد غير معروف';
  }

  /// The name of the account [uid], or null when it is not in the scope.
  String? userName(String? uid) {
    for (final user in users) {
      if (user.uid == uid) return user.name;
    }
    return null;
  }

  /// The squares a supervisor can be linked to: those without a supervisor,
  /// and the one [supervisor] already holds.
  List<Square> squaresOpenTo(AppUser? supervisor) => [
    for (final square in squares)
      if (square.supervisorId == null ||
          square.supervisorId == supervisor?.uid ||
          square.id == supervisor?.squareId)
        square,
  ];
}
