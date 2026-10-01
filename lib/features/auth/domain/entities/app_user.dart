import 'user_role.dart';

/// An account from the `users` collection.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.phone,
    this.regionId,
    this.squareId,
    this.mosqueId,
    this.photoUrl,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final String? phone;
  final String? regionId;
  final String? squareId;
  final String? mosqueId;
  final String? photoUrl;

  /// Returns null when the document has no valid role.
  static AppUser? fromMap(String uid, Map<String, dynamic> data) {
    final role = UserRole.fromValue(data['role']);
    if (role == null) return null;
    return AppUser(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: role,
      isActive: data['isActive'] == true,
      phone: data['phone'] as String?,
      regionId: data['regionId'] as String?,
      squareId: data['squareId'] as String?,
      mosqueId: data['mosqueId'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }
}
