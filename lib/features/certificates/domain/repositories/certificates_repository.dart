import '../entities/certificate.dart';

/// Reads certificates. They are created only when a supervisor approves a
/// passed examination. All methods throw `AppFailure` on error.
abstract interface class CertificatesRepository {
  /// Returns null when [examId] has no certificate.
  Future<Certificate?> fetchCertificate(String examId);

  /// The certificates of [studentId], newest first.
  Future<List<Certificate>> fetchStudentCertificates(String studentId);
}
