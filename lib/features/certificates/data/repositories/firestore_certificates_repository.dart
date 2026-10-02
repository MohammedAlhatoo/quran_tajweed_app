import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/certificate.dart';
import '../../domain/repositories/certificates_repository.dart';

class FirestoreCertificatesRepository implements CertificatesRepository {
  FirestoreCertificatesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _certificates =>
      _firestore.collection(FirebaseCollections.certificates);

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  /// The fields of the certificate of a passed examination. Its ID is
  /// [examId].
  static Map<String, dynamic> document({
    required String examId,
    required String studentId,
    required String courseId,
    required int finalScore,
  }) {
    return {
      'studentId': studentId,
      'examId': examId,
      'courseId': courseId,
      'certificateNumber': Certificate.numberFor(
        examId: examId,
        year: DateTime.now().year,
      ),
      'finalScore': finalScore,
      'issuedAt': FieldValue.serverTimestamp(),
      // The certificate is shown inside the app; no file is generated.
      'fileUrl': null,
    };
  }

  @override
  Future<Certificate?> fetchCertificate(String examId) async {
    try {
      final snapshot = await _certificates.doc(examId).get();
      final data = snapshot.data();
      return data == null
          ? null
          : Certificate.fromMap(snapshot.id, data, toDate: _toDate);
    } on FirebaseException catch (e) {
      // A missing certificate is refused by the security rules, because they
      // read the student from the document.
      if (e.code == 'permission-denied') return null;
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<List<Certificate>> fetchStudentCertificates(String studentId) async {
    try {
      // The security rules allow a student to read only their own
      // certificates, so the query must filter on studentId.
      final snapshot = await _certificates
          .where('studentId', isEqualTo: studentId)
          .get();
      final certificates = [
        for (final doc in snapshot.docs)
          ?Certificate.fromMap(doc.id, doc.data(), toDate: _toDate),
      ];
      // Sorted here to avoid requiring a composite index.
      final oldest = DateTime.fromMillisecondsSinceEpoch(0);
      certificates.sort(
        (a, b) => (b.issuedAt ?? oldest).compareTo(a.issuedAt ?? oldest),
      );
      return certificates;
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }
}
