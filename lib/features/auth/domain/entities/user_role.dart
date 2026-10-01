enum UserRole {
  student('student'),
  squareSupervisor('square_supervisor'),
  regionOfficer('region_officer'),
  generalAdmin('general_admin');

  const UserRole(this.value);

  /// The value stored in the `role` field of the `users` document.
  final String value;

  static UserRole? fromValue(Object? value) {
    for (final role in values) {
      if (role.value == value) return role;
    }
    return null;
  }
}
