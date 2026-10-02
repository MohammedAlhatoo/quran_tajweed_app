import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/evaluation.dart';
import '../../domain/repositories/evaluations_repository.dart';

class FirestoreEvaluationsRepository implements EvaluationsRepository {
  FirestoreEvaluationsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  @override
  Future<Evaluation?> fetchEvaluation(String examId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.evaluations)
          .doc(examId)
          .get();
      final data = snapshot.data();
      return data == null
          ? null
          : Evaluation.fromMap(snapshot.id, data, toDate: _toDate);
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }

  @override
  Future<Map<String, Evaluation>> fetchEvaluations(
    Iterable<String> examIds,
  ) async {
    // Read one by one by ID: an evaluation holds no square or region, so the
    // security rules check the examination of each one.
    final evaluations = await Future.wait(examIds.map(fetchEvaluation));
    return {
      for (final evaluation in evaluations) ?evaluation?.examId: ?evaluation,
    };
  }
}
