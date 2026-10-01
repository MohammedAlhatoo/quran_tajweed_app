/// Throws `AppFailure` on error.
abstract interface class StudentProfileRepository {
  /// The name of the student's mosque, or null when it cannot be shown, for
  /// example because the mosque is no longer active.
  Future<String?> fetchMosqueName(String mosqueId);
}
