import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/exam_status.dart';
import '../../domain/entities/submission_answer.dart';
import '../../domain/repositories/recording_repository.dart';
import '../../domain/repositories/submission_repository.dart';

class FirestoreSubmissionRepository implements SubmissionRepository {
  FirestoreSubmissionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> submitExam({
    required String examId,
    required String studentId,
    required List<SubmissionAnswer> answers,
  }) async {
    // The submission shares the examination's ID, so an examination can be
    // submitted only once.
    final submission = _firestore
        .collection(FirebaseCollections.submissions)
        .doc(examId);
    final exam = _firestore.collection(FirebaseCollections.exams).doc(examId);

    final batch = _firestore.batch()
      ..set(submission, {
        'examId': examId,
        'studentId': studentId,
        // The Storage path, not a download link: a link would let anyone
        // holding it bypass the Storage rules.
        'recordingUrl': recitationRecordingPath(examId),
        'answers': [for (final answer in answers) answer.toMap()],
        'submittedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..update(exam, {
        'status': ExamStatus.pendingReview.value,
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }
}
