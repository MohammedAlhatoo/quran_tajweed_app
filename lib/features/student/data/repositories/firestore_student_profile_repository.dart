import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/utils/app_failure.dart';
import '../../domain/repositories/student_profile_repository.dart';

class FirestoreStudentProfileRepository implements StudentProfileRepository {
  FirestoreStudentProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<String?> fetchMosqueName(String mosqueId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.mosques)
          .doc(mosqueId)
          .get();
      return snapshot.data()?['name'] as String?;
    } on FirebaseException catch (e) {
      // Only active mosques are readable.
      if (e.code == 'permission-denied') return null;
      throw AppFailure.fromFirebase(e);
    }
  }
}
