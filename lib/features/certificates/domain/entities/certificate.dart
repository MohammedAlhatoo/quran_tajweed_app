/// A certificate from the `certificates` collection. Its ID is the ID of the
/// passed examination it was issued for.
class Certificate {
  const Certificate({
    required this.examId,
    required this.studentId,
    required this.courseId,
    required this.certificateNumber,
    required this.finalScore,
    this.issuedAt,
  });

  final String examId;
  final String studentId;
  final String courseId;
  final String certificateNumber;
  final int finalScore;
  final DateTime? issuedAt;

  /// The number of the certificate of [examId], issued in [year]. It is
  /// unique because every examination has at most one certificate.
  static String numberFor({required String examId, required int year}) {
    final code = examId.length > 8 ? examId.substring(0, 8) : examId;
    return 'QT-$year-${code.toUpperCase()}';
  }

  /// Returns null when a required field is missing. [toDate] converts a
  /// stored timestamp value.
  static Certificate? fromMap(
    String id,
    Map<String, dynamic> data, {
    required DateTime? Function(Object? value) toDate,
  }) {
    final studentId = data['studentId'];
    final courseId = data['courseId'];
    final number = data['certificateNumber'];
    final finalScore = data['finalScore'];
    if (studentId is! String ||
        courseId is! String ||
        number is! String ||
        finalScore is! int) {
      return null;
    }
    return Certificate(
      examId: id,
      studentId: studentId,
      courseId: courseId,
      certificateNumber: number,
      finalScore: finalScore,
      issuedAt: toDate(data['issuedAt']),
    );
  }
}
