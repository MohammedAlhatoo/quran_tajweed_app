import 'package:cloud_firestore/cloud_firestore.dart';

import 'curriculum_seeder.dart';

/// A [SeedStore] over Firestore.
///
/// The security rules give no client write access to `courses`,
/// `tajweed_rules` or `course_rules`, so this only succeeds against the
/// emulator or where those writes are allowed. Nothing in the app calls it.
class FirestoreSeedStore implements SeedStore {
  FirestoreSeedStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Firestore allows at most 500 writes in a batch.
  static const int _batchSize = 400;

  @override
  Object get timestamp => FieldValue.serverTimestamp();

  @override
  Future<Map<String, Map<String, dynamic>>> readAll(String collection) async {
    final snapshot = await _firestore.collection(collection).get();
    return {for (final doc in snapshot.docs) doc.id: doc.data()};
  }

  @override
  Future<void> writeAll(
    String collection,
    Map<String, Map<String, Object?>> documents,
  ) async {
    final entries = documents.entries.toList();
    for (var i = 0; i < entries.length; i += _batchSize) {
      final batch = _firestore.batch();
      for (final entry in entries.skip(i).take(_batchSize)) {
        batch.set(
          _firestore.collection(collection).doc(entry.key),
          entry.value,
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }
}
